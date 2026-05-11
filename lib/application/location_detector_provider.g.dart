// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_detector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationDetectorHash() => r'ee515a3a9ec36f2d57885e709980609b1f917ad7';

/// Provider for the [LocationDetector] used by
/// [ClockEntryCollectionNotifier]'s first-launch detection path. Tests
/// override this with a `mocktail` mock; production binding is wired
/// in `main()` with [LocationDetectorAdapter].
///
/// Copied from [locationDetector].
@ProviderFor(locationDetector)
final locationDetectorProvider = Provider<LocationDetector>.internal(
  locationDetector,
  name: r'locationDetectorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationDetectorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationDetectorRef = ProviderRef<LocationDetector>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
