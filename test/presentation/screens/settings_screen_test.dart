import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timer_utility/application/settings_notifier.dart';
import 'package:timer_utility/application/user_preferences_provider.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/settings_screen.dart';

class _MemoryUserPrefs implements UserPreferences {
  final Map<String, bool> _bools = <String, bool>{};
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
}

Widget _harness({UserPreferences? prefs}) {
  final router = GoRouter(
    initialLocation: SettingsScreen.routeLocation,
    routes: <RouteBase>[
      GoRoute(
        path: SettingsScreen.routeLocation,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/licenses',
        builder: (_, _) => const Scaffold(
          key: Key('licenses_stub'),
          body: Center(child: Text('licenses-stub')),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: <Override>[
      userPreferencesProvider.overrideWithValue(prefs ?? _MemoryUserPrefs()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
    ),
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets('3 セクションヘッダと各 ListTile が描画される', (WidgetTester tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      // セクションヘッダ。「デフォルト」と「情報」は他箇所の表示文字列と
      // 重なる可能性があるため、少なくとも 1 つ以上見つかることだけを
      // 確認する (一意性は不要)。
      expect(find.text('表示'), findsWidgets);
      expect(find.text('デフォルト'), findsWidgets);
      expect(find.text('情報'), findsWidgets);

      expect(find.byKey(const Key('settings_theme_tile')), findsOneWidget);
      expect(find.byKey(const Key('settings_snooze_tile')), findsOneWidget);
      expect(find.byKey(const Key('settings_sound_tile')), findsOneWidget);
      expect(find.byKey(const Key('settings_licenses_tile')), findsOneWidget);
    });

    testWidgets('テーマ Light 選択で state.themeMode が light に更新される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(
        find.byKey(const Key('settings_theme_tile')),
      );
      final ProviderContainer container = ProviderScope.containerOf(ctx);

      // Light を選択。SegmentedButton の各 segment は描画上の Text で hit する。
      await tester.tap(find.text('ライト'));
      await tester.pumpAndSettle();

      expect(
        container.read(settingsNotifierProvider).themeMode,
        ThemeMode.light,
      );
    });

    testWidgets('スヌーズ 10 分選択で state.defaultSnoozeMinutes が 10 になる', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(
        find.byKey(const Key('settings_snooze_tile')),
      );
      final ProviderContainer container = ProviderScope.containerOf(ctx);

      // SegmentedButton 内で「10 分」を tap。"5 分" / "10 分" / "15 分" が並ぶ。
      await tester.tap(find.text('10 分'));
      await tester.pumpAndSettle();

      expect(container.read(settingsNotifierProvider).defaultSnoozeMinutes, 10);
    });

    testWidgets('音源 ListTile タップ → SoundSelectSheet → 選択で state 更新', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(
        find.byKey(const Key('settings_sound_tile')),
      );
      final ProviderContainer container = ProviderScope.containerOf(ctx);

      await tester.tap(find.byKey(const Key('settings_sound_tile')));
      await tester.pumpAndSettle();

      // SoundSelectSheet の 'gentle' エントリを tap。
      await tester.tap(find.byKey(const Key('sound_select_gentle')));
      await tester.pumpAndSettle();

      expect(
        container.read(settingsNotifierProvider).defaultAlarmSoundId,
        'gentle',
      );
    });

    testWidgets('ライセンス ListTile タップで /licenses に push される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_licenses_tile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('licenses_stub')), findsOneWidget);
    });

    testWidgets('言語 ListTile が表示され副題はデフォルトで「システムに合わせる」', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_language_tile')), findsOneWidget);
      // 副題は ARB の settingsLanguageSystem (ja)。タイトルの「言語」と区別する
      // ため subtitle 上の Text を直接探す。
      expect(
        find.descendant(
          of: find.byKey(const Key('settings_language_tile')),
          matching: find.text('システムに合わせる'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('言語 ListTile タップで BottomSheet に system + ja + en の 3 件が表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_language_tile')));
      await tester.pumpAndSettle();

      // 3 件のラジオオプション。
      expect(
        find.byKey(const Key('settings_language_option_system')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings_language_option_ja')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings_language_option_en')),
        findsOneWidget,
      );
      // experimental フラグ false (defaultValue) のとき zh / zh-Hant / ko は出ない。
      expect(
        find.byKey(const Key('settings_language_option_zh')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('settings_language_option_zh-Hant')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('settings_language_option_ko')),
        findsNothing,
      );
    });

    testWidgets('英語を選択すると state.localeOverride が Locale("en") になる', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(
        find.byKey(const Key('settings_language_tile')),
      );
      final ProviderContainer container = ProviderScope.containerOf(ctx);

      await tester.tap(find.byKey(const Key('settings_language_tile')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_language_option_en')));
      await tester.pumpAndSettle();

      expect(
        container.read(settingsNotifierProvider).localeOverride,
        const Locale('en'),
      );
      // シートは閉じている。
      expect(
        find.byKey(const Key('settings_language_option_en')),
        findsNothing,
      );
    });

    testWidgets('「システムに合わせる」を選ぶと localeOverride が null になる', (
      WidgetTester tester,
    ) async {
      final prefs = _MemoryUserPrefs();
      // 初期値として ja を入れておき、システムを選択して null に戻ることを確認。
      await prefs.setString(UserPreferenceKeys.localeTag, 'ja');
      await tester.pumpWidget(_harness(prefs: prefs));
      await tester.pumpAndSettle();

      final BuildContext ctx = tester.element(
        find.byKey(const Key('settings_language_tile')),
      );
      final ProviderContainer container = ProviderScope.containerOf(ctx);

      // restore が走った直後は Locale("ja") のはず。
      expect(
        container.read(settingsNotifierProvider).localeOverride,
        const Locale('ja'),
      );

      await tester.tap(find.byKey(const Key('settings_language_tile')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settings_language_option_system')),
      );
      await tester.pumpAndSettle();

      expect(container.read(settingsNotifierProvider).localeOverride, isNull);
    });
  });
}
