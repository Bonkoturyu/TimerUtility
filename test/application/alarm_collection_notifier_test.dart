import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_collection_notifier.dart';
import 'package:timer_utility/application/alarm_repository_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/alarm/alarm_repeat.dart';
import 'package:timer_utility/domain/alarm/day_of_week.dart';
import 'package:timer_utility/domain/alarm/exceptions.dart';
import 'package:timer_utility/domain/alarm/time_of_day_value.dart';
import 'package:timer_utility/domain/ports/alarm_repository.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';

import '../helpers/test_notification_strings.dart';

class _MockScheduler extends Mock implements NotificationScheduler {}

class _InMemoryAlarmRepo implements AlarmRepository {
  final Map<String, AlarmEntity> store = <String, AlarmEntity>{};

  @override
  Future<void> delete(String id) async {
    store.remove(id);
  }

  @override
  Future<List<AlarmEntity>> findAll() async => store.values.toList();

  @override
  Future<AlarmEntity?> findById(String id) async => store[id];

  @override
  Future<void> upsert(AlarmEntity entity) async {
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

class _GrantedPermissionNotifier extends PermissionNotifier {
  @override
  PermissionState build() => const PermissionState(
    postNotifications: DomainPermissionStatus.granted,
    scheduleExactAlarm: DomainPermissionStatus.granted,
    fullScreenIntent: DomainPermissionStatus.granted,
  );
}

ProviderContainer _makeContainer({
  required Clock clock,
  required AlarmRepository repo,
  required NotificationScheduler scheduler,
}) {
  return ProviderContainer(
    overrides: <Override>[
      clockProvider.overrideWithValue(clock),
      alarmRepositoryProvider.overrideWithValue(repo),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      testNotificationStringsOverride(),
      permissionNotifierProvider.overrideWith(
        () => _GrantedPermissionNotifier(),
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime.utc(2026));
  });

  group('AlarmCollectionNotifier basic CRUD', () {
    test('build() は空リストで始まる', () async {
      final repo = _InMemoryAlarmRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);

      expect(container.read(alarmCollectionNotifierProvider), isEmpty);
    });

    test('create でアラームが追加され、永続化と schedule が走る', () async {
      final repo = _InMemoryAlarmRepo();
      final scheduler = _stubScheduler();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);

      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      final AlarmEntity created = await notifier.create(
        label: 'Wake up',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        repeat: const AlarmRepeatOnce(),
        snoozeMinutes: 5,
        enabled: true,
      );
      await Future<void>.value();

      expect(container.read(alarmCollectionNotifierProvider).length, 1);
      expect(repo.store[created.id], isNotNull);
      verify(
        () => scheduler.schedule(
          notificationId: created.notificationId,
          fireAt: DateTime(2026, 5, 4, 7, 0),
          title: 'Wake up',
          body: any(named: 'body'),
          exact: true,
          payload: 'alarm:${created.id}',
        ),
      ).called(1);
    });

    test('enabled = false で create したアラームは schedule されない', () async {
      final repo = _InMemoryAlarmRepo();
      final scheduler = _stubScheduler();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      await notifier.create(
        label: '',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        repeat: const AlarmRepeatOnce(),
        snoozeMinutes: 5,
        enabled: false,
      );

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

    test('上限 50 件超えで MaxAlarmCountExceededException', () async {
      final repo = _InMemoryAlarmRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      for (int i = 0; i < AlarmCollectionNotifier.maxSize; i++) {
        await notifier.create(
          label: '',
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
          repeat: const AlarmRepeatOnce(),
          snoozeMinutes: 5,
          enabled: false,
        );
      }
      await expectLater(
        notifier.create(
          label: '',
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
          repeat: const AlarmRepeatOnce(),
          snoozeMinutes: 5,
          enabled: false,
        ),
        throwsA(isA<MaxAlarmCountExceededException>()),
      );
    });

    test('snoozeMinutes が 5/10/15 以外なら例外', () async {
      final repo = _InMemoryAlarmRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      await expectLater(
        notifier.create(
          label: '',
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
          repeat: const AlarmRepeatOnce(),
          snoozeMinutes: 7,
          enabled: false,
        ),
        throwsA(isA<InvalidSnoozeMinutesException>()),
      );
    });

    test('delete: スケジュールも cancel される', () async {
      final repo = _InMemoryAlarmRepo();
      final scheduler = _stubScheduler();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      final AlarmEntity created = await notifier.create(
        label: '',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        repeat: const AlarmRepeatOnce(),
        snoozeMinutes: 5,
        enabled: true,
      );
      await notifier.delete(created.id);
      await Future<void>.value();

      expect(container.read(alarmCollectionNotifierProvider), isEmpty);
      verify(() => scheduler.cancel(created.notificationId)).called(1);
    });

    test('delete: 存在しない id は no-op', () async {
      final repo = _InMemoryAlarmRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      await notifier.delete('missing');
      expect(container.read(alarmCollectionNotifierProvider), isEmpty);
    });
  });

  group('AlarmCollectionNotifier toggle / update', () {
    test('toggle で enabled が反転、true なら schedule、false なら cancel', () async {
      final repo = _InMemoryAlarmRepo();
      final scheduler = _stubScheduler();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      final AlarmEntity created = await notifier.create(
        label: '',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        repeat: const AlarmRepeatOnce(),
        snoozeMinutes: 5,
        enabled: false,
      );
      // ON
      await notifier.toggle(created.id);
      verify(
        () => scheduler.schedule(
          notificationId: created.notificationId,
          fireAt: any(named: 'fireAt'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          exact: any(named: 'exact'),
          payload: 'alarm:${created.id}',
        ),
      ).called(1);
      // OFF
      await notifier.toggle(created.id);
      verify(() => scheduler.cancel(created.notificationId)).called(1);
    });

    test('toggle: 存在しない id は AlarmNotFoundException', () async {
      final repo = _InMemoryAlarmRepo();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6)),
        repo: repo,
        scheduler: _stubScheduler(),
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      await expectLater(
        notifier.toggle('missing'),
        throwsA(isA<AlarmNotFoundException>()),
      );
    });

    test('update で enabled = true なら一旦 cancel して再 schedule', () async {
      final repo = _InMemoryAlarmRepo();
      final scheduler = _stubScheduler();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      final AlarmEntity created = await notifier.create(
        label: 'Old',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        repeat: const AlarmRepeatOnce(),
        snoozeMinutes: 5,
        enabled: true,
      );
      // create で 1 回 schedule 済 → reset カウントするため verify でリセット。
      await notifier.update(
        created.copyWith(
          label: 'New',
          targetTime: const TimeOfDayValue.unsafe(hour: 8, minute: 0),
        ),
      );

      // create + update で schedule 2 回、cancel 1 回 (update が cancel→schedule)。
      verify(() => scheduler.cancel(created.notificationId)).called(1);
      verify(
        () => scheduler.schedule(
          notificationId: created.notificationId,
          fireAt: any(named: 'fireAt'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          exact: any(named: 'exact'),
          payload: 'alarm:${created.id}',
        ),
      ).called(2);

      // notificationId / createdAt は保持される。
      final AlarmEntity restored = container
          .read(alarmCollectionNotifierProvider)
          .first;
      expect(restored.notificationId, created.notificationId);
      expect(restored.createdAt, created.createdAt);
      expect(restored.label, 'New');
    });
  });

  group('AlarmCollectionNotifier 鳴動イベント', () {
    test('onFiredStop: once は enabled=false に落ちて schedule なし', () async {
      final repo = _InMemoryAlarmRepo();
      final scheduler = _stubScheduler();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 7, 0)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      final AlarmEntity created = await notifier.create(
        label: '',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        repeat: const AlarmRepeatOnce(),
        snoozeMinutes: 5,
        enabled: true,
      );
      // create で 1 回 schedule 済。
      await notifier.onFiredStop(created.id);

      final AlarmEntity advanced = container
          .read(alarmCollectionNotifierProvider)
          .first;
      expect(advanced.enabled, isFalse);
      verify(() => scheduler.cancel(created.notificationId)).called(1);
    });

    test('onFiredStop: weekly は enabled 維持で次回曜日が再 schedule', () async {
      final repo = _InMemoryAlarmRepo();
      final scheduler = _stubScheduler();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 7, 0)), // Mon 07:00
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      final AlarmEntity created = await notifier.create(
        label: '',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        repeat: AlarmRepeatWeekly.create(<DayOfWeek>{
          DayOfWeek.monday,
          DayOfWeek.wednesday,
        }),
        snoozeMinutes: 5,
        enabled: true,
      );
      // create で 1 回 schedule (Mon 07:00 は等価なので Wed が選ばれる)。
      // onFiredStop で再 schedule (Wed)。
      await notifier.onFiredStop(created.id);

      final AlarmEntity advanced = container
          .read(alarmCollectionNotifierProvider)
          .first;
      expect(advanced.enabled, isTrue);
      verify(
        () => scheduler.schedule(
          notificationId: created.notificationId,
          fireAt: any(named: 'fireAt'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          exact: any(named: 'exact'),
          payload: 'alarm:${created.id}',
        ),
      ).called(2);
    });

    test('onFiredSnooze: now + snoozeMinutes に再 schedule', () async {
      final repo = _InMemoryAlarmRepo();
      final scheduler = _stubScheduler();
      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 7, 0)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);
      final notifier = container.read(alarmCollectionNotifierProvider.notifier);
      final AlarmEntity created = await notifier.create(
        label: '',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        repeat: const AlarmRepeatOnce(),
        snoozeMinutes: 10,
        enabled: true,
      );
      await notifier.onFiredSnooze(created.id);

      verify(
        () => scheduler.schedule(
          notificationId: created.notificationId,
          fireAt: DateTime(2026, 5, 4, 7, 10),
          title: any(named: 'title'),
          body: any(named: 'body'),
          exact: any(named: 'exact'),
          payload: 'alarm:${created.id}',
        ),
      ).called(1);
    });
  });

  group('AlarmCollectionNotifier 復元', () {
    test('永続化されたアラームを起動時に load し、enabled なものは schedule', () async {
      final scheduler = _stubScheduler();
      final repo = _InMemoryAlarmRepo();
      final AlarmEntity persisted = AlarmEntity(
        id: 'a-existing',
        notificationId: 12345,
        label: 'Daily',
        targetTime: const TimeOfDayValue.unsafe(hour: 6, minute: 30),
        repeat: AlarmRepeatWeekly.create(DayOfWeek.values.toSet()),
        snoozeMinutes: 5,
        enabled: true,
        soundId: null,
        createdAt: DateTime.utc(2026, 5, 1),
      );
      repo.store[persisted.id] = persisted;

      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 6, 0)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);

      // build トリガ + microtask 完了待ち
      container.read(alarmCollectionNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.value();

      expect(
        container
            .read(alarmCollectionNotifierProvider)
            .map((AlarmEntity a) => a.id),
        <String>['a-existing'],
      );
      verify(
        () => scheduler.schedule(
          notificationId: 12345,
          fireAt: any(named: 'fireAt'),
          title: 'Daily',
          body: any(named: 'body'),
          exact: any(named: 'exact'),
          payload: 'alarm:a-existing',
        ),
      ).called(1);
    });

    test('Phase 10: 過去到達 once-mode は enabled=false に落ちて show 1 回', () async {
      final scheduler = _stubScheduler();
      final repo = _InMemoryAlarmRepo();
      final AlarmEntity persisted = AlarmEntity(
        id: 'a-pastdue',
        notificationId: 99001,
        label: 'Wake up',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 30),
        repeat: const AlarmRepeatOnce(),
        snoozeMinutes: 5,
        enabled: true,
        soundId: null,
        createdAt: DateTime(2026, 5, 4, 6, 0),
      );
      repo.store[persisted.id] = persisted;

      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 8, 0)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);

      container.read(alarmCollectionNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.value();

      final List<AlarmEntity> loaded = container.read(
        alarmCollectionNotifierProvider,
      );
      expect(loaded.single.enabled, isFalse);
      expect(repo.store['a-pastdue']!.enabled, isFalse);
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
      verify(
        () => scheduler.show(
          notificationId: 99001,
          title: 'Wake up',
          body: any(named: 'body'),
          payload: 'alarm:a-pastdue',
        ),
      ).called(1);
    });

    test('Phase 10: 過去到達 weekly は enabled 維持で次回曜日に再 schedule', () async {
      final scheduler = _stubScheduler();
      final repo = _InMemoryAlarmRepo();
      final AlarmEntity persisted = AlarmEntity(
        id: 'a-weekly',
        notificationId: 99002,
        label: '',
        targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 30),
        repeat: AlarmRepeatWeekly.create(DayOfWeek.values.toSet()),
        snoozeMinutes: 5,
        enabled: true,
        soundId: null,
        createdAt: DateTime(2026, 5, 4, 6, 0),
      );
      repo.store[persisted.id] = persisted;

      final container = _makeContainer(
        clock: Clock.fixed(DateTime(2026, 5, 4, 8, 0)),
        repo: repo,
        scheduler: scheduler,
      );
      addTearDown(container.dispose);

      container.read(alarmCollectionNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.value();

      final List<AlarmEntity> loaded = container.read(
        alarmCollectionNotifierProvider,
      );
      expect(loaded.single.enabled, isTrue);
      verify(
        () => scheduler.schedule(
          notificationId: 99002,
          fireAt: DateTime(2026, 5, 5, 7, 30),
          title: any(named: 'title'),
          body: any(named: 'body'),
          exact: any(named: 'exact'),
          payload: 'alarm:a-weekly',
        ),
      ).called(1);
      verifyNever(
        () => scheduler.show(
          notificationId: any(named: 'notificationId'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test(
      'Phase 10: createdAt が今日の targetTime より後の once は past-due 扱いしない',
      () async {
        final scheduler = _stubScheduler();
        final repo = _InMemoryAlarmRepo();
        final AlarmEntity persisted = AlarmEntity(
          id: 'a-tomorrow-intent',
          notificationId: 99003,
          label: '',
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 30),
          repeat: const AlarmRepeatOnce(),
          snoozeMinutes: 5,
          enabled: true,
          soundId: null,
          // 今日の 7:30 より後に作成 → ユーザは「明日の 7:30」を意図。
          createdAt: DateTime(2026, 5, 4, 9, 0),
        );
        repo.store[persisted.id] = persisted;

        final container = _makeContainer(
          clock: Clock.fixed(DateTime(2026, 5, 4, 10, 0)),
          repo: repo,
          scheduler: scheduler,
        );
        addTearDown(container.dispose);

        container.read(alarmCollectionNotifierProvider);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.value();

        final List<AlarmEntity> loaded = container.read(
          alarmCollectionNotifierProvider,
        );
        expect(loaded.single.enabled, isTrue);
        verify(
          () => scheduler.schedule(
            notificationId: 99003,
            fireAt: DateTime(2026, 5, 5, 7, 30),
            title: any(named: 'title'),
            body: any(named: 'body'),
            exact: any(named: 'exact'),
            payload: 'alarm:a-tomorrow-intent',
          ),
        ).called(1);
        verifyNever(
          () => scheduler.show(
            notificationId: any(named: 'notificationId'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ),
        );
      },
    );
  });
}
