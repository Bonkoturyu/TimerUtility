import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timer_utility/application/diagnostic_log_exporter_provider.dart';
import 'package:timer_utility/application/diagnostic_settings_notifier.dart';
import 'package:timer_utility/application/user_preferences_provider.dart';
import 'package:timer_utility/domain/ports/diagnostic_log_exporter.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/settings_screen.dart';

class _MemoryPrefs implements UserPreferences {
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

  bool? diagBool() => _bools[UserPreferenceKeys.diagnosticLogEnabled];
}

/// Fake exporter: records calls and lets the test pick success / error.
class _FakeExporter implements DiagnosticLogExporter {
  _FakeExporter({this.throwOnCreate = false});

  bool throwOnCreate;
  int createCalls = 0;
  int shareCalls = 0;

  @override
  Future<String> createArchive() async {
    createCalls++;
    if (throwOnCreate) throw StateError('create boom');
    return '/tmp/zip.zip';
  }

  String? lastSubject;

  @override
  Future<void> share(String path, {required String subject}) async {
    shareCalls++;
    lastSubject = subject;
  }
}

Widget _harness({
  required UserPreferences prefs,
  required DiagnosticLogExporter exporter,
  bool diagnosticDefaultEnabled = false,
}) {
  final router = GoRouter(
    initialLocation: SettingsScreen.routeLocation,
    routes: <RouteBase>[
      GoRoute(
        path: SettingsScreen.routeLocation,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/licenses',
        builder: (_, _) => const Scaffold(body: Center(child: Text('lic'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: <Override>[
      userPreferencesProvider.overrideWithValue(prefs),
      diagnosticLogExporterProvider.overrideWithValue(exporter),
      diagnosticSettingsNotifierProvider.overrideWith(
        () =>
            DiagnosticSettingsNotifier()
              ..defaultEnabled = diagnosticDefaultEnabled,
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
    ),
  );
}

/// Diagnostics セクションは ListView の末尾に配置されているため、
/// 800x600 のテスト viewport だと初期描画では見えない。各テストの
/// 冒頭で対象を viewport に入れる。
Future<void> _scrollToDiagnostics(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('settings_diagnostic_toggle')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SettingsScreen Diagnostics section', () {
    testWidgets('Diagnostics セクションヘッダとトグル / 共有 tile が描画される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(prefs: _MemoryPrefs(), exporter: _FakeExporter()),
      );
      await tester.pumpAndSettle();
      await _scrollToDiagnostics(tester);
      // ARB に追加した「診断ログ」ヘッダ。
      expect(find.text('診断ログ'), findsOneWidget);
      expect(
        find.byKey(const Key('settings_diagnostic_toggle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings_diagnostic_share_tile')),
        findsOneWidget,
      );
    });

    testWidgets('toggle を tap すると DiagnosticSettingsNotifier に永続化される', (
      WidgetTester tester,
    ) async {
      final _MemoryPrefs prefs = _MemoryPrefs();
      await tester.pumpWidget(
        _harness(prefs: prefs, exporter: _FakeExporter()),
      );
      await tester.pumpAndSettle();
      await _scrollToDiagnostics(tester);

      // 初期値: defaultEnabled=false で永続値なし → off。
      final Finder switchFinder = find.byKey(
        const Key('settings_diagnostic_toggle'),
      );
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(prefs.diagBool(), isTrue);
    });

    testWidgets('Share logs tap → 成功 SnackBar が表示される', (
      WidgetTester tester,
    ) async {
      final _FakeExporter exporter = _FakeExporter();
      await tester.pumpWidget(
        _harness(prefs: _MemoryPrefs(), exporter: exporter),
      );
      await tester.pumpAndSettle();
      await _scrollToDiagnostics(tester);

      await tester.tap(find.byKey(const Key('settings_diagnostic_share_tile')));
      // 進行中の CircularProgressIndicator を経て done に遷移するため、
      // 1 つ余分に pump して SnackBar が出るところまで進める。
      await tester.pump(); // inProgress
      await tester.pumpAndSettle(); // done → SnackBar

      expect(exporter.createCalls, 1);
      expect(exporter.shareCalls, 1);
      expect(find.text('共有メニューを開きました'), findsOneWidget);
    });

    testWidgets('Share logs tap → exporter 例外で失敗 SnackBar が表示される', (
      WidgetTester tester,
    ) async {
      final _FakeExporter exporter = _FakeExporter(throwOnCreate: true);
      await tester.pumpWidget(
        _harness(prefs: _MemoryPrefs(), exporter: exporter),
      );
      await tester.pumpAndSettle();
      await _scrollToDiagnostics(tester);

      await tester.tap(find.byKey(const Key('settings_diagnostic_share_tile')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(exporter.shareCalls, 0);
      expect(find.textContaining('create boom'), findsOneWidget);
    });

    testWidgets('Export controller state は autoDispose で初期化される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(prefs: _MemoryPrefs(), exporter: _FakeExporter()),
      );
      await tester.pumpAndSettle();
      await _scrollToDiagnostics(tester);
      // 起動直後は idle なので Share 説明文 (settingsDiagnosticShareLogsDescription)
      // が見える。
      expect(find.text('保存済みログを zip にまとめて共有メニューを開きます。'), findsOneWidget);
    });
  });
}
