/// Port for small, lightly-typed user preferences.
///
/// Phase 9 introduces this for the "don't ask again" delete-confirm
/// state, which is too small to deserve its own DB table but needs to
/// outlive process restarts. Implementations live under
/// `infrastructure/preferences/`. The intent is to mirror the slice of
/// `shared_preferences` we actually use, so the domain layer stays
/// Pure Dart.
///
/// Future Phase 11 settings (default snooze minutes, theme, etc.) are
/// expected to grow alongside this same port rather than reach for
/// `shared_preferences` directly.
abstract class UserPreferences {
  /// Reads a stored boolean. Returns `null` when the key has never
  /// been written, so callers can distinguish "not set" from
  /// "explicitly false".
  Future<bool?> getBool(String key);

  /// Writes a boolean. Persists immediately on the underlying store.
  Future<void> setBool(String key, bool value);

  /// Reads a stored int. Returns `null` when the key has never been
  /// written, mirroring the [getBool] contract so callers can tell
  /// "first launch" apart from a deliberately stored `0`.
  Future<int?> getInt(String key);

  /// Writes an int. Persists immediately on the underlying store.
  Future<void> setInt(String key, int value);

  /// Reads a stored string. Returns `null` when the key has never been
  /// written so callers can distinguish "first launch" from an
  /// explicitly stored empty string. Phase 11 settings screen uses this
  /// for the default alarm sound id (catalog ids are strings); future
  /// language-preference work is expected to reuse the same surface.
  Future<String?> getString(String key);

  /// Writes a string. Persists immediately on the underlying store.
  Future<void> setString(String key, String value);

  /// Removes a key. No-op if absent.
  Future<void> remove(String key);
}

/// Well-known preference keys. Centralised here so adapters and
/// notifiers don't drift on string literals.
class UserPreferenceKeys {
  const UserPreferenceKeys._();

  /// `true` when the user ticked "Don't ask again" in the preset delete
  /// confirmation dialog. Absent / `false` means "show the dialog".
  static const String skipPresetDeleteConfirm = 'skipPresetDeleteConfirm';

  /// `true` when the user ticked "Don't ask again" in the alarm delete
  /// confirmation dialog (Phase 9.5)。Absent / `false` means "show the
  /// dialog". preset と同じ運用 (UI 側で読んでスキップ判定、ダイアログの
  /// 結果を書き戻す)。
  static const String skipAlarmDeleteConfirm = 'skipAlarmDeleteConfirm';

  /// Index (0..3) of the last HomeScreen tab the user was viewing when
  /// the app was last suspended. Phase 11 restores this on cold start
  /// so the user doesn't always land on Timer (the default) after a
  /// kill/restart cycle. Absent / `null` means "first launch — fall
  /// back to the default landing tab".
  static const String lastHomePageIndex = 'lastHomePageIndex';

  /// Manual theme override. Stored as `ThemeMode.index` (`0=system /
  /// 1=light / 2=dark` per Flutter SDK `material/app.dart` declaration
  /// order). Absent / out-of-range value means "follow the system" —
  /// the Phase 11 settings notifier clamps and falls back accordingly.
  static const String themeMode = 'themeMode';

  /// Default snooze minutes seeded into newly-created alarms. Allowed
  /// values are `{5, 10, 15}` (matches the alarm edit `SegmentedButton`
  /// choices); anything else falls back to `5`.
  static const String defaultSnoozeMinutes = 'defaultSnoozeMinutes';

  /// Default alarm sound id seeded into newly-created alarms and
  /// presets. Resolved against `AlarmSoundCatalog.findById`; an unknown
  /// id (e.g. asset removed in a future release) falls back to the
  /// catalog's `defaultSound`.
  static const String defaultAlarmSoundId = 'defaultAlarmSoundId';
}
