// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$presetRepositoryHash() => r'6fc40b76a77ffe837c24f433b64395f1ff9e71b3';

/// Provider for the [PresetRepository] used by
/// [PresetCollectionNotifier]. Tests override this with an in-memory
/// fake; production binding is wired in `main()` after the
/// [AppDatabase] has been opened.
///
/// Copied from [presetRepository].
@ProviderFor(presetRepository)
final presetRepositoryProvider = Provider<PresetRepository>.internal(
  presetRepository,
  name: r'presetRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$presetRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PresetRepositoryRef = ProviderRef<PresetRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
