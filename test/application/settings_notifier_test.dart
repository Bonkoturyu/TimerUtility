import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/settings_notifier.dart';
import 'package:timer_utility/application/user_preferences_provider.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';

/// In-memory [UserPreferences] used for SettingsNotifier unit tests.
/// 既存テストの `_MemoryUserPrefs` パターンを踏襲し、Phase 11 で追加した
/// String 系も保持する。
class _MemoryUserPrefs implements UserPreferences {
  _MemoryUserPrefs({
    Map<String, bool>? bools,
    Map<String, int>? ints,
    Map<String, String>? strings,
  }) : _bools = <String, bool>{...?bools},
       _ints = <String, int>{...?ints},
       _strings = <String, String>{...?strings};

  final Map<String, bool> _bools;
  final Map<String, int> _ints;
  final Map<String, String> _strings;

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

  int get themeMode => _ints[UserPreferenceKeys.themeMode] ?? -1;
  int get snoozeMinutes => _ints[UserPreferenceKeys.defaultSnoozeMinutes] ?? -1;
  String? get alarmSoundId => _strings[UserPreferenceKeys.defaultAlarmSoundId];
  String? get localeTag => _strings[UserPreferenceKeys.localeTag];
  bool hasLocaleTag() => _strings.containsKey(UserPreferenceKeys.localeTag);
}

