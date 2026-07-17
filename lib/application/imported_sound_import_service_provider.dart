import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'imported_sound_import_service.dart';

/// Entry point for the file-picker based import transaction.
///
/// The production composition root supplies the platform adapters. Tests can
/// replace this with a deterministic service without registering channels.
final Provider<ImportedSoundImportService>
importedSoundImportServiceProvider = Provider<ImportedSoundImportService>(
  (Ref ref) => throw UnimplementedError(
    'importedSoundImportServiceProvider must be overridden in main() or tests.',
  ),
);
