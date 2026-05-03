import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_ringing_notifier.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/notification_strings_provider.dart';
import 'package:timer_utility/application/timer_collection_notifier.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/timer/alarm_sound.dart';
import 'package:timer_utility/domain/timer/alarm_sound_catalog.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/alarm_ringing_screen.dart';

import '../../helpers/test_notification_strings.dart';

class _StubAlarmSoundPlayer implements AlarmSoundPlayer {
  bool _isPlaying = false;
  int playCalls = 0;
  int stopCalls = 0;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> play(AlarmSound sound) async {
    playCalls++;
    _isPlaying = true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {}
}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

/// In-memory [TimerRepository] used by every harness so the
/// [TimerCollectionNotifier] under test never touches a real DB.
class _InMemoryTimerRepository implements TimerRepository {
  final Map<String, TimerEntity> _store = <String, TimerEntity>{};

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }

  @override
  Future<List<TimerEntity>> findAll() async => _store.values.toList();

  @override
  Future<TimerEntity?> findById(String id) async => _store[id];

  @override
  Future<void> upsert(TimerEntity entity) async {
    _store[entity.id] = entity;
  }
}

NotificationScheduler _stubScheduler() {
  final scheduler = _MockNotificationScheduler();
  when(
    () => scheduler.schedule(
      notificationId: any(named: 'notificationId'),
      fireAt: any(named: 'fireAt'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      exact: any(named: 'exact'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => scheduler.show(
      notificationId: any(named: 'notificationId'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});
  when(() => scheduler.cancel(any())).thenAnswer((_) async {});
  when(() => scheduler.cancelAll()).thenAnswer((_) async {});
  return scheduler;
}

Widget _harness(
  _StubAlarmSoundPlayer player, {
  DateTime? now,
  TimerEntity? seedRinging,
}) {
  final NotificationScheduler scheduler = _stubScheduler();
  final _InMemoryTimerRepository repo = _InMemoryTimerRepository();
  if (seedRinging != null) {
    repo._store[seedRinging.id] = seedRinging;
  }

  final router = GoRouter(
    initialLocation: '/alarm-ringing',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('home-stub')),
      ),
      GoRoute(
        path: '/timer',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('timer-stub')),
      ),
      GoRoute(
        path: '/alarm-ringing',
        builder: (BuildContext context, GoRouterState state) =>
            const AlarmRingingScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      alarmSoundPlayerProvider.overrideWithValue(player),
      clockProvider.overrideWithValue(Clock(() => now ?? DateTime(2026, 1, 1))),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      notificationStringsProvider.overrideWithValue(testNotificationStrings),
      timerRepositoryProvider.overrideWithValue(repo),
    ],
    // Force Japanese so existing assertions for "スヌーズ時間を選択"
    // remain stable; the alarm screen text now resolves through
    // AppLocalizations.
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
    ),
  );
}

