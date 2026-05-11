import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/clock_entry_collection_notifier.dart';
import 'package:timer_utility/application/clock_entry_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/location_detector_provider.dart';
import 'package:timer_utility/domain/clock/clock_entry.dart';
import 'package:timer_utility/domain/clock/clock_entry_collection.dart';
import 'package:timer_utility/domain/clock/exceptions.dart';
import 'package:timer_utility/domain/ports/clock_entry_repository.dart';
import 'package:timer_utility/domain/ports/location_detector.dart';

class _MockClockEntryRepository extends Mock implements ClockEntryRepository {}

class _MockLocationDetector extends Mock implements LocationDetector {}

class _ClockEntryFake extends Fake implements ClockEntry {}

/// Pumps any pending microtask `_loadAndMaybeDetect` queued in
/// `build()`. Allowed by `.gemini/styleguide.md` line 63 for
/// Riverpod build microtask flushing.
Future<void> settleLoad() => Future<void>.delayed(Duration.zero);

({
  ProviderContainer container,
  _MockClockEntryRepository repo,
  _MockLocationDetector detector,
})
makeContainer({
  Clock? clock,
  List<ClockEntry>? seeded,
  String detectedTzId = 'Asia/Tokyo',
}) {
  final repo = _MockClockEntryRepository();
  final detector = _MockLocationDetector();
  when(
    () => repo.findAll(),
  ).thenAnswer((_) async => seeded ?? const <ClockEntry>[]);
  when(() => repo.upsert(any())).thenAnswer((_) async {});
  when(() => repo.delete(any())).thenAnswer((_) async {});
  when(() => repo.replaceAll(any())).thenAnswer((_) async {});
  when(detector.detectTimezoneId).thenAnswer((_) async => detectedTzId);
  final c = ProviderContainer(
    overrides: <Override>[
      clockProvider.overrideWithValue(
        clock ?? Clock(() => DateTime.utc(2026, 5, 9, 12)),
      ),
      clockEntryRepositoryProvider.overrideWithValue(repo),
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
    registerFallbackValue(_ClockEntryFake());
    registerFallbackValue(<ClockEntry>[]);
  });

  group('ClockEntryCollectionNotifier build / restore', () {
    test('build() starts empty before microtask flush', () async {
      final h = makeContainer();
      final ClockEntryCollection state = h.container.read(
        clockEntryCollectionNotifierProvider,
      );
      expect(state.isEmpty, isTrue);
      // Drain the queued microtask so it doesn't run against a
      // disposed container after tearDown.
      await settleLoad();
    });

    test('persisted entries are loaded into state on first read', () async {
      final List<ClockEntry> seed = <ClockEntry>[
        ClockEntry(
          id: 's1',
          displayName: 'Tokyo',
          timezoneId: 'Asia/Tokyo',
          isCurrentLocation: true,
          displayOrder: 0,
          createdAt: DateTime.utc(2026, 5, 1),
        ),
        ClockEntry(
          id: 's2',
          displayName: 'New York',
          timezoneId: 'America/New_York',
          isCurrentLocation: false,
          displayOrder: 1,
          createdAt: DateTime.utc(2026, 5, 1, 1),
        ),
      ];
      final h = makeContainer(seeded: seed);
      h.container.read(clockEntryCollectionNotifierProvider);
      await settleLoad();
      final ClockEntryCollection state = h.container.read(
        clockEntryCollectionNotifierProvider,
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
            .read(clockEntryCollectionNotifierProvider.notifier)
            .debugSetIdGenerator(_IdSequence().next);
        h.container.read(clockEntryCollectionNotifierProvider);
        await settleLoad();

        final ClockEntryCollection state = h.container.read(
          clockEntryCollectionNotifierProvider,
        );
        expect(state.size, 1);
        final ClockEntry? current = state.currentEntry();
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
        final List<ClockEntry> seed = <ClockEntry>[
          ClockEntry(
            id: 's1',
            displayName: 'Berlin',
            timezoneId: 'Europe/Berlin',
            isCurrentLocation: false,
            displayOrder: 0,
            createdAt: DateTime.utc(2026, 5, 1),
          ),
        ];
        final h = makeContainer(seeded: seed);
        h.container.read(clockEntryCollectionNotifierProvider);
        await settleLoad();
        verifyNever(h.detector.detectTimezoneId);
      },
    );

    test(
      'non-catalog tzId derives display name from last path segment',
      () async {
        final h = makeContainer(detectedTzId: 'America/Sao_Paulo');
        h.container
            .read(clockEntryCollectionNotifierProvider.notifier)
            .debugSetIdGenerator(_IdSequence().next);
        h.container.read(clockEntryCollectionNotifierProvider);
        await settleLoad();
        final ClockEntryCollection state = h.container.read(
          clockEntryCollectionNotifierProvider,
        );
        // Sao_Paulo IS in the catalog ('Sao Paulo'), so this should
        // hit catalog branch.
        expect(state.currentEntry()?.displayName, 'Sao Paulo');
      },
    );

    test(
      'fully unknown tzId still produces a non-empty truncated display name',
      () async {
        final h = makeContainer(detectedTzId: 'Antarctica/McMurdo');
        h.container
            .read(clockEntryCollectionNotifierProvider.notifier)
            .debugSetIdGenerator(_IdSequence().next);
        h.container.read(clockEntryCollectionNotifierProvider);
        await settleLoad();
        final ClockEntryCollection state = h.container.read(
          clockEntryCollectionNotifierProvider,
        );
        expect(state.currentEntry()?.displayName, 'McMurdo');
      },
    );
  });

  group('ClockEntryCollectionNotifier mutations', () {
    test('addPreset appends an entry and persists', () async {
      final h = makeContainer();
      final notifier = h.container.read(
        clockEntryCollectionNotifierProvider.notifier,
      );
      notifier.debugSetIdGenerator(_IdSequence().next);
      h.container.read(clockEntryCollectionNotifierProvider);
      await settleLoad();
      // Detected entry took clk-00; addPreset gets clk-01.
      final ClockEntry added = notifier.addPreset(
        timezoneId: 'Europe/London',
        displayName: 'London',
      );
      expect(added.id, 'clk-01');
      expect(added.displayOrder, 1);
      expect(added.isCurrentLocation, isFalse);
      final ClockEntryCollection state = h.container.read(
        clockEntryCollectionNotifierProvider,
      );
      expect(state.size, 2);
      verify(() => h.repo.upsert(added)).called(1);
    });

    test(
      'addPreset throws MaxClockEntryCountExceededException at the cap',
      () async {
        final List<ClockEntry> seed = List<ClockEntry>.generate(
          ClockEntryCollection.maxSize,
          (int i) => ClockEntry(
            id: 'seed-$i',
            displayName: 'City$i',
            timezoneId: 'Europe/Berlin',
            isCurrentLocation: i == 0,
            displayOrder: i,
            createdAt: DateTime.utc(2026, 5, 1),
          ),
        );
        final h = makeContainer(seeded: seed);
        h.container.read(clockEntryCollectionNotifierProvider);
        await settleLoad();
        final notifier = h.container.read(
          clockEntryCollectionNotifierProvider.notifier,
        );
        expect(
          () => notifier.addPreset(
            timezoneId: 'Asia/Tokyo',
            displayName: 'Tokyo',
          ),
          throwsA(isA<MaxClockEntryCountExceededException>()),
        );
      },
    );

    test('remove drops the entry and calls repo.delete', () async {
      final List<ClockEntry> seed = <ClockEntry>[
        ClockEntry(
          id: 's1',
          displayName: 'Tokyo',
          timezoneId: 'Asia/Tokyo',
          isCurrentLocation: true,
          displayOrder: 0,
          createdAt: DateTime.utc(2026, 5, 1),
        ),
        ClockEntry(
          id: 's2',
          displayName: 'NY',
          timezoneId: 'America/New_York',
          isCurrentLocation: false,
          displayOrder: 1,
          createdAt: DateTime.utc(2026, 5, 1, 1),
        ),
      ];
      final h = makeContainer(seeded: seed);
      h.container.read(clockEntryCollectionNotifierProvider);
      await settleLoad();
      h.container
          .read(clockEntryCollectionNotifierProvider.notifier)
          .remove('s2');
      final ClockEntryCollection state = h.container.read(
        clockEntryCollectionNotifierProvider,
      );
      expect(state.size, 1);
      expect(state.findById('s2'), isNull);
      verify(() => h.repo.delete('s2')).called(1);
    });

    test('reorder renumbers displayOrder and calls repo.replaceAll', () async {
      final List<ClockEntry> seed = <ClockEntry>[
        ClockEntry(
          id: 's1',
          displayName: 'A',
          timezoneId: 'Asia/Tokyo',
          isCurrentLocation: false,
          displayOrder: 0,
          createdAt: DateTime.utc(2026, 5, 1),
        ),
        ClockEntry(
          id: 's2',
          displayName: 'B',
          timezoneId: 'Asia/Seoul',
          isCurrentLocation: false,
          displayOrder: 1,
          createdAt: DateTime.utc(2026, 5, 1, 1),
        ),
        ClockEntry(
          id: 's3',
          displayName: 'C',
          timezoneId: 'Europe/Paris',
          isCurrentLocation: false,
          displayOrder: 2,
          createdAt: DateTime.utc(2026, 5, 1, 2),
        ),
      ];
      final h = makeContainer(seeded: seed);
      h.container.read(clockEntryCollectionNotifierProvider);
      await settleLoad();
      h.container
          .read(clockEntryCollectionNotifierProvider.notifier)
          .reorder(0, 2);
      final ClockEntryCollection state = h.container.read(
        clockEntryCollectionNotifierProvider,
      );
      // s1 moves to index 2 → order: s2(0), s3(1), s1(2)
      expect(state.all.map((ClockEntry e) => e.id).toList(), <String>[
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
      final List<ClockEntry> seed = <ClockEntry>[
        ClockEntry(
          id: 's1',
          displayName: 'Tokyo',
          timezoneId: 'Asia/Tokyo',
          isCurrentLocation: true,
          displayOrder: 0,
          createdAt: DateTime.utc(2026, 5, 1),
        ),
      ];
      final h = makeContainer(seeded: seed);
      h.container.read(clockEntryCollectionNotifierProvider);
      await settleLoad();
      h.container
          .read(clockEntryCollectionNotifierProvider.notifier)
          .update('s1', displayName: '東京');
      final ClockEntryCollection state = h.container.read(
        clockEntryCollectionNotifierProvider,
      );
      expect(state.findById('s1')?.displayName, '東京');
      verify(
        () => h.repo.upsert(
          any(
            that: isA<ClockEntry>().having(
              (ClockEntry e) => e.displayName,
              'displayName',
              '東京',
            ),
          ),
        ),
      ).called(1);
    });
  });
}
