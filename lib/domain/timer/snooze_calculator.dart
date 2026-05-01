import 'package:clock/clock.dart';

/// Calculates the absolute time at which a snoozed alarm should re-fire.
///
/// Phase 7 ships a fixed three-preset model (3 / 5 / 10 minutes). Storing
/// snooze state on the timer (count, lastSnoozedAt, totalSnoozeDuration)
/// is intentionally deferred — the BACKLOG marks the "snooze count cap"
/// as optional, and we keep the entity slim until a concrete requirement
/// for it shows up.
class SnoozeCalculator {
  SnoozeCalculator({required Clock clock}) : _clock = clock;

  final Clock _clock;

  /// The user-selectable snooze durations in minutes. Anything outside
  /// this set is rejected at the domain boundary so UI bugs cannot leak
  /// through and produce arbitrary-length snoozes.
  static const Set<int> allowedMinutes = <int>{3, 5, 10};

  /// Returns the absolute fire time `now + snoozeMinutes`.
  ///
  /// Throws [ArgumentError] when [snoozeMinutes] is not one of
  /// [allowedMinutes].
  DateTime snoozeUntil(int snoozeMinutes) {
    if (!allowedMinutes.contains(snoozeMinutes)) {
      throw ArgumentError.value(
        snoozeMinutes,
        'snoozeMinutes',
        'must be one of $allowedMinutes',
      );
    }
    return _clock.now().add(Duration(minutes: snoozeMinutes));
  }
}
