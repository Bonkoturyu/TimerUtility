import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:timer_utility/presentation/screens/home/clock_page.dart';
import 'package:timer_utility/presentation/widgets/clock_design_a.dart';
import 'package:timer_utility/presentation/widgets/clock_design_b.dart';

class _MockClockLocationRepository extends Mock
    implements ClockLocationRepository {}

class _MockLocationDetector extends Mock implements LocationDetector {}

class _ClockLocationFake extends Fake implements ClockLocation {}

class _IdentityResolver implements TimezoneResolver {
  @override
  DateTime computeAt(DateTime now, String timezoneId) => now;
}

/// Same seam as `clock_screen_test.dart`: bypass the production
/// notifier's microtask seed so the test mounts a deterministic
/// `ClockCollection` without the repo / detector dance.
class _SeededClockCollectionNotifier extends ClockCollectionNotifier {
  _SeededClockCollectionNotifier(this._initial);
  final ClockCollection _initial;

  @override
  ClockCollection build() => _initial;
}

ClockLocation _loc(int order, String name) => ClockLocation(
  id: 'id-$order',
  displayName: name,
  timezoneId: 'Etc/UTC',
  isCurrentLocation: order == 0,
  displayOrder: order,
  createdAt: DateTime.utc(2026, 1, 1),
);

Widget _harness({required List<ClockLocation> seeded}) {
  final DateTime now = DateTime.utc(2026, 5, 10, 9);
  final ClockCollection collection = seeded.isEmpty
      ? ClockCollection.empty()
      : ClockCollection.fromList(seeded);

  final repo = _MockClockLocationRepository();
  final detector = _MockLocationDetector();
  when(() => repo.findAll()).thenAnswer((_) async => seeded);
  when(() => repo.upsert(any())).thenAnswer((_) async {});
  when(() => repo.delete(any())).thenAnswer((_) async {});
  when(() => repo.replaceAll(any())).thenAnswer((_) async {});
  when(() => detector.detectTimezoneId()).thenAnswer((_) async => 'Etc/UTC');

  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock.fixed(now)),
      timezoneResolverProvider.overrideWithValue(_IdentityResolver()),
      currentTimeProvider.overrideWith(
        (Ref ref) => Stream<DateTime>.value(now),
      ),
      clockCollectionNotifierProvider.overrideWith(
        () => _SeededClockCollectionNotifier(collection),
      ),
      clockLocationRepositoryProvider.overrideWithValue(repo),
      locationDetectorProvider.overrideWithValue(detector),
    ],
    child: const MaterialApp(
      locale: Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: <Locale>[Locale('ja'), Locale('en')],
      home: Scaffold(body: ClockPage()),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_ClockLocationFake());
    registerFallbackValue(<ClockLocation>[]);
  });

  group('ClockPage (Phase 11 body widget)', () {
    testWidgets(
      'renders SegmentedButton + Design A on first paint and switches to Design B on tap',
      (WidgetTester tester) async {
        // Same surface size convention as clock_screen_test: tall enough
        // to lay out Design A's GridView.count without overflow.
        await tester.binding.setSurfaceSize(const Size(800, 1600));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _harness(seeded: <ClockLocation>[_loc(0, 'Tokyo')]),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('clock_design_segmented')), findsOneWidget);
        expect(find.byType(ClockDesignA), findsOneWidget);
        expect(find.byType(ClockDesignB), findsNothing);

        await tester.tap(find.text('デジタル'));
        await tester.pumpAndSettle();

        expect(find.byType(ClockDesignB), findsOneWidget);
        expect(find.byType(ClockDesignA), findsNothing);
      },
    );
  });
}
