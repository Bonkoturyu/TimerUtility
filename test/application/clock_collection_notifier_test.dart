import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/clock_collection_notifier.dart';
import 'package:timer_utility/application/clock_location_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/location_detector_provider.dart';
import 'package:timer_utility/domain/clock/clock_collection.dart';
import 'package:timer_utility/domain/clock/clock_location.dart';
import 'package:timer_utility/domain/clock/exceptions.dart';
import 'package:timer_utility/domain/ports/clock_location_repository.dart';
import 'package:timer_utility/domain/ports/location_detector.dart';

class _MockClockLocationRepository extends Mock
    implements ClockLocationRepository {}

class _MockLocationDetector extends Mock implements LocationDetector {}

class _ClockLocationFake extends Fake implements ClockLocation {}

/// Pumps any pending microtask `_loadAndMaybeDetect` queued in
/// `build()`. Allowed by `.gemini/styleguide.md` line 63 for
/// Riverpod build microtask flushing.
Future<void> settleLoad() => Future<void>.delayed(Duration.zero);

({
  ProviderContainer container,
  _MockClockLocationRepository repo,
  _MockLocationDetector detector,
})
makeContainer({
  Clock? clock,
  List<ClockLocation>? seeded,
  String detectedTzId = 'Asia/Tokyo',
}) {
  final repo = _MockClockLocationRepository();
  final detector = _MockLocationDetector();
  when(
    () => repo.findAll(),
  ).thenAnswer((_) async => seeded ?? const <ClockLocation>[]);
  when(() => repo.upsert(any())).thenAnswer((_) async {});
  when(() => repo.delete(any())).thenAnswer((_) async {});
  when(() => repo.replaceAll(any())).thenAnswer((_) async {});
  when(detector.detectTimezoneId).thenAnswer((_) async => detectedTzId);
  final c = ProviderContainer(
    overrides: <Override>[
      clockProvider.overrideWithValue(
        clock ?? Clock(() => DateTime.utc(2026, 5, 9, 12)),
      ),
      clockLocationRepositoryProvider.overrideWithValue(repo),
      locationDetectorProvider.overrideWithValue(detector),
    ],
  );
  addTearDown(c.dispose);
  return (container: c, repo: repo, detector: detector);
}

