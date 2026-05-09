/// Thrown when adding a new clock location would push
/// [ClockCollection.size] past [ClockCollection.maxSize].
///
/// Caller (`ClockCollectionNotifier.addPreset` etc.) is expected to
/// surface this to the UI as a SnackBar.
class MaxClockLocationCountExceededException implements Exception {
  const MaxClockLocationCountExceededException(this.maxSize);

  final int maxSize;

  @override
  String toString() =>
      'MaxClockLocationCountExceededException: cannot exceed $maxSize clock locations';
}

/// Thrown when an operation references a clock location id that is not
/// in the collection. Indicates either a stale UI reference or a bug.
class ClockLocationNotFoundException implements Exception {
  const ClockLocationNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'ClockLocationNotFoundException: $id';
}

/// Thrown when [TimezoneResolver.computeAt] is given an id that is not
/// in the IANA Time Zone Database. The Infrastructure adapter wraps
/// `tz.LocationNotFoundException` into this Domain-level exception so
/// the application layer can react without knowing about the
/// `timezone` package.
class InvalidTimezoneIdException implements Exception {
  const InvalidTimezoneIdException(this.timezoneId);

  final String timezoneId;

  @override
  String toString() => 'InvalidTimezoneIdException: $timezoneId';
}
