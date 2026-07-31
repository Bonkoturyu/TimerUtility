import 'dart:async';

import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/imported_sound_repository.dart';
import '../domain/ports/user_preferences.dart';
import '../domain/timer/alarm_sound_catalog.dart';
import 'imported_sound_mutation_coordinator.dart';
import 'imported_sound_repository_provider.dart';
import 'user_preferences_provider.dart';

part 'settings_notifier.freezed.dart';
part 'settings_notifier.g.dart';

/// Allowed default-snooze choices, mirrored by the SegmentedButton in
/// the alarm edit screen and the settings screen. Stored values outside
/// this set fall back to `5` on restore.
const Set<int> kAllowedDefaultSnoozeMinutes = <int>{5, 10, 15};

/// BCP-47 tags the language picker is allowed to persist, in the order
/// the picker lists them. Every tag ships in every build — zh / zh-Hant
/// / ko were behind the `ENABLE_EXPERIMENTAL_LOCALES` compile-time flag
/// until their ARB files reached full key parity with ja / en.
///
/// The notifier still validates against this list on `set` / `_restore`
/// (defence in depth) so a stored tag from an older build can't resolve
/// to a locale the app no longer ships.
const List<String> supportedLocaleTags = <String>[
  'ja',
  'en',
  'zh',
  'zh-Hant',
  'ko',
];

/// Parse a stored BCP-47 tag into a [Locale]. We hand-roll instead of
/// reaching for a package because the surface is small and we want to
/// preserve the scriptCode for `zh-Hant` — `Locale('zh-Hant')` would
/// silently treat the whole string as a single language code.
///
/// Subtag disambiguation follows RFC 5646: a 4-char alpha subtag is a
/// script (e.g. `Hant`), a 2-char alpha subtag is a region (e.g. `US`).
/// Today only `zh-Hant` exercises this path, but the explicit length
/// check keeps the door open for `en-US` etc. without re-introducing the
/// silent-corruption bug.
Locale? parseLocaleTag(String tag) {
  if (!supportedLocaleTags.contains(tag)) return null;
  final List<String> parts = tag.split('-');
  if (parts.length == 1) return Locale(parts[0]);
  final String second = parts[1];
  return Locale.fromSubtags(
    languageCode: parts[0],
    scriptCode: second.length == 4 ? second : null,
    countryCode: second.length == 2 ? second : null,
  );
}

