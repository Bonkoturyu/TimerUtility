import '../sound/imported_sound_format.dart';

/// Opaque reference to a temporary app-private copy.
///
/// [token] is a storage-generated identifier, never a URI or file path.
class StagedImportedSoundFile {
  const StagedImportedSoundFile({
    required this.token,
    required this.byteLength,
    required this.contentHash,
  });

  final String token;
  final int byteLength;
  final String contentHash;
}

class QuarantinedImportedSoundFile {
  const QuarantinedImportedSoundFile({
    required this.soundId,
    required this.format,
  });

  final String soundId;
  final ImportedSoundFormat format;
}

/// Manages imported sound bytes in app-private storage.
abstract class ImportedSoundFileStore {
  Future<StagedImportedSoundFile> stage({
    required Stream<List<int>> source,
    required int expectedByteLength,
  });

  Future<void> commit({
    required String token,
    required String soundId,
    required ImportedSoundFormat format,
  });

  Future<void> discard(String token);

  Future<void> delete(String soundId, ImportedSoundFormat format);

  /// Atomically moves a committed file into the deletion-pending area.
  Future<void> quarantine(String soundId, ImportedSoundFormat format);

  Future<void> restoreQuarantined(String soundId, ImportedSoundFormat format);

  Future<void> purgeQuarantined(String soundId, ImportedSoundFormat format);

  Future<List<QuarantinedImportedSoundFile>> findQuarantined();
}
