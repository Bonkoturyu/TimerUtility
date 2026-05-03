import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../domain/alarm/alarm_entity.dart';
import '../domain/alarm/alarm_repeat.dart';
import '../domain/alarm/exceptions.dart';
import '../domain/alarm/time_of_day_value.dart';
import '../domain/ports/permission_manager.dart';
import '../domain/timer/notification_id_generator.dart';
import 'alarm_repository_provider.dart';
import 'alarm_service_provider.dart';
import 'clock_provider.dart';
import 'notification_scheduler_provider.dart';
import 'notification_strings_provider.dart';
import 'permission_notifier.dart';

part 'alarm_collection_notifier.g.dart';

/// Phase 9.5 の指定時刻アラーム集合の唯一の情報源。
///
/// Timer Aggregate と分離した別 Notifier (ADR 0005)。State は
/// `List<AlarmEntity>` で、永続データが中心 (Timer のような揮発状態
/// — running/paused/ringing — は持たない)。
///
/// 各操作:
///   1. 必要なら `AlarmService` で次回発火時刻を計算
///   2. State を更新
///   3. `AlarmRepository.upsert` / `delete` で永続化 (fire-and-forget)
///   4. `NotificationScheduler` に schedule (`payload: 'alarm:<id>'`) /
///      cancel
///
/// 通知 payload には ADR 0005 で定めた `alarm:<AlarmId>` プレフィックスを
/// 必ず付ける。`main.dart` の `onDidReceiveNotificationResponse` がこれを
/// 見て Timer / Alarm のどちらに引き渡すかを分岐する。
///
/// アラームの最大数は 50 件 (`docs/domain-model.md` Phase 9.5 セクション)。
/// `create` で超過すると [MaxAlarmCountExceededException] を投げ、
/// 呼び出し側が SnackBar 等でフィードバックする想定。
///
/// `nextFireAt` 結果はエンティティに格納せず毎回計算する設計。
/// 再起動 / 端末時刻変更後も `nextFireAt(alarm)` を呼べば常に正しい値が
/// 出るので、永続化スキーマに「次回発火時刻」列を持つ必要がない。
@Riverpod(keepAlive: true)
class AlarmCollectionNotifier extends _$AlarmCollectionNotifier {
  static const int maxSize = 50;

  static const Uuid _uuid = Uuid();

  @override
  List<AlarmEntity> build() {
    // 同期返却。永続化された alarm の読み込みは microtask 化して
    // 後追いで反映する (TimerCollectionNotifier の restore と同じ流儀)。
    Future<void>.microtask(_loadFromRepository);
    return const <AlarmEntity>[];
  }

  Future<void> _loadFromRepository() async {
    // 競合回避: build() が microtask で load を予約するが、その完了前に
    // ユーザが create / toggle 等で state を populate するケースがある
    // (テストでは特に頻繁に起きる)。state が既に空でなければ in-memory
    // 側を信頼し、load は何もしない (ダブル schedule を防ぐ)。
    if (state.isNotEmpty) return;
    final List<AlarmEntity> persisted = await ref
        .read(alarmRepositoryProvider)
        .findAll();
    if (persisted.isEmpty) return;
    // 二重チェック: findAll 中に state が populate された場合も捨てる。
    if (state.isNotEmpty) return;
    state = List<AlarmEntity>.unmodifiable(persisted);
    // enabled なアラームは永続化された予約とアプリ内 state を同期させる
    // ため、起動時に一度 reschedule する。Phase 10 BootReceiver は
    // app プロセスが死んでいる間の再起動経由の再予約を担うが、
    // app 起動中の resume / 状態同期はここでカバーする。
    for (final AlarmEntity a in persisted) {
      if (a.enabled) _scheduleAlarm(a);
    }
  }

  /// 新規アラームを作成して永続化、`enabled = true` なら schedule する。
  ///
  /// 戻り値は確定済みの [AlarmEntity] (`id` / `notificationId` / `createdAt`
  /// が確定した状態)。UI 側はこの値を使って次の編集 / 削除フローに
  /// 引き継ぐ。
  Future<AlarmEntity> create({
    required String label,
    required TimeOfDayValue targetTime,
    required AlarmRepeat repeat,
    required int snoozeMinutes,
    required bool enabled,
    String? soundId,
  }) async {
    if (state.length >= maxSize) {
      throw const MaxAlarmCountExceededException(maxSize);
    }
    _validateSnoozeMinutes(snoozeMinutes);
    _validateRepeat(repeat);

    final String id = _uuid.v4();
    final AlarmEntity entity = AlarmEntity(
      id: id,
      notificationId: const NotificationIdGenerator().idFor(id),
      label: label,
      targetTime: targetTime,
      repeat: repeat,
      snoozeMinutes: snoozeMinutes,
      enabled: enabled,
      soundId: soundId,
      createdAt: ref.read(clockProvider).now(),
    );

    state = List<AlarmEntity>.unmodifiable(<AlarmEntity>[...state, entity]);
    _persist(entity);
    if (entity.enabled) _scheduleAlarm(entity);
    return entity;
  }

  /// 既存アラームを置換 (label / targetTime / repeat / snoozeMinutes /
  /// soundId / enabled すべてが対象)。`notificationId` / `createdAt` /
  /// `id` は保持する。
  ///
  /// 既存スケジュールは一旦キャンセルし、enabled=true なら新しい値で
  /// 再 schedule する。
  Future<void> update(AlarmEntity updated) async {
    final int index = state.indexWhere((AlarmEntity a) => a.id == updated.id);
    if (index < 0) {
      throw AlarmNotFoundException(updated.id);
    }
    _validateSnoozeMinutes(updated.snoozeMinutes);
    _validateRepeat(updated.repeat);

    final AlarmEntity merged = updated.copyWith(
      // Identity 系は元の値を保持する。UI で書き換えても無視。
      notificationId: state[index].notificationId,
      createdAt: state[index].createdAt,
    );
    final List<AlarmEntity> next = List<AlarmEntity>.from(state)
      ..[index] = merged;
    state = List<AlarmEntity>.unmodifiable(next);
    _persist(merged);
    _cancel(merged.notificationId);
    if (merged.enabled) _scheduleAlarm(merged);
  }

