/// Pure Dart formatter for [Duration] values.
///
/// Output formats:
///   - [formatStopwatch]  : `MM:SS.cc` (or `HH:MM:SS.cc` when hours > 0).
///   - [formatTimer]      : `MM:SS`    (or `HH:MM:SS`    when hours > 0).
///
/// Negative durations are clamped to zero.
class DurationFormatter {
  const DurationFormatter();

  /// Stopwatch display: minutes:seconds.centiseconds.
  String formatStopwatch(Duration duration) {
    final clamped = duration.isNegative ? Duration.zero : duration;
    final hours = clamped.inHours;
    final minutes = clamped.inMinutes.remainder(60);
    final seconds = clamped.inSeconds.remainder(60);
    final centiseconds = clamped.inMilliseconds.remainder(1000) ~/ 10;
    if (hours > 0) {
      return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}'
          '.${_two(centiseconds)}';
    }
    return '${_two(minutes)}:${_two(seconds)}.${_two(centiseconds)}';
  }

  /// Timer display: minutes:seconds (or hours:minutes:seconds).
  String formatTimer(Duration duration) {
    final clamped = duration.isNegative ? Duration.zero : duration;
    final hours = clamped.inHours;
    final minutes = clamped.inMinutes.remainder(60);
    final seconds = clamped.inSeconds.remainder(60);
    if (hours > 0) {
      return '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
    }
    return '${_two(minutes)}:${_two(seconds)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
