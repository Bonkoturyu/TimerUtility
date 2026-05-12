import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/ports/user_preferences.dart';

/// `shared_preferences`-backed [UserPreferences].
///
/// A single [SharedPreferences] handle is loaded once per construction
/// and reused — `SharedPreferences.getInstance()` is internally
/// memoized, so this is mostly bookkeeping to avoid awaiting it on
/// every read.
///
/// Lives outside `infrastructure/database/` because it is intentionally
/// a separate concern from Drift: only key-value preferences belong
/// here, while structured user data goes in the SQLite tables.
class SharedPreferencesUserPreferences implements UserPreferences {
  SharedPreferencesUserPreferences._(this._prefs);

  /// Test seam: lets unit tests construct an adapter over a
  /// `SharedPreferences.setMockInitialValues(...)`-backed instance
  /// without going through the async factory.
  SharedPreferencesUserPreferences.forTesting(this._prefs);

  /// Async factory: awaits the platform handle. The notifier layer
  /// caches the resulting instance so this only runs once per app
  /// launch.
  static Future<SharedPreferencesUserPreferences> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return SharedPreferencesUserPreferences._(prefs);
  }

  final SharedPreferences _prefs;

  @override
  Future<bool?> getBool(String key) async {
    if (!_prefs.containsKey(key)) return null;
    return _prefs.getBool(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    if (!_prefs.containsKey(key)) return null;
    return _prefs.getInt(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    if (!_prefs.containsKey(key)) return null;
    return _prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
