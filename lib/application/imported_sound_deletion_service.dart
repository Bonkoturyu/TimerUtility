import '../domain/ports/imported_sound_file_store.dart';
import '../domain/ports/imported_sound_reference_store.dart';
import '../domain/ports/imported_sound_repository.dart';
import '../domain/ports/user_preferences.dart';
import '../domain/timer/alarm_sound_catalog.dart';

class ImportedSoundDeletionResult {
  const ImportedSoundDeletionResult({
    required this.deleted,
    required this.defaultSettingChanged,
    required this.preferenceRepairPending,
    required this.cleanupPending,
  });

  final bool deleted;
  final bool defaultSettingChanged;
  final bool preferenceRepairPending;
  final bool cleanupPending;
}

/// Coordinates SharedPreferences, app-private bytes, and the Drift
/// transaction as a recoverable deletion saga.
class ImportedSoundDeletionService {
  ImportedSoundDeletionService({
    required ImportedSoundRepository repository,
    required ImportedSoundReferenceStore referenceStore,
    required ImportedSoundFileStore fileStore,
    required UserPreferences preferences,
  }) : _repository = repository,
       _referenceStore = referenceStore,
       _fileStore = fileStore,
       _preferences = preferences;

  final ImportedSoundRepository _repository;
  final ImportedSoundReferenceStore _referenceStore;
  final ImportedSoundFileStore _fileStore;
  final UserPreferences _preferences;

  Future<ImportedSoundDeletionResult> delete(String soundId) async {
    final sound = await _repository.findById(soundId);
    if (sound == null) {
      final bool cleanupPending = await _retryPendingCleanup(soundId);
      return ImportedSoundDeletionResult(
        deleted: false,
        defaultSettingChanged: false,
        preferenceRepairPending: false,
        cleanupPending: cleanupPending,
      );
    }

    final String fallbackId = AlarmSoundCatalog.defaultSound.id;
    final String? previousDefault = await _preferences.getString(
      UserPreferenceKeys.defaultAlarmSoundId,
    );
    final bool defaultSettingChanged = previousDefault == soundId;

    await _fileStore.quarantine(sound.id, sound.format);

    try {
      await _referenceStore.replaceReferencesAndDeleteMetadata(
        soundId: sound.id,
        fallbackSoundId: fallbackId,
      );
    } catch (_) {
      try {
        await _fileStore.restoreQuarantined(sound.id, sound.format);
      } catch (_) {
        // Startup recovery restores the quarantine while metadata remains.
      }
      rethrow;
    }

    bool preferenceRepairPending = false;
    if (defaultSettingChanged) {
      try {
        await _preferences.setString(
          UserPreferenceKeys.defaultAlarmSoundId,
          fallbackId,
        );
      } catch (_) {
        // The DB transaction is already committed and must not be rolled back.
        // Settings restoration validates the stored id and repairs this value
        // on the next launch; the controller also reconciles in-memory state.
        preferenceRepairPending = true;
      }
    }

    bool cleanupPending = false;
    try {
      await _fileStore.purgeQuarantined(sound.id, sound.format);
    } catch (_) {
      // DB references and metadata are already atomically removed. Leaving
      // the quarantined file is safe; startup recovery will purge it.
      cleanupPending = true;
    }
    return ImportedSoundDeletionResult(
      deleted: true,
      defaultSettingChanged: defaultSettingChanged,
      preferenceRepairPending: preferenceRepairPending,
      cleanupPending: cleanupPending,
    );
  }

  Future<bool> _retryPendingCleanup(String soundId) async {
    bool cleanupPending = false;
    final quarantined = await _fileStore.findQuarantined();
    for (final file in quarantined) {
      if (file.soundId != soundId) continue;
      try {
        await _fileStore.purgeQuarantined(file.soundId, file.format);
      } catch (_) {
        cleanupPending = true;
      }
    }
    return cleanupPending;
  }
}
