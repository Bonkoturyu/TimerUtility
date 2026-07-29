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

  /// Removes interrupted imports and reconciles deletion transactions.
  Future<void> recover() async {
    int failureCount = 0;

    try {
      final List<String> stagedTokens = await _fileStore.findStagedTokens();
      for (final String token in stagedTokens) {
        try {
          await _fileStore.discard(token);
        } catch (_) {
          failureCount++;
        }
      }
    } catch (_) {
      failureCount++;
    }

    try {
      final List<CommittedImportedSoundFile> committed = await _fileStore
          .findCommitted();
      for (final CommittedImportedSoundFile file in committed) {
        try {
          final metadata = await _repository.findById(file.soundId);
          if (metadata == null || metadata.format != file.format) {
            await _fileStore.delete(file.soundId, file.format);
          }
        } catch (_) {
          failureCount++;
        }
      }
    } catch (_) {
      failureCount++;
    }

    try {
      final List<QuarantinedImportedSoundFile> quarantined = await _fileStore
          .findQuarantined();
      for (final QuarantinedImportedSoundFile file in quarantined) {
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
    } catch (_) {
      failureCount++;
    }

    if (failureCount > 0) {
      throw ImportedSoundRecoveryException(failureCount);
    }
  }
}