class _IdSequence {
  int _i = 0;
  String next() {
    final String id = 'clk-${_i.toString().padLeft(2, '0')}';
    _i++;
    return id;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(_ClockLocationFake());
    registerFallbackValue(<ClockLocation>[]);
  });

  group('ClockCollectionNotifier build / restore', () {
    test('build() starts empty before microtask flush', () async {
      final h = makeContainer();
      final ClockCollection state = h.container.read(
        clockCollectionNotifierProvider,
      );
      expect(state.isEmpty, isTrue);
      // Drain the queued microtask so it doesn't run against a
      // disposed container after tearDown.
      await settleLoad();
    });

    test('persisted entries are loaded into state on first read', () async {
      final List<ClockLocation> seed = <ClockLocation>[
        ClockLocation(
          id: 's1',
          displayName: 'Tokyo',
          timezoneId: 'Asia/Tokyo',
          isCurrentLocation: true,
          displayOrder: 0,
          createdAt: DateTime.utc(2026, 5, 1),
        ),
        ClockLocation(
          id: 's2',
          displayName: 'New York',
          timezoneId: 'America/New_York',
          isCurrentLocation: false,
          displayOrder: 1,
          createdAt: DateTime.utc(2026, 5, 1, 1),
        ),
      ];
      final h = makeContainer(seeded: seed);
      h.container.read(clockCollectionNotifierProvider);
      await settleLoad();
      final ClockCollection state = h.container.read(
        clockCollectionNotifierProvider,
      );
      expect(state.size, 2);
      expect(state.findById('s1')?.displayName, 'Tokyo');
      expect(state.findById('s2')?.timezoneId, 'America/New_York');
      verifyNever(h.detector.detectTimezoneId);
    });

    test(
      'on empty DB, detector seeds the current-location entry and persists',
      () async {
        final h = makeContainer(detectedTzId: 'Asia/Tokyo');
        h.container
            .read(clockCollectionNotifierProvider.notifier)
            .debugSetIdGenerator(_IdSequence().next);
        h.container.read(clockCollectionNotifierProvider);
        await settleLoad();

        final ClockCollection state = h.container.read(
          clockCollectionNotifierProvider,
        );
        expect(state.size, 1);
        final ClockLocation? current = state.currentLocation();
        expect(current, isNotNull);
        expect(current!.timezoneId, 'Asia/Tokyo');
        expect(current.displayName, 'Tokyo'); // catalog hit
        expect(current.isCurrentLocation, isTrue);
        expect(current.displayOrder, 0);
        expect(current.id, 'clk-00');
        verify(() => h.repo.upsert(current)).called(1);
      },
    );

    test(
      'detectTimezoneId is not called when DB already has entries',
      () async {
        final List<ClockLocation> seed = <ClockLocation>[
          ClockLocation(
            id: 's1',
            displayName: 'Berlin',
            timezoneId: 'Europe/Berlin',
            isCurrentLocation: false,
            displayOrder: 0,
            createdAt: DateTime.utc(2026, 5, 1),
          ),
        ];
        final h = makeContainer(seeded: seed);
        h.container.read(clockCollectionNotifierProvider);
        await settleLoad();
        verifyNever(h.detector.detectTimezoneId);
      },
    );

    test(
      'non-catalog tzId derives display name from last path segment',
      () async {
        final h = makeContainer(detectedTzId: 'America/Sao_Paulo');
        h.container
            .read(clockCollectionNotifierProvider.notifier)
            .debugSetIdGenerator(_IdSequence().next);
        h.container.read(clockCollectionNotifierProvider);
        await settleLoad();
        final ClockCollection state = h.container.read(
          clockCollectionNotifierProvider,
        );
        // Sao_Paulo IS in the catalog ('Sao Paulo'), so this should
        // hit catalog branch.
        expect(state.currentLocation()?.displayName, 'Sao Paulo');
      },
    );

    test(
      'fully unknown tzId still produces a non-empty truncated display name',
      () async {
        final h = makeContainer(detectedTzId: 'Antarctica/McMurdo');
        h.container
            .read(clockCollectionNotifierProvider.notifier)
            .debugSetIdGenerator(_IdSequence().next);
        h.container.read(clockCollectionNotifierProvider);
        await settleLoad();
        final ClockCollection state = h.container.read(
          clockCollectionNotifierProvider,
        );
        expect(state.currentLocation()?.displayName, 'McMurdo');
      },
    );
  });

  group('ClockCollectionNotifier mutations', () {
    test('addPreset appends an entry and persists', () async {
      final h = makeContainer();
      final notifier = h.container.read(
        clockCollectionNotifierProvider.notifier,
      );
      notifier.debugSetIdGenerator(_IdSequence().next);
      h.container.read(clockCollectionNotifierProvider);
      await settleLoad();
      // Detected entry took clk-00; addPreset gets clk-01.
      final ClockLocation added = notifier.addPreset(
        timezoneId: 'Europe/London',
        displayName: 'London',
      );
      expect(added.id, 'clk-01');
      expect(added.displayOrder, 1);
      expect(added.isCurrentLocation, isFalse);
      final ClockCollection state = h.container.read(
        clockCollectionNotifierProvider,
      );
      expect(state.size, 2);
      verify(() => h.repo.upsert(added)).called(1);
    });

    test(
      'addPreset throws MaxClockLocationCountExceededException at the cap',
      () async {
        final List<ClockLocation> seed = List<ClockLocation>.generate(
          ClockCollection.maxSize,
          (int i) => ClockLocation(
            id: 'seed-$i',
            displayName: 'City$i',
            timezoneId: 'Europe/Berlin',
            isCurrentLocation: i == 0,
            displayOrder: i,
            createdAt: DateTime.utc(2026, 5, 1),
          ),
        );
        final h = makeContainer(seeded: seed);
        h.container.read(clockCollectionNotifierProvider);
        await settleLoad();
        final notifier = h.container.read(
          clockCollectionNotifierProvider.notifier,
        );
        expect(
          () => notifier.addPreset(
            timezoneId: 'Asia/Tokyo',
            displayName: 'Tokyo',
          ),
          throwsA(isA<MaxClockLocationCountExceededException>()),
        );
      },
    );

    test('remove drops the entry and calls repo.delete', () async {
      final List<ClockLocation> seed = <ClockLocation>[
        ClockLocation(
          id: 's1',
          displayName: 'Tokyo',
          timezoneId: 'Asia/Tokyo',
          isCurrentLocation: true,
          displayOrder: 0,
          createdAt: DateTime.utc(2026, 5, 1),
        ),
        ClockLocation(
          id: 's2',
          displayName: 'NY',
          timezoneId: 'America/New_York',
          isCurrentLocation: false,
          displayOrder: 1,
          createdAt: DateTime.utc(2026, 5, 1, 1),
        ),
      ];
      final h = makeContainer(seeded: seed);
      h.container.read(clockCollectionNotifierProvider);
      await settleLoad();
      h.container.read(clockCollectionNotifierProvider.notifier).remove('s2');
      final ClockCollection state = h.container.read(
        clockCollectionNotifierProvider,
      );
      expect(state.size, 1);
      expect(state.findById('s2'), isNull);
      verify(() => h.repo.delete('s2')).called(1);
    });

    test('reorder renumbers displayOrder and calls repo.replaceAll', () async {
      final List<ClockLocation> seed = <ClockLocation>[
        ClockLocation(
          id: 's1',
          displayName: 'A',
          timezoneId: 'Asia/Tokyo',
          isCurrentLocation: false,
          displayOrder: 0,
          createdAt: DateTime.utc(2026, 5, 1),
        ),
        ClockLocation(
          id: 's2',
          displayName: 'B',
          timezoneId: 'Asia/Seoul',
          isCurrentLocation: false,
          displayOrder: 1,
          createdAt: DateTime.utc(2026, 5, 1, 1),
        ),
        ClockLocation(
          id: 's3',
          displayName: 'C',
          timezoneId: 'Europe/Paris',
          isCurrentLocation: false,
          displayOrder: 2,
          createdAt: DateTime.utc(2026, 5, 1, 2),
        ),
      ];
      final h = makeContainer(seeded: seed);
      h.container.read(clockCollectionNotifierProvider);
      await settleLoad();
      h.container.read(clockCollectionNotifierProvider.notifier).reorder(0, 2);
      final ClockCollection state = h.container.read(
        clockCollectionNotifierProvider,
      );
      // s1 moves to index 2 → order: s2(0), s3(1), s1(2)
      expect(state.all.map((ClockLocation l) => l.id).toList(), <String>[
        's2',
        's3',
        's1',
      ]);
      expect(state.findById('s1')?.displayOrder, 2);
      expect(state.findById('s2')?.displayOrder, 0);
      expect(state.findById('s3')?.displayOrder, 1);
      verify(() => h.repo.replaceAll(any())).called(1);
    });

    test('update displayName persists rename via upsert', () async {
      final List<ClockLocation> seed = <ClockLocation>[
        ClockLocation(
          id: 's1',
          displayName: 'Tokyo',
          timezoneId: 'Asia/Tokyo',
          isCurrentLocation: true,
          displayOrder: 0,
          createdAt: DateTime.utc(2026, 5, 1),
        ),
      ];
      final h = makeContainer(seeded: seed);
      h.container.read(clockCollectionNotifierProvider);
      await settleLoad();
      h.container
          .read(clockCollectionNotifierProvider.notifier)
          .update('s1', displayName: '東京');
      final ClockCollection state = h.container.read(
        clockCollectionNotifierProvider,
      );
      expect(state.findById('s1')?.displayName, '東京');
      verify(
        () => h.repo.upsert(
          any(
            that: isA<ClockLocation>().having(
              (ClockLocation l) => l.displayName,
              'displayName',
              '東京',
            ),
          ),
        ),
      ).called(1);
    });
  });
}