  /// 既存アラームの `enabled` を反転する (一覧の ON/OFF トグル用途)。
  /// 切り替えた結果に応じて schedule / cancel を行う。
  Future<void> toggle(String id) async {
    final int index = state.indexWhere((AlarmEntity a) => a.id == id);
    if (index < 0) throw AlarmNotFoundException(id);
    final AlarmEntity current = state[index];
    final AlarmEntity next = current.copyWith(enabled: !current.enabled);

    final List<AlarmEntity> updated = List<AlarmEntity>.from(state)
      ..[index] = next;
    state = List<AlarmEntity>.unmodifiable(updated);
    _persist(next);
    if (next.enabled) {
      _scheduleAlarm(next);
    } else {
      _cancel(next.notificationId);
    }
  }

  /// 既存アラームを削除し、保留中の予約も取り消す。
  Future<void> delete(String id) async {
    final int index = state.indexWhere((AlarmEntity a) => a.id == id);
    if (index < 0) return;
    final AlarmEntity removed = state[index];
    final List<AlarmEntity> next = List<AlarmEntity>.from(state)
      ..removeAt(index);
    state = List<AlarmEntity>.unmodifiable(next);
    _cancel(removed.notificationId);
    unawaited(ref.read(alarmRepositoryProvider).delete(id));
  }

  /// 鳴動 → 停止イベント。`AlarmService.advanceAfterFire` で once は
  /// `enabled = false` 化、weekly は維持。weekly の場合は次回発火時刻を
  /// 再計算して schedule し直す。
  Future<void> onFiredStop(String id) async {
    final int index = state.indexWhere((AlarmEntity a) => a.id == id);
    if (index < 0) throw AlarmNotFoundException(id);
    final AlarmEntity advanced = ref
        .read(alarmServiceProvider)
        .advanceAfterFire(state[index]);

    final List<AlarmEntity> next = List<AlarmEntity>.from(state)
      ..[index] = advanced;
    state = List<AlarmEntity>.unmodifiable(next);
    _persist(advanced);
    if (advanced.enabled) {
      // weekly: 次回曜日の発火時刻を再 schedule。
      _scheduleAlarm(advanced);
    } else {
      // once: enabled を落としたので schedule 不要、保留中があれば cancel。
      _cancel(advanced.notificationId);
    }
  }

  /// 鳴動 → スヌーズイベント。`AlarmService.snoozeUntil(now + N 分)` を
  /// 同じ `notificationId` で再 schedule する (上書き)。
  Future<void> onFiredSnooze(String id) async {
    final int index = state.indexWhere((AlarmEntity a) => a.id == id);
    if (index < 0) throw AlarmNotFoundException(id);
    final AlarmEntity alarm = state[index];
    final DateTime fireAt = ref.read(alarmServiceProvider).snoozeUntil(alarm);
    _scheduleAt(alarm: alarm, fireAt: fireAt);
  }

  /// `AlarmCollectionNotifier` の状態を初期化済アラームで上書きする。
  /// 主にテスト用 (実装側からは使わない想定だが、Phase 10 BootReceiver
  /// 経由の再復元に備えて公開しておく)。
  void debugReplaceState(List<AlarmEntity> alarms) {
    state = List<AlarmEntity>.unmodifiable(alarms);
  }

  // ---------------------------------------------------------------------
  // 内部ヘルパ
  // ---------------------------------------------------------------------

  void _persist(AlarmEntity entity) {
    unawaited(ref.read(alarmRepositoryProvider).upsert(entity));
  }

  void _scheduleAlarm(AlarmEntity entity) {
    final DateTime fireAt = ref.read(alarmServiceProvider).nextFireAt(entity);
    _scheduleAt(alarm: entity, fireAt: fireAt);
  }

  void _scheduleAt({required AlarmEntity alarm, required DateTime fireAt}) {
    final DomainPermissionStatus exact = ref
        .read(permissionNotifierProvider)
        .scheduleExactAlarm;
    final bool useExact =
        exact == DomainPermissionStatus.granted ||
        exact == DomainPermissionStatus.notRequired;
    final NotificationStrings strings = ref.read(
      notificationStringsNotifierProvider,
    );
    final String title = alarm.label.isEmpty
        ? strings.alarmRingingTitle
        : alarm.label;
    unawaited(
      ref
          .read(notificationSchedulerProvider)
          .schedule(
            notificationId: alarm.notificationId,
            fireAt: fireAt,
            title: title,
            body: strings.alarmRingingBody,
            exact: useExact,
            payload: 'alarm:${alarm.id}',
          ),
    );
  }

  void _cancel(int notificationId) {
    unawaited(ref.read(notificationSchedulerProvider).cancel(notificationId));
  }

  void _validateSnoozeMinutes(int snoozeMinutes) {
    if (snoozeMinutes != 5 && snoozeMinutes != 10 && snoozeMinutes != 15) {
      throw InvalidSnoozeMinutesException(snoozeMinutes);
    }
  }

  void _validateRepeat(AlarmRepeat repeat) {
    if (repeat is AlarmRepeatWeekly && repeat.days.isEmpty) {
      throw const InvalidAlarmRepeatException(
        'AlarmRepeatWeekly requires at least one day',
      );
    }
  }
}
