import '../sound/imported_sound.dart';

/// Persistence boundary for imported sound metadata.
///
/// File bytes are managed by a separate infrastructure adapter. Implementors
/// must preserve [ImportedSound.id] as the stable key used by Timer, Alarm,
/// Preset, and default settings.
abstract class ImportedSoundRepository {
  Future<List<ImportedSound>> findAll();
  Future<ImportedSound?> findById(String id);
  Future<ImportedSound?> findByContentHash(String contentHash);
  Future<void> upsert(ImportedSound sound);
  Future<void> delete(String id);
}
