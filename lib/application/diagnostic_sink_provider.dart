import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/diagnostic_sink.dart';
import '../infrastructure/diagnostics/in_memory_diagnostic_sink_adapter.dart';

part 'diagnostic_sink_provider.g.dart';

/// Provider for the diagnostic-log sink.
///
/// Defaults to an [InMemoryDiagnosticSinkAdapter] so that existing
/// unit tests (which don't care about diagnostic logging) don't need to
/// override anything to instantiate notifiers that record events. The
/// logger's [DiagnosticLogger.isEnabled] gate keeps these default
/// in-memory sinks empty in disabled (release-default) state, so the
/// fallback is a true no-op.
///
/// Production wiring overrides this in `main()` with the same in-memory
/// adapter (Phase D-1) or the file-backed adapter (Phase D-2) so the
/// app can observe writes; the override is preserved even with this
/// default for clarity of intent.
@Riverpod(keepAlive: true)
DiagnosticSink diagnosticSink(Ref ref) => InMemoryDiagnosticSinkAdapter();
