import '../domain/ports/imported_sound_file_store.dart';
import '../domain/ports/imported_sound_repository.dart';

class ImportedSoundRecoveryException implements Exception {
  const ImportedSoundRecoveryException(this.failureCount);

  final int failureCount;

  @override
  String toString() =>
      'ImportedSoundRecoveryException(failureCount: $failureCount)';
}

class ImportedSoundRecoveryService {
  const ImportedSoundRecoveryService({
    required ImportedSoundRepository repository,
    required ImportedSoundFileStore fileStore,
  }) : _repository = repository,
       _fileStore = fileStore;

  final ImportedSoundRepository _repository;
  final ImportedSoundFileStore _fileStore;

  /// Restores pre-transaction quarantines and purges post-transaction ones.
  Future<void> recover() async {
    final quarantined = await _fileStore.findQuarantined();
    int failureCount = 0;
    for (final file in quarantined) {
      try {
        final metadata = await _repository.findById(file.soundId);
        if (metadata == null) {
          await _fileStore.purgeQuarantined(file.soundId, file.format);
        } else {
          await _fileStore.restoreQuarantined(file.soundId, file.format);
        }
      } catch (_) {
        // A permanently broken entry must not starve the remaining recovery
        // queue. Report the aggregate after every independent entry was tried.
        failureCount++;
      }
    }
    if (failureCount > 0) {
      throw ImportedSoundRecoveryException(failureCount);
    }
  }
}
