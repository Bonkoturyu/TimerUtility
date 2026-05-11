import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_repository_provider.dart';
import 'package:timer_utility/application/clock_location_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/location_detector_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/application/preset_repository_provider.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/application/timezone_resolver_provider.dart';
import 'package:timer_utility/application/user_preferences_provider.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/clock/clock_location.dart';
import 'package:timer_utility/domain/clock/clock_time.dart';
import 'package:timer_utility/domain/ports/alarm_repository.dart';
import 'package:timer_utility/domain/ports/clock_location_repository.dart';
import 'package:timer_utility/domain/ports/location_detector.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/domain/ports/preset_repository.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/alarm_ringing_screen.dart';
import 'package:timer_utility/presentation/screens/home/alarm_list_page.dart';
import 'package:timer_utility/presentation/screens/home/clock_page.dart';
import 'package:timer_utility/presentation/screens/home/home_screen.dart';
import 'package:timer_utility/presentation/screens/home/stopwatch_page.dart';
import 'package:timer_utility/presentation/screens/home/timer_list_page.dart';
import 'package:timer_utility/presentation/widgets/home_dot_indicator.dart';

import '../../../helpers/test_notification_strings.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

class _MockClockLocationRepository extends Mock
    implements ClockLocationRepository {}

class _MockLocationDetector extends Mock implements LocationDetector {}

class _ClockLocationFake extends Fake implements ClockLocation {}

class _IdentityResolver implements TimezoneResolver {
  @override
  DateTime computeAt(DateTime now, String timezoneId) => now;
}

/// In-memory [UserPreferences] that records every `setInt` call so
/// tests can verify persistence behaviour. Distinguishes "explicitly
/// stored" from "absent" the same way the real adapter does.
class _RecordingPrefs implements UserPreferences {
  _RecordingPrefs({Map<String, int>? seedInts})
    : _ints = <String, int>{...?seedInts};

  final Map<String, bool> _bools = <String, bool>{};
  final Map<String, int> _ints;
  final List<MapEntry<String, int>> setIntCalls = <MapEntry<String, int>>[];

  @override
  Future<bool?> getBool(String key) async => _bools[key];

  @override
  Future<void> setBool(String key, bool value) async => _bools[key] = value;

  @override
  Future<int?> getInt(String key) async => _ints[key];

  @override
  Future<void> setInt(String key, int value) async {
    setIntCalls.add(MapEntry<String, int>(key, value));
    _ints[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _bools.remove(key);
    _ints.remove(key);
  }
}

class _InMemoryTimerRepo implements TimerRepository {
  final Map<String, TimerEntity> store = <String, TimerEntity>{};

  @override
  Future<void> delete(String id) async => store.remove(id);

  @override
  Future<List<TimerEntity>> findAll() async => store.values.toList();

  @override
  Future<TimerEntity?> findById(String id) async => store[id];

  @override
  Future<void> upsert(TimerEntity entity) async => store[entity.id] = entity;
}

class _InMemoryPresetRepo implements PresetRepository {
  final Map<String, Preset> store = <String, Preset>{};

  @override
  Future<void> delete(String id) async => store.remove(id);

  @override
  Future<List<Preset>> findAll() async => store.values.toList();

  @override
  Future<Preset?> findById(String id) async => store[id];

  @override
  Future<void> upsert(Preset entity) async => store[entity.id] = entity;

  @override
  Future<void> replaceAll(List<Preset> entities) async {
    store.clear();
    for (final Preset e in entities) {
      store[e.id] = e;
    }
  }
}

class _InMemoryAlarmRepo implements AlarmRepository {
  final Map<String, AlarmEntity> store = <String, AlarmEntity>{};

  @override
  Future<void> delete(String id) async => store.remove(id);

  @override
  Future<List<AlarmEntity>> findAll() async => store.values.toList();

  @override
  Future<AlarmEntity?> findById(String id) async => store[id];