void main() {
  group('AlarmRingingScreen', () {
    testWidgets('shows title, label, and Stop / Snooze buttons', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_harness(player));
      await tester.pumpAndSettle();
      // Drain the 500ms cancel→play delay AlarmRingingNotifier.start
      // schedules so no Timer is left pending at teardown.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('alarm_ringing_title')), findsOneWidget);
      expect(find.byKey(const Key('alarm_stop_button')), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_button')), findsOneWidget);
      expect(find.byKey(const Key('alarm_ringing_label')), findsNothing);
    });

    testWidgets(
      'AppBar has no back button while the alarm is ringing — Stop / Snooze are the only exits',
      (WidgetTester tester) async {
        final player = _StubAlarmSoundPlayer();
        await tester.pumpWidget(_harness(player));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        // automaticallyImplyLeading: false drops the BackButton, and
        // PopScope(canPop: false) blocks both gesture-back and any
        // explicit Navigator.pop attempts.
        expect(find.byType(BackButton), findsNothing);
      },
    );

    testWidgets(
      'self-bootstraps audio on cold-start (no ringing timer in collection)',
      (WidgetTester tester) async {
        // Cold launch: collection is empty. The screen still arms audio
        // with the synthetic 'unknown' timer id so the user is not met
        // with silence after the OS notification was dismissed.
        final player = _StubAlarmSoundPlayer();
        await tester.pumpWidget(_harness(player));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        final BuildContext context = tester.element(
          find.byType(AlarmRingingScreen),
        );
        final container = ProviderScope.containerOf(context);

        expect(player.playCalls, 1);
        final ringing = container.read(alarmRingingNotifierProvider);
        expect(ringing.isPlaying, isTrue);
        expect(ringing.currentTimerId, 'unknown');
        expect(ringing.currentSoundId, 'default');
      },
    );

    testWidgets('start is idempotent — second start while playing is a no-op', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_harness(player));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      expect(player.playCalls, 1);

      final BuildContext context = tester.element(
        find.byType(AlarmRingingScreen),
      );
      final container = ProviderScope.containerOf(context);
      await container
          .read(alarmRingingNotifierProvider.notifier)
          .start(
            timerId: 'late-tick',
            sound: AlarmSoundCatalog.defaultSound,
            notificationId: 99,
          );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      expect(player.playCalls, 1);
    });

    testWidgets('Stop button stops the player and cancels the ringing timer', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      final TimerEntity seeded = TimerEntity(
        id: 'ringing-1',
        notificationId: 1,
        label: '',
        duration: const Duration(seconds: 5),
        endAt: null,
        pausedRemaining: null,
        status: TimerStatus.ringing,
        createdAt: DateTime(2026, 1, 1),
      );
      await tester.pumpWidget(_harness(player, seedRinging: seeded));
      // Pump the microtask that loads the collection from the repo.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(const Key('alarm_stop_button')));
      await tester.pumpAndSettle();

      expect(player.stopCalls, greaterThanOrEqualTo(1));
      final BuildContext context = tester.element(find.text('timer-stub'));
      final container = ProviderScope.containerOf(context);
      final ringing = container.read(alarmRingingNotifierProvider);
      expect(ringing.isPlaying, isFalse);
      expect(ringing.currentTimerId, isNull);
      final collection = container.read(timerCollectionNotifierProvider);
      expect(collection.findById('ringing-1')?.status, TimerStatus.cancelled);
      expect(find.text('timer-stub'), findsOneWidget);
      expect(find.byType(AlarmRingingScreen), findsNothing);
    });

    testWidgets('Snooze button opens 3/5/10-minute chooser sheet', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      final TimerEntity seeded = _seedRinging();
      await tester.pumpWidget(_harness(player, seedRinging: seeded));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(const Key('alarm_snooze_button')));
      await tester.pumpAndSettle();

      expect(find.text('スヌーズ時間を選択'), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_choice_3m')), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_choice_5m')), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_choice_10m')), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_cancel')), findsOneWidget);
    });

    testWidgets(
      'selecting 5 minutes snoozes the timer and leaves the alarm screen',
      (WidgetTester tester) async {
        final player = _StubAlarmSoundPlayer();
        final TimerEntity seeded = _seedRinging();
        final DateTime fixedNow = DateTime(2026, 5, 1, 7, 30);
        await tester.pumpWidget(
          _harness(player, now: fixedNow, seedRinging: seeded),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        await tester.tap(find.byKey(const Key('alarm_snooze_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('alarm_snooze_choice_5m')));
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(find.text('timer-stub'));
        final container = ProviderScope.containerOf(context);
        final TimerEntity entity = container
            .read(timerCollectionNotifierProvider)
            .findById('ringing-1')!;
        expect(entity.status, TimerStatus.running);
        expect(entity.endAt, isNotNull);
        expect(find.text('timer-stub'), findsOneWidget);
        expect(find.byType(AlarmRingingScreen), findsNothing);
      },
    );

    group('tryReservePush dedup', () {
      tearDown(AlarmRingingScreen.debugResetPushReservation);

      test('first caller acquires, subsequent callers blocked until reset', () {
        expect(AlarmRingingScreen.tryReservePush(), isTrue);
        expect(AlarmRingingScreen.tryReservePush(), isFalse);
        expect(AlarmRingingScreen.tryReservePush(), isFalse);
        AlarmRingingScreen.debugResetPushReservation();
        expect(AlarmRingingScreen.tryReservePush(), isTrue);
      });
    });

    testWidgets(
      'cancelling the snooze chooser keeps the alarm screen and timer ringing',
      (WidgetTester tester) async {
        final player = _StubAlarmSoundPlayer();
        final TimerEntity seeded = _seedRinging();
        await tester.pumpWidget(_harness(player, seedRinging: seeded));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));

        await tester.tap(find.byKey(const Key('alarm_snooze_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('alarm_snooze_cancel')));
        await tester.pumpAndSettle();

        expect(find.text('スヌーズ時間を選択'), findsNothing);
        expect(find.byType(AlarmRingingScreen), findsOneWidget);
        final BuildContext context = tester.element(
          find.byType(AlarmRingingScreen),
        );
        final container = ProviderScope.containerOf(context);
        expect(
          container
              .read(timerCollectionNotifierProvider)
              .findById('ringing-1')!
              .status,
          TimerStatus.ringing,
        );
      },
    );
  });
}

TimerEntity _seedRinging() => TimerEntity(
  id: 'ringing-1',
  notificationId: 42,
  label: '',
  duration: const Duration(seconds: 5),
  endAt: null,
  pausedRemaining: null,
  status: TimerStatus.ringing,
  createdAt: DateTime(2026, 5, 1, 7, 30),
);
