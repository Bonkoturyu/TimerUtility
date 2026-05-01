import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/presentation/widgets/duration_picker.dart';

/// Wraps the picker in a MaterialApp + bottom sheet so that the test can
/// inspect both the Confirm button state and the value popped via Navigator.
Future<Duration?> _showPicker(
  WidgetTester tester, {
  Duration initial = const Duration(minutes: 1),
}) async {
  Duration? popped;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => Center(
            child: ElevatedButton(
              key: const Key('open'),
              onPressed: () async {
                popped = await showModalBottomSheet<Duration>(
                  context: context,
                  builder: (_) => DurationPicker(initial: initial),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return popped;
}

void main() {
  group('DurationPicker', () {
    testWidgets('renders with the initial duration broken into HH/MM/SS', (
      WidgetTester tester,
    ) async {
      await _showPicker(
        tester,
        initial: const Duration(hours: 1, minutes: 23, seconds: 45),
      );

      expect(find.text('カスタム時間を選択'), findsOneWidget);
      // The selected row in each CupertinoPicker is the centred one. Each
      // visible value text should appear at least once for the picked entry.
      expect(find.text('01'), findsWidgets); // hours wheel
      expect(find.text('23'), findsWidgets); // minutes wheel
      expect(find.text('45'), findsWidgets); // seconds wheel
    });

    testWidgets('0:00:00 disables the confirm button', (
      WidgetTester tester,
    ) async {
      await _showPicker(tester, initial: Duration.zero);

      final FilledButton confirm = tester.widget<FilledButton>(
        find.byKey(const Key('duration_picker_confirm')),
      );
      expect(confirm.onPressed, isNull);
    });

    testWidgets('a positive initial enables the confirm button', (
      WidgetTester tester,
    ) async {
      await _showPicker(tester, initial: const Duration(seconds: 5));

      final FilledButton confirm = tester.widget<FilledButton>(
        find.byKey(const Key('duration_picker_confirm')),
      );
      expect(confirm.onPressed, isNotNull);
    });

    testWidgets('99:00:00 (== maxDuration) is confirmable and pops it back', (
      WidgetTester tester,
    ) async {
      Duration? popped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: ElevatedButton(
                  key: const Key('open'),
                  onPressed: () async {
                    popped = await showModalBottomSheet<Duration>(
                      context: context,
                      builder: (_) =>
                          const DurationPicker(initial: Duration(hours: 99)),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('duration_picker_confirm')));
      await tester.pumpAndSettle();

      expect(popped, const Duration(hours: 99));
    });

    testWidgets('exceeding maxDuration disables confirm', (
      WidgetTester tester,
    ) async {
      // Initial 99h + 1s pushes the total above the 99h cap, so the picker
      // should refuse to confirm even though every individual wheel is in
      // its valid range.
      await _showPicker(tester, initial: const Duration(hours: 99, seconds: 1));

      final FilledButton confirm = tester.widget<FilledButton>(
        find.byKey(const Key('duration_picker_confirm')),
      );
      expect(confirm.onPressed, isNull);
    });

    testWidgets('cancel pops null', (WidgetTester tester) async {
      Duration? popped = const Duration(minutes: 99);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: ElevatedButton(
                  key: const Key('open'),
                  onPressed: () async {
                    popped = await showModalBottomSheet<Duration>(
                      context: context,
                      builder: (_) =>
                          const DurationPicker(initial: Duration(seconds: 5)),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('duration_picker_cancel')));
      await tester.pumpAndSettle();

      expect(popped, isNull);
    });

    testWidgets('scrolling the seconds wheel updates the selection', (
      WidgetTester tester,
    ) async {
      Duration? popped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: ElevatedButton(
                  key: const Key('open'),
                  onPressed: () async {
                    popped = await showModalBottomSheet<Duration>(
                      context: context,
                      builder: (_) =>
                          const DurationPicker(initial: Duration(seconds: 5)),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      // Drag upward on the seconds wheel; itemExtent is 32 px, so dragging
      // by ~96 px advances the selection by roughly 3 items. Exact pixel
      // mechanics vary, so we only assert the value changed from 5 s.
      await tester.drag(
        find.byKey(const Key('duration_picker_seconds')),
        const Offset(0, -96),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('duration_picker_confirm')));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped! > Duration.zero, isTrue);
      expect(popped! <= DurationPicker.maxDuration, isTrue);
      expect(popped, isNot(const Duration(seconds: 5)));
    });
  });
}
