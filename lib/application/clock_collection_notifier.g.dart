// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_collection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clockCollectionNotifierHash() =>
    r'd027575cd6a094e60ff525fef169cf3c2d4b7088';

/// Phase 10.5 single source of truth for pinned world-clock locations.
///
/// Mirrors `PresetCollectionNotifier`:
///   - State = immutable aggregate ([ClockCollection]).
///   - Mutations: validate via the aggregate, update [state], persist
///     via [ClockLocationRepository] in a fire-and-forget pattern.
///   - Restore on build: asynchronously load the persisted collection.
///     On a fresh install (DB empty) we additionally call
///     [LocationDetector.detectTimezoneId] to seed a single
///     "current location" entry so the first launch shows local time.
///
/// Copied from [ClockCollectionNotifier].
@ProviderFor(ClockCollectionNotifier)
final clockCollectionNotifierProvider =
    NotifierProvider<ClockCollectionNotifier, ClockCollection>.internal(
      ClockCollectionNotifier.new,
      name: r'clockCollectionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$clockCollectionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ClockCollectionNotifier = Notifier<ClockCollection>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
