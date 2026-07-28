// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appVersionReaderHash() => r'a7dd62934225815a11265c313862675fbadfe1d8';

/// Default-bound [AppVersionReader]. Override in tests via
/// `appVersionReaderProvider.overrideWithValue(StubAppVersionReader(...))`.
///
/// Copied from [appVersionReader].
@ProviderFor(appVersionReader)
final appVersionReaderProvider = Provider<AppVersionReader>.internal(
  appVersionReader,
  name: r'appVersionReaderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appVersionReaderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppVersionReaderRef = ProviderRef<AppVersionReader>;
String _$appVersionHash() => r'903f57d388babcedb7e828fdb69a0eae96f0c9ed';

/// The running build's version, shown in the settings "About" section.
///
/// `keepAlive` because the value is immutable for the process lifetime —
/// re-reading it on every settings screen open would hit the platform
/// channel for nothing.
///
/// Copied from [appVersion].
@ProviderFor(appVersion)
final appVersionProvider = FutureProvider<AppVersion>.internal(
  appVersion,
  name: r'appVersionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appVersionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppVersionRef = FutureProviderRef<AppVersion>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
