// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_location_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clockLocationRepositoryHash() =>
    r'aa491afd6c5d2a9c223309b016d2a3da4689d254';

/// Provider for the [ClockLocationRepository] used by
/// [ClockCollectionNotifier]. Tests override this with an in-memory
/// fake; production binding is wired in `main()` after the
/// [AppDatabase] has been opened.
///
/// Copied from [clockLocationRepository].
@ProviderFor(clockLocationRepository)
final clockLocationRepositoryProvider =
    Provider<ClockLocationRepository>.internal(
      clockLocationRepository,
      name: r'clockLocationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$clockLocationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClockLocationRepositoryRef = ProviderRef<ClockLocationRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
