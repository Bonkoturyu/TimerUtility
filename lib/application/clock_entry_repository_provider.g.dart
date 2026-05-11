// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_entry_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clockEntryRepositoryHash() =>
    r'638475535ebfd8344fa8c14cde380645cdf52db0';

/// Provider for the [ClockEntryRepository] used by
/// [ClockEntryCollectionNotifier]. Tests override this with an in-memory
/// fake; production binding is wired in `main()` after the
/// [AppDatabase] has been opened.
///
/// Copied from [clockEntryRepository].
@ProviderFor(clockEntryRepository)
final clockEntryRepositoryProvider = Provider<ClockEntryRepository>.internal(
  clockEntryRepository,
  name: r'clockEntryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$clockEntryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClockEntryRepositoryRef = ProviderRef<ClockEntryRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
