import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/clock_entry_collection_notifier.dart';
import 'package:timer_utility/application/clock_entry_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/clock_tick/current_time_stream_provider.dart';
import 'package:timer_utility/application/location_detector_provider.dart';
import 'package:timer_utility/application/timezone_resolver_provider.dart';
import 'package:timer_utility/domain/clock/clock_entry.dart';
import 'package:timer_utility/domain/clock/clock_entry_collection.dart';
import 'package:timer_utility/domain/clock/clock_time.dart';
import 'package:timer_utility/domain/ports/clock_entry_repository.dart';
import 'package:timer_utility/domain/ports/location_detector.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/clock_entry_edit_screen.dart';
import 'package:timer_utility/presentation/screens/clock_screen.dart';
import 'package:timer_utility/presentation/widgets/clock_design_a.dart';
import 'package:timer_utility/presentation/widgets/clock_design_b.dart';
import 'package:timer_utility/presentation/widgets/clock_design_c.dart';

class _MockClockEntryRepository extends Mock implements ClockEntryRepository {}

class _MockLocationDetector extends Mock implements LocationDetector {}

class _ClockEntryFake extends Fake implements ClockEntry {}

/// Returns the input `now` unchanged so the digital readout reflects
/// the stream-emitted UTC time verbatim. Lets the test assert on
/// `find.text('HH:mm')` without modelling timezone offsets.
class _IdentityResolver implements TimezoneResolver {
  @override
  DateTime computeAt(DateTime now, String timezoneId) => now;
}

/// Subclass-override seam for `clockEntryCollectionNotifierProvider`.
///
/// The production notifier seeds itself by reading the repository in a
/// `Future.microtask` from `build()`; that's painful in a widget test
/// because the notifier insists on driving `findAll` and (on empty)
/// `detectTimezoneId`. Overriding `build()` to return the test
/// collection directly skips both code paths and keeps mutations
/// (which these tests don't exercise) routing through the real
/// implementation should we need them later.
class _SeededClockEntryCollectionNotifier extends ClockEntryCollectionNotifier {
  _SeededClockEntryCollectionNotifier(this._initial);
  final ClockEntryCollection _initial;

  @override
  ClockEntryCollection build() => _initial;
}

ClockEntry _entry(int order, String name, {String tz = 'Etc/UTC'}) =>
    ClockEntry(
      id: 'id-$order',
      displayName: name,
      timezoneId: tz,
      isCurrentLocation: order == 0,
      displayOrder: order,
      createdAt: DateTime.utc(2026, 1, 1),
    );

/// Builds the widget under test wrapped in a `GoRouter` so the
/// right-bottom FAB (`ClockPage.buildFab`) can
/// `context.push('/clock/entries')` against a real router (we stub
/// the destination route to a Scaffold and look for its key to verify
/// navigation occurred). PR #29 follow-up #2 replaced the AppBar
/// overflow entry with this FAB to align with the Timer / Alarm tabs.
Widget _harness({
  required List<ClockEntry> seeded,
  Stream<DateTime>? timeStream,
  DateTime? fixedNow,
}) {
  final DateTime now = fixedNow ?? DateTime.utc(2026, 5, 10, 9);
  final ClockEntryCollection collection = seeded.isEmpty
      ? ClockEntryCollection.empty()
      : ClockEntryCollection.fromList(seeded);
  final Stream<DateTime> stream = timeStream ?? Stream<DateTime>.value(now);

  final repo = _MockClockEntryRepository();
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
        path: ClockEntryEditScreen.routeLocation,
        builder: (BuildContext context, GoRouterState state) => const Scaffold(
          key: Key('clock_entries_stub'),
          body: Center(child: Text('entries-stub')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(now)),
      timezoneResolverProvider.overrideWithValue(_IdentityResolver()),
      currentTimeProvider.overrideWith((Ref ref) => stream),
      clockEntryCollectionNotifierProvider.overrideWith(
        () => _SeededClockEntryCollectionNotifier(collection),
      ),
      clockEntryRepositoryProvider.overrideWithValue(repo),
      locationDetectorProvider.overrideWithValue(detector),
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
  setUpAll(() {
    registerFallbackValue(_ClockEntryFake());
    registerFallbackValue(<ClockEntry>[]);
  });

  group('ClockScreen', () {
    testWidgets('初期表示は SegmentedButton + Design A のみがビルドされる', (
      WidgetTester tester,
    ) async {
      // GridView.count (Design A) を 1 画面で安定 layout させるため
      // 縦長 surface を確保 (clock_design_a_test と同じ理由)。
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          seeded: <ClockEntry>[
            _entry(0, 'Tokyo'),
            _entry(1, 'New York'),
            _entry(2, 'London'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClockDesignA), findsOneWidget);
      expect(find.byType(ClockDesignB), findsNothing);
      expect(find.byType(ClockDesignC), findsNothing);
      expect(find.byKey(const Key('clock_design_segmented')), findsOneWidget);
      expect(find.text('世界時計'), findsOneWidget);
      // SegmentedButton の 3 ラベルがレンダされている。
      expect(find.text('アナログ'), findsOneWidget);
      expect(find.text('デジタル'), findsOneWidget);
      expect(find.text('コンパクト'), findsOneWidget);
    });

    testWidgets('「デジタル」セグメント tap で Design B に切替わる', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          seeded: <ClockEntry>[_entry(0, 'Tokyo'), _entry(1, 'New York')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('デジタル'));
      await tester.pumpAndSettle();

      expect(find.byType(ClockDesignB), findsOneWidget);
      expect(find.byType(ClockDesignA), findsNothing);
      expect(find.byType(ClockDesignC), findsNothing);
    });

    testWidgets('「コンパクト」セグメント tap で Design C に切替わる', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          seeded: <ClockEntry>[_entry(0, 'Tokyo'), _entry(1, 'New York')],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('コンパクト'));
      await tester.pumpAndSettle();

      expect(find.byType(ClockDesignC), findsOneWidget);
      expect(find.byType(ClockDesignA), findsNothing);
      expect(find.byType(ClockDesignB), findsNothing);
    });

    testWidgets('右下 FAB タップで /clock/entries へ push される', (
      WidgetTester tester,
    ) async {
      // PR #29 follow-up #2: AppBar overflow の「都市を編集」を廃止して
      // 右下 FAB (`clock_list_add_fab`) に統一。Timer / Alarm タブと
      // 同じ UX を deep link `/clock` 経由でも提供する。
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(seeded: <ClockEntry>[_entry(0, 'Tokyo')]),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clock_list_add_fab')), findsOneWidget);

      await tester.tap(find.byKey(const Key('clock_list_add_fab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clock_entries_stub')), findsOneWidget);
      expect(find.text('entries-stub'), findsOneWidget);
    });

    testWidgets('時刻 stream の値が選択中の Design 配下のデジタル時計に伝搬する (smoke)', (
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
          seeded: <ClockEntry>[_entry(0, 'Tokyo')],
          timeStream: Stream<DateTime>.fromIterable(<DateTime>[t1, t2]),
        ),
      );
      await tester.pumpAndSettle();

      // Design A の DigitalClockWidget は HH:mm (showSeconds: false) で
      // 1 entry 分 = 1 個。'09:00' → '09:01' に上書きされていること。
      expect(find.text('09:01'), findsOneWidget);
      expect(find.text('09:00'), findsNothing);
    });
  });
}
