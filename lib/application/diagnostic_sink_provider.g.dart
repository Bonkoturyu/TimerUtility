// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostic_sink_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$diagnosticSinkHash() => r'63c3140e0dcc7069a4a6b7e1b783598b85043c7a';

/// Provider for the diagnostic-log sink. Phase D-1 overrides this in
/// `main()` with `InMemoryDiagnosticSinkAdapter`; Phase D-2 swaps it
/// for the file-backed adapter. Tests override with a fake.
///
/// Throws by default so a missing override is loud rather than silent —
/// matches the [userPreferencesProvider] pattern.
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
