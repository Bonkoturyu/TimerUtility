import 'day_of_week.dart';

/// Repeat policy for an alarm. Sealed so callers must handle both
/// variants explicitly via Dart's exhaustive switch — adding a third
/// case (e.g. monthly) becomes a compile error at every call site.
///
/// Pure Dart, no freezed: the value is small and we want pattern-match
/// ergonomics (`switch (repeat) { case AlarmRepeatOnce(): ... }`)
/// without freezed's union boilerplate.
sealed class AlarmRepeat {
  const AlarmRepeat();
}

/// One-shot alarm. Fires once at the next occurrence of the
/// `AlarmEntity.targetTime` and then expects the caller to flip
/// `enabled` to false (handled by `AlarmService.advanceAfterFire`).
class AlarmRepeatOnce extends AlarmRepeat {
  const AlarmRepeatOnce();

  @override
  bool operator ==(Object other) => other is AlarmRepeatOnce;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'AlarmRepeatOnce()';
}

/// Weekly recurring alarm. [days] is the set of weekdays the alarm
/// fires on. Must contain 1..7 entries (empty set is rejected by
/// [AlarmRepeatWeekly.create]).
class AlarmRepeatWeekly extends AlarmRepeat {
  /// Use [AlarmRepeatWeekly.create] for validated construction; this
  /// constructor is `const`-able for tests / fixtures that already
  /// know the input is valid.
  const AlarmRepeatWeekly(this.days);

  /// Validates that [days] is non-empty before constructing. Throws
  /// `ArgumentError` for the empty set so the domain invariant
  /// "weekly alarms have at least one day" is enforced at the
  /// construction boundary (the same constraint is also surfaced as
  /// `InvalidAlarmRepeatException` at higher layers — see
  /// `AlarmCollectionNotifier`).
  factory AlarmRepeatWeekly.create(Set<DayOfWeek> days) {
    if (days.isEmpty) {
      throw ArgumentError.value(
        days,
        'days',
        'AlarmRepeatWeekly requires at least one day',
      );
    }
    // Defensive copy + unmodifiable so equality is value-based and
    // callers cannot mutate the set after construction.
    return AlarmRepeatWeekly(Set<DayOfWeek>.unmodifiable(days));
  }

  final Set<DayOfWeek> days;

  @override
  bool operator ==(Object other) {
    if (other is! AlarmRepeatWeekly) return false;
    if (other.days.length != days.length) return false;
    return other.days.containsAll(days);
  }

  @override
  int get hashCode => Object.hashAllUnordered(days);

  @override
  String toString() {
    final List<DayOfWeek> sorted = days.toList()
      ..sort((a, b) => a.weekday.compareTo(b.weekday));
    return 'AlarmRepeatWeekly($sorted)';
  }
}
