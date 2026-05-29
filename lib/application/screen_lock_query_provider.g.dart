// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screen_lock_query_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$screenLockQueryHash() => r'fca76466919b43dcaaa6e87fc42d3e957b58fc77';

/// Default-bound [ScreenLockQuery]. Override in tests via
/// `screenLockQueryProvider.overrideWithValue(StubScreenLockQuery(...))`.
///
/// Used by [AlarmRingingNotifier.start] (Issue #74 fix) to pick the
/// cancel→play delay based on whether the keyguard is currently up.
///
/// Copied from [screenLockQuery].
@ProviderFor(screenLockQuery)
final screenLockQueryProvider = Provider<ScreenLockQuery>.internal(
  screenLockQuery,
  name: r'screenLockQueryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$screenLockQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScreenLockQueryRef = ProviderRef<ScreenLockQuery>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
