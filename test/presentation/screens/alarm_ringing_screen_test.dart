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
import 'package:timer_utility/application/timer_notifier.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/timer/alarm_sound.dart';
import 'package:timer_utility/domain/timer/alarm_sound_catalog.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';
import 'package:timer_utility/presentation/screens/alarm_ringing_screen.dart';

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

Widget _harness(_StubAlarmSoundPlayer player, {DateTime? now}) {
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
  when(() => scheduler.cancel(any())).thenAnswer((_) async {});
  when(() => scheduler.cancelAll()).thenAnswer((_) async {});

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
    ],
    child: MaterialApp.router(routerConfig: router),
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

      expect(find.byKey(const Key('alarm_ringing_title')), findsOneWidget);
      expect(find.byKey(const Key('alarm_stop_button')), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_button')), findsOneWidget);
      // The "Timer: <id>" debug label is intentionally absent — there's no
      // user-facing label input, so showing the internal id was noise.
      expect(find.byKey(const Key('alarm_ringing_label')), findsNothing);
    });

    testWidgets('self-bootstraps audio on cold-start (TimerNotifier is null)', (
      WidgetTester tester,
    ) async {
      // Simulates the cold-launch / FSI path where the screen appears
      // without TimerNotifier._onTick ever firing. The screen must
      // start the player itself so the user is not left in silence
      // after the OS notification was dismissed.
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_harness(player));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(AlarmRingingScreen),
      );
      final container = ProviderScope.containerOf(context);

      expect(player.playCalls, 1);
      final ringing = container.read(alarmRingingNotifierProvider);
      expect(ringing.isPlaying, isTrue);
      expect(ringing.currentTimerId, 'unknown');
      expect(ringing.currentSoundId, 'default');
    });

    testWidgets('start is idempotent — second start while playing is a no-op', (
      WidgetTester tester,
    ) async {
      // Self-bootstrap fires on mount. A subsequent `start()` (e.g. a
      // late foreground tick) must NOT re-trigger play / cancel — that
      // would cause stuttering or re-fetching the asset.
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_harness(player));
      await tester.pumpAndSettle();
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

      // Still 1: the second start saw isPlaying=true and bailed.
      expect(player.playCalls, 1);
    });

    testWidgets('Stop button stops the player and clears the timer', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_harness(player));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(AlarmRingingScreen),
      );
      final container = ProviderScope.containerOf(context);
      // Pre-populate a timer so we can prove `clear()` runs.
      container
          .read(timerNotifierProvider.notifier)
          .create(label: '', duration: const Duration(seconds: 5));
      await container
          .read(alarmRingingNotifierProvider.notifier)
          .start(
            timerId: 't-1',
            sound: AlarmSoundCatalog.defaultSound,
            notificationId: 1,
          );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('alarm_stop_button')));
      await tester.pumpAndSettle();

      expect(player.stopCalls, greaterThanOrEqualTo(1));
      final ringing = container.read(alarmRingingNotifierProvider);
      expect(ringing.isPlaying, isFalse);
      expect(ringing.currentTimerId, isNull);
      expect(container.read(timerNotifierProvider), isNull);
      // The harness starts at /alarm-ringing (no back stack), so the
      // screen should navigate to /timer rather than try to pop.
      expect(find.text('timer-stub'), findsOneWidget);
      expect(find.byType(AlarmRingingScreen), findsNothing);
    });

    testWidgets('Snooze button opens 3/5/10-minute chooser sheet', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_snoozeHarness(player));
      await tester.pumpAndSettle();

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
        await tester.pumpWidget(_snoozeHarness(player));
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(
          find.byType(AlarmRingingScreen),
        );
        final container = ProviderScope.containerOf(context);

        await tester.tap(find.byKey(const Key('alarm_snooze_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('alarm_snooze_choice_5m')));
        await tester.pumpAndSettle();

        // Timer transitioned ringing → running with the snoozed endAt.
        final entity = container.read(timerNotifierProvider)!;
        expect(entity.status, TimerStatus.running);
        expect(entity.endAt, isNotNull);
        // No longer on the alarm screen — replaced with /timer stub.
        expect(find.text('timer-stub'), findsOneWidget);
        expect(find.byType(AlarmRingingScreen), findsNothing);
      },
    );

    testWidgets(
      'cancelling the snooze chooser keeps the alarm screen and timer ringing',
      (WidgetTester tester) async {
        final player = _StubAlarmSoundPlayer();
        await tester.pumpWidget(_snoozeHarness(player));
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(
          find.byType(AlarmRingingScreen),
        );
        final container = ProviderScope.containerOf(context);

        await tester.tap(find.byKey(const Key('alarm_snooze_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('alarm_snooze_cancel')));
        await tester.pumpAndSettle();

        // Sheet closed, but the alarm screen stays and the timer remains
        // ringing.
        expect(find.text('スヌーズ時間を選択'), findsNothing);
        expect(find.byType(AlarmRingingScreen), findsOneWidget);
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.ringing,
        );
      },
    );
  });
}

/// Harness for snooze flow tests: seeds TimerNotifier with a ringing
/// TimerEntity so the user-facing snooze button has something to act on
/// without requiring fake_async for ticker-driven ringing transitions.
Widget _snoozeHarness(_StubAlarmSoundPlayer player) {
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
  when(() => scheduler.cancel(any())).thenAnswer((_) async {});
  when(() => scheduler.cancelAll()).thenAnswer((_) async {});

  final fixedNow = DateTime(2026, 5, 1, 7, 30);
  final ringing = TimerEntity(
    id: 'test-id',
    notificationId: 42,
    label: '',
    duration: const Duration(seconds: 5),
    endAt: null,
    pausedRemaining: null,
    status: TimerStatus.ringing,
    createdAt: fixedNow,
  );

  final router = GoRouter(
    initialLocation: '/alarm-ringing',
    routes: <RouteBase>[
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
      clockProvider.overrideWithValue(Clock.fixed(fixedNow)),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      timerNotifierProvider.overrideWith(() => _SeededTimerNotifier(ringing)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Seeds the TimerNotifier state with a pre-built entity. We still call
/// `super.build()` so the parent's `ref.onDispose(_stopTicker)` runs and
/// any snooze-spawned Timer.periodic gets cancelled at widget teardown
/// (otherwise flutter_test fails the test for a leaked timer).
class _SeededTimerNotifier extends TimerNotifier {
  _SeededTimerNotifier(this._seed);
  final TimerEntity _seed;

  @override
  TimerEntity? build() {
    super.build();
    return _seed;
  }
}
