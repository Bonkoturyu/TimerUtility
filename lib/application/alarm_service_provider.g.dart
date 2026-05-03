// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$alarmServiceHash() => r'5ed4c9bcdc99abcde13a98fb15db1c31d479a4de';

/// アプリ用 [Clock] を注入した [AlarmService] を提供するプロバイダ
/// (Phase 9.5)。
///
/// `timerServiceProvider` と同形の `keepAlive` 関数 Provider。
/// Notifier 側 (`AlarmCollectionNotifier`) は
/// `ref.read(alarmServiceProvider)` 経由で参照し、テストは
/// `clockProvider` を override すれば現在時刻を任意の値に固定できる。
///
/// Copied from [alarmService].
@ProviderFor(alarmService)
final alarmServiceProvider = Provider<AlarmService>.internal(
  alarmService,
  name: r'alarmServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alarmServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlarmServiceRef = ProviderRef<AlarmService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
