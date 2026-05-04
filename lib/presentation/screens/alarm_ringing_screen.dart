import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/alarm_collection_notifier.dart';
import '../../application/alarm_ringing_notifier.dart';
import '../../application/timer_collection_notifier.dart';
import '../../domain/alarm/alarm_entity.dart';
import '../../domain/alarm/exceptions.dart';
import '../../domain/timer/alarm_sound.dart';
import '../../domain/timer/alarm_sound_catalog.dart';
import '../../domain/timer/notification_id_generator.dart';
import '../../domain/timer/snooze_calculator.dart';
import '../../domain/timer/timer_entity.dart';
import '../../l10n/app_localizations.dart';

/// Native channel used to release the keyguard-override state set by
/// Android when this screen was launched via FullScreenIntent. Reuses
/// the existing permission channel rather than spinning up a second
/// channel just for one method.
const MethodChannel _permissionChannel = MethodChannel(
  'com.bonkotu.timer/permission',
);

/// Phase 8 ringing screen. Reads the currently ringing timer from
/// [TimerCollectionNotifier]. If multiple timers ring concurrently we
/// service the first one in collection order — Stop / Snooze still
/// only act on that single entry, so a second ringing timer surfaces
/// once the user dismisses this one.
///
/// `initState` self-bootstraps `AlarmRingingNotifier.start` whenever
/// the notifier is still idle on entry, covering the FSI / cold-start
/// paths where the foreground tick path either hasn't fired or doesn't
/// know which timer fired (cold launch with no in-memory state). When
/// no ringing timer is found in the collection, we still bootstrap
/// audio with a synthetic 'unknown' id so the user is never met with
/// silence on this screen.
class AlarmRingingScreen extends ConsumerStatefulWidget {
  const AlarmRingingScreen({super.key, this.payload});

  /// 通知タップ時の payload (ADR 0005 で定めた `timer:<id>` /
  /// `alarm:<id>` 形式)。warm-launch / cold-launch 共に
  /// `main.dart` 側で queryParameters['payload'] に詰めて渡される。
  /// `null` の場合は app 内 ringing listener 経由 (既存の Timer
  /// path) として扱う。
  final String? payload;

  @override
  ConsumerState<AlarmRingingScreen> createState() => _AlarmRingingScreenState();

  /// Synchronous reservation flag used by both push paths
  /// (`main.dart#onNotificationTap` and `TimerListScreen`'s ringing
  /// listener) to dedupe concurrent push attempts.
  ///
  /// Both paths can fire in the same frame when a timer rings while
  /// the app is backgrounded:
  ///   1. The OS notification tap delivers `onDidReceiveNotificationResponse`
  ///   2. The TimerCollection ticker resumes and flips state to ringing,
  ///      causing TimerListScreen's `ref.listen` to schedule a push.
  /// Each path's "is alarm screen already on top?" check (matchedLocation)
  /// can race past the other before the route stack settles, leaving
  /// two `/alarm-ringing` frames stacked. With this flag both callers
  /// commit synchronously to the push attempt and the loser bails
  /// before adding a second frame.
  ///
  /// Reset in [_AlarmRingingScreenState.dispose] so a future ring can
  /// push again after the screen is dismissed.
  static bool _pushReserved = false;

  /// Atomic check-and-set: returns false if a push has already been
  /// reserved (and is either pending or currently mounted), true if
  /// this caller now owns the slot. Caller must follow up with a
  /// `push('/alarm-ringing')`. The reservation is released in
  /// [_AlarmRingingScreenState.dispose].
  static bool tryReservePush() {
    if (_pushReserved) return false;
    _pushReserved = true;
    return true;
  }

  /// Test seam: tests can call this in `tearDown` to reset the flag
  /// without going through the full widget mount/dispose cycle.
  @visibleForTesting
  static void debugResetPushReservation() {
    _pushReserved = false;
  }
}

