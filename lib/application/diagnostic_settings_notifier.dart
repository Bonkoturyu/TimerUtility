import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/user_preferences.dart';
import 'user_preferences_provider.dart';

part 'diagnostic_settings_notifier.freezed.dart';
part 'diagnostic_settings_notifier.g.dart';

/// User-controlled state for the diagnostic logging feature.
///
/// Currently a single `enabled` flag — Phase D-3 may add a severity
/// threshold knob; until then the logger threshold is hard-coded to
/// `debug` in [diagnosticLoggerProvider].
@freezed
class DiagnosticSettingsState with _$DiagnosticSettingsState {
  const factory DiagnosticSettingsState({required bool enabled}) =
      _DiagnosticSettingsState;
}

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
@Riverpod(keepAlive: true)
class DiagnosticSettingsNotifier extends _$DiagnosticSettingsNotifier {
  /// Override at construction so tests can inject either default.
  /// Production wiring passes `!kReleaseMode` from `main.dart`.
  bool defaultEnabled = false;

  @override
  DiagnosticSettingsState build() {
    Future<void>.microtask(_restore);
    return DiagnosticSettingsState(enabled: defaultEnabled);
  }

  Future<void> _restore() async {
    // Wrapped in try/catch so unit tests that don't override the
    // user-preferences provider don't trip the keepAlive logger chain
    // (logger → settings build → _restore → prefs read). In production
    // both providers are always wired up in main(), so the catch never
    // fires there.
    try {
      final UserPreferences prefs = ref.read(userPreferencesProvider);
      final bool? stored = await prefs.getBool(
        UserPreferenceKeys.diagnosticLogEnabled,
      );
      state = DiagnosticSettingsState(enabled: stored ?? defaultEnabled);
    } on UnimplementedError {
      // userPreferencesProvider is the standard UnimplementedError
      // placeholder in unit tests; treat as "no stored override".
    }
  }

  /// Flip / set the toggle and persist immediately.
  Future<void> setEnabled(bool enabled) async {
    state = DiagnosticSettingsState(enabled: enabled);
    await ref
        .read(userPreferencesProvider)
        .setBool(UserPreferenceKeys.diagnosticLogEnabled, enabled);
  }

  /// Convenience for the Settings screen toggle (avoids a read at the
  /// call site to flip the current value).
  Future<void> toggle() => setEnabled(!state.enabled);
}
