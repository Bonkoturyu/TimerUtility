/// Thrown when adding a new timer would push [TimerCollection.size]
/// past [TimerCollection.maxSize].
///
/// Caller (`TimerCollectionNotifier.create`) is expected to surface
/// this to the UI as a SnackBar / banner rather than letting it bubble
/// up uncaught.
class MaxTimerCountExceededException implements Exception {
  const MaxTimerCountExceededException(this.maxSize);

  final int maxSize;

  @override
  String toString() =>
      'MaxTimerCountExceededException: cannot exceed $maxSize timers';
}

/// Thrown when an operation references a `TimerId` that is not in the
/// collection. Indicates either a stale UI reference or a bug, never
/// expected user input.
class TimerNotFoundException implements Exception {
  const TimerNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'TimerNotFoundException: $id';
}
