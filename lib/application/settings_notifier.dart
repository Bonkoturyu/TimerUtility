import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
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

/// Holds the user's app-wide preferences: theme override and the
/// default seed values used when creating new alarms / presets.
///
/// `themeMode` follows `ThemeMode.system` until the user picks a
/// specific mode; `defaultSnoozeMinutes` / `defaultAlarmSoundId` are
/// the seeds applied by the alarm-edit / preset-edit screens for new
/// entities only (existing entities keep their own stored values).
@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    required ThemeMode themeMode,
    required int defaultSnoozeMinutes,
    required String defaultAlarmSoundId,
  }) = _SettingsState;

  /// Initial values used both before the persisted state is read and
  /// when a stored value cannot be resolved (out-of-range int / unknown
  /// sound id).
  factory SettingsState.defaults() => SettingsState(
    themeMode: ThemeMode.system,
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
/// no validation is needed at the call site.
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

    state = SettingsState(
      themeMode: themeMode,
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
}