ProviderContainer _makeContainer(UserPreferences prefs) {
  final container = ProviderContainer(
    overrides: <Override>[userPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('SettingsState.defaults', () {
    test('returns ThemeMode.system / null locale / 5 分 / default 音源', () {
      final SettingsState s = SettingsState.defaults();
      expect(s.themeMode, ThemeMode.system);
      expect(s.localeOverride, isNull);
      expect(s.defaultSnoozeMinutes, 5);
      expect(s.defaultAlarmSoundId, 'default');
    });
  });

  group('SettingsNotifier build', () {
    test('初期 state は SettingsState.defaults と一致する', () {
      final container = _makeContainer(_MemoryUserPrefs());
      // build 直後は microtask が走る前のデフォルト値が返る。
      expect(
        container.read(settingsNotifierProvider),
        SettingsState.defaults(),
      );
    });

    test('UserPreferences が空のとき restore 後も defaults のまま', () async {
      final container = _makeContainer(_MemoryUserPrefs());
      // microtask による _restore() の完了を待つ。
      // build() の microtask 経由 _restore() が走り state が確定するのを待つ。
      // _restore は複数の await を含むので Duration.zero で event loop に
      // 戻して microtask キューを丸ごと drain する。
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(settingsNotifierProvider),
        SettingsState.defaults(),
      );
    });

    test('永続化された値が読み込まれる', () async {
      final prefs = _MemoryUserPrefs(
        ints: <String, int>{
          UserPreferenceKeys.themeMode: ThemeMode.dark.index,
          UserPreferenceKeys.defaultSnoozeMinutes: 10,
        },
        strings: <String, String>{
          UserPreferenceKeys.defaultAlarmSoundId: 'gentle',
        },
      );
      final container = _makeContainer(prefs);
      // build() の microtask 経由 _restore() が走り state が確定するのを待つ。
      // _restore は複数の await を含むので Duration.zero で event loop に
      // 戻して microtask キューを丸ごと drain する。
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      final SettingsState s = container.read(settingsNotifierProvider);
      expect(s.themeMode, ThemeMode.dark);
      expect(s.defaultSnoozeMinutes, 10);
      expect(s.defaultAlarmSoundId, 'gentle');
    });

    test('範囲外 themeMode (-1 / 99) は system に fallback', () async {
      final prefs = _MemoryUserPrefs(
        ints: <String, int>{UserPreferenceKeys.themeMode: 99},
      );
      final container = _makeContainer(prefs);
      // build() の microtask 経由 _restore() が走り state が確定するのを待つ。
      // _restore は複数の await を含むので Duration.zero で event loop に
      // 戻して microtask キューを丸ごと drain する。
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(settingsNotifierProvider).themeMode,
        ThemeMode.system,
      );

      final prefs2 = _MemoryUserPrefs(
        ints: <String, int>{UserPreferenceKeys.themeMode: -1},
      );
      final container2 = _makeContainer(prefs2);
      container2.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        container2.read(settingsNotifierProvider).themeMode,
        ThemeMode.system,
      );
    });

    test('不正な snooze (7) は 5 にフォールバック', () async {
      final prefs = _MemoryUserPrefs(
        ints: <String, int>{UserPreferenceKeys.defaultSnoozeMinutes: 7},
      );
      final container = _makeContainer(prefs);
      // build() の microtask 経由 _restore() が走り state が確定するのを待つ。
      // _restore は複数の await を含むので Duration.zero で event loop に
      // 戻して microtask キューを丸ごと drain する。
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(settingsNotifierProvider).defaultSnoozeMinutes, 5);
    });

    test('未知の sound id は default にフォールバック', () async {
      final prefs = _MemoryUserPrefs(
        strings: <String, String>{
          UserPreferenceKeys.defaultAlarmSoundId: 'bogus',
        },
      );
      final container = _makeContainer(prefs);
      // build() の microtask 経由 _restore() が走り state が確定するのを待つ。
      // _restore は複数の await を含むので Duration.zero で event loop に
      // 戻して microtask キューを丸ごと drain する。
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(settingsNotifierProvider).defaultAlarmSoundId,
        'default',
      );
    });
  });

  group('SettingsNotifier mutators', () {
    test('setThemeMode は state と UserPreferences を更新する', () async {
      final prefs = _MemoryUserPrefs();
      final container = _makeContainer(prefs);
      // build() の microtask 経由 _restore() が走り state が確定するのを待つ。
      // _restore は複数の await を含むので Duration.zero で event loop に
      // 戻して microtask キューを丸ごと drain する。
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsNotifierProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(
        container.read(settingsNotifierProvider).themeMode,
        ThemeMode.dark,
      );
      expect(prefs.themeMode, ThemeMode.dark.index);
    });

    test('setDefaultSnoozeMinutes(10) は state と prefs を更新する', () async {
      final prefs = _MemoryUserPrefs();
      final container = _makeContainer(prefs);
      // build() の microtask 経由 _restore() が走り state が確定するのを待つ。
      // _restore は複数の await を含むので Duration.zero で event loop に
      // 戻して microtask キューを丸ごと drain する。
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsNotifierProvider.notifier)
          .setDefaultSnoozeMinutes(10);

      expect(container.read(settingsNotifierProvider).defaultSnoozeMinutes, 10);
      expect(prefs.snoozeMinutes, 10);
    });

    test('setDefaultSnoozeMinutes(7) は ArgumentError', () async {
      final container = _makeContainer(_MemoryUserPrefs());
      // build() の microtask 経由 _restore() が走り state が確定するのを待つ。
      // _restore は複数の await を含むので Duration.zero で event loop に
      // 戻して microtask キューを丸ごと drain する。
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        () => container
            .read(settingsNotifierProvider.notifier)
            .setDefaultSnoozeMinutes(7),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('setDefaultAlarmSoundId(gentle) は state と prefs を更新する', () async {
      final prefs = _MemoryUserPrefs();
      final container = _makeContainer(prefs);
      // build() の microtask 経由 _restore() が走り state が確定するのを待つ。
      // _restore は複数の await を含むので Duration.zero で event loop に
      // 戻して microtask キューを丸ごと drain する。
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsNotifierProvider.notifier)
          .setDefaultAlarmSoundId('gentle');

      expect(
        container.read(settingsNotifierProvider).defaultAlarmSoundId,
        'gentle',
      );
      expect(prefs.alarmSoundId, 'gentle');
    });

    test('setDefaultAlarmSoundId(bogus) は ArgumentError', () async {
      final container = _makeContainer(_MemoryUserPrefs());
      // build() の microtask 経由 _restore() が走り state が確定するのを待つ。
      // _restore は複数の await を含むので Duration.zero で event loop に
      // 戻して microtask キューを丸ごと drain する。
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        () => container
            .read(settingsNotifierProvider.notifier)
            .setDefaultAlarmSoundId('bogus'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SettingsNotifier localeOverride', () {
    test('永続化された "ja" は Locale("ja") に復元される', () async {
      final prefs = _MemoryUserPrefs(
        strings: <String, String>{UserPreferenceKeys.localeTag: 'ja'},
      );
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(settingsNotifierProvider).localeOverride,
        const Locale('ja'),
      );
    });

    test('永続化された "en" は Locale("en") に復元される', () async {
      final prefs = _MemoryUserPrefs(
        strings: <String, String>{UserPreferenceKeys.localeTag: 'en'},
      );
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(settingsNotifierProvider).localeOverride,
        const Locale('en'),
      );
    });

    test('未サポート文字列 "xx" は null にフォールバック', () async {
      final prefs = _MemoryUserPrefs(
        strings: <String, String>{UserPreferenceKeys.localeTag: 'xx'},
      );
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(settingsNotifierProvider).localeOverride, isNull);
    });

    test('setLocaleOverride(null) は localeTag を remove する', () async {
      final prefs = _MemoryUserPrefs(
        strings: <String, String>{UserPreferenceKeys.localeTag: 'ja'},
      );
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsNotifierProvider.notifier)
          .setLocaleOverride(null);

      expect(container.read(settingsNotifierProvider).localeOverride, isNull);
      expect(prefs.hasLocaleTag(), isFalse);
    });

    test('setLocaleOverride(Locale("en")) は "en" を setString で永続化', () async {
      final prefs = _MemoryUserPrefs();
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsNotifierProvider.notifier)
          .setLocaleOverride(const Locale('en'));

      expect(
        container.read(settingsNotifierProvider).localeOverride,
        const Locale('en'),
      );
      expect(prefs.localeTag, 'en');
    });

    test(
      'setLocaleOverride(unsupported "xx") は null に矯正され remove される',
      () async {
        final prefs = _MemoryUserPrefs(
          strings: <String, String>{UserPreferenceKeys.localeTag: 'ja'},
        );
        final container = _makeContainer(prefs);
        container.read(settingsNotifierProvider);
        await Future<void>.delayed(Duration.zero);

        await container
            .read(settingsNotifierProvider.notifier)
            .setLocaleOverride(const Locale('xx'));

        expect(container.read(settingsNotifierProvider).localeOverride, isNull);
        expect(prefs.hasLocaleTag(), isFalse);
      },
    );
  });
}
