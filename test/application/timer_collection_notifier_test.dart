import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/application/timer_collection_notifier.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/timer/exceptions.dart';
import 'package:timer_utility/domain/timer/timer_collection.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';

import '../helpers/test_notification_strings.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

class _InMemoryRepo implements TimerRepository {
  final Map<String, TimerEntity> store = <String, TimerEntity>{};

  @override
  Future<void> delete(String id) async {
    store.remove(id);
  }

  @override
  Future<List<TimerEntity>> findAll() async => store.values.toList();

  @override
  Future<TimerEntity?> findById(String id) async => store[id];

  @override
  Future<void> upsert(TimerEntity entity) async {
    store[entity.id] = entity;
  }
}

_MockScheduler _stubScheduler() {
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

ProviderContainer _makeContainer({
  required Clock clock,
  required TimerRepository repo,
  required NotificationScheduler scheduler,
}) {
  return ProviderContainer(
    overrides: <Override>[
      clockProvider.overrideWithValue(clock),
      timerRepositoryProvider.overrideWithValue(repo),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      testNotificationStringsOverride(),
      permissionNotifierProvider.overrideWith(
        () => _GrantedPermissionNotifier(),
      ),
    ],
  );
}

/// Granted-everything stand-in so `_scheduleNotification` always picks
/// the exact-alarm branch without going through the real
/// permission_handler plumbing.
class _GrantedPermissionNotifier extends PermissionNotifier {
  @override
  PermissionState build() => const PermissionState(
    postNotifications: DomainPermissionStatus.granted,
    scheduleExactAlarm: DomainPermissionStatus.granted,
    fullScreenIntent: DomainPermissionStatus.granted,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
  });

  group('TimerCollectionNotifier basic CRUD', () {
    test('build() starts with an empty collection', () async {
      final repo = _InMemoryRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 1)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);

      final TimerCollection state = container.read(
        timerCollectionNotifierProvider,
      );
      expect(state.isEmpty, isTrue);
    });

    test('create adds a timer and persists it', () async {
      final repo = _InMemoryRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 1)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);

      final notifier = container.read(timerCollectionNotifierProvider.notifier);
      final TimerEntity created = notifier.create(
        label: 'Focus',
        duration: const Duration(minutes: 25),
      );

      // Allow microtasks so unawaited persistence resolves.
      await Future<void>.value();

      expect(container.read(timerCollectionNotifierProvider).size, 1);
      expect(repo.store[created.id], isNotNull);
    });

    test('create throws when at max capacity', () async {
      final repo = _InMemoryRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 1)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);

      final notifier = container.read(timerCollectionNotifierProvider.notifier);
      for (int i = 0; i < TimerCollection.maxSize; i++) {
        notifier.create(label: '', duration: const Duration(seconds: 5));
      }
      expect(
        () => notifier.create(label: '', duration: const Duration(seconds: 5)),
        throwsA(isA<MaxTimerCountExceededException>()),
      );
    });

    test('delete removes the timer and is idempotent for missing id', () async {
      final repo = _InMemoryRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 1)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);

      final notifier = container.read(timerCollectionNotifierProvider.notifier);
      final TimerEntity t = notifier.create(
        label: '',
        duration: const Duration(seconds: 5),
      );
      notifier.delete(t.id);
      // No throw on missing id.
      notifier.delete('missing');
      expect(container.read(timerCollectionNotifierProvider).isEmpty, isTrue);
    });
  });

  group('TimerCollectionNotifier start / pause / resume', () {
    test(
      'start transitions idle → running and schedules a notification',
      () async {
        final DateTime now = DateTime.utc(2026, 5, 1, 12);
        final scheduler = _stubScheduler();
        final repo = _InMemoryRepo();
        final container = _makeContainer(
          clock: Clock.fixed(now),
          repo: repo,
          scheduler: scheduler,
        );
        addTearDown(container.dispose);
        final notifier = container.read(
          timerCollectionNotifierProvider.notifier,
        );
        final TimerEntity created = notifier.create(
          label: 'Tea',
          duration: const Duration(minutes: 3),
        );
        notifier.start(created.id);
        await Future<void>.value();

        final TimerEntity running = container
            .read(timerCollectionNotifierProvider)
            .findById(created.id)!;
        expect(running.status, TimerStatus.running);
        expect(running.endAt, now.add(const Duration(minutes: 3)));
        verify(
          () => scheduler.schedule(
            notificationId: created.notificationId,
            fireAt: running.endAt!,
            title: 'Tea',
            body: any(named: 'body'),
            exact: true,
            payload: 'timer:${created.id}',
          ),
        ).called(1);
        // Stop the ticker so the test can finish.
        notifier.cancel(created.id);
      },
    );

    test('pause cancels the OS notification and stops the ticker', () async {
      final scheduler = _stubScheduler();
      final repo = _InMemoryRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime.utc(2026, 5, 1, 12)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);
      final notifier = container.read(timerCollectionNotifierProvider.notifier);
      final TimerEntity created = notifier.create(
        label: '',
        duration: const Duration(minutes: 2),
      );
      notifier.start(created.id);
      notifier.pause(created.id);
      await Future<void>.value();

      verify(() => scheduler.cancel(created.notificationId)).called(1);
      expect(
        container
            .read(timerCollectionNotifierProvider)
            .findById(created.id)!
            .status,
        TimerStatus.paused,
      );
    });
  });

  group('TimerCollectionNotifier restoration', () {
    test(
      'restoring a past-due running timer marks it completed and shows',
      () async {
        final DateTime now = DateTime.utc(2026, 5, 1, 12, 30);
        final scheduler = _stubScheduler();
        final TimerEntity overdue = TimerEntity(
          id: 'overdue-1',
          notificationId: 1,
          label: 'Stew',
          duration: const Duration(minutes: 30),
          endAt: now.subtract(const Duration(minutes: 5)),
          pausedRemaining: null,
          status: TimerStatus.running,
          createdAt: now.subtract(const Duration(minutes: 35)),
        );
        final repo = _InMemoryRepo()..store['overdue-1'] = overdue;

        final container = _makeContainer(
          clock: Clock.fixed(now),
          repo: repo,
          scheduler: scheduler,
        );
        addTearDown(container.dispose);

        // Trigger the build + microtask restore.
        container.read(timerCollectionNotifierProvider);
        await Future<void>.delayed(Duration.zero);
        // Allow the unawaited upsert / show to settle.
        await Future<void>.value();

        final TimerEntity? restored = container
            .read(timerCollectionNotifierProvider)
            .findById('overdue-1');
        expect(restored, isNotNull);
        expect(restored!.status, TimerStatus.completed);
        // Pending OS-side schedule is cancelled BEFORE the show notification
        // so a delayed AlarmManager fire (app-only kill / Doze) cannot
        // double-notify after the entity is rewritten to completed.
        // Mirrors the AlarmCollectionNotifier past-due once-mode contract.
        // `verifyInOrder` makes the cancel→show contract explicit (Copilot
        // PR #17 review feedback).
        verifyInOrder(<dynamic Function()>[
          () => scheduler.cancel(1),
          () => scheduler.show(
            notificationId: 1,
            title: 'Stew',
            body: any(named: 'body'),
            payload: 'timer:overdue-1',
          ),
        ]);
        // Persisted as completed.
        expect(repo.store['overdue-1']!.status, TimerStatus.completed);
      },
    );

    test('restoring an idle timer leaves it untouched', () async {
      final DateTime now = DateTime.utc(2026, 5, 1, 12);
      final TimerEntity idle = TimerEntity(
        id: 'idle-1',
        notificationId: 2,
        label: '',
        duration: const Duration(minutes: 5),
        endAt: null,
        pausedRemaining: null,
        status: TimerStatus.idle,
        createdAt: now,
      );
      final repo = _InMemoryRepo()..store['idle-1'] = idle;
      final scheduler = _stubScheduler();

      final container = _makeContainer(
        clock: Clock.fixed(now),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);

      container.read(timerCollectionNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        container
            .read(timerCollectionNotifierProvider)
            .findById('idle-1')!
            .status,
        TimerStatus.idle,
      );
      verifyNever(
        () => scheduler.show(
          notificationId: any(named: 'notificationId'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      );
    });
  });

  group('TimerCollectionNotifier findRinging', () {
    test('returns null when no timer is ringing', () async {
      final repo = _InMemoryRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 1)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);
      final notifier = container.read(timerCollectionNotifierProvider.notifier);
      notifier.create(label: '', duration: const Duration(seconds: 5));
      expect(notifier.findRinging(), isNull);
    });
  });

  group('TimerCollectionNotifier NotificationIdGenerator collisions', () {
    test('10 created timers all have distinct notification ids', () async {
      final repo = _InMemoryRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 1)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);
      final notifier = container.read(timerCollectionNotifierProvider.notifier);
      final Set<int> seen = <int>{};
      for (int i = 0; i < TimerCollection.maxSize; i++) {
        final TimerEntity t = notifier.create(
          label: 'timer-$i',
          duration: const Duration(seconds: 5),
        );
        expect(
          seen.add(t.notificationId),
          isTrue,
          reason: 'collision at $i (${t.notificationId})',
        );
      }
    });
  });
}
