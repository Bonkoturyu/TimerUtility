// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diagnostic_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$diagnosticSettingsNotifierHash() =>
    r'94435ca083b0382e7339d59c47678b322d1cf022';

/// Persists the diagnostic-logging on/off toggle.
///
/// Initial value priority:
///   1. Stored preference (if the user has explicitly toggled it).
///   2. [defaultEnabled] from the constructor — wired in `main.dart`
///      to `!kReleaseMode` so debug builds opt in automatically while
///      release builds stay off until the user enables it.
///
/// The `defaultEnabled` indirection (vs. reading `kReleaseMode` here)
/// keeps the notifier testable: unit tests can drive both Debug and
/// Release defaults without compile-time flags.
///
/// Pattern mirrors [SettingsNotifier]: synchronous `build()` returns
/// the default so the UI can paint immediately, then a microtask
/// resolves the persisted value and replaces state.
///
/// Copied from [DiagnosticSettingsNotifier].
@ProviderFor(DiagnosticSettingsNotifier)
final diagnosticSettingsNotifierProvider =
    NotifierProvider<
      DiagnosticSettingsNotifier,
      DiagnosticSettingsState
    >.internal(
      DiagnosticSettingsNotifier.new,
      name: r'diagnosticSettingsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$diagnosticSettingsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DiagnosticSettingsNotifier = Notifier<DiagnosticSettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
