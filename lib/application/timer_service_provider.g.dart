// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timerServiceHash() => r'8bf8677d9f23c9e42227f7595e559120222111dd';

/// Default-bound [TimerService] wired with the application [Clock].
///
/// Extracted from the Phase 3 `timer_notifier.dart` so the service can
/// outlive the deprecated single-timer notifier and be shared by the
/// Phase 8 [TimerCollectionNotifier] and any future preset / alarm
/// flows that need to drive [TimerEntity] state transitions.
///
/// Copied from [timerService].
@ProviderFor(timerService)
final timerServiceProvider = Provider<TimerService>.internal(
  timerService,
  name: r'timerServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timerServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TimerServiceRef = ProviderRef<TimerService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
