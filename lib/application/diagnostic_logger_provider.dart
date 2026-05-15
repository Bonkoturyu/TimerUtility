import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/diagnostics/diagnostic_event.dart';
import '../domain/diagnostics/diagnostic_logger.dart';
import 'diagnostic_settings_notifier.dart';
import 'diagnostic_sink_provider.dart';

part 'diagnostic_logger_provider.g.dart';

/// Builds the application-wide [DiagnosticLogger].
///
/// `isEnabled` is a thunk closing over `ref.read` of the settings
/// notifier so flipping the toggle in Settings takes effect on the very
/// next `log()` call without rebuilding this provider. The sink is
/// `ref.watch`-ed because the file adapter (Phase D-2) replaces the
/// in-memory one at startup and any future swap should propagate.
///
/// Threshold is fixed to [DiagnosticSeverity.debug] — the cheaper gate
/// is the master `isEnabled()` flag controlled by the user, and we want
/// timer-action breadcrumbs (debug-level) included whenever logging is
/// on. A higher floor can be re-introduced later if log volume becomes
/// an issue in the field.
@Riverpod(keepAlive: true)
DiagnosticLogger diagnosticLogger(Ref ref) {
  return DiagnosticLogger(
    sink: ref.watch(diagnosticSinkProvider),
    isEnabled: () => ref.read(diagnosticSettingsNotifierProvider).enabled,
    threshold: DiagnosticSeverity.debug,
  );
}
