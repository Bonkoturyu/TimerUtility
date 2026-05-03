// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$alarmRepositoryHash() => r'6861bd0dd5a70582d2cebee92e928bbef297036c';

/// [AlarmCollectionNotifier] が依存する [AlarmRepository] を提供する
/// プロバイダ (Phase 9.5)。
///
/// 本番では `main()` で `DriftAlarmRepository` に override、
/// テストでは in-memory fake に override する想定。
/// override し忘れた場合に挙動が黙って壊れないよう、
/// `timerRepositoryProvider` と同じく throw-on-default とする。
///
/// Copied from [alarmRepository].
@ProviderFor(alarmRepository)
final alarmRepositoryProvider = Provider<AlarmRepository>.internal(
  alarmRepository,
  name: r'alarmRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alarmRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlarmRepositoryRef = ProviderRef<AlarmRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
