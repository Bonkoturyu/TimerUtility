import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/clock_collection_notifier.dart';
import 'package:timer_utility/application/clock_location_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/clock_tick/current_time_stream_provider.dart';
import 'package:timer_utility/application/location_detector_provider.dart';
import 'package:timer_utility/application/timezone_resolver_provider.dart';
import 'package:timer_utility/domain/clock/clock_collection.dart';
import 'package:timer_utility/domain/clock/clock_location.dart';
import 'package:timer_utility/domain/clock/clock_time.dart';
import 'package:timer_utility/domain/ports/clock_location_repository.dart';
import 'package:timer_utility/domain/ports/location_detector.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/clock_screen.dart';
import 'package:timer_utility/presentation/widgets/clock_design_a.dart';
import 'package:timer_utility/presentation/widgets/clock_design_b.dart';
import 'package:timer_utility/presentation/widgets/clock_design_c.dart';

class _MockClockLocationRepository extends Mock
    implements ClockLocationRepository {}

class _MockLocationDetector extends Mock implements LocationDetector {}

class _ClockLocationFake extends Fake implements ClockLocation {}

/// Returns the input `now` unchanged so the digital readout reflects
/// the stream-emitted UTC time verbatim. Lets the test assert on
/// `find.text('HH:mm')` without modelling timezone offsets.
class _IdentityResolver implements TimezoneResolver {
  @override
  DateTime computeAt(DateTime now, String timezoneId) => now;
}

/// Subclass-override seam for `clockCollectionNotifierProvider`.
///
/// The production notifier seeds itself by reading the repository in a
/// `Future.microtask` from `build()`; that's painful in a widget test
/// because the notifier insists on driving `findAll` and (on empty)
/// `detectTimezoneId`. Overriding `build()` to return the test
/// collection directly skips both code paths and keeps mutations
/// (which these tests don't exercise) routing through the real
/// implementation should we need them later.
class _SeededClockCollectionNotifier extends ClockCollectionNotifier {
  _SeededClockCollectionNotifier(this._initial);
  final ClockCollection _initial;

  @override
  ClockCollection build() => _initial;
}

ClockLocation _loc(int order, String name, {String tz = 'Etc/UTC'}) =>
    ClockLocation(
      id: 'id-$order',
      displayName: name,
      timezoneId: tz,
      isCurrentLocation: order == 0,
      displayOrder: order,
      createdAt: DateTime.utc(2026, 1, 1),
    );

