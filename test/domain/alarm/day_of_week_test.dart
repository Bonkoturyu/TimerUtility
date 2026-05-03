import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/alarm/day_of_week.dart';

void main() {
  group('DayOfWeek', () {
    test('weekday values are 1..7 mirroring DateTime.weekday', () {
      expect(DayOfWeek.monday.weekday, 1);
      expect(DayOfWeek.tuesday.weekday, 2);
      expect(DayOfWeek.wednesday.weekday, 3);
      expect(DayOfWeek.thursday.weekday, 4);
      expect(DayOfWeek.friday.weekday, 5);
      expect(DayOfWeek.saturday.weekday, 6);
      expect(DayOfWeek.sunday.weekday, 7);
    });

    test('fromWeekday is the inverse of .weekday', () {
      for (final DayOfWeek d in DayOfWeek.values) {
        expect(DayOfWeek.fromWeekday(d.weekday), d);
      }
    });

    test('fromWeekday throws for out-of-range values', () {
      expect(() => DayOfWeek.fromWeekday(0), throwsArgumentError);
      expect(() => DayOfWeek.fromWeekday(8), throwsArgumentError);
      expect(() => DayOfWeek.fromWeekday(-1), throwsArgumentError);
    });

    test('round-trips through DateTime.weekday', () {
      // Monday 2026-05-04 — pick deterministic weekdays for the loop.
      final DateTime monday = DateTime(2026, 5, 4);
      for (int offset = 0; offset < 7; offset++) {
        final DateTime d = monday.add(Duration(days: offset));
        expect(DayOfWeek.fromWeekday(d.weekday).weekday, d.weekday);
      }
    });
  });
}
