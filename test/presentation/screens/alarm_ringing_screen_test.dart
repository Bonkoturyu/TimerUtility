import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timer_utility/application/alarm_ringing_notifier.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
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

Widget _harness(_StubAlarmSoundPlayer player) {
  final router = GoRouter(
    initialLocation: '/alarm-ringing',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('home-stub')),
      ),
      GoRoute(
        path: '/alarm-ringing',
        builder: (BuildContext context, GoRouterState state) =>
            const AlarmRingingScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[alarmSoundPlayerProvider.overrideWithValue(player)],
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

    testWidgets('Stop button stops the player and resets state', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_harness(player));
      await tester.pumpAndSettle();

      // Simulate that the alarm is currently ringing.
      final BuildContext context = tester.element(
        find.byType(AlarmRingingScreen),
      );
      final container = ProviderScope.containerOf(context);
      await container
          .read(alarmRingingNotifierProvider.notifier)
          .start(timerId: 't-1', sound: AlarmSoundCatalog.defaultSound);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('alarm_stop_button')));
      await tester.pumpAndSettle();

      expect(player.stopCalls, greaterThanOrEqualTo(1));
      final state = container.read(alarmRingingNotifierProvider);
      expect(state.isPlaying, isFalse);
      expect(state.currentTimerId, isNull);
    });

    testWidgets('Snooze button flips snoozeRequested and stops audio', (
      WidgetTester tester,
    ) async {
      final player = _StubAlarmSoundPlayer();
      await tester.pumpWidget(_harness(player));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(AlarmRingingScreen),
      );
      final container = ProviderScope.containerOf(context);
      await container
          .read(alarmRingingNotifierProvider.notifier)
          .start(timerId: 't-1', sound: AlarmSoundCatalog.defaultSound);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('alarm_snooze_button')));
      await tester.pumpAndSettle();

      final state = container.read(alarmRingingNotifierProvider);
      expect(state.snoozeRequested, isTrue);
      expect(state.isPlaying, isFalse);
      expect(player.stopCalls, greaterThanOrEqualTo(1));
    });
  });
}
