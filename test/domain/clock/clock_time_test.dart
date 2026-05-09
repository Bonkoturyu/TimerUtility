import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/clock_time.dart';

void main() {
  group('ClockTime', () {
    test('value equality (same fields → equal)', () {
      final a = ClockTime(
        now: DateTime.utc(2026, 5, 9, 12),
        timezoneId: 'Asia/Tokyo',
      );
      final b = ClockTime(
        now: DateTime.utc(2026, 5, 9, 12),
        timezoneId: 'Asia/Tokyo',
      );
      expect(a, equals(b));
    });

    test('different timezoneId breaks equality', () {
      final a = ClockTime(
        now: DateTime.utc(2026, 5, 9, 12),
        timezoneId: 'Asia/Tokyo',
      );
      final b = ClockTime(
        now: DateTime.utc(2026, 5, 9, 12),
        timezoneId: 'America/Los_Angeles',
      );
      expect(a, isNot(equals(b)));
    });

    test('copyWith updates timezoneId only', () {
      final original = ClockTime(
        now: DateTime.utc(2026, 5, 9, 12),
        timezoneId: 'Asia/Tokyo',
      );
      final copy = original.copyWith(timezoneId: 'America/Los_Angeles');
      expect(copy.now, original.now);
      expect(copy.timezoneId, 'America/Los_Angeles');
    });
  });
}
