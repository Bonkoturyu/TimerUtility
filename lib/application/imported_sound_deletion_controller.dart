import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'alarm_collection_notifier.dart';
import 'imported_sound_deletion_service.dart';
import 'imported_sound_file_store_provider.dart';
import 'imported_sound_mutation_coordinator.dart';
import 'imported_sound_reference_store_provider.dart';
import 'imported_sound_repository_provider.dart';
import 'preset_collection_notifier.dart';
import 'settings_notifier.dart';
import 'timer_collection_notifier.dart';
import 'user_preferences_provider.dart';

part 'imported_sound_deletion_controller.g.dart';

@Riverpod(keepAlive: true)
class ImportedSoundDeletionController
    extends _$ImportedSoundDeletionController {
  final Map<String, Future<ImportedSoundDeletionResult>> _inFlight =
      <String, Future<ImportedSoundDeletionResult>>{};

  @override
  void build() {}

  Future<ImportedSoundDeletionResult> delete(String soundId) {
    final Future<ImportedSoundDeletionResult>? existing = _inFlight[soundId];
    if (existing != null) return existing;

    late final Future<ImportedSoundDeletionResult> tracked;
    tracked = ref
        .read(importedSoundMutationCoordinatorProvider)
        .run(() => _deleteExclusively(soundId))
        .whenComplete(() {
          if (identical(_inFlight[soundId], tracked)) {
            _inFlight.remove(soundId);
          }
        });
    _inFlight[soundId] = tracked;
    return tracked;
  }

  Future<ImportedSoundDeletionResult> _deleteExclusively(String soundId) async {
    final ImportedSoundDeletionRegistry registry = ref.read(
      importedSoundDeletionRegistryProvider,
    );
    registry.markDeleting(soundId);

    try {
      final ImportedSoundDeletionResult result =
          await ImportedSoundDeletionService(
            repository: ref.read(importedSoundRepositoryProvider),
            referenceStore: ref.read(importedSoundReferenceStoreProvider),
            fileStore: ref.read(importedSoundFileStoreProvider),
            preferences: ref.read(userPreferencesProvider),
          ).delete(soundId);

      if (!result.deleted) {
        registry.clearDeleting(soundId);
        return result;
      }

      registry.markDeleted(soundId);
      ref
          .read(timerCollectionNotifierProvider.notifier)
          .reconcileDeletedSound(soundId);
      ref
          .read(alarmCollectionNotifierProvider.notifier)
          .reconcileDeletedSound(soundId);
      ref
          .read(presetCollectionNotifierProvider.notifier)
          .reconcileDeletedSound(soundId);
      ref
          .read(settingsNotifierProvider.notifier)
          .reconcileDeletedSound(soundId);
      return result;
    } catch (_) {
      registry.clearDeleting(soundId);
      rethrow;
    }
  }
}
