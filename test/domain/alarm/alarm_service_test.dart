import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/alarm/alarm_repeat.dart';
import 'package:timer_utility/domain/alarm/alarm_service.dart';
import 'package:timer_utility/domain/alarm/day_of_week.dart';
import 'package:timer_utility/domain/alarm/time_of_day_value.dart';

AlarmEntity _alarm({
  required AlarmRepeat repeat,
  TimeOfDayValue? targetTime,
  bool enabled = true,
  int snoozeMinutes = 5,
}) {
  return AlarmEntity(
    id: 'alarm-1',
    notificationId: 1,
    label: '',
    targetTime: targetTime ?? const TimeOfDayValue.unsafe(hour: 7, minute: 0),
    repeat: repeat,
    snoozeMinutes: snoozeMinutes,
    enabled: enabled,
    createdAt: DateTime(2026, 5, 1),
  );
}

void main() {
  group('AlarmService.nextFireAt — once', () {
    test('targetTime in the future today → today', () {
      final now = DateTime(2026, 5, 4, 6, 0); // 06:00 Mon
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.nextFireAt(
        _alarm(
          repeat: const AlarmRepeatOnce(),
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        ),
      );
      expect(result, DateTime(2026, 5, 4, 7, 0));
    });

    test('targetTime already past today → tomorrow', () {
      final now = DateTime(2026, 5, 4, 8, 0); // 08:00 Mon
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.nextFireAt(
        _alarm(
          repeat: const AlarmRepeatOnce(),
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        ),
      );
      expect(result, DateTime(2026, 5, 5, 7, 0));
    });

    test('targetTime equal to now → tomorrow (boundary)', () {
      final now = DateTime(2026, 5, 4, 7, 0);
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.nextFireAt(
        _alarm(
          repeat: const AlarmRepeatOnce(),
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        ),
      );
      expect(result, DateTime(2026, 5, 5, 7, 0));
    });

    test('crosses month boundary correctly', () {
      // 2026-05-31 23:30, target 23:00 → next day = 2026-06-01.
      final now = DateTime(2026, 5, 31, 23, 30);
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.nextFireAt(
        _alarm(
          repeat: const AlarmRepeatOnce(),
          targetTime: const TimeOfDayValue.unsafe(hour: 23, minute: 0),
        ),
      );
      expect(result, DateTime(2026, 6, 1, 23, 0));
    });
  });

  group('AlarmService.nextFireAt — weekly', () {
    test('today is in days set and time is future → today', () {
      // 2026-05-04 is Monday.
      final now = DateTime(2026, 5, 4, 6, 0);
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.nextFireAt(
        _alarm(
          repeat: AlarmRepeatWeekly.create(<DayOfWeek>{DayOfWeek.monday}),
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        ),
      );
      expect(result, DateTime(2026, 5, 4, 7, 0));
    });

    test('today is in days set but time is past → next matching day', () {
      // Mon 09:00 with target 07:00 + days={Mon,Wed} → next is Wed.
      final now = DateTime(2026, 5, 4, 9, 0);
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.nextFireAt(
        _alarm(
          repeat: AlarmRepeatWeekly.create(<DayOfWeek>{
            DayOfWeek.monday,
            DayOfWeek.wednesday,
          }),
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        ),
      );
      expect(result, DateTime(2026, 5, 6, 7, 0));
    });

    test('today is not in days set → first future matching day', () {
      // Mon 06:00 + days={Wed} → 2026-05-06 (Wed).
      final now = DateTime(2026, 5, 4, 6, 0);
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.nextFireAt(
        _alarm(
          repeat: AlarmRepeatWeekly.create(<DayOfWeek>{DayOfWeek.wednesday}),
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        ),
      );
      expect(result, DateTime(2026, 5, 6, 7, 0));
    });

    test('weekly with single day set today (already past) wraps a week', () {
      // Mon 09:00 with target 07:00, days={Mon} → next Mon.
      final now = DateTime(2026, 5, 4, 9, 0);
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.nextFireAt(
        _alarm(
          repeat: AlarmRepeatWeekly.create(<DayOfWeek>{DayOfWeek.monday}),
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        ),
      );
      expect(result, DateTime(2026, 5, 11, 7, 0));
    });

    test('weekly with all 7 days behaves like daily', () {
      final now = DateTime(2026, 5, 4, 9, 0); // Mon, 09:00
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.nextFireAt(
        _alarm(
          repeat: AlarmRepeatWeekly.create(DayOfWeek.values.toSet()),
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        ),
      );
      // 07:00 today is past → 07:00 tomorrow.
      expect(result, DateTime(2026, 5, 5, 7, 0));
    });

    test('weekly across month boundary', () {
      // Sun 2026-05-31, days={Wed}, target 07:00 → Wed 2026-06-03.
      final now = DateTime(2026, 5, 31, 8, 0);
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.nextFireAt(
        _alarm(
          repeat: AlarmRepeatWeekly.create(<DayOfWeek>{DayOfWeek.wednesday}),
          targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 0),
        ),
      );
      expect(result, DateTime(2026, 6, 3, 7, 0));
    });
  });

  group('AlarmService.advanceAfterFire', () {
    test('once → enabled flips to false', () {
      final svc = AlarmService(Clock.fixed(DateTime(2026, 5, 4, 8)));
      final input = _alarm(repeat: const AlarmRepeatOnce(), enabled: true);
      final result = svc.advanceAfterFire(input);
      expect(result.enabled, isFalse);
    });

    test('weekly → enabled remains true', () {
      final svc = AlarmService(Clock.fixed(DateTime(2026, 5, 4, 8)));
      final input = _alarm(
        repeat: AlarmRepeatWeekly.create(<DayOfWeek>{DayOfWeek.monday}),
        enabled: true,
      );
      final result = svc.advanceAfterFire(input);
      expect(result.enabled, isTrue);
    });

    test('returns a fresh instance (no mutation)', () {
      final svc = AlarmService(Clock.fixed(DateTime(2026, 5, 4, 8)));
      final input = _alarm(repeat: const AlarmRepeatOnce(), enabled: true);
      final result = svc.advanceAfterFire(input);
      expect(identical(input, result), isFalse);
      // Confirm the original is unchanged (freezed entity is immutable
      // anyway, but assert anyway as a regression guard).
      expect(input.enabled, isTrue);
    });
  });

  group('AlarmService.snoozeUntil', () {
    test('returns now + snoozeMinutes', () {
      final now = DateTime(2026, 5, 4, 7, 30);
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.snoozeUntil(
        _alarm(repeat: const AlarmRepeatOnce(), snoozeMinutes: 10),
      );
      expect(result, DateTime(2026, 5, 4, 7, 40));
    });

    test('handles day rollover', () {
      final now = DateTime(2026, 5, 4, 23, 55);
      final svc = AlarmService(Clock.fixed(now));
      final result = svc.snoozeUntil(
        _alarm(repeat: const AlarmRepeatOnce(), snoozeMinutes: 15),
      );
      expect(result, DateTime(2026, 5, 5, 0, 10));
    });
  });
}
