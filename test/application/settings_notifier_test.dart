import 'dart:async';

import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/imported_sound_repository_provider.dart';
import 'package:timer_utility/application/settings_notifier.dart';
import 'package:timer_utility/application/user_preferences_provider.dart';
import 'package:timer_utility/domain/ports/imported_sound_repository.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';
import 'package:timer_utility/domain/timer/alarm_sound_catalog.dart';

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

class _MemoryImportedSoundRepository implements ImportedSoundRepository {
  _MemoryImportedSoundRepository([
    Iterable<ImportedSound> sounds = const <ImportedSound>[],
  ]) : _sounds = <String, ImportedSound>{
         for (final ImportedSound sound in sounds) sound.id: sound,
       };

  final Map<String, ImportedSound> _sounds;
  Completer<ImportedSound?>? findByIdGate;

  @override
  Future<void> delete(String id) async => _sounds.remove(id);

  @override
  Future<List<ImportedSound>> findAll() async => _sounds.values.toList();

  @override
  Future<ImportedSound?> findByContentHash(String contentHash) async {
    for (final ImportedSound sound in _sounds.values) {
      if (sound.contentHash == contentHash) return sound;
    }
    return null;
  }

  @override
  Future<ImportedSound?> findById(String id) async =>
      findByIdGate?.future ?? _sounds[id];

  @override
  Future<void> upsert(ImportedSound sound) async => _sounds[sound.id] = sound;
}

ImportedSound _importedSound(String id) => ImportedSound.create(
  id: id,
  displayName: 'Imported sound',
  format: ImportedSoundFormat.mp3,
  byteLength: 1024,
  duration: const Duration(seconds: 3),
  contentHash:
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  createdAt: DateTime.utc(2026, 7, 16),
);

