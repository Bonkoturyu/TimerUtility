// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_collection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timerCollectionNotifierHash() =>
    r'b055e2bc3786d43a6c6f7781902ed67d785f9da5';

/// Phase 8 single source of truth for every active timer.
///
/// Replaces the Phase 3 single-timer `TimerNotifier`. State is the full
/// [TimerCollection] (immutable aggregate). Each mutation:
///   1. Computes the next [TimerEntity] via [TimerService].
///   2. Writes the new collection to [state].
///   3. Persists the changed entity via [TimerRepository.upsert] /
///      `delete`, fire-and-forget.
///   4. Coordinates with [NotificationScheduler] (schedule on running,
///      cancel on pause / cancel / delete / reset / clear).
///
/// A single 200 ms ticker drives every running timer; tick walks the
/// collection and only re-emits state when at least one timer flipped
/// to `ringing`. The ticker stops itself once `runningCount == 0` and
/// is restarted by any operation that produces a running timer.
///
/// Restoration semantics: at `build()` we asynchronously load the
/// stored collection. Any timer whose `status == running` and whose
/// `endAt` already passed is rewritten to `completed`, persisted, and
/// surfaced via [NotificationScheduler.show] exactly once. The alarm
/// screen is intentionally NOT launched and audio is NOT played for
/// these — see Phase 8 plan #4.
///
/// Copied from [TimerCollectionNotifier].
@ProviderFor(TimerCollectionNotifier)
final timerCollectionNotifierProvider =
    NotifierProvider<TimerCollectionNotifier, TimerCollection>.internal(
      TimerCollectionNotifier.new,
      name: r'timerCollectionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$timerCollectionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TimerCollectionNotifier = Notifier<TimerCollection>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
