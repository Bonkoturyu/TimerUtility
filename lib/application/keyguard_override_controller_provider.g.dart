// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyguard_override_controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$keyguardOverrideControllerHash() =>
    r'f80d7ff4ea50e3de9c6e3b72e08f919111bd3f19';

/// Default-bound [KeyguardOverrideController]. Override in tests via
/// `keyguardOverrideControllerProvider.overrideWithValue(...)`.
///
/// Used by [AlarmRingingScreen] to release the keyguard-override state
/// (set by Android when the screen was launched via FullScreenIntent) when
/// the user leaves the alarm screen — keeps the Presentation layer off the
/// raw MethodChannel (Issue #73). Sibling of [screenLockQueryProvider].
///
/// Copied from [keyguardOverrideController].
@ProviderFor(keyguardOverrideController)
final keyguardOverrideControllerProvider =
    Provider<KeyguardOverrideController>.internal(
      keyguardOverrideController,
      name: r'keyguardOverrideControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$keyguardOverrideControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef KeyguardOverrideControllerRef = ProviderRef<KeyguardOverrideController>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