/// Holds the user's app-wide preferences: theme override, manual locale
/// override, and the default seed values used when creating new alarms
/// / presets.
///
/// `themeMode` follows `ThemeMode.system` until the user picks a
/// specific mode; `localeOverride` is `null` for "follow the system"
/// (so `MaterialApp.locale` stays null and `localeResolutionCallback`
/// decides — see F-9); `defaultSnoozeMinutes` / `defaultAlarmSoundId`
/// are the seeds applied by the alarm-edit / preset-edit screens for
/// new entities only (existing entities keep their own stored values).
@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    required ThemeMode themeMode,
    required Locale? localeOverride,
    required int defaultSnoozeMinutes,
    required String defaultAlarmSoundId,
    required bool onDeviceVoiceStopEnabled,
  }) = _SettingsState;

  /// Initial values used both before the persisted state is read and
  /// when a stored value cannot be resolved (out-of-range int / unknown
  /// sound id).
  factory SettingsState.defaults() => SettingsState(
    themeMode: ThemeMode.system,
    localeOverride: null,
    defaultSnoozeMinutes: 5,
    defaultAlarmSoundId: AlarmSoundCatalog.defaultSound.id,
    onDeviceVoiceStopEnabled: false,
  );
}

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
/// a nullable BCP-47 tag string (null = follow system) and silently
/// drops tags outside [supportedLocaleTags] (defence in depth — the UI
/// already hides experimental options on public builds). Tag-in /
/// `Locale`-out keeps the BCP-47 parsing single-sourced inside
/// [parseLocaleTag] so call sites can't re-invent the `zh-Hant`
/// script/region disambiguation.
@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  int _restoreGeneration = 0;
  final Set<String> _deletedSoundIds = <String>{};
  bool _disposed = false;

  @override
  SettingsState build() {
    _disposed = false;
    final UserPreferences preferences = ref.read(userPreferencesProvider);
    final ImportedSoundMutationCoordinator coordinator = ref.read(
      importedSoundMutationCoordinatorProvider,
    );
    final ImportedSoundDeletionRegistry registry = ref.read(
      importedSoundDeletionRegistryProvider,
    );
    ref.onDispose(() => _disposed = true);
    Future<void>.microtask(() => _restore(preferences, coordinator, registry));
    return SettingsState.defaults();
  }

  Future<void> _restore(
    UserPreferences prefs,
    ImportedSoundMutationCoordinator coordinator,
    ImportedSoundDeletionRegistry registry,
  ) async {
    final int restoreGeneration = _restoreGeneration;
    final int? storedTheme = await prefs.getInt(UserPreferenceKeys.themeMode);
    final int? storedSnooze = await prefs.getInt(
      UserPreferenceKeys.defaultSnoozeMinutes,
    );
    final String? storedSound = await prefs.getString(
      UserPreferenceKeys.defaultAlarmSoundId,
    );
    final String? storedLocale = await prefs.getString(
      UserPreferenceKeys.localeTag,
    );
    final bool? storedVoiceStop = await prefs.getBool(
      UserPreferenceKeys.onDeviceVoiceStopEnabled,
    );

    // フォールバック値は SettingsState.defaults() を唯一の情報源にして
    // ハードコード重複を避ける (Gemini review #36)。将来 defaults() の
    // 規定値を変更した際に _restore 側の取りこぼしを防ぐ。
    final SettingsState defaults = SettingsState.defaults();
    final ThemeMode themeMode =
        (storedTheme != null &&
            storedTheme >= 0 &&
            storedTheme < ThemeMode.values.length)
        ? ThemeMode.values[storedTheme]
        : defaults.themeMode;
    final int snooze =
        (storedSnooze != null &&
            kAllowedDefaultSnoozeMinutes.contains(storedSnooze))
        ? storedSnooze
        : defaults.defaultSnoozeMinutes;
    final Locale? localeOverride = storedLocale == null
        ? defaults.localeOverride
        : parseLocaleTag(storedLocale);

    if (_disposed) return;
    await coordinator.run(() async {
      if (_disposed || restoreGeneration != _restoreGeneration) return;
      final ImportedSoundRepository? repository =
          storedSound != null &&
              AlarmSoundCatalog.findById(storedSound) == null &&
              !registry.isUnavailable(storedSound)
          ? ref.read(importedSoundRepositoryProvider)
          : null;
      final bool isKnown =
          storedSound != null &&
          await _isKnownSoundId(storedSound, registry, repository);
      if (_disposed || restoreGeneration != _restoreGeneration) return;
      final bool remainsAvailable =
          isKnown && !registry.isUnavailable(storedSound);
      final String soundId = remainsAvailable
          ? storedSound
          : defaults.defaultAlarmSoundId;
      state = SettingsState(
        themeMode: themeMode,
        localeOverride: localeOverride,
        defaultSnoozeMinutes: snooze,
        defaultAlarmSoundId: soundId,
        onDeviceVoiceStopEnabled:
            storedVoiceStop ?? defaults.onDeviceVoiceStopEnabled,
      );

      if (storedSound != null && storedSound != soundId) {
        try {
          await prefs.setString(
            UserPreferenceKeys.defaultAlarmSoundId,
            soundId,
          );
        } catch (_) {
          // Startup remains available. A later restore retries the repair.
        }
      }
    });
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _restoreGeneration++;
    state = state.copyWith(themeMode: mode);
    await ref
        .read(userPreferencesProvider)
        .setInt(UserPreferenceKeys.themeMode, mode.index);
  }

  Future<void> setOnDeviceVoiceStopEnabled(bool enabled) async {
    _restoreGeneration++;
    state = state.copyWith(onDeviceVoiceStopEnabled: enabled);
    await ref
        .read(userPreferencesProvider)
        .setBool(UserPreferenceKeys.onDeviceVoiceStopEnabled, enabled);
  }

  Future<void> setDefaultSnoozeMinutes(int minutes) async {
    if (!kAllowedDefaultSnoozeMinutes.contains(minutes)) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'must be one of $kAllowedDefaultSnoozeMinutes',
      );
    }
    _restoreGeneration++;
    state = state.copyWith(defaultSnoozeMinutes: minutes);
    await ref
        .read(userPreferencesProvider)
        .setInt(UserPreferenceKeys.defaultSnoozeMinutes, minutes);
  }

  Future<void> setDefaultAlarmSoundId(String soundId) async {
    final ImportedSoundMutationCoordinator coordinator = ref.read(
      importedSoundMutationCoordinatorProvider,
    );
    final ImportedSoundDeletionRegistry registry = ref.read(
      importedSoundDeletionRegistryProvider,
    );
    final ImportedSoundRepository? repository =
        AlarmSoundCatalog.findById(soundId) == null
        ? ref.read(importedSoundRepositoryProvider)
        : null;
    final UserPreferences preferences = ref.read(userPreferencesProvider);
    await coordinator.run(() async {
      if (!await _isKnownSoundId(soundId, registry, repository)) {
        throw ArgumentError.value(soundId, 'soundId', 'unknown alarm sound id');
      }
      if (registry.isUnavailable(soundId)) {
        throw ArgumentError.value(soundId, 'soundId', 'unknown alarm sound id');
      }
      _restoreGeneration++;
      state = state.copyWith(defaultAlarmSoundId: soundId);
      await preferences.setString(
        UserPreferenceKeys.defaultAlarmSoundId,
        soundId,
      );
    });
  }

  /// Persist the user's manual locale choice. `null` means "follow the
  /// system" and clears the stored tag, restoring the
  /// `localeResolutionCallback` path. Tags outside [supportedLocaleTags]
  /// (or that [parseLocaleTag] cannot resolve) are coerced to null — UI
  /// already hides experimental options on public builds, so this is
  /// the belt-and-braces.
  Future<void> setLocaleOverride(String? tag) async {
    _restoreGeneration++;
    final UserPreferences prefs = ref.read(userPreferencesProvider);
    if (tag == null) {
      state = state.copyWith(localeOverride: null);
      await prefs.remove(UserPreferenceKeys.localeTag);
      return;
    }
    final Locale? locale = parseLocaleTag(tag);
    if (locale == null) {
      state = state.copyWith(localeOverride: null);
      await prefs.remove(UserPreferenceKeys.localeTag);
      return;
    }
    state = state.copyWith(localeOverride: locale);
    await prefs.setString(UserPreferenceKeys.localeTag, tag);
  }

  /// Mirrors a successful deletion whose preference write already completed.
  void reconcileDeletedSound(String soundId) {
    _deletedSoundIds.add(soundId);
    ref.read(importedSoundDeletionRegistryProvider).markDeleted(soundId);
    if (state.defaultAlarmSoundId == soundId) {
      state = state.copyWith(
        defaultAlarmSoundId: AlarmSoundCatalog.defaultSound.id,
      );
    }
  }

  Future<bool> _isKnownSoundId(
    String soundId,
    ImportedSoundDeletionRegistry registry,
    ImportedSoundRepository? repository,
  ) async {
    if (_deletedSoundIds.contains(soundId) || registry.isUnavailable(soundId)) {
      return false;
    }
    if (AlarmSoundCatalog.findById(soundId) != null) return true;
    if (repository == null) return false;
    final bool exists = await repository.findById(soundId) != null;
    return exists &&
        !_deletedSoundIds.contains(soundId) &&
        !registry.isUnavailable(soundId);
  }
}
