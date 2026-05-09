import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/exceptions.dart';

void main() {
  group('MaxClockLocationCountExceededException', () {
    test('toString includes the maxSize', () {
      const e = MaxClockLocationCountExceededException(6);
      expect(e.toString(), contains('6'));
      expect(e.toString(), contains('cannot exceed'));
    });
  });

  group('ClockLocationNotFoundException', () {
    test('toString includes the id', () {
      const e = ClockLocationNotFoundException('abc-123');
      expect(e.toString(), contains('abc-123'));
    });
  });

  group('InvalidTimezoneIdException', () {
    test('toString includes the timezone id', () {
      const e = InvalidTimezoneIdException('Foo/Bar');
      expect(e.toString(), contains('Foo/Bar'));
    });
  });
}
