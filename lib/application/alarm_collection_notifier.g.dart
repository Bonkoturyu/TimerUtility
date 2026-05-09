// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_collection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$alarmCollectionNotifierHash() =>
    r'cad41f961165293765901599216427eff8370cb3';

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
///
/// Copied from [AlarmCollectionNotifier].
@ProviderFor(AlarmCollectionNotifier)
final alarmCollectionNotifierProvider =
    NotifierProvider<AlarmCollectionNotifier, List<AlarmEntity>>.internal(
      AlarmCollectionNotifier.new,
      name: r'alarmCollectionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$alarmCollectionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AlarmCollectionNotifier = Notifier<List<AlarmEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
