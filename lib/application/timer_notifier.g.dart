// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timerServiceHash() => r'8bf8677d9f23c9e42227f7595e559120222111dd';

/// Timer domain service wired with the application [Clock].
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
String _$timerNotifierHash() => r'b7d8b912e359da06ed688e9ff612820837d00dd1';

/// Single-timer state holder for Phase 3.
///
/// State `null` means "no timer configured yet" (initial app state).
/// While a timer is `running`, an internal 200ms ticker calls
/// `TimerService.tick` to detect when `endAt` is reached and transition
/// to `ringing`. The ticker also covers the "returned from background"
/// case naturally: a single tick after resume re-checks `endAt` against
/// the current clock and flips to `ringing` immediately if the deadline
/// has already passed.
///
/// Copied from [TimerNotifier].
@ProviderFor(TimerNotifier)
final timerNotifierProvider =
    NotifierProvider<TimerNotifier, TimerEntity?>.internal(
      TimerNotifier.new,
      name: r'timerNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$timerNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TimerNotifier = Notifier<TimerEntity?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
