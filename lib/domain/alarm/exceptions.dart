/// Thrown when adding a new alarm would push past the configured
/// maximum (50 — see `docs/domain-model.md` Phase 9.5 section).
///
/// Caller (`AlarmCollectionNotifier.create`) is expected to surface
/// this as a SnackBar / banner rather than letting it bubble up.
class MaxAlarmCountExceededException implements Exception {
  const MaxAlarmCountExceededException(this.maxSize);

  final int maxSize;

  @override
  String toString() =>
      'MaxAlarmCountExceededException: cannot exceed $maxSize alarms';
}

/// Thrown when an operation references an `AlarmId` that is not in the
/// collection. Indicates either a stale UI reference or a bug, never
/// expected user input.
class AlarmNotFoundException implements Exception {
  const AlarmNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'AlarmNotFoundException: $id';
}

/// Thrown when an `AlarmRepeatWeekly` is constructed (or about to be
/// persisted) with an empty `days` set. The Pure-Dart factory
/// `AlarmRepeatWeekly.create` raises `ArgumentError` for this; the
/// application layer rewraps it as this domain-specific exception so
/// the UI can render a localized message instead of a generic stack
/// trace.
class InvalidAlarmRepeatException implements Exception {
  const InvalidAlarmRepeatException(this.message);

  final String message;

  @override
  String toString() => 'InvalidAlarmRepeatException: $message';
}

/// Thrown when `snoozeMinutes` is set to a value outside the allowed
/// preset list (5 / 10 / 15 — mirrored from `SnoozeCalculator`).
/// Surface boundary: `AlarmEntity` construction or `update` flows.
class InvalidSnoozeMinutesException implements Exception {
  const InvalidSnoozeMinutesException(this.snoozeMinutes);

  final int snoozeMinutes;

  @override
  String toString() =>
      'InvalidSnoozeMinutesException: $snoozeMinutes is not in {5, 10, 15}';
}
