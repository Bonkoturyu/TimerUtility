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
      expect(find.byKey(const Key('alarm_ringing_label')), findsOneWidget);
      expect(find.byKey(const Key('alarm_stop_button')), findsOneWidget);
      expect(find.byKey(const Key('alarm_snooze_button')), findsOneWidget);
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
          .start(timerId: 't-1', sound: AlarmSoundCatalog.defaultSound);
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

    testWidgets(
      'Snooze button flips snoozeRequested, stops audio, clears the timer',
      (WidgetTester tester) async {
        final player = _StubAlarmSoundPlayer();
        await tester.pumpWidget(_harness(player));
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(
          find.byType(AlarmRingingScreen),
        );
        final container = ProviderScope.containerOf(context);
        container
            .read(timerNotifierProvider.notifier)
            .create(label: '', duration: const Duration(seconds: 5));
        await container
            .read(alarmRingingNotifierProvider.notifier)
            .start(timerId: 't-1', sound: AlarmSoundCatalog.defaultSound);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('alarm_snooze_button')));
        await tester.pumpAndSettle();

        final ringing = container.read(alarmRingingNotifierProvider);
        expect(ringing.snoozeRequested, isTrue);
        expect(ringing.isPlaying, isFalse);
        expect(player.stopCalls, greaterThanOrEqualTo(1));
        expect(container.read(timerNotifierProvider), isNull);
        expect(find.text('timer-stub'), findsOneWidget);
        expect(find.byType(AlarmRingingScreen), findsNothing);
      },
    );
  });
}
