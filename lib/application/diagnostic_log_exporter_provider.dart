import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/diagnostic_log_exporter.dart';

part 'diagnostic_log_exporter_provider.g.dart';

/// Provider for the diagnostic-log exporter. Phase D-3 binds the real
/// `ZipDiagnosticLogExporterAdapter`; Phase D-1 leaves the provider
/// unbound by default and the unit tests pass in a fake. The Settings
/// screen's "Share logs" action ends up here.
@Riverpod(keepAlive: true)
DiagnosticLogExporter diagnosticLogExporter(Ref ref) {
  throw UnimplementedError(
    'diagnosticLogExporterProvider must be overridden in main() once '
    'Phase D-3 wires up the zip + share_plus adapter (or in tests with '
    'a fake exporter).',
  );
}
