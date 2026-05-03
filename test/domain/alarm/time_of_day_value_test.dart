import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/alarm/time_of_day_value.dart';

void main() {
  group('TimeOfDayValue', () {
    test('valid construction', () {
      final t = TimeOfDayValue(hour: 7, minute: 30);
      expect(t.hour, 7);
      expect(t.minute, 30);
    });

    test('boundary values 00:00 and 23:59 are valid', () {
      expect(() => TimeOfDayValue(hour: 0, minute: 0), returnsNormally);
      expect(() => TimeOfDayValue(hour: 23, minute: 59), returnsNormally);
    });

    test('rejects out-of-range hour', () {
      expect(() => TimeOfDayValue(hour: -1, minute: 0), throwsArgumentError);
      expect(() => TimeOfDayValue(hour: 24, minute: 0), throwsArgumentError);
    });

    test('rejects out-of-range minute', () {
      expect(() => TimeOfDayValue(hour: 0, minute: -1), throwsArgumentError);
      expect(() => TimeOfDayValue(hour: 0, minute: 60), throwsArgumentError);
    });

    test('toMinutesFromMidnight', () {
      expect(
        const TimeOfDayValue.unsafe(hour: 0, minute: 0).toMinutesFromMidnight(),
        0,
      );
      expect(
        const TimeOfDayValue.unsafe(
          hour: 7,
          minute: 30,
        ).toMinutesFromMidnight(),
        450,
      );
      expect(
        const TimeOfDayValue.unsafe(
          hour: 23,
          minute: 59,
        ).toMinutesFromMidnight(),
        24 * 60 - 1,
      );
    });

    test('fromMinutesFromMidnight is the inverse', () {
      for (final int m in <int>[0, 1, 60, 450, 1439]) {
        final TimeOfDayValue t = TimeOfDayValue.fromMinutesFromMidnight(m);
        expect(t.toMinutesFromMidnight(), m);
      }
    });

    test('fromMinutesFromMidnight rejects out-of-range', () {
      expect(
        () => TimeOfDayValue.fromMinutesFromMidnight(-1),
        throwsArgumentError,
      );
      expect(
        () => TimeOfDayValue.fromMinutesFromMidnight(24 * 60),
        throwsArgumentError,
      );
    });

    test('value equality + hashCode', () {
      const a = TimeOfDayValue.unsafe(hour: 7, minute: 30);
      const b = TimeOfDayValue.unsafe(hour: 7, minute: 30);
      const c = TimeOfDayValue.unsafe(hour: 7, minute: 31);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
