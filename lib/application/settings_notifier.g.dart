// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsNotifierHash() => r'7be41fa332c0f16481238df3289e8dcfac802b20';

/// Phase 11 settings notifier.
///
/// Pattern mirrors `PresetCollectionNotifier`: synchronous `build()`
/// returns the defaults so the UI can render before the prefs read
/// resolves; a `microtask` then calls `_restore()` and replaces state
/// with the persisted (and validated) values. Each mutator updates the
/// state and persists in one step.
///
/// `setDefaultSnoozeMinutes` / `setDefaultAlarmSoundId` validate against
/// [kAllowedDefaultSnoozeMinutes] and `AlarmSoundCatalog.findById`
/// respectively and throw `ArgumentError` on invalid input — the UI
/// only ever passes values from the curated lists, so these are
/// programmer-error paths. `setThemeMode` takes a typed `ThemeMode` so
/// no validation is needed at the call site. `setLocaleOverride` takes
/// a nullable `Locale` (null = follow system) and silently drops tags
/// outside [supportedLocaleTags] (defence in depth — the UI already
/// hides experimental options on public builds).
///
/// Copied from [SettingsNotifier].
@ProviderFor(SettingsNotifier)
final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, SettingsState>.internal(
      SettingsNotifier.new,
      name: r'settingsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$settingsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SettingsNotifier = Notifier<SettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
