/// Thrown when adding a new clock entry would push
/// [ClockEntryCollection.size] past [ClockEntryCollection.maxSize].
///
/// The application layer is expected to surface this to the UI as a
/// SnackBar.
class MaxClockEntryCountExceededException implements Exception {
  const MaxClockEntryCountExceededException(this.maxSize);

  final int maxSize;

  @override
  String toString() =>
      'MaxClockEntryCountExceededException: cannot exceed $maxSize clock entries';
}

/// Thrown when an operation references a clock entry id that is not
/// in the collection. Indicates either a stale UI reference or a bug.
class ClockEntryNotFoundException implements Exception {
  const ClockEntryNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'ClockEntryNotFoundException: $id';
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
