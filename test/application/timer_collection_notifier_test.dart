import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/interval_notification_scheduler_provider.dart';
import 'package:timer_utility/application/imported_sound_mutation_coordinator.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/application/timer_collection_notifier.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/interval_notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/timer/alarm_sound_catalog.dart';
import 'package:timer_utility/domain/timer/exceptions.dart';
import 'package:timer_utility/domain/timer/timer_collection.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';

import '../helpers/test_notification_strings.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

class _MockIntervalScheduler extends Mock
    implements IntervalNotificationScheduler {}

class _InMemoryRepo implements TimerRepository {
  final Map<String, TimerEntity> store = <String, TimerEntity>{};
  int upsertCalls = 0;
  Completer<List<TimerEntity>>? findAllGate;

  @override
  Future<void> delete(String id) async {
    store.remove(id);
  }

  @override
  Future<List<TimerEntity>> findAll() async =>
      findAllGate?.future ?? store.values.toList();

  @override
  Future<TimerEntity?> findById(String id) async => store[id];

  @override
  Future<void> upsert(TimerEntity entity) async {
    upsertCalls++;
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
  IntervalNotificationScheduler? intervalScheduler,
  ImportedSoundMutationCoordinator? mutationCoordinator,
  ImportedSoundDeletionRegistry? deletionRegistry,
}) {
  return ProviderContainer(
    overrides: <Override>[
      clockProvider.overrideWithValue(clock),
      timerRepositoryProvider.overrideWithValue(repo),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      if (intervalScheduler != null)
        intervalNotificationSchedulerProvider.overrideWithValue(
          intervalScheduler,
        ),
      if (mutationCoordinator != null)
        importedSoundMutationCoordinatorProvider.overrideWithValue(
          mutationCoordinator,
        ),
      if (deletionRegistry != null)
        importedSoundDeletionRegistryProvider.overrideWithValue(
          deletionRegistry,
        ),
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
  // TimerCollectionNotifier.build() registers a WidgetsBindingObserver
  // (Review #9), so the binding must exist even for these plain `test()`
  // cases that never pump a widget.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
    registerFallbackValue(const Duration(minutes: 1));
  });

  group('TimerCollectionNotifier imported sound reconciliation', () {
    test('削除中にqueueされたupsertは成功後にdefaultへ正規化する', () async {
      final ImportedSoundMutationCoordinator coordinator =
          ImportedSoundMutationCoordinator();
      final ImportedSoundDeletionRegistry registry =
          ImportedSoundDeletionRegistry();
      final Completer<void> gate = Completer<void>();
      final Future<void> blocker = coordinator.run(() => gate.future);
      final _InMemoryRepo repo = _InMemoryRepo();
      final ProviderContainer container = _makeContainer(
        clock: Clock(() => DateTime.utc(2026, 5, 1, 12)),
        repo: repo,
        scheduler: _stubScheduler(),
        mutationCoordinator: coordinator,
        deletionRegistry: registry,
      );
      addTearDown(container.dispose);
      final TimerCollectionNotifier notifier = container.read(
        timerCollectionNotifierProvider.notifier,
      );

      final TimerEntity created = notifier.create(
        label: 'Queued',
        duration: const Duration(minutes: 1),
        soundId: 'imported-target',
      );
      registry.markDeleted('imported-target');
      notifier.reconcileDeletedSound('imported-target');
      gate.complete();
      await blocker;
      await Future<void>.delayed(Duration.zero);

      expect(
        repo.store[created.id]?.soundId,
        AlarmSoundCatalog.defaultSound.id,
      );
      expect(
        container
            .read(timerCollectionNotifierProvider)
            .findById(created.id)
            ?.soundId,
        AlarmSoundCatalog.defaultSound.id,
      );
    });

    test('削除中にqueueされたupsertは削除失敗時に元の音源を保持する', () async {
      final ImportedSoundMutationCoordinator coordinator =
          ImportedSoundMutationCoordinator();
      final ImportedSoundDeletionRegistry registry =
          ImportedSoundDeletionRegistry()..markDeleting('imported-target');
      final Completer<void> gate = Completer<void>();
      final Future<void> blocker = coordinator.run(() => gate.future);
      final _InMemoryRepo repo = _InMemoryRepo();
      final ProviderContainer container = _makeContainer(
        clock: Clock(() => DateTime.utc(2026, 5, 1, 12)),
        repo: repo,
        scheduler: _stubScheduler(),
        mutationCoordinator: coordinator,
        deletionRegistry: registry,
      );
      addTearDown(container.dispose);
      final TimerCollectionNotifier notifier = container.read(
        timerCollectionNotifierProvider.notifier,
      );

      final TimerEntity created = notifier.create(
        label: 'Queued',
        duration: const Duration(minutes: 1),
        soundId: 'imported-target',
      );
      registry.clearDeleting('imported-target');
      gate.complete();
      await blocker;
      await Future<void>.delayed(Duration.zero);

      expect(repo.store[created.id]?.soundId, 'imported-target');
      expect(
        container
            .read(timerCollectionNotifierProvider)
            .findById(created.id)
            ?.soundId,
        'imported-target',
      );
    });

    test('対象音だけを default に置換し、他の状態を維持して永続化しない', () async {
      final DateTime now = DateTime.utc(2026, 5, 1, 12);
      final TimerEntity target = TimerEntity(
        id: 'target',
        notificationId: 10,
        label: 'Target',
        duration: const Duration(minutes: 5),
        endAt: null,
        pausedRemaining: null,
        status: TimerStatus.idle,
        createdAt: now,
        intervalNotificationEnabled: true,
        soundId: 'imported-target',
      );
      final TimerEntity untouched = TimerEntity(
        id: 'untouched',
        notificationId: 11,
        label: 'Untouched',
        duration: const Duration(minutes: 10),
        endAt: null,
        pausedRemaining: null,
        status: TimerStatus.idle,
        createdAt: now.add(const Duration(minutes: 1)),
        soundId: 'imported-other',
      );
      final repo = _InMemoryRepo()
        ..store.addAll(<String, TimerEntity>{
          target.id: target,
          untouched.id: untouched,
        });
      final Map<String, TimerEntity> persistedBefore = Map.of(repo.store);
      final container = _makeContainer(
        clock: Clock.fixed(now),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);

      container.read(timerCollectionNotifierProvider);
      await Future<void>.delayed(Duration.zero);

      container
          .read(timerCollectionNotifierProvider.notifier)
          .reconcileDeletedSound('imported-target');
      await Future<void>.value();

      final TimerCollection state = container.read(
        timerCollectionNotifierProvider,
      );
      expect(
        state.findById(target.id),
        target.copyWith(soundId: AlarmSoundCatalog.defaultSound.id),
      );
      expect(state.findById(untouched.id), untouched);
      expect(repo.upsertCalls, 0);
      expect(repo.store, persistedBefore);
    });

    test('遅延restoreの古いsnapshotから削除済み音源IDを復活させない', () async {
      final DateTime now = DateTime.utc(2026, 5, 1, 12);
      final TimerEntity target = TimerEntity(
        id: 'delayed-target',
        notificationId: 12,
        label: 'Delayed',
        duration: const Duration(minutes: 5),
        endAt: null,
        pausedRemaining: null,
        status: TimerStatus.idle,
        createdAt: now,
        soundId: 'imported-target',
      );
      final repo = _InMemoryRepo()
        ..findAllGate = Completer<List<TimerEntity>>();
      final container = _makeContainer(
        clock: Clock.fixed(now),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);

      container.read(timerCollectionNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      container
          .read(timerCollectionNotifierProvider.notifier)
          .reconcileDeletedSound('imported-target');
      repo.findAllGate!.complete(<TimerEntity>[target]);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(timerCollectionNotifierProvider).findById(target.id),
        target.copyWith(soundId: AlarmSoundCatalog.defaultSound.id),
      );
    });
  });

  test('定間隔通知を有効にしたタイマーはNative周期予約を使用する', () async {
    final repo = _InMemoryRepo();
    final interval = _MockIntervalScheduler();
    when(
      () => interval.schedule(
        notificationId: any(named: 'notificationId'),
        firstFireAt: any(named: 'firstFireAt'),
        interval: any(named: 'interval'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        exact: any(named: 'exact'),
      ),
    ).thenAnswer((_) async {});
    when(() => interval.cancel(any())).thenAnswer((_) async {});
    final container = _makeContainer(
      clock: Clock.fixed(DateTime(2026, 5, 1, 12)),
      repo: repo,
      scheduler: _stubScheduler(),
      intervalScheduler: interval,
    );
    addTearDown(container.dispose);
    final notifier = container.read(timerCollectionNotifierProvider.notifier);
    final timer = notifier.create(
      label: 'pace',
      duration: const Duration(minutes: 2),
      intervalNotificationEnabled: true,
    );

    notifier.start(timer.id);

    verify(
      () => interval.schedule(
        notificationId: timer.notificationId,
        firstFireAt: DateTime(2026, 5, 1, 12, 2),
        interval: const Duration(minutes: 2),
        title: 'pace',
        body: any(named: 'body'),
        exact: true,
      ),
    ).called(1);
  });

  test('定間隔通知タイマーの一時停止でNative予約を解除する', () async {
    final repo = _InMemoryRepo();
    final interval = _MockIntervalScheduler();
    when(
      () => interval.schedule(
        notificationId: any(named: 'notificationId'),
        firstFireAt: any(named: 'firstFireAt'),
        interval: any(named: 'interval'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        exact: any(named: 'exact'),
      ),
    ).thenAnswer((_) async {});
    when(() => interval.cancel(any())).thenAnswer((_) async {});
    final container = _makeContainer(
      clock: Clock.fixed(DateTime(2026, 5, 1, 12)),
      repo: repo,
      scheduler: _stubScheduler(),
      intervalScheduler: interval,
    );
    addTearDown(container.dispose);
    final notifier = container.read(timerCollectionNotifierProvider.notifier);
    final timer = notifier.create(
      label: '',
      duration: const Duration(minutes: 2),
      intervalNotificationEnabled: true,
    );
    notifier.start(timer.id);
    clearInteractions(interval);

    notifier.pause(timer.id);

    verify(() => interval.cancel(timer.notificationId)).called(1);
    expect(
      container
          .read(timerCollectionNotifierProvider)
          .findById(timer.id)!
          .status,
      TimerStatus.paused,
    );
  });

  group('TimerCollectionNotifier basic CRUD', () {
    test('findAll待機中のcreateを古いrestore snapshotで上書きしない', () async {
      final DateTime now = DateTime.utc(2026, 5, 1, 12);
      final _InMemoryRepo repo = _InMemoryRepo()
        ..findAllGate = Completer<List<TimerEntity>>();
      final ProviderContainer container = _makeContainer(
        clock: Clock.fixed(now),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);
      final TimerCollectionNotifier notifier = container.read(
        timerCollectionNotifierProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);

      final TimerEntity created = notifier.create(
        label: 'New',
        duration: const Duration(minutes: 1),
      );
      repo.findAllGate!.complete(<TimerEntity>[
        TimerEntity(
          id: 'old',
          notificationId: 9,
          label: 'Old',
          duration: const Duration(minutes: 2),
          endAt: null,
          pausedRemaining: null,
          status: TimerStatus.idle,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      final TimerCollection state = container.read(
        timerCollectionNotifierProvider,
      );
      expect(state.findById(created.id), created);
      expect(state.findById('old'), isNull);
    });

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

  group('TimerCollectionNotifier changeDuration', () {
    test('inactive timer duration is updated and persisted', () async {
      final repo = _InMemoryRepo();
      final scheduler = _stubScheduler();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 1)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);
      final notifier = container.read(timerCollectionNotifierProvider.notifier);
      final TimerEntity created = notifier.create(
        label: '',
        duration: const Duration(minutes: 1),
      );

      notifier.changeDuration(created.id, const Duration(minutes: 4));
      await Future<void>.delayed(Duration.zero);

      final TimerEntity changed = container
          .read(timerCollectionNotifierProvider)
          .findById(created.id)!;
      expect(changed.duration, const Duration(minutes: 4));
      expect(repo.store[created.id]?.duration, const Duration(minutes: 4));
      verifyNever(
        () => scheduler.schedule(
          notificationId: any(named: 'notificationId'),
          fireAt: any(named: 'fireAt'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          exact: any(named: 'exact'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('running timer rejects duration changes without mutating state', () {
      final repo = _InMemoryRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 1)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);
      final notifier = container.read(timerCollectionNotifierProvider.notifier);
      final TimerEntity created = notifier.create(
        label: '',
        duration: const Duration(minutes: 1),
      );
      notifier.start(created.id);

      expect(
        () => notifier.changeDuration(created.id, const Duration(minutes: 2)),
        throwsStateError,
      );
      final TimerEntity running = container
          .read(timerCollectionNotifierProvider)
          .findById(created.id)!;
      expect(running.status, TimerStatus.running);
      expect(running.duration, const Duration(minutes: 1));

      notifier.cancel(created.id);
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
            soundId: created.soundId,
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

  group('TimerCollectionNotifier lifecycle ticker (Review #9)', () {
    test('paused stops the 200ms ticker; resumed re-arms it while running', () {
      fakeAsync((FakeAsync async) {
        final container = _makeContainer(
          clock: Clock.fixed(DateTime.utc(2026, 5, 1, 12)),
          repo: _InMemoryRepo(),
          scheduler: _stubScheduler(),
        );
        addTearDown(container.dispose);
        final notifier = container.read(
          timerCollectionNotifierProvider.notifier,
        );
        final TimerEntity created = notifier.create(
          label: '',
          duration: const Duration(minutes: 5),
        );
        notifier.start(created.id);
        async.flushMicrotasks();
        expect(
          async.periodicTimerCount,
          greaterThanOrEqualTo(1),
          reason: 'a running timer arms the 200 ms ticker',
        );

        notifier.didChangeAppLifecycleState(AppLifecycleState.paused);
        expect(
          async.periodicTimerCount,
          0,
          reason: 'paused cancels the ticker — OS AlarmManager still fires',
        );

        notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(
          async.periodicTimerCount,
          greaterThanOrEqualTo(1),
          reason: 'resumed re-arms the ticker because a timer is running',
        );

        // Cancel so fakeAsync ends with no pending periodic timer.
        notifier.cancel(created.id);
        expect(async.periodicTimerCount, 0);
      });
    });

    test('resumed does NOT arm the ticker when no timer is running', () {
      fakeAsync((FakeAsync async) {
        final container = _makeContainer(
          clock: Clock.fixed(DateTime.utc(2026, 5, 1, 12)),
          repo: _InMemoryRepo(),
          scheduler: _stubScheduler(),
        );
        addTearDown(container.dispose);
        final notifier = container.read(
          timerCollectionNotifierProvider.notifier,
        );
        async.flushMicrotasks();
        expect(async.periodicTimerCount, 0);

        notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(
          async.periodicTimerCount,
          0,
          reason: 'no running timers → resume must not start a ticker',
        );
      });
    });

    test('start() while paused does NOT arm the ticker; resume arms it', () {
      // PR #89 review (gemini): a background start/resume/snooze must not
      // sneak the ticker on while paused, defeating the battery saving.
      fakeAsync((FakeAsync async) {
        final container = _makeContainer(
          clock: Clock.fixed(DateTime.utc(2026, 5, 1, 12)),
          repo: _InMemoryRepo(),
          scheduler: _stubScheduler(),
        );
        addTearDown(container.dispose);
        final notifier = container.read(
          timerCollectionNotifierProvider.notifier,
        );
        notifier.didChangeAppLifecycleState(AppLifecycleState.paused);

        final TimerEntity created = notifier.create(
          label: '',
          duration: const Duration(minutes: 5),
        );
        notifier.start(created.id);
        async.flushMicrotasks();
        expect(
          async.periodicTimerCount,
          0,
          reason: 'start() while paused must not arm the ticker',
        );

        notifier.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(
          async.periodicTimerCount,
          greaterThanOrEqualTo(1),
          reason: 'resume arms the ticker that start() deferred',
        );

        notifier.cancel(created.id);
        expect(async.periodicTimerCount, 0);
      });
    });
  });
}
