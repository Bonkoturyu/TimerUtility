// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostic_log_exporter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$diagnosticLogExporterHash() =>
    r'd2e9aec3f12c6b493e34f81fbc25e9362141e940';

/// Provider for the diagnostic-log exporter. Phase D-3 binds the real
/// `ZipDiagnosticLogExporterAdapter`; Phase D-1 leaves the provider
/// unbound by default and the unit tests pass in a fake. The Settings
/// screen's "Share logs" action ends up here.
///
/// Copied from [diagnosticLogExporter].
@ProviderFor(diagnosticLogExporter)
final diagnosticLogExporterProvider = Provider<DiagnosticLogExporter>.internal(
  diagnosticLogExporter,
  name: r'diagnosticLogExporterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$diagnosticLogExporterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiagnosticLogExporterRef = ProviderRef<DiagnosticLogExporter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
