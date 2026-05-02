// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preset_collection_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$presetCollectionNotifierHash() =>
    r'dc9c6c9e51a1a5bff244c80699aa378c2b003c31';

/// Phase 9 single source of truth for every saved preset.
///
/// Mirrors `TimerCollectionNotifier`:
///   - State = immutable aggregate ([PresetCollection]).
///   - Mutations: validate via [PresetService], update [state],
///     persist via [PresetRepository], all in one go.
///   - Restore on build: asynchronously load the persisted collection
///     so the UI can render an empty list while the DB call resolves.
///
/// `replaceFromTemplate` is unique to this notifier: it implements the
/// "Replace from template" UX. The two supported modes are described
/// on [ReplaceTemplateMode].
///
/// Copied from [PresetCollectionNotifier].
@ProviderFor(PresetCollectionNotifier)
final presetCollectionNotifierProvider =
    NotifierProvider<PresetCollectionNotifier, PresetCollection>.internal(
      PresetCollectionNotifier.new,
      name: r'presetCollectionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$presetCollectionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PresetCollectionNotifier = Notifier<PresetCollection>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
