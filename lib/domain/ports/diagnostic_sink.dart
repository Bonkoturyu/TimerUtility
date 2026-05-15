import '../diagnostics/diagnostic_event.dart';

/// Sink that records [DiagnosticEvent]s for the debug/diagnostic log.
///
/// Implementations live under `infrastructure/diagnostics/`. Phase D-1
/// ships an in-memory adapter only; Phase D-2 introduces the file-backed
/// adapter with daily rotation. Callers (the [DiagnosticLogger]) treat
/// [write] as fire-and-forget — implementations must not throw on
/// individual writes (failing to log must not crash the app).
///
/// [flush] is called from the AppLifecycle `detached` hook so the
/// file-backed adapter can flush buffered bytes before process death.
abstract class DiagnosticSink {
  void write(DiagnosticEvent event);

  Future<void> flush();
}
