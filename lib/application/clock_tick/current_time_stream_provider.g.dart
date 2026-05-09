// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_time_stream_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentTimeHash() => r'f486bedffe7e2c74870d31336a0e268c55e375b9';

/// 1-second cadence stream of "now" used by the world-clock screen
/// (Phase 10.5). Implemented as a function-form `@riverpod` so it
/// auto-disposes when no listeners are attached: a clock screen that
/// is no longer in the foreground stops emitting.
///
/// Initial value is emitted synchronously on subscribe (via
/// `Stream.multi`) so the UI never has to render a frame with the
/// "no value yet" placeholder. Subsequent emissions come from a
/// `Timer.periodic` that runs through `clockProvider` so unit tests
/// can advance time deterministically with `fake_async`.
///
/// Copied from [currentTime].
@ProviderFor(currentTime)
final currentTimeProvider = AutoDisposeStreamProvider<DateTime>.internal(
  currentTime,
  name: r'currentTimeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentTimeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentTimeRef = AutoDisposeStreamProviderRef<DateTime>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
