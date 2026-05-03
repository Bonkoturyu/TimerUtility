import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/alarm/alarm_repeat.dart';
import 'package:timer_utility/domain/alarm/day_of_week.dart';

void main() {
  group('AlarmRepeatOnce', () {
    test('two instances are equal and share hashCode', () {
      const a = AlarmRepeatOnce();
      const b = AlarmRepeatOnce();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('is distinguishable from AlarmRepeatWeekly', () {
      const AlarmRepeat once = AlarmRepeatOnce();
      final AlarmRepeat weekly = AlarmRepeatWeekly.create(<DayOfWeek>{
        DayOfWeek.monday,
      });
      expect(once == weekly, isFalse);
    });
  });

  group('AlarmRepeatWeekly.create', () {
    test('rejects empty days set', () {
      expect(
        () => AlarmRepeatWeekly.create(<DayOfWeek>{}),
        throwsArgumentError,
      );
    });

    test('preserves the day set (value-equality)', () {
      final w = AlarmRepeatWeekly.create(<DayOfWeek>{
        DayOfWeek.monday,
        DayOfWeek.wednesday,
        DayOfWeek.friday,
      });
      expect(w.days, <DayOfWeek>{
        DayOfWeek.friday,
        DayOfWeek.wednesday,
        DayOfWeek.monday,
      });
    });

    test('equality is order-independent on days', () {
      final a = AlarmRepeatWeekly.create(<DayOfWeek>{
        DayOfWeek.monday,
        DayOfWeek.friday,
      });
      final b = AlarmRepeatWeekly.create(<DayOfWeek>{
        DayOfWeek.friday,
        DayOfWeek.monday,
      });
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality on day set difference', () {
      final a = AlarmRepeatWeekly.create(<DayOfWeek>{DayOfWeek.monday});
      final b = AlarmRepeatWeekly.create(<DayOfWeek>{DayOfWeek.tuesday});
      expect(a == b, isFalse);
    });

    test('returned days set is unmodifiable', () {
      final w = AlarmRepeatWeekly.create(<DayOfWeek>{DayOfWeek.monday});
      expect(() => w.days.add(DayOfWeek.tuesday), throwsUnsupportedError);
    });
  });

  group('switch exhaustiveness', () {
    test('sealed pattern match covers both variants', () {
      String describe(AlarmRepeat r) => switch (r) {
        AlarmRepeatOnce() => 'once',
        AlarmRepeatWeekly() => 'weekly',
      };
      expect(describe(const AlarmRepeatOnce()), 'once');
      expect(
        describe(AlarmRepeatWeekly.create(<DayOfWeek>{DayOfWeek.sunday})),
        'weekly',
      );
    });
  });
}
