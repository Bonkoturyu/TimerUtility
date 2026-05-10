import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/timezone_resolver_provider.dart';
import 'package:timer_utility/infrastructure/clock/tz_database_timezone_resolver.dart';
import 'package:timer_utility/presentation/widgets/digital_clock_widget.dart';

Future<void> _pump(
  WidgetTester tester, {
  required DateTime time,
  required String timezoneId,
  bool showSeconds = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        timezoneResolverProvider.overrideWithValue(
          TzDatabaseTimezoneResolver(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DigitalClockWidget(
            time: time,
            timezoneId: timezoneId,
            showSeconds: showSeconds,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('DigitalClockWidget', () {
    testWidgets('UTC 12:00 + Asia/Tokyo で 21:00:00 が表示される', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        time: DateTime.utc(2026, 1, 15, 12),
        timezoneId: 'Asia/Tokyo',
      );
      expect(find.text('21:00:00'), findsOneWidget);
    });

    testWidgets('showSeconds: false で秒表記が省略される (21:00)', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        time: DateTime.utc(2026, 1, 15, 12),
        timezoneId: 'Asia/Tokyo',
        showSeconds: false,
      );
      expect(find.text('21:00'), findsOneWidget);
      expect(find.text('21:00:00'), findsNothing);
    });

    testWidgets('Asia/Seoul (Tokyo と同オフセット) でも 21:00:00 が表示される', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        time: DateTime.utc(2026, 1, 15, 12),
        timezoneId: 'Asia/Seoul',
      );
      expect(find.text('21:00:00'), findsOneWidget);
    });
  });
}
