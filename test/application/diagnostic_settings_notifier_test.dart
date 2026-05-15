import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/diagnostic_settings_notifier.dart';
import 'package:timer_utility/application/user_preferences_provider.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';

class _MemoryUserPrefs implements UserPreferences {
  _MemoryUserPrefs({Map<String, bool>? bools})
    : _bools = <String, bool>{...?bools};
  final Map<String, bool> _bools;
  final Map<String, int> _ints = <String, int>{};
  final Map<String, String> _strings = <String, String>{};

  @override
  Future<bool?> getBool(String key) async => _bools[key];

  @override
  Future<void> setBool(String key, bool value) async => _bools[key] = value;

  @override
  Future<int?> getInt(String key) async => _ints[key];

  @override
  Future<void> setInt(String key, int value) async => _ints[key] = value;

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<void> setString(String key, String value) async =>
      _strings[key] = value;

  @override
  Future<void> remove(String key) async {
    _bools.remove(key);
    _ints.remove(key);
    _strings.remove(key);
  }

  bool? get diagEnabled => _bools[UserPreferenceKeys.diagnosticLogEnabled];
}

ProviderContainer _container(
  UserPreferences prefs, {
  bool defaultEnabled = false,
}) {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      userPreferencesProvider.overrideWithValue(prefs),
      diagnosticSettingsNotifierProvider.overrideWith(
        () => DiagnosticSettingsNotifier()..defaultEnabled = defaultEnabled,
      ),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('DiagnosticSettingsNotifier build / restore', () {
    test('defaultEnabled=true / 永続値なし → 初期 state は enabled=true', () async {
      final _MemoryUserPrefs prefs = _MemoryUserPrefs();
      final ProviderContainer c = _container(prefs, defaultEnabled: true);

      // build() 直後の同期値。
      expect(c.read(diagnosticSettingsNotifierProvider).enabled, isTrue);
      // microtask 経由の _restore() を待ってもまだ enabled=true。
      await Future<void>.delayed(Duration.zero);
      expect(c.read(diagnosticSettingsNotifierProvider).enabled, isTrue);
    });

    test('defaultEnabled=false / 永続値なし → 初期 state は enabled=false', () async {
      final _MemoryUserPrefs prefs = _MemoryUserPrefs();
      final ProviderContainer c = _container(prefs);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(diagnosticSettingsNotifierProvider).enabled, isFalse);
    });

    test('永続値=true が default=false を上書きする', () async {
      final _MemoryUserPrefs prefs = _MemoryUserPrefs(
        bools: <String, bool>{UserPreferenceKeys.diagnosticLogEnabled: true},
      );
      final ProviderContainer c = _container(prefs);
      // Trigger build() *before* the await so the scheduled `_restore`
      // microtask can run during the `delayed(zero)` drain. Without
      // this read, the provider is lazy and build() doesn't fire until
      // the final assertion — by which time the test is already done.
      c.read(diagnosticSettingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(diagnosticSettingsNotifierProvider).enabled, isTrue);
    });

    test('永続値=false が default=true を上書きする', () async {
      final _MemoryUserPrefs prefs = _MemoryUserPrefs(
        bools: <String, bool>{UserPreferenceKeys.diagnosticLogEnabled: false},
      );
      final ProviderContainer c = _container(prefs, defaultEnabled: true);
      c.read(diagnosticSettingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(diagnosticSettingsNotifierProvider).enabled, isFalse);
    });
  });

  group('DiagnosticSettingsNotifier mutators', () {
    test('setEnabled(true) は state を更新し永続化する', () async {
      final _MemoryUserPrefs prefs = _MemoryUserPrefs();
      final ProviderContainer c = _container(prefs);
      c.read(diagnosticSettingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await c
          .read(diagnosticSettingsNotifierProvider.notifier)
          .setEnabled(true);

      expect(c.read(diagnosticSettingsNotifierProvider).enabled, isTrue);
      expect(prefs.diagEnabled, isTrue);
    });

    test('toggle() は現在値を反転して永続化する', () async {
      final _MemoryUserPrefs prefs = _MemoryUserPrefs();
      final ProviderContainer c = _container(prefs, defaultEnabled: true);
      c.read(diagnosticSettingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await c.read(diagnosticSettingsNotifierProvider.notifier).toggle();
      expect(c.read(diagnosticSettingsNotifierProvider).enabled, isFalse);
      expect(prefs.diagEnabled, isFalse);

      await c.read(diagnosticSettingsNotifierProvider.notifier).toggle();
      expect(c.read(diagnosticSettingsNotifierProvider).enabled, isTrue);
      expect(prefs.diagEnabled, isTrue);
    });
  });
}
