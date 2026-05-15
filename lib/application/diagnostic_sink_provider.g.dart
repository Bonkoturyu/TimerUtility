// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostic_sink_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$diagnosticSinkHash() => r'ffeaf28e9cc41eaf4042108bc8e926d3f5b02224';

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
///
/// Copied from [diagnosticSink].
@ProviderFor(diagnosticSink)
final diagnosticSinkProvider = Provider<DiagnosticSink>.internal(
  diagnosticSink,
  name: r'diagnosticSinkProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$diagnosticSinkHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiagnosticSinkRef = ProviderRef<DiagnosticSink>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
