// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$permissionManagerHash() => r'1845660cc02a3ad656c908ae75ec094233a6a3e2';

/// Default-bound permission manager. Override in tests via
/// `permissionManagerProvider.overrideWithValue(fakePermissionManager)`.
///
/// Copied from [permissionManager].
@ProviderFor(permissionManager)
final permissionManagerProvider = Provider<PermissionManager>.internal(
  permissionManager,
  name: r'permissionManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$permissionManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PermissionManagerRef = ProviderRef<PermissionManager>;
String _$permissionNotifierHash() =>
    r'04a6b06cc2d0eb08f0db8024016e6440bc129edd';

/// Holds the latest known permission state and exposes request actions.
///
/// Copied from [PermissionNotifier].
@ProviderFor(PermissionNotifier)
final permissionNotifierProvider =
    NotifierProvider<PermissionNotifier, PermissionState>.internal(
      PermissionNotifier.new,
      name: r'permissionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$permissionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PermissionNotifier = Notifier<PermissionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
