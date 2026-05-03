import 'package:clock/clock.dart';

import 'alarm_entity.dart';
import 'alarm_repeat.dart';
import 'day_of_week.dart';
import 'time_of_day_value.dart';

/// Pure-Dart domain service for [AlarmEntity] arithmetic.
///
/// All time-dependent logic lives here so the application layer
/// (`AlarmCollectionNotifier`) just orchestrates between the service,
/// the repository, and the `NotificationScheduler` port. `Clock` is
/// injected so tests can pin "now" and exercise day-rollover edge
/// cases without `fake_async` hacks.
///
/// All methods are side-effect free; they return new values. The
/// notifier is responsible for persistence and OS notification calls.
class AlarmService {
  const AlarmService(this._clock);

  final Clock _clock;

  /// Compute the absolute wall-clock time the alarm should fire at
  /// next, given the current `Clock.now()`.
  ///
  /// - `AlarmRepeatOnce`: today's `targetTime` if still in the future
  ///   (strictly greater than now); otherwise tomorrow's `targetTime`.
  /// - `AlarmRepeatWeekly`: the soonest day in `repeat.days` that is
  ///   either today (with `targetTime` still in the future) or a
  ///   later weekday. Loops across week boundaries, so an alarm only
  ///   set for Monday at 07:00, evaluated on Tuesday 09:00, returns
  ///   *next* Monday at 07:00.
  ///
  /// Boundary semantics: when "now" lands exactly on `targetTime`
  /// the next firing is one period later (not "now"). This matches
  /// what users intuit for repeating alarms — once it fired, the
  /// next slot is the *next* occurrence.
  DateTime nextFireAt(AlarmEntity alarm) {
    final DateTime now = _clock.now();
    return switch (alarm.repeat) {
      AlarmRepeatOnce() => _nextOnceFireAt(now, alarm.targetTime),
      AlarmRepeatWeekly(days: final Set<DayOfWeek> days) => _nextWeeklyFireAt(
        now,
        alarm.targetTime,
        days,
      ),
    };
  }

  /// Apply the post-fire state transition.
  ///
  /// - `AlarmRepeatOnce`: the alarm is single-shot, so `enabled`
  ///   flips to `false`. The notifier persists this and *does not*
  ///   re-schedule.
  /// - `AlarmRepeatWeekly`: `enabled` is preserved; the notifier
  ///   computes a new `nextFireAt` and reschedules.
  ///
  /// Always returns a fresh entity copy (no in-place mutation).
  AlarmEntity advanceAfterFire(AlarmEntity alarm) {
    return switch (alarm.repeat) {
      AlarmRepeatOnce() => alarm.copyWith(enabled: false),
      AlarmRepeatWeekly() => alarm,
    };
  }

  /// Compute the absolute time a snooze should re-arm to: `now +
  /// alarm.snoozeMinutes`. Pure addition — no rounding to the next
  /// minute, no day boundary handling needed (DateTime arithmetic
  /// already handles roll-over).
  DateTime snoozeUntil(AlarmEntity alarm) {
    return _clock.now().add(Duration(minutes: alarm.snoozeMinutes));
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  DateTime _nextOnceFireAt(DateTime now, TimeOfDayValue target) {
    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
      target.hour,
      target.minute,
    );
    if (today.isAfter(now)) return today;
    // strictly past or equal → tomorrow.
    return today.add(const Duration(days: 1));
  }

  DateTime _nextWeeklyFireAt(
    DateTime now,
    TimeOfDayValue target,
    Set<DayOfWeek> days,
  ) {
    // Try today first (only if the time is still in the future and
    // today is one of the selected weekdays). Then walk forward day
    // by day for up to 7 days; the set is non-empty so a hit is
    // guaranteed within that window.
    for (int offset = 0; offset < 8; offset++) {
      final DateTime candidate = DateTime(
        now.year,
        now.month,
        now.day + offset,
        target.hour,
        target.minute,
      );
      if (!candidate.isAfter(now)) continue;
      if (days.contains(DayOfWeek.fromWeekday(candidate.weekday))) {
        return candidate;
      }
    }
    // Unreachable: a non-empty Set<DayOfWeek> guarantees a match
    // within 8 calendar days. The throw is defensive against a
    // future regression that would let an empty set leak in.
    throw StateError('AlarmService: no matching day in 8-day window');
  }
}
