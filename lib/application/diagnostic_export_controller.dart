import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'diagnostic_log_exporter_provider.dart';

part 'diagnostic_export_controller.g.dart';

/// State of the "Share logs" action. Sealed so the UI's switch over the
/// four states is exhaustive at compile time.
sealed class DiagnosticExportState {
  const DiagnosticExportState();
}

final class DiagnosticExportIdle extends DiagnosticExportState {
  const DiagnosticExportIdle();

  @override
  bool operator ==(Object other) => other is DiagnosticExportIdle;

  @override
  int get hashCode => 0;
}

final class DiagnosticExportInProgress extends DiagnosticExportState {
  const DiagnosticExportInProgress();

  @override
  bool operator ==(Object other) => other is DiagnosticExportInProgress;

  @override
  int get hashCode => 1;
}

final class DiagnosticExportDone extends DiagnosticExportState {
  const DiagnosticExportDone(this.archivePath);
  final String archivePath;

  @override
  bool operator ==(Object other) =>
      other is DiagnosticExportDone && other.archivePath == archivePath;

  @override
  int get hashCode => archivePath.hashCode;
}

final class DiagnosticExportError extends DiagnosticExportState {
  const DiagnosticExportError(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      other is DiagnosticExportError && other.message == message;

  @override
  int get hashCode => message.hashCode;
}

/// Drives the "Share logs" action from the Settings screen.
///
/// On [export]: idle → inProgress → (done | error). The autoDispose
/// scope is intentional: re-entering the Settings screen resets the
/// state to idle, so a stale `done(path)` from a previous session does
/// not flash a misleading SnackBar.
@riverpod
class DiagnosticExportController extends _$DiagnosticExportController {
  @override
  DiagnosticExportState build() => const DiagnosticExportIdle();

  /// Bundle the logs and open the share sheet. Any exception during
  /// archive creation or share is captured as
  /// [DiagnosticExportError] — the Settings UI surfaces this via a
  /// SnackBar instead of letting it bubble into the Flutter error
  /// handler (which would also write a diagnostic event and create a
  /// loop on top of the failure).
  Future<void> export() async {
    state = const DiagnosticExportInProgress();
    try {
      final exporter = ref.read(diagnosticLogExporterProvider);
      final String path = await exporter.createArchive();
      await exporter.share(path);
      state = DiagnosticExportDone(path);
    } catch (e) {
      state = DiagnosticExportError(e.toString());
    }
  }

  /// Reset to idle (used by tests and by the SnackBar dismissal flow
  /// in Phase D-3).
  void reset() {
    state = const DiagnosticExportIdle();
  }
}
