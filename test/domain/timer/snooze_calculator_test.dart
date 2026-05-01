import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/snooze_calculator.dart';

void main() {
  group('SnoozeCalculator', () {
    test('3 分スヌーズで now + 3 分の絶対時刻を返す', () {
      final fixedNow = DateTime(2026, 5, 1, 7, 30);
      withClock(Clock.fixed(fixedNow), () {
        final calc = SnoozeCalculator(clock: clock);

        expect(calc.snoozeUntil(3), DateTime(2026, 5, 1, 7, 33));
      });
    });

    test('5 分スヌーズで now + 5 分の絶対時刻を返す', () {
      final fixedNow = DateTime(2026, 5, 1, 7, 30);
      withClock(Clock.fixed(fixedNow), () {
        final calc = SnoozeCalculator(clock: clock);

        expect(calc.snoozeUntil(5), DateTime(2026, 5, 1, 7, 35));
      });
    });

    test('10 分スヌーズで now + 10 分の絶対時刻を返す', () {
      final fixedNow = DateTime(2026, 5, 1, 7, 30);
      withClock(Clock.fixed(fixedNow), () {
        final calc = SnoozeCalculator(clock: clock);

        expect(calc.snoozeUntil(10), DateTime(2026, 5, 1, 7, 40));
      });
    });

    test('日付跨ぎでも正しく加算する', () {
      final fixedNow = DateTime(2026, 5, 1, 23, 55);
      withClock(Clock.fixed(fixedNow), () {
        final calc = SnoozeCalculator(clock: clock);

        expect(calc.snoozeUntil(10), DateTime(2026, 5, 2, 0, 5));
      });
    });

    test('プリセット外（1 分）は ArgumentError を throw する', () {
      withClock(Clock.fixed(DateTime(2026, 5, 1, 7, 30)), () {
        final calc = SnoozeCalculator(clock: clock);

        expect(() => calc.snoozeUntil(1), throwsArgumentError);
      });
    });

    test('プリセット外（0）は ArgumentError を throw する', () {
      withClock(Clock.fixed(DateTime(2026, 5, 1, 7, 30)), () {
        final calc = SnoozeCalculator(clock: clock);

        expect(() => calc.snoozeUntil(0), throwsArgumentError);
      });
    });

    test('プリセット外（負値）は ArgumentError を throw する', () {
      withClock(Clock.fixed(DateTime(2026, 5, 1, 7, 30)), () {
        final calc = SnoozeCalculator(clock: clock);

        expect(() => calc.snoozeUntil(-5), throwsArgumentError);
      });
    });

    test('allowedMinutes は {3, 5, 10} のみを含む', () {
      expect(SnoozeCalculator.allowedMinutes, <int>{3, 5, 10});
    });
  });
}
