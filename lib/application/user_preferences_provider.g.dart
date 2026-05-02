// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userPreferencesHash() => r'8c32799f135cfbea55cdf4967db4893d1619e147';

/// Provider for the [UserPreferences] adapter. Tests override with an
/// in-memory fake; production binding is wired in `main()` after
/// `SharedPreferencesUserPreferences.create()` has resolved.
///
/// Kept on a single global provider rather than splitting per key —
/// the surface area is small (one bool today; a handful expected
/// across Phase 11), so the additional indirection isn't worth it.
///
/// Copied from [userPreferences].
@ProviderFor(userPreferences)
final userPreferencesProvider = Provider<UserPreferences>.internal(
  userPreferences,
  name: r'userPreferencesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userPreferencesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserPreferencesRef = ProviderRef<UserPreferences>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
