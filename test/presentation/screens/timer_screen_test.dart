import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/timer_notifier.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';
import 'package:timer_utility/presentation/screens/timer_screen.dart';

class _MutableNow {
  _MutableNow(this.now);
  DateTime now;
}

Widget _harness(_MutableNow holder) {
  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock(() => holder.now)),
    ],
    child: const MaterialApp(home: TimerScreen()),
  );
}

void main() {
  group('TimerScreen setup mode', () {
    testWidgets('shows preset duration chips when no timer is configured', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      expect(find.text('Choose a duration'), findsOneWidget);
      expect(find.byKey(const Key('timer_preset_5s')), findsOneWidget);
      expect(find.byKey(const Key('timer_preset_60s')), findsOneWidget);
    });

    testWidgets('tapping a preset transitions to active idle view', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_preset_5s')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('timer_display')), findsOneWidget);
      expect(find.byKey(const Key('timer_start_button')), findsOneWidget);
      expect(
        (tester.widget<Text>(find.byKey(const Key('timer_display')))).data,
        '00:05',
      );
    });
  });

  group('TimerScreen active mode', () {
    testWidgets('5-second timer reaches Time\'s up after elapsing 5 s', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_preset_5s')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('timer_start_button')));
      await tester.pump();

      // Advance the clock and let internal Timer.periodic fire.
      now.now = DateTime(2026, 1, 1, 12, 0, 6);
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text("Time's up!"), findsOneWidget);
      expect(find.byKey(const Key('timer_dismiss_button')), findsOneWidget);

      // Stop ticker so Flutter's leak detector is happy.
      await tester.tap(find.byKey(const Key('timer_dismiss_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Pause replaces Pause button with Resume', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_preset_60s')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('timer_start_button')));
      await tester.pump();

      now.now = DateTime(2026, 1, 1, 12, 0, 5);
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.byKey(const Key('timer_pause_button')));
      await tester.pump();

      expect(find.byKey(const Key('timer_resume_button')), findsOneWidget);
      expect(find.byKey(const Key('timer_pause_button')), findsNothing);

      // Verify state via container
      final BuildContext context = tester.element(find.byType(TimerScreen));
      final container = ProviderScope.containerOf(context);
      expect(container.read(timerNotifierProvider)!.status, TimerStatus.paused);
    });

    testWidgets('Back button returns to setup view', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timer_preset_5s')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('timer_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('Choose a duration'), findsOneWidget);
      expect(find.byKey(const Key('timer_display')), findsNothing);
    });
  });
}
