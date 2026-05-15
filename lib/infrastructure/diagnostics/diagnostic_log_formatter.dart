import 'dart:convert' show jsonEncode;

import '../../domain/diagnostics/diagnostic_event.dart';

/// Serializes a [DiagnosticEvent] to a single JSON-Lines record.
///
/// Output shape (one event per line, UTF-8, terminated with `\n`):
///
/// ```text
/// {"t":"2026-05-15T10:30:00.000Z","sev":"info","kind":"timerAction",
///  "timerId":"uuid-1","action":"start"}
/// ```
///
/// Envelope fields:
///   - `t`: occurredAt in ISO 8601 UTC (always trailing `Z` so external
///     parsers don't have to guess local offset). Non-UTC inputs are
///     normalized via `.toUtc()`.
///   - `sev`: [DiagnosticSeverity.name] (`debug` / `info` / `warning` /
///     `error`).
///   - `kind`: stable JSON kind string from [DiagnosticEvent.kind].
///
/// Variant fields come from [DiagnosticEvent.toJsonPayload] and are
/// merged into the envelope at the top level. This keeps the on-disk
/// format flat and grep-friendly.
class DiagnosticLogFormatter {
  const DiagnosticLogFormatter();

  /// Returns a single line ending in `\n`. The trailing newline lets
  /// the file sink concatenate writes without worrying about partial
  /// records when several events land in the same buffer flush.
  String format(DiagnosticEvent event) {
    final Map<String, Object?> record = <String, Object?>{
      't': event.occurredAt.toUtc().toIso8601String(),
      'sev': event.severity.name,
      'kind': event.kind,
      ...event.toJsonPayload(),
    };
    return '${jsonEncode(record)}\n';
  }
}
