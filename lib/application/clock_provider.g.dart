// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clockHash() => r'30e71d378a201482bb785bc8babd9bfcb65538f7';

/// Application-wide [Clock] instance.
///
/// Override in tests via `clockProvider.overrideWithValue(Clock.fixed(...))`.
/// Domain code receives this through constructor injection (e.g. via
/// `stopwatchServiceProvider`); it must never call `DateTime.now()` directly.
///
/// Copied from [clock].
@ProviderFor(clock)
final clockProvider = Provider<Clock>.internal(
  clock,
  name: r'clockProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$clockHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClockRef = ProviderRef<Clock>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
