// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostic_export_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$diagnosticExportControllerHash() =>
    r'e7acdaaefa66a3e152e3584a68ab5186cf64e455';

/// Drives the "Share logs" action from the Settings screen.
///
/// On [export]: idle → inProgress → (done | error). The autoDispose
/// scope is intentional: re-entering the Settings screen resets the
/// state to idle, so a stale `done(path)` from a previous session does
/// not flash a misleading SnackBar.
///
/// Copied from [DiagnosticExportController].
@ProviderFor(DiagnosticExportController)
final diagnosticExportControllerProvider =
    AutoDisposeNotifierProvider<
      DiagnosticExportController,
      DiagnosticExportState
    >.internal(
      DiagnosticExportController.new,
      name: r'diagnosticExportControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$diagnosticExportControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DiagnosticExportController =
    AutoDisposeNotifier<DiagnosticExportState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
