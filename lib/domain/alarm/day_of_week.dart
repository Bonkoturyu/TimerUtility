/// Days of the week mapped 1:1 to `DateTime.weekday` values.
///
/// Pure Dart enum so it can live in `lib/domain/` without pulling
/// `package:flutter/*`. The numeric values mirror Dart's
/// `DateTime.weekday` (1 = Monday … 7 = Sunday) so conversions stay
/// trivial:
///
/// ```dart
/// final dow = DayOfWeek.fromWeekday(DateTime.now().weekday);
/// final weekday = DayOfWeek.monday.weekday;        // 1
/// ```
///
/// Used by [AlarmRepeatWeekly.days] to express "fire on Mon/Wed/Fri".
enum DayOfWeek {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);

  const DayOfWeek(this.weekday);

  /// 1..7 — same convention as `DateTime.weekday`.
  final int weekday;

  /// Inverse of [weekday]. Throws [ArgumentError] for values outside 1..7.
  static DayOfWeek fromWeekday(int weekday) {
    for (final DayOfWeek d in DayOfWeek.values) {
      if (d.weekday == weekday) return d;
    }
    throw ArgumentError.value(
      weekday,
      'weekday',
      'Must be in [1..7] (DateTime.weekday convention)',
    );
  }
}
