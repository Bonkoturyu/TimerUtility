import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/stopwatch_notifier.dart';
import 'package:timer_utility/presentation/widgets/lap_list.dart';

class _MutableNow {
  _MutableNow(this.now);
  DateTime now;
}

Widget _harness(_MutableNow holder) {
  return ProviderScope(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock(() => holder.now)),
    ],
    child: const MaterialApp(home: Scaffold(body: LapList())),
  );
}

Future<void> _drive(
  WidgetTester tester,
  _MutableNow now,
  void Function(StopwatchNotifier notifier) actions,
) async {
  await tester.pumpWidget(_harness(now));
  final BuildContext context = tester.element(find.byType(LapList));
  final ProviderContainer container = ProviderScope.containerOf(context);
  actions(container.read(stopwatchNotifierProvider.notifier));
  await tester.pumpAndSettle();
}

void main() {
  group('LapList', () {
    testWidgets('renders empty placeholder when there are no laps', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1));
      await tester.pumpWidget(_harness(now));
      await tester.pumpAndSettle();

      expect(find.text('No laps recorded'), findsOneWidget);
      expect(find.byKey(const Key('lap_list')), findsNothing);
    });

    testWidgets('renders one row per lap, newest first', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await _drive(tester, now, (notifier) {
        notifier.start();
        now.now = DateTime(2026, 1, 1, 12, 0, 3);
        notifier.lap();
        now.now = DateTime(2026, 1, 1, 12, 0, 7);
        notifier.lap();
      });

      expect(find.byKey(const Key('lap_list')), findsOneWidget);
      expect(find.textContaining('Lap'), findsNWidgets(2));
      // Lap 2 should be above Lap 1 (newest first)
      final lap2 = tester.getCenter(find.text('Lap 2'));
      final lap1 = tester.getCenter(find.text('Lap 1'));
      expect(lap2.dy, lessThan(lap1.dy));
    });

    testWidgets('shows split and total formatted as MM:SS.cc', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await _drive(tester, now, (notifier) {
        notifier.start();
        now.now = DateTime(2026, 1, 1, 12, 0, 5);
        notifier.lap();
      });

      expect(find.text('Split 00:05.00'), findsOneWidget);
      expect(find.text('Total 00:05.00'), findsOneWidget);
    });

    testWidgets('reflects laps after pause (Paused state retains laps)', (
      WidgetTester tester,
    ) async {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      await _drive(tester, now, (notifier) {
        notifier.start();
        now.now = DateTime(2026, 1, 1, 12, 0, 4);
        notifier.lap();
        now.now = DateTime(2026, 1, 1, 12, 0, 5);
        notifier.pause();
      });

      expect(find.text('Lap 1'), findsOneWidget);
    });
  });
}
