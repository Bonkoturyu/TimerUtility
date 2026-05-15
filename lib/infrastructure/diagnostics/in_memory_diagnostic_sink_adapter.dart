import '../../domain/diagnostics/diagnostic_event.dart';
import '../../domain/ports/diagnostic_sink.dart';

/// In-memory [DiagnosticSink] used in Phase D-1 (no file deps yet) and
/// as a test fake thereafter. Recorded events are exposed read-only via
/// [events] so callers can assert which entries were captured.
class InMemoryDiagnosticSinkAdapter implements DiagnosticSink {
  InMemoryDiagnosticSinkAdapter();

  final List<DiagnosticEvent> _events = <DiagnosticEvent>[];

  /// Unmodifiable snapshot of the events written so far. Each call
  /// returns a fresh copy via [List.unmodifiable], so callers should
  /// re-read the getter after a [write] to see the new entry rather
  /// than holding the previous return value.
  List<DiagnosticEvent> get events =>
      List<DiagnosticEvent>.unmodifiable(_events);

  @override
  void write(DiagnosticEvent event) {
    _events.add(event);
  }

  @override
  Future<void> flush() async {
    // No-op: in-memory adapter holds nothing that needs to drain to a
    // backing store. Phase D-2's file adapter overrides this to flush
    // the IOSink.
  }

  /// Test-only: drop all recorded events.
  void clear() => _events.clear();
}
