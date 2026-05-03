/// Pure-Dart "hour:minute" value object used by `AlarmEntity`.
///
/// `docs/domain-model.md` (Phase 9.5 section) describes
/// `targetTime: TimeOfDay`, but `material.TimeOfDay` lives in
/// `package:flutter/*` which the `lib/domain/` rule forbids. This
/// mirrors the same shape (24-hour hour 0..23, minute 0..59) without
/// the Flutter dependency. Presentation maps between this and
/// `material.TimeOfDay` at the layer boundary.
class TimeOfDayValue {
  /// Validating constructor. Throws [ArgumentError] for out-of-range
  /// values; callers in the application layer are responsible for
  /// catching and surfacing user-facing errors (the Entity itself
  /// stays free of UI concerns).
  TimeOfDayValue({required this.hour, required this.minute}) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'Must be in [0..23]');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'Must be in [0..59]');
    }
  }

  /// Trusts the inputs without validation. Reserved for places where
  /// the values were already validated upstream (e.g. Drift mapper
  /// reading from the database column where `_check` ran on insert).
  const TimeOfDayValue.unsafe({required this.hour, required this.minute});

  /// Inverse of [toMinutesFromMidnight].
  factory TimeOfDayValue.fromMinutesFromMidnight(int minutes) {
    if (minutes < 0 || minutes > 24 * 60 - 1) {
      throw ArgumentError.value(minutes, 'minutes', 'Must be in [0..1439]');
    }
    return TimeOfDayValue.unsafe(hour: minutes ~/ 60, minute: minutes % 60);
  }

  final int hour;
  final int minute;

  /// Convert to "minutes-from-midnight" — the canonical persistence
  /// form used by the Drift mapper. 0 = 00:00, 1439 = 23:59.
  int toMinutesFromMidnight() => hour * 60 + minute;

  @override
  bool operator ==(Object other) =>
      other is TimeOfDayValue && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() {
    final String hh = hour.toString().padLeft(2, '0');
    final String mm = minute.toString().padLeft(2, '0');
    return 'TimeOfDayValue($hh:$mm)';
  }
}