class _AlarmRingingScreenState extends ConsumerState<AlarmRingingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapRingingIfNeeded();
    });
  }

  @override
  void dispose() {
    // Release the reservation regardless of how this screen was
    // entered. Cold-launch via `initialLocation` skips the reserve
    // step (the flag stays false there), so resetting to false here
    // is always correct.
    AlarmRingingScreen._pushReserved = false;
    super.dispose();
  }

  void _bootstrapRingingIfNeeded() {
    final ringing = ref.read(alarmRingingNotifierProvider);
    if (ringing.isPlaying) return;

    final (AlarmSource source, String? sourceId) = _parsePayload(
      widget.payload,
    );

    if (source == AlarmSource.alarm && sourceId != null) {
      _bootstrapAlarm(sourceId);
    } else {
      _bootstrapTimer(payloadId: sourceId);
    }
  }

  void _bootstrapTimer({String? payloadId}) {
    final TimerEntity? entity = ref
        .read(timerCollectionNotifierProvider.notifier)
        .findRinging();
    // 1) in-memory に ringing 中の timer があればその id
    // 2) 無ければ payload の id (旧形式 payload / cold-start で state 未復元)
    // 3) どちらも無ければ 'unknown' (audio だけは鳴らす、Phase 8 既存挙動)
    final String timerId = entity?.id ?? payloadId ?? 'unknown';
    final AlarmSound sound =
        (entity?.soundId == null
            ? null
            : AlarmSoundCatalog.findById(entity!.soundId!)) ??
        AlarmSoundCatalog.defaultSound;
    // Cold start may have lost the entity, so we have no notification id
    // to cancel. -1 is harmless: cancel on a non-existent id is a no-op
    // on Android.
    final int notificationId = entity?.notificationId ?? -1;

    ref
        .read(alarmRingingNotifierProvider.notifier)
        .start(
          timerId: timerId,
          sound: sound,
          notificationId: notificationId,
          source: AlarmSource.timer,
        );
  }

  void _bootstrapAlarm(String alarmId) {
    final List<AlarmEntity> alarms = ref.read(alarmCollectionNotifierProvider);
    AlarmEntity? entity;
    for (final AlarmEntity a in alarms) {
      if (a.id == alarmId) {
        entity = a;
        break;
      }
    }
    final AlarmSound sound =
        (entity?.soundId == null
            ? null
            : AlarmSoundCatalog.findById(entity!.soundId!)) ??
        AlarmSoundCatalog.defaultSound;
    // cold-start + FSI 経路では `AlarmCollectionNotifier._loadFromRepository`
    // の microtask が `addPostFrameCallback` より遅れることがあり、entity が
    // 取れないケースがある。その場合に `-1` を渡すと `cancel(-1)` が no-op
    // になって OS 通知音が止まらず audioplayers と重なる二重音が発生する
    // (実機検証 2026-05-04 シナリオ 4 で観測)。
    //
    // `NotificationIdGenerator.idFor(alarmId)` は deterministic
    // (`alarmId.hashCode & 0x7FFFFFFF`) なので、entity が無くても同じ id を
    // 再計算できる。`AlarmCollectionNotifier.create` でも
    // `NotificationIdGenerator().idFor(id)` で発番しているため、永続化済の
    // notificationId と必ず一致する。
    final int notificationId =
        entity?.notificationId ??
        const NotificationIdGenerator().idFor(alarmId);
    ref
        .read(alarmRingingNotifierProvider.notifier)
        .start(
          timerId: alarmId,
          sound: sound,
          notificationId: notificationId,
          source: AlarmSource.alarm,
        );
  }

  /// payload を `(source, sourceId)` に分解。
  /// - `'timer:abc'` → `(timer, 'abc')`
  /// - `'alarm:def'` → `(alarm, 'def')`
  /// - `null` → `(timer, null)` (in-app ringing listener 経由)
  /// - その他 (プレフィックスなし) → `(timer, payload)`
  ///   後方互換パス。Phase 9 までは payload に timer の id を裸で
  ///   入れていたので、アプリ更新後に旧形式の永続化通知をタップしても
  ///   id を失わず timer として扱う。
  (AlarmSource, String?) _parsePayload(String? payload) {
    if (payload == null) return (AlarmSource.timer, null);
    if (payload.startsWith('alarm:')) {
      return (AlarmSource.alarm, payload.substring('alarm:'.length));
    }
    if (payload.startsWith('timer:')) {
      return (AlarmSource.timer, payload.substring('timer:'.length));
    }
    return (AlarmSource.timer, payload);
  }

  @override
  Widget build(BuildContext context) {
    final ringingNotifier = ref.read(alarmRingingNotifierProvider.notifier);
    final collection = ref.read(timerCollectionNotifierProvider.notifier);
    final AppLocalizations l = AppLocalizations.of(context);
    // Stop / Snooze 押下時の分岐は、現在 ringing 中の AlarmRingingState の
    // currentSource を見る (build 直前に Notifier に source を保存済)。
    // null の場合は Phase 8 までの「タイマーのみ」path にフォールバック。
    final AlarmSource? activeSource = ref
        .watch(alarmRingingNotifierProvider)
        .currentSource;
    final String? activeSourceId = ref
        .watch(alarmRingingNotifierProvider)
        .currentTimerId;

    // Block hardware back / system back gesture / AppBar back button
    // while the alarm is ringing — accidentally dismissing an alarm by
    // brushing the back gesture (especially when half-asleep) silently
    // loses the wake-up signal. Users must tap Stop or Snooze to leave.
    // This matches Google Clock's alarm screen behaviour.
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l.alarmAppBarTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  l.alarmTimesUp,
                  key: const Key('alarm_ringing_title'),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FilledButton(
                      key: const Key('alarm_stop_button'),
                      onPressed: () async {
                        await ringingNotifier.stop();
                        if (activeSource == AlarmSource.alarm &&
                            activeSourceId != null) {
                          // Phase 9.5: alarm 由来 → AlarmCollectionNotifier に
                          // 委譲。once は enabled=false 化、weekly は次回曜日に
                          // 自動進行する。
                          // cold-start で AlarmCollectionNotifier の load が
                          // まだ完了していない / すでに削除済みの場合に
                          // AlarmNotFoundException が飛ぶことがあるが、
                          // 鳴動停止は既に完了しているので no-op で抜ける。
                          try {
                            await ref
                                .read(alarmCollectionNotifierProvider.notifier)
                                .onFiredStop(activeSourceId);
                          } on AlarmNotFoundException {
                            // 何もしない: 通知音は止まっているのでユーザは
                            // 画面を抜けられる。weekly の次回 schedule が
                            // 載らない可能性があるが、次回起動時の load 後に
                            // 反映される。
                          }
                        } else {
                          // Phase 8 までの既存 path: TimerCollection の
                          // ringing を cancelled に落とす。
                          final TimerEntity? ringing = collection.findRinging();
                          if (ringing != null) {
                            collection.cancel(ringing.id);
                          }
                        }
                        if (!context.mounted) return;
                        _leaveAlarmScreen(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          l.alarmStop,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    OutlinedButton(
                      key: const Key('alarm_snooze_button'),
                      onPressed: () {
                        if (activeSource == AlarmSource.alarm &&
                            activeSourceId != null) {
                          _onAlarmSnoozeTap(context, activeSourceId);
                        } else {
                          _onSnoozeTap(context);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          l.alarmSnooze,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSnoozeTap(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final int? minutes = await showModalBottomSheet<int>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l.alarmSnoozePickerTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final int m in SnoozeCalculator.allowedMinutes) ...<Widget>[
                FilledButton(
                  key: Key('alarm_snooze_choice_${m}m'),
                  onPressed: () => Navigator.of(sheetContext).pop(m),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l.alarmSnoozeMinutes(m),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                key: const Key('alarm_snooze_cancel'),
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(l.alarmSnoozeCancel),
              ),
            ],
          ),
        ),
      ),
    );

    if (minutes == null) return;
    if (!context.mounted) return;

    final collection = ref.read(timerCollectionNotifierProvider.notifier);
    final TimerEntity? ringing = collection.findRinging();
    if (ringing == null) return;
    await ref.read(alarmRingingNotifierProvider.notifier).stop();
    collection.snooze(ringing.id, minutes);
    if (!context.mounted) return;
    _leaveAlarmScreen(context);
  }

  /// Phase 9.5: alarm 由来のスヌーズハンドラ。
  ///
  /// Timer 側のように毎回シートで分単位を選択させる UX ではなく、
  /// `AlarmEntity.snoozeMinutes` (5/10/15、edit 画面で設定済) を即時
  /// 適用する。Google Clock 等の標準目覚ましアプリと同じ挙動。
  /// 内部で `AlarmCollectionNotifier.onFiredSnooze` が
  /// `AlarmService.snoozeUntil` を呼び、同 notificationId で再 schedule する。
  Future<void> _onAlarmSnoozeTap(BuildContext context, String alarmId) async {
    await ref.read(alarmRingingNotifierProvider.notifier).stop();
    // Stop 同様、cold-start で load 未完了 / 削除済みの場合に
    // AlarmNotFoundException が飛ぶ可能性があるので握りつぶす。
    // スヌーズ再 schedule は失敗するが、ユーザは画面を抜けられる。
    try {
      await ref
          .read(alarmCollectionNotifierProvider.notifier)
          .onFiredSnooze(alarmId);
    } on AlarmNotFoundException {
      // no-op
    }
    if (!context.mounted) return;
    _leaveAlarmScreen(context);
  }

  /// Leaves the alarm screen back to wherever the user came from.
  ///
  /// Prefer `pop` so the back stack is preserved — when this screen was
  /// pushed onto `[home, /timer]` (in-app ringing or warm-launch from
  /// notification tap with the new push semantics), pop returns to
  /// `[home, /timer]` and the user can back-navigate to home as
  /// expected.
  ///
  /// Cold-launch from a dead-process notification tap starts directly
  /// on `/alarm-ringing` as the initial location, so canPop is false
  /// there. Phase 9.5 follow-up (2026-05-04): payload 種別で fallback
  /// 行き先を切り替える。alarm 由来なら `/alarms` (一覧)、それ以外 (timer
  /// 由来 / payload なし) なら `/timer` に飛ばす。fallback では `go` を
  /// 使うため back-stack はリセットされる。Android 戻るキーで Home に
  /// 戻れない件は、Native 側の launchMode / taskAffinity の調整が必要に
  /// なるので別 follow-up で対応 (本 commit のスコープ外)。
  void _leaveAlarmScreen(BuildContext context) {
    _permissionChannel
        .invokeMethod<void>('clearShowWhenLocked')
        .catchError((_) {});
    if (context.canPop()) {
      context.pop();
      return;
    }
    final AlarmSource? activeSource = ref
        .read(alarmRingingNotifierProvider)
        .currentSource;
    if (activeSource == AlarmSource.alarm) {
      context.go('/alarms');
    } else {
      context.go('/timer');
    }
  }
}
