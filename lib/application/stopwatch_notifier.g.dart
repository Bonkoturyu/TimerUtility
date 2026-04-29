// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stopwatch_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stopwatchServiceHash() => r'b51a948119fa8d2ac7b6a5f4517f2cf470214c95';

/// Stopwatch domain service wired with the application [Clock].
///
/// Copied from [stopwatchService].
@ProviderFor(stopwatchService)
final stopwatchServiceProvider = Provider<StopwatchService>.internal(
  stopwatchService,
  name: r'stopwatchServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stopwatchServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StopwatchServiceRef = ProviderRef<StopwatchService>;
String _$stopwatchNotifierHash() => r'0f839bb01f965ee07e816b245a8e33419ccffb24';

/// Stopwatch state holder.
///
/// The displayed elapsed value should be derived from the *current* clock
/// each frame; this notifier only tracks discrete transitions (start, pause,
/// resume, lap, reset). The absolute-time design (`startedAt` + `clock.now()`)
/// makes the value naturally correct after the app returns from background,
/// so no `AppLifecycleListener` plumbing is required at this layer.
///
/// Copied from [StopwatchNotifier].
@ProviderFor(StopwatchNotifier)
final stopwatchNotifierProvider =
    NotifierProvider<StopwatchNotifier, StopwatchState>.internal(
      StopwatchNotifier.new,
      name: r'stopwatchNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$stopwatchNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StopwatchNotifier = Notifier<StopwatchState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
