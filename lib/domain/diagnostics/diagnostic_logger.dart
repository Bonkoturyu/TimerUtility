import '../ports/diagnostic_sink.dart';
import 'diagnostic_event.dart';

/// Pure-Dart domain service that gates [DiagnosticEvent]s on the
/// enabled flag and severity threshold before forwarding to [sink].
///
/// [isEnabled] is a thunk rather than a `bool` so the logger picks up
/// flips of the user-facing toggle without having to be rebuilt — the
/// Application-layer provider closes over `ref.read` of the settings
/// notifier and re-evaluates on every [log] call.
///
/// [threshold] is the minimum severity that survives. Events strictly
/// below `threshold.index` are dropped silently (debug builds typically
/// use [DiagnosticSeverity.debug]; release builds can be tightened to
/// `.info` later if the file size becomes an issue).
class DiagnosticLogger {
  const DiagnosticLogger({
    required this.sink,
    required this.isEnabled,
    required this.threshold,
  });

  final DiagnosticSink sink;
  final bool Function() isEnabled;
  final DiagnosticSeverity threshold;

  /// Record [event] if the logger is currently enabled and the event
  /// meets [threshold]. Fire-and-forget; never throws.
  void log(DiagnosticEvent event) {
    if (!isEnabled()) return;
    if (event.severity.index < threshold.index) return;
    sink.write(event);
  }
}
