import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/stopwatch_notifier.dart';
import 'package:timer_utility/domain/stopwatch/stopwatch_state.dart';
import 'package:timer_utility/presentation/screens/stopwatch_screen.dart';

class _MutableNow {
  _MutableNow(this.now);
  DateTime now;
}

Widget _harness(_MutableNow holder) {
  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock(() => holder.now)),
    ],
    child: const MaterialApp(home: StopwatchScreen()),
  );
}

void main() {
  group('StopwatchScreen', () {
    testWidgets('shows 00:00.00 and Start button on first paint', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));

      expect(find.byKey(const Key('stopwatch_display')), findsOneWidget);
      expect(
        (tester.widget<Text>(find.byKey(const Key('stopwatch_display')))).data,
        '00:00.00',
      );
      expect(find.byKey(const Key('stopwatch_start_button')), findsOneWidget);
    });

    testWidgets('Start → display advances → Pause shows Resume', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));

      // Start
      await tester.tap(find.byKey(const Key('stopwatch_start_button')));
      await tester.pump();

      // 5 seconds elapse on the clock
      now.now = DateTime(2026, 1, 1, 12, 0, 5);

      // Pump to let the tick stream emit and rebuild the display.
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        (tester.widget<Text>(find.byKey(const Key('stopwatch_display')))).data,
        '00:05.00',
      );

      // Pause
      await tester.tap(find.byKey(const Key('stopwatch_pause_button')));
      await tester.pump();

      expect(find.byKey(const Key('stopwatch_resume_button')), findsOneWidget);
      expect(find.byKey(const Key('stopwatch_pause_button')), findsNothing);
    });

    testWidgets('Lap button records and screen reflects lap count', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));

      await tester.tap(find.byKey(const Key('stopwatch_start_button')));
      await tester.pump();

      now.now = DateTime(2026, 1, 1, 12, 0, 3);
      await tester.tap(find.byKey(const Key('stopwatch_lap_button')));
      await tester.pump();

      now.now = DateTime(2026, 1, 1, 12, 0, 8);
      await tester.tap(find.byKey(const Key('stopwatch_lap_button')));
      await tester.pump();

      // Verify state via container
      final BuildContext context = tester.element(find.byType(StopwatchScreen));
      final ProviderContainer container = ProviderScope.containerOf(context);
      final state = container.read(stopwatchNotifierProvider);
      expect(state, isA<StopwatchRunning>());
      expect((state as StopwatchRunning).laps, hasLength(2));

      // UI shows Lap 1 and Lap 2 entries
      expect(find.text('Lap 1'), findsOneWidget);
      expect(find.text('Lap 2'), findsOneWidget);
    });

    testWidgets('Reset returns display to 00:00.00 and Start', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await tester.pumpWidget(_harness(now));

      await tester.tap(find.byKey(const Key('stopwatch_start_button')));
      await tester.pump();
      now.now = DateTime(2026, 1, 1, 12, 0, 4);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.byKey(const Key('stopwatch_reset_button')));
      await tester.pump();

      expect(
        (tester.widget<Text>(find.byKey(const Key('stopwatch_display')))).data,
        '00:00.00',
      );
      expect(find.byKey(const Key('stopwatch_start_button')), findsOneWidget);
    });
  });
}