/// Builds the widget under test wrapped in a `GoRouter` so the AppBar
/// overflow can `context.push('/clock/locations')` against a real
/// router (we stub the destination route to a Scaffold and look for
/// its key to verify navigation occurred).
Widget _harness({
  required List<ClockLocation> seeded,
  Stream<DateTime>? timeStream,
  DateTime? fixedNow,
}) {
  final DateTime now = fixedNow ?? DateTime.utc(2026, 5, 10, 9);
  final ClockCollection collection = seeded.isEmpty
      ? ClockCollection.empty()
      : ClockCollection.fromList(seeded);
  final Stream<DateTime> stream = timeStream ?? Stream<DateTime>.value(now);

  // Repository / detector are not exercised when the notifier is
  // overridden via `_SeededClockCollectionNotifier`, but we still wire
  // benign stubs in case a future test path triggers a mutation.
  // mocktail tear-off form (`when(repo.findAll)`) works at runtime but
  // we stick to `when(() => repo.foo())` for visual consistency with
  // the rest of the test suite.
  final repo = _MockClockLocationRepository();
  final detector = _MockLocationDetector();
  when(() => repo.findAll()).thenAnswer((_) async => seeded);
  when(() => repo.upsert(any())).thenAnswer((_) async {});
  when(() => repo.delete(any())).thenAnswer((_) async {});
  when(() => repo.replaceAll(any())).thenAnswer((_) async {});
  when(() => detector.detectTimezoneId()).thenAnswer((_) async => 'Etc/UTC');

  final GoRouter router = GoRouter(
    initialLocation: ClockScreen.routeLocation,
    routes: <RouteBase>[
      GoRoute(
        path: ClockScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) =>
            const ClockScreen(),
      ),
      GoRoute(
        path: '/clock/locations',
        builder: (BuildContext context, GoRouterState state) => const Scaffold(
          key: Key('clock_locations_stub'),
          body: Center(child: Text('locations-stub')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(now)),
      timezoneResolverProvider.overrideWithValue(_IdentityResolver()),
      currentTimeProvider.overrideWith((Ref ref) => stream),
      clockCollectionNotifierProvider.overrideWith(
        () => _SeededClockCollectionNotifier(collection),
      ),
      clockLocationRepositoryProvider.overrideWithValue(repo),
      locationDetectorProvider.overrideWithValue(detector),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      // ClockScreen now reads its strings via `AppLocalizations.of(context)`
      // (PR #23 review: presentation 層は l10n キー必須)。テストでは
      // 日本語ロケール固定で AppBar / メニューのラベルを assert する。
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_ClockLocationFake());
    registerFallbackValue(<ClockLocation>[]);
  });

  group('ClockScreen', () {
    testWidgets('初期表示は Design A のみがビルドされる', (WidgetTester tester) async {
      // GridView.count (Design A) を 1 画面で安定 layout させるため
      // 縦長 surface を確保 (clock_design_a_test と同じ理由)。
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          seeded: <ClockLocation>[
            _loc(0, 'Tokyo'),
            _loc(1, 'New York'),
            _loc(2, 'London'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClockDesignA), findsOneWidget);
      expect(find.byType(ClockDesignB), findsNothing);
      expect(find.byType(ClockDesignC), findsNothing);
      // PageView 自体は body 直下に存在し、AppBar の title もリテラル
      // で出ている (l10n 化は Session 5)。
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('世界時計'), findsOneWidget);
      // Dot indicator: 3 個並ぶ。
      for (int i = 0; i < 3; i++) {
        expect(find.byKey(Key('clock_dot_$i')), findsOneWidget);
      }
    });

    testWidgets('横スワイプで Design B に切替わり 2 個目の dot がアクティブ色になる', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          seeded: <ClockLocation>[_loc(0, 'Tokyo'), _loc(1, 'New York')],
        ),
      );
      await tester.pumpAndSettle();

      // 画面幅 800 の半分超を確実に超えるよう -500。default
      // PageScrollPhysics は drag 終端の offset で次ページ判定するため
      // 50% 境界 (-400) を跨ぐ必要がある。
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.byType(ClockDesignB), findsOneWidget);
      // 既知の theme は Material 3 default (light)。アクティブ dot は
      // primary 色、非アクティブは onSurface に alpha 0.3。直接の
      // 色定数を assert するのは脆いので「2 番目の dot の色 ≠ 1 番目」
      // で active/inactive の差分だけを確認する。
      final BuildContext ctx = tester.element(find.byType(ClockScreen));
      final ColorScheme scheme = Theme.of(ctx).colorScheme;
      final Container dot1 = tester.widget<Container>(
        find.byKey(const Key('clock_dot_1')),
      );
      final Container dot0 = tester.widget<Container>(
        find.byKey(const Key('clock_dot_0')),
      );
      final Color? color1 = (dot1.decoration as BoxDecoration?)?.color;
      final Color? color0 = (dot0.decoration as BoxDecoration?)?.color;
      expect(color1, equals(scheme.primary));
      expect(color0, isNot(equals(scheme.primary)));
    });

    testWidgets('AppBar overflow → 都市を編集 で /clock/locations へ push される', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(seeded: <ClockLocation>[_loc(0, 'Tokyo')]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('clock_menu')));
      await tester.pumpAndSettle();

      // Overflow メニューに表示された PopupMenuItem の child Text。
      expect(find.text('都市を編集'), findsOneWidget);

      await tester.tap(find.text('都市を編集'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clock_locations_stub')), findsOneWidget);
      expect(find.text('locations-stub'), findsOneWidget);
    });

    testWidgets('時刻 stream の値が PageView 配下のデジタル時計に伝搬する (smoke)', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 09:00 → 09:01 の 2 値で finite stream を組む。fromIterable は
      // microtask で順次 push するため pumpAndSettle 後には最終値
      // (09:01) が反映されているはず — このテストは「stream の emit
      // が children まで届く」smoke の確認なので最終値だけを assert する。
      final DateTime t1 = DateTime.utc(2026, 5, 10, 9, 0);
      final DateTime t2 = DateTime.utc(2026, 5, 10, 9, 1);
      await tester.pumpWidget(
        _harness(
          seeded: <ClockLocation>[_loc(0, 'Tokyo')],
          timeStream: Stream<DateTime>.fromIterable(<DateTime>[t1, t2]),
        ),
      );
      await tester.pumpAndSettle();

      // Design A の DigitalClockWidget は HH:mm (showSeconds: false) で
      // 1 location 分 = 1 個。'09:00' → '09:01' に上書きされていること。
      expect(find.text('09:01'), findsOneWidget);
      expect(find.text('09:00'), findsNothing);
    });
  });
}
