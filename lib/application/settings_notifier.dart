import 'dart:async';

import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/user_preferences.dart';
import '../domain/timer/alarm_sound_catalog.dart';
import 'user_preferences_provider.dart';

part 'settings_notifier.freezed.dart';
part 'settings_notifier.g.dart';

/// Allowed default-snooze choices, mirrored by the SegmentedButton in
/// the alarm edit screen and the settings screen. Stored values outside
/// this set fall back to `5` on restore.
const Set<int> kAllowedDefaultSnoozeMinutes = <int>{5, 10, 15};

/// Compile-time mirror of `main.dart`'s `kEnableExperimentalLocales`.
///
/// Duplicated here (not imported) because `main.dart` already depends on
/// this file; importing back would create a cycle. Both reads of
/// `bool.fromEnvironment('ENABLE_EXPERIMENTAL_LOCALES')` resolve to the
/// same compile-time value, so the two stay in sync without runtime
/// coordination.
const bool _experimentalLocalesEnabled = bool.fromEnvironment(
  'ENABLE_EXPERIMENTAL_LOCALES',
  defaultValue: false,
);

const List<String> _publicLocaleTags = <String>['ja', 'en'];
const List<String> _experimentalLocaleTags = <String>['zh', 'zh-Hant', 'ko'];

/// BCP-47 tags the language picker is allowed to persist. The
/// experimental tags only appear when the compile-time flag is on; UI
/// already hides them, but the notifier also drops them on `set` /
/// `_restore` as a safety net so a stored value from a previous
/// experimental build can't sneak through on a public build.
List<String> get supportedLocaleTags => <String>[
  ..._publicLocaleTags,
  if (_experimentalLocalesEnabled) ..._experimentalLocaleTags,
];

/// Parse a stored BCP-47 tag into a [Locale]. We hand-roll instead of
/// reaching for a package because the surface is tiny (5 tags) and we
/// want to preserve the scriptCode for `zh-Hant` — `Locale('zh-Hant')`
/// would silently treat the whole string as a single language code.
Locale? _parseLocaleTag(String tag) {
  if (!supportedLocaleTags.contains(tag)) return null;
  final List<String> parts = tag.split('-');
  if (parts.length == 1) return Locale(parts[0]);
  // `zh-Hant` form. countryCode/scriptCode disambiguation: a 4-char
  // capitalised segment is a script per BCP-47, which is what we use.
  return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
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
  }) = _SettingsState;

  /// Initial values used both before the persisted state is read and
  /// when a stored value cannot be resolved (out-of-range int / unknown
  /// sound id).
  factory SettingsState.defaults() => SettingsState(
    themeMode: ThemeMode.system,
    localeOverride: null,
    defaultSnoozeMinutes: 5,
    defaultAlarmSoundId: AlarmSoundCatalog.defaultSound.id,
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
/// a nullable `Locale` (null = follow system) and silently drops tags
/// outside [supportedLocaleTags] (defence in depth — the UI already
/// hides experimental options on public builds).
@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  SettingsState build() {
    Future<void>.microtask(_restore);
    return SettingsState.defaults();
  }

  Future<void> _restore() async {
    final UserPreferences prefs = ref.read(userPreferencesProvider);
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
    final String soundId =
        (storedSound != null && AlarmSoundCatalog.findById(storedSound) != null)
        ? storedSound
        : defaults.defaultAlarmSoundId;
    final Locale? localeOverride = storedLocale == null
        ? defaults.localeOverride
        : _parseLocaleTag(storedLocale);

    state = SettingsState(
      themeMode: themeMode,
      localeOverride: localeOverride,
      defaultSnoozeMinutes: snooze,
      defaultAlarmSoundId: soundId,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref
        .read(userPreferencesProvider)
        .setInt(UserPreferenceKeys.themeMode, mode.index);
  }

  Future<void> setDefaultSnoozeMinutes(int minutes) async {
    if (!kAllowedDefaultSnoozeMinutes.contains(minutes)) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'must be one of $kAllowedDefaultSnoozeMinutes',
      );
    }
    state = state.copyWith(defaultSnoozeMinutes: minutes);
    await ref
        .read(userPreferencesProvider)
        .setInt(UserPreferenceKeys.defaultSnoozeMinutes, minutes);
  }

  Future<void> setDefaultAlarmSoundId(String soundId) async {
    if (AlarmSoundCatalog.findById(soundId) == null) {
      throw ArgumentError.value(soundId, 'soundId', 'unknown alarm sound id');
    }
    state = state.copyWith(defaultAlarmSoundId: soundId);
    await ref
        .read(userPreferencesProvider)
        .setString(UserPreferenceKeys.defaultAlarmSoundId, soundId);
  }

  /// Persist the user's manual locale choice. `null` means "follow the
  /// system" and clears the stored tag, restoring the
  /// `localeResolutionCallback` path. Non-null locales outside
  /// [supportedLocaleTags] are coerced to null — UI already hides
  /// experimental options on public builds, so this is the
  /// belt-and-braces.
  Future<void> setLocaleOverride(Locale? locale) async {
    final UserPreferences prefs = ref.read(userPreferencesProvider);
    if (locale == null) {
      state = state.copyWith(localeOverride: null);
      await prefs.remove(UserPreferenceKeys.localeTag);
      return;
    }
    final String tag = locale.toLanguageTag();
    if (!supportedLocaleTags.contains(tag)) {
      state = state.copyWith(localeOverride: null);
      await prefs.remove(UserPreferenceKeys.localeTag);
      return;
    }
    state = state.copyWith(localeOverride: locale);
    await prefs.setString(UserPreferenceKeys.localeTag, tag);
  }
}