ProviderContainer _makeContainer(
  UserPreferences prefs, {
  ImportedSoundRepository? importedSoundRepository,
}) {
  final container = ProviderContainer(
    overrides: <Override>[
      userPreferencesProvider.overrideWithValue(prefs),
      importedSoundRepositoryProvider.overrideWithValue(
        importedSoundRepository ?? _MemoryImportedSoundRepository(),
      ),
    ],
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
      expect(prefs.alarmSoundId, AlarmSoundCatalog.defaultSound.id);
    });

    test('取り込み音源IDを復元できる', () async {
      final ImportedSound sound = _importedSound('imported-restore');
      final prefs = _MemoryUserPrefs(
        strings: <String, String>{
          UserPreferenceKeys.defaultAlarmSoundId: sound.id,
        },
      );
      final container = _makeContainer(
        prefs,
        importedSoundRepository: _MemoryImportedSoundRepository(<ImportedSound>[
          sound,
        ]),
      );

      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(settingsNotifierProvider).defaultAlarmSoundId,
        sound.id,
      );
    });

    test('遅延restore中に削除された音源IDだけをfallbackして他設定を復元する', () async {
      final ImportedSound sound = _importedSound('imported-delayed');
      final repository = _MemoryImportedSoundRepository(<ImportedSound>[sound])
        ..findByIdGate = Completer<ImportedSound?>();
      final prefs = _MemoryUserPrefs(
        ints: <String, int>{
          UserPreferenceKeys.themeMode: ThemeMode.dark.index,
          UserPreferenceKeys.defaultSnoozeMinutes: 10,
        },
        strings: <String, String>{
          UserPreferenceKeys.defaultAlarmSoundId: sound.id,
        },
      );
      final container = _makeContainer(
        prefs,
        importedSoundRepository: repository,
      );

      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      container
          .read(settingsNotifierProvider.notifier)
          .reconcileDeletedSound(sound.id);
      repository.findByIdGate!.complete(sound);
      await Future<void>.delayed(Duration.zero);

      final SettingsState state = container.read(settingsNotifierProvider);
      expect(state.defaultAlarmSoundId, AlarmSoundCatalog.defaultSound.id);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.defaultSnoozeMinutes, 10);
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

    test('setDefaultAlarmSoundIdは取り込み音源IDを受理する', () async {
      final ImportedSound sound = _importedSound('imported-setter');
      final prefs = _MemoryUserPrefs();
      final container = _makeContainer(
        prefs,
        importedSoundRepository: _MemoryImportedSoundRepository(<ImportedSound>[
          sound,
        ]),
      );
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsNotifierProvider.notifier)
          .setDefaultAlarmSoundId(sound.id);

      expect(
        container.read(settingsNotifierProvider).defaultAlarmSoundId,
        sound.id,
      );
      expect(prefs.alarmSoundId, sound.id);
    });

    test('取り込み音源確認直後の削除でもsetterは削除IDを保存しない', () async {
      final ImportedSound sound = _importedSound('imported-race');
      final repository = _MemoryImportedSoundRepository(<ImportedSound>[sound])
        ..findByIdGate = Completer<ImportedSound?>();
      final prefs = _MemoryUserPrefs();
      final ProviderContainer container = _makeContainer(
        prefs,
        importedSoundRepository: repository,
      );
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      final Future<void> setting = container
          .read(settingsNotifierProvider.notifier)
          .setDefaultAlarmSoundId(sound.id);
      repository.findByIdGate!.complete(sound);
      container
          .read(settingsNotifierProvider.notifier)
          .reconcileDeletedSound(sound.id);

      await expectLater(setting, throwsArgumentError);
      expect(
        container.read(settingsNotifierProvider).defaultAlarmSoundId,
        AlarmSoundCatalog.defaultSound.id,
      );
      expect(prefs.alarmSoundId, isNot(sound.id));
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

    test('setLocaleOverride("en") は "en" を setString で永続化', () async {
      final prefs = _MemoryUserPrefs();
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsNotifierProvider.notifier)
          .setLocaleOverride('en');

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
            .setLocaleOverride('xx');

        expect(container.read(settingsNotifierProvider).localeOverride, isNull);
        expect(prefs.hasLocaleTag(), isFalse);
      },
    );

    test('永続化された "zh" は Locale("zh") に復元される', () async {
      final prefs = _MemoryUserPrefs(
        strings: <String, String>{UserPreferenceKeys.localeTag: 'zh'},
      );
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(settingsNotifierProvider).localeOverride,
        const Locale('zh'),
      );
    });

    // scriptCode を保持できないと gen-l10n の
    // `switch (locale.scriptCode) case 'Hant'` に乗らず簡体字に落ちる。
    test('永続化された "zh-Hant" は scriptCode 付きで復元される', () async {
      final prefs = _MemoryUserPrefs(
        strings: <String, String>{UserPreferenceKeys.localeTag: 'zh-Hant'},
      );
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      final Locale? restored = container
          .read(settingsNotifierProvider)
          .localeOverride;
      expect(restored, isNotNull);
      expect(restored!.languageCode, 'zh');
      expect(restored.scriptCode, 'Hant');
      expect(restored.countryCode, isNull);
    });

    test('永続化された "ko" は Locale("ko") に復元される', () async {
      final prefs = _MemoryUserPrefs(
        strings: <String, String>{UserPreferenceKeys.localeTag: 'ko'},
      );
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(settingsNotifierProvider).localeOverride,
        const Locale('ko'),
      );
    });

    test('setLocaleOverride("zh-Hant") は "zh-Hant" を永続化する', () async {
      final prefs = _MemoryUserPrefs();
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsNotifierProvider.notifier)
          .setLocaleOverride('zh-Hant');

      final Locale? applied = container
          .read(settingsNotifierProvider)
          .localeOverride;
      expect(applied?.scriptCode, 'Hant');
      expect(prefs.localeTag, 'zh-Hant');
    });

    test('setLocaleOverride("ko") は "ko" を永続化する', () async {
      final prefs = _MemoryUserPrefs();
      final container = _makeContainer(prefs);
      container.read(settingsNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(settingsNotifierProvider.notifier)
          .setLocaleOverride('ko');

      expect(
        container.read(settingsNotifierProvider).localeOverride,
        const Locale('ko'),
      );
      expect(prefs.localeTag, 'ko');
    });

    // 公開ビルドで選べる 5 言語がすべて許可タグに載っていること。
    test('supportedLocaleTags は ja / en / zh / zh-Hant / ko を含む', () {
      expect(supportedLocaleTags, <String>['ja', 'en', 'zh', 'zh-Hant', 'ko']);
    });
  });
}
