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
}
