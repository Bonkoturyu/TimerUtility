// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_entry_collection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clockEntryCollectionNotifierHash() =>
    r'c11098e27d0aad0b9e6ed7ecc429f0d3eb65579f';

/// Phase 10.5 single source of truth for pinned world-clock entries
/// (Phase 11 で `ClockCollectionNotifier` → `ClockEntryCollectionNotifier`
/// にリネーム)。
///
/// Mirrors `PresetCollectionNotifier`:
///   - State = immutable aggregate ([ClockEntryCollection]).
///   - Mutations: validate via the aggregate, update [state], persist
///     via [ClockEntryRepository] in a fire-and-forget pattern.
///   - Restore on build: asynchronously load the persisted collection.
///     On a fresh install (DB empty) we additionally call
///     [LocationDetector.detectTimezoneId] to seed a single
///     "current location" entry so the first launch shows local time.
///
/// Copied from [ClockEntryCollectionNotifier].
@ProviderFor(ClockEntryCollectionNotifier)
final clockEntryCollectionNotifierProvider =
    NotifierProvider<
      ClockEntryCollectionNotifier,
      ClockEntryCollection
    >.internal(
      ClockEntryCollectionNotifier.new,
      name: r'clockEntryCollectionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$clockEntryCollectionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ClockEntryCollectionNotifier = Notifier<ClockEntryCollection>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
