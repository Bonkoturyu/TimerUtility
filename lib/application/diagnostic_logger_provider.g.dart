// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostic_logger_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$diagnosticLoggerHash() => r'ecdbef293b3da4cc11a193df62c8590a6813f55b';

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
///
/// Copied from [diagnosticLogger].
@ProviderFor(diagnosticLogger)
final diagnosticLoggerProvider = Provider<DiagnosticLogger>.internal(
  diagnosticLogger,
  name: r'diagnosticLoggerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$diagnosticLoggerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiagnosticLoggerRef = ProviderRef<DiagnosticLogger>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