  @override
  Future<void> upsert(AlarmEntity entity) async => store[entity.id] = entity;
}

class _GrantedPermissionNotifier extends PermissionNotifier {
  @override
  PermissionState build() => const PermissionState(
    postNotifications: DomainPermissionStatus.granted,
    scheduleExactAlarm: DomainPermissionStatus.granted,
    fullScreenIntent: DomainPermissionStatus.granted,
  );
}

NotificationScheduler _stubScheduler() {
  final s = _MockScheduler();
  when(
    () => s.schedule(
      notificationId: any(named: 'notificationId'),
      fireAt: any(named: 'fireAt'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      exact: any(named: 'exact'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => s.show(
      notificationId: any(named: 'notificationId'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});
  when(() => s.cancel(any())).thenAnswer((_) async {});
  when(() => s.cancelAll()).thenAnswer((_) async {});
  return s;
}

ClockLocationRepository _stubClockRepo() {
  final r = _MockClockLocationRepository();
  when(() => r.findAll()).thenAnswer((_) async => <ClockLocation>[]);
  when(() => r.upsert(any())).thenAnswer((_) async {});
  when(() => r.delete(any())).thenAnswer((_) async {});
  when(() => r.replaceAll(any())).thenAnswer((_) async {});
  return r;
}

LocationDetector _stubDetector() {
  final d = _MockLocationDetector();
  when(() => d.detectTimezoneId()).thenAnswer((_) async => 'Etc/UTC');
  return d;
}

/// Mounts [HomeScreen] under a real [GoRouter] with stubbed destination
/// routes for the AppBar overflow flows (`/licenses`, `/presets`,
/// `/clock/locations`). Caller-supplied [prefs] is the recording
/// preferences fake used by the persistence-verify scenario.
/// [timerRepo] lets the (m) ringing-listener test seed an already-
/// ringing TimerEntity so the HomeScreen-level `ref.listen` fires.
/// [initialPageIndex] mirrors the `main()` post-prefs-read value that
/// HomeScreen takes through its constructor (PR #29 G3); pass it to
/// exercise the restore path without relying on a microtask-based
/// jump.
Widget _harness({
  required _RecordingPrefs prefs,
  _InMemoryTimerRepo? timerRepo,
  int initialPageIndex = HomeScreen.defaultPageIndex,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, _) => HomeScreen(initialPageIndex: initialPageIndex),
      ),
      GoRoute(
        path: '/licenses',
        builder: (_, _) => const Scaffold(
          key: Key('licenses_stub'),
          body: Center(child: Text('licenses-stub')),
        ),
      ),
      GoRoute(
        path: '/presets',
        builder: (_, _) => const Scaffold(
          key: Key('presets_stub'),
          body: Center(child: Text('presets-stub')),
        ),
      ),
      GoRoute(
        path: '/clock/locations',
        builder: (_, _) => const Scaffold(
          key: Key('clock_locations_stub'),
          body: Center(child: Text('locations-stub')),
        ),
      ),
      GoRoute(
        path: '/alarm-ringing',
        builder: (_, _) => const Scaffold(
          key: Key('alarm_ringing_stub'),
          body: Center(child: Text('alarm-ringing-stub')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 5, 10, 9))),
      userPreferencesProvider.overrideWithValue(prefs),
      timerRepositoryProvider.overrideWithValue(
        timerRepo ?? _InMemoryTimerRepo(),
      ),
      presetRepositoryProvider.overrideWithValue(_InMemoryPresetRepo()),
      alarmRepositoryProvider.overrideWithValue(_InMemoryAlarmRepo()),
      notificationSchedulerProvider.overrideWithValue(_stubScheduler()),
      clockLocationRepositoryProvider.overrideWithValue(_stubClockRepo()),
      locationDetectorProvider.overrideWithValue(_stubDetector()),
      timezoneResolverProvider.overrideWithValue(_IdentityResolver()),
      testNotificationStringsOverride(),
      permissionNotifierProvider.overrideWith(
        () => _GrantedPermissionNotifier(),
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

/// Pumps + drains the post-frame microtask that restores
/// `lastHomePageIndex`. The HomeScreen issues a `Future.microtask` from
/// `initState` (so we can `await` the prefs read), so a single
/// `pumpAndSettle` may finish before that future flushes the page jump.
Future<void> _settleRestore(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(Duration.zero);
  await tester.pumpAndSettle();
}

/// Asserts the [HomeDotIndicator] highlights [expectedIndex] as the
/// active dot — based on the active dot's pill width (24dp) versus the
/// inactive width (10dp).
void _expectActiveDot(WidgetTester tester, int expectedIndex) {
  for (int i = 0; i < HomeScreen.pageCount; i++) {
    final Container dot = tester.widget<Container>(
      find.byKey(Key('home_dot_$i')),
    );
    final BoxConstraints? constraints = dot.constraints;
    final double width = constraints?.maxWidth ?? 0;
    if (i == expectedIndex) {
      expect(width, 24, reason: 'dot $i should be the active 24dp pill');
    } else {
      expect(width, 10, reason: 'dot $i should be inactive 10dp circle');
    }
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(_ClockLocationFake());
    registerFallbackValue(<ClockLocation>[]);
  });

  group('HomeScreen (Phase 11 PageView)', () {
    testWidgets('(a) lastHomePageIndex が未保存なら Timer ページがデフォルト表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness(prefs: _RecordingPrefs()));
      await _settleRestore(tester);

      // Timer タブ (index 1) がデフォルト。AppBar title で確認する。
      expect(find.byType(TimerListPage), findsOneWidget);
    });

    testWidgets('(b) initialPageIndex = 2 で Alarm ページが復元される', (
      WidgetTester tester,
    ) async {
      // PR #29 G3: HomeScreen は initialPageIndex をコンストラクタで
      // 受け取る方式に変更。`main()` が prefs を読んでこの値に解決する。
      await tester.pumpWidget(
        _harness(prefs: _RecordingPrefs(), initialPageIndex: 2),
      );
      await _settleRestore(tester);

      expect(find.byType(AlarmListPage), findsOneWidget);
    });

    testWidgets('(c) 左 fling で次タブに、右 fling で前タブに遷移する', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness(prefs: _RecordingPrefs()));
      await _settleRestore(tester);

      // initial = Timer (index 1)。左 fling で Alarm (index 2) へ。
      await tester.fling(
        find.byKey(const Key('home_page_view')),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlarmListPage), findsOneWidget);

      // 右 fling で 1 つ前 (Timer) に戻る。
      await tester.fling(
        find.byKey(const Key('home_page_view')),
        const Offset(400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.byType(TimerListPage), findsOneWidget);

      // 末端の循環確認: Alarm → Clock → さらに左 fling で Stopwatch に
      // 戻れることを確認 (Phase 11 follow-up Step 3 の wrap-around)。
      for (int i = 0; i < 2; i++) {
        await tester.fling(
          find.byKey(const Key('home_page_view')),
          const Offset(-400, 0),
          1000,
        );
        await tester.pumpAndSettle();
      }
      expect(find.byType(ClockPage), findsOneWidget);

      await tester.fling(
        find.byKey(const Key('home_page_view')),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.byType(StopwatchPage), findsOneWidget);
    });

    testWidgets(
      '(d) PageView は wrap-around (Clock 左 fling → Stopwatch / Stopwatch 右 fling → Clock)',
      (WidgetTester tester) async {
        // Clock (index 3) 起動 → 左 fling で Stopwatch (index 0) に循環。
        await tester.pumpWidget(
          _harness(prefs: _RecordingPrefs(), initialPageIndex: 3),
        );
        await _settleRestore(tester);
        expect(find.byType(ClockPage), findsOneWidget);

        await tester.fling(
          find.byKey(const Key('home_page_view')),
          const Offset(-400, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.byType(StopwatchPage), findsOneWidget);

        // 逆方向も確認: Stopwatch から右 fling で Clock に戻る。
        await tester.fling(
          find.byKey(const Key('home_page_view')),
          const Offset(400, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.byType(ClockPage), findsOneWidget);
      },
    );

    testWidgets('(e) PageNavigationHint 右タップで次ページに animateToPage する', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness(prefs: _RecordingPrefs()));
      await _settleRestore(tester);

      // initial = Timer。trailing hint をタップして Alarm へ。
      await tester.tap(find.byKey(const Key('page_nav_hint_right')));
      await tester.pumpAndSettle();

      expect(find.byType(AlarmListPage), findsOneWidget);
    });

    testWidgets('(f) DotIndicator の active dot が現在ページと一致する', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness(prefs: _RecordingPrefs()));
      await _settleRestore(tester);

      // initial = Timer (index 1)。
      _expectActiveDot(tester, 1);

      // Alarm (index 2) に進めて再確認。
      await tester.fling(
        find.byKey(const Key('home_page_view')),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      _expectActiveDot(tester, 2);
    });

    testWidgets(
      '(g) FAB は Timer / Alarm ページのみ visible、Stopwatch / Clock では消える',
      (WidgetTester tester) async {
        await tester.pumpWidget(_harness(prefs: _RecordingPrefs()));
        await _settleRestore(tester);

        // Timer (index 1) で timer FAB が出る。
        expect(find.byKey(const Key('timer_list_add_fab')), findsOneWidget);
        expect(find.byKey(const Key('alarm_list_add_fab')), findsNothing);

        // Alarm へ swipe → alarm FAB のみ。
        await tester.fling(
          find.byKey(const Key('home_page_view')),
          const Offset(-400, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('timer_list_add_fab')), findsNothing);
        expect(find.byKey(const Key('alarm_list_add_fab')), findsOneWidget);

        // Clock へ swipe → どちらも消える。
        await tester.fling(
          find.byKey(const Key('home_page_view')),
          const Offset(-400, 0),
          1000,
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('timer_list_add_fab')), findsNothing);
        expect(find.byKey(const Key('alarm_list_add_fab')), findsNothing);

        // Stopwatch (index 0) まで戻して FAB なしを確認。
        for (int i = 0; i < 3; i++) {
          await tester.fling(
            find.byKey(const Key('home_page_view')),
            const Offset(400, 0),
            1000,
          );
          await tester.pumpAndSettle();
        }
        expect(find.byKey(const Key('timer_list_add_fab')), findsNothing);
        expect(find.byKey(const Key('alarm_list_add_fab')), findsNothing);
      },
    );

    testWidgets('(h) AppBar overflow → ライセンス で /licenses が push される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_harness(prefs: _RecordingPrefs()));
      await _settleRestore(tester);

      await tester.tap(find.byKey(const Key('home_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home_menu_licenses')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('licenses_stub')), findsOneWidget);
    });

    testWidgets(
      '(i) overflow メニューはページに応じて manage_presets / edit_locations が出し分けされる',
      (WidgetTester tester) async {
        await tester.pumpWidget(_harness(prefs: _RecordingPrefs()));
        await _settleRestore(tester);

        // Timer (index 1) では manage_presets が出る、edit_locations は無い。
        await tester.tap(find.byKey(const Key('home_menu')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('home_menu_manage_presets')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('home_menu_edit_locations')), findsNothing);
        // メニューを閉じる。
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Clock (index 3) まで進める。
        for (int i = 0; i < 2; i++) {
          await tester.fling(
            find.byKey(const Key('home_page_view')),
            const Offset(-400, 0),
            1000,
          );
          await tester.pumpAndSettle();
        }
        expect(find.byType(ClockPage), findsOneWidget);

        await tester.tap(find.byKey(const Key('home_menu')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home_menu_manage_presets')), findsNothing);
        expect(
          find.byKey(const Key('home_menu_edit_locations')),
          findsOneWidget,
        );
      },
    );

    testWidgets('(j) ページ切替時に lastHomePageIndex が UserPreferences に保存される', (
      WidgetTester tester,
    ) async {
      final prefs = _RecordingPrefs();
      await tester.pumpWidget(_harness(prefs: prefs));
      await _settleRestore(tester);

      // Initial 復元では setInt は呼ばれない。
      expect(prefs.setIntCalls, isEmpty);

      // Timer (1) → Alarm (2) に swipe。
      await tester.fling(
        find.byKey(const Key('home_page_view')),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // setInt が `lastHomePageIndex = 2` で 1 度呼ばれている
      // (PageView の onPageChanged は終点の index 1 回のみ発火)。
      expect(prefs.setIntCalls, hasLength(1));
      expect(prefs.setIntCalls.first.key, 'lastHomePageIndex');
      expect(prefs.setIntCalls.first.value, 2);
    });

    testWidgets(
      '(k) Pixel 6a 412dp 幅で Timer / Alarm の AppBar title が省略表示されない',
      (WidgetTester tester) async {
        // Pixel 6a の論理幅 412 × 800 (高さは AppBar/FAB が描ければ何でも可)。
        // dpr = 1 で physicalSize = logicalSize としておけば
        // tester.getSize / find.text の挙動と一致する。
        await tester.binding.setSurfaceSize(const Size(412, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_harness(prefs: _RecordingPrefs()));
        await _settleRestore(tester);

        // Timer (index 1) — initial。AppBar title は AppBar 内側の Text で
        // 描画されているので、AppBar 内に限定して find する。
        Finder titleInAppBar(String s) =>
            find.descendant(of: find.byType(AppBar), matching: find.text(s));

        final RenderParagraph timerTitle = tester.renderObject<RenderParagraph>(
          titleInAppBar('タイマー'),
        );
        expect(
          timerTitle.didExceedMaxLines,
          isFalse,
          reason: 'Timer の AppBar title が省略表示されている',
        );

        // Alarm (index 2) に進めて再確認。
        await tester.fling(
          find.byKey(const Key('home_page_view')),
          const Offset(-400, 0),
          1000,
        );
        await tester.pumpAndSettle();

        final RenderParagraph alarmTitle = tester.renderObject<RenderParagraph>(
          titleInAppBar('アラーム'),
        );
        expect(
          alarmTitle.didExceedMaxLines,
          isFalse,
          reason: 'Alarm の AppBar title が省略表示されている',
        );
      },
    );

    testWidgets('(l) Pixel 6a 412dp 幅で FAB と HomeDotIndicator が縦方向に重ならない', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(412, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_harness(prefs: _RecordingPrefs()));
      await _settleRestore(tester);

      // initial = Timer (index 1)。Timer タブの FAB と DotIndicator が
      // 同居する状態で Y 方向 overlap がないことを確認。
      final Rect fabRect = tester.getRect(
        find.byKey(const Key('timer_list_add_fab')),
      );
      final Rect dotRect = tester.getRect(find.byType(HomeDotIndicator));

      // bottomNavigationBar slot に置いたので、DotIndicator は FAB より
      // 下、または body 領域外に配置されているはず。FAB の bottom が
      // DotIndicator の top 以下であれば overlap なし。
      expect(
        fabRect.bottom,
        lessThanOrEqualTo(dotRect.top),
        reason:
            'FAB と DotIndicator が Y 軸で重なっている '
            '(FAB.bottom=${fabRect.bottom}, dot.top=${dotRect.top})',
      );
    });

    testWidgets(
      '(m) ringing 検知は HomeScreen レベルなので Stopwatch タブ表示中でも /alarm-ringing へ push される',
      (WidgetTester tester) async {
        // PR #29 G1 のリグレッションガード。旧実装では ringing → push
        // ロジックが `TimerListPage` の build にあり、Stopwatch タブを
        // 表示している間は `TimerListPage` が dispose されて listener
        // が失われていた。新実装は `HomeScreen` の build に listener が
        // あるので、どのタブが表示されていても発火する。
        final timerRepo = _InMemoryTimerRepo();
        timerRepo.store['ring-1'] = TimerEntity(
          id: 'ring-1',
          notificationId: 1,
          label: '',
          duration: const Duration(seconds: 5),
          endAt: null,
          pausedRemaining: null,
          status: TimerStatus.ringing,
          createdAt: DateTime(2026, 5, 10),
        );
        addTearDown(AlarmRingingScreen.debugResetPushReservation);

        // Stopwatch (index 0) で起動して、Timer タブが visible でない
        // 状況を作る。
        await tester.pumpWidget(
          _harness(
            prefs: _RecordingPrefs(),
            timerRepo: timerRepo,
            initialPageIndex: 0,
          ),
        );
        await _settleRestore(tester);

        // ref.listen が走り、HomeScreen から /alarm-ringing へ push
        // されていることを stub の存在で確認する。
        expect(find.byKey(const Key('alarm_ringing_stub')), findsOneWidget);
      },
    );

    testWidgets('(n) PageNavigationHint は隣接タブ名を Semantics ラベルとして公開する', (
      WidgetTester tester,
    ) async {
      // PR #29 C1: leading / trailing hint は視覚上ラベル無しだが、
      // スクリーンリーダーは隣タブ名で読み上げられる必要がある。
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_harness(prefs: _RecordingPrefs()));
        await _settleRestore(tester);

        // initial = Timer (index 1)。
        //   prev = Stopwatch → leading semantics label = "ストップウォッチ"
        //   next = Alarm     → trailing semantics label = "アラーム"
        expect(
          find.bySemanticsLabel('ストップウォッチ'),
          findsOneWidget,
          reason: 'leading hint の Semantics label が前タブ名を出していない',
        );
        expect(
          find.bySemanticsLabel('アラーム'),
          findsOneWidget,
          reason: 'trailing hint の Semantics label が次タブ名を出していない',
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
