import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/shared/duration_formatter.dart';

void main() {
  const formatter = DurationFormatter();

  group('DurationFormatter.formatStopwatch', () {
    test('zero duration is "00:00.00"', () {
      expect(formatter.formatStopwatch(Duration.zero), '00:00.00');
    });

    test('negative duration is clamped to "00:00.00"', () {
      expect(
        formatter.formatStopwatch(const Duration(seconds: -5)),
        '00:00.00',
      );
    });

    test('5.42 seconds is "00:05.42"', () {
      expect(
        formatter.formatStopwatch(const Duration(milliseconds: 5420)),
        '00:05.42',
      );
    });

    test('1 minute 23.45 seconds is "01:23.45"', () {
      expect(
        formatter.formatStopwatch(
          const Duration(minutes: 1, seconds: 23, milliseconds: 450),
        ),
        '01:23.45',
      );
    });

    test('1 hour 2 minutes 3.45 seconds is "01:02:03.45"', () {
      expect(
        formatter.formatStopwatch(
          const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 450),
        ),
        '01:02:03.45',
      );
    });

    test('exactly 1 hour is "01:00:00.00"', () {
      expect(
        formatter.formatStopwatch(const Duration(hours: 1)),
        '01:00:00.00',
      );
    });

    test('centiseconds round down (truncate)', () {
      // 999ms = 0.99s, not 1s
      expect(
        formatter.formatStopwatch(const Duration(milliseconds: 999)),
        '00:00.99',
      );
    });
  });

  group('DurationFormatter.formatTimer', () {
    test('zero duration is "00:00"', () {
      expect(formatter.formatTimer(Duration.zero), '00:00');
    });

    test('negative duration is clamped to "00:00"', () {
      expect(formatter.formatTimer(const Duration(seconds: -1)), '00:00');
    });

    test('45 seconds is "00:45"', () {
      expect(formatter.formatTimer(const Duration(seconds: 45)), '00:45');
    });

    test('5 minutes is "05:00"', () {
      expect(formatter.formatTimer(const Duration(minutes: 5)), '05:00');
    });

    test('1 hour 30 minutes is "01:30:00"', () {
      expect(
        formatter.formatTimer(const Duration(hours: 1, minutes: 30)),
        '01:30:00',
      );
    });

    test('milliseconds are ignored (truncate to second)', () {
      expect(
        formatter.formatTimer(const Duration(seconds: 5, milliseconds: 999)),
        '00:05',
      );
    });
  });
}
