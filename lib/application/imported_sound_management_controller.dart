import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sound/imported_sound.dart';
import '../domain/sound/imported_sound_policy.dart';
import 'imported_sound_deletion_controller.dart';
import 'imported_sound_import_service.dart';
import 'imported_sound_import_service_provider.dart';
import 'imported_sound_mutation_coordinator.dart';
import 'imported_sound_repository_provider.dart';

/// UI-facing state and mutations for the imported-sound management screen.
///
/// File selection, validation, persistence and reference replacement remain
/// in Application services. This controller only exposes their results as an
/// immutable list that presentation can observe and test.
final AsyncNotifierProvider<
  ImportedSoundManagementController,
  List<ImportedSound>
>
importedSoundManagementControllerProvider =
    AsyncNotifierProvider<
      ImportedSoundManagementController,
      List<ImportedSound>
    >(ImportedSoundManagementController.new);

class ImportedSoundManagementController
    extends AsyncNotifier<List<ImportedSound>> {
  @override
  Future<List<ImportedSound>> build() =>
      ref.read(importedSoundRepositoryProvider).findAll();

  Future<ImportedSound?> importOne() async {
    final ImportedSound? imported = await ref
        .read(importedSoundMutationCoordinatorProvider)
        .run(
          () => ref
              .read(importedSoundImportServiceProvider)
              .importOne(ImportedSoundPolicy.standard),
        );
    if (imported != null) await reload();
    return imported;
  }

  Future<PrepareImportedSoundResult?> prepareImport() => ref
      .read(importedSoundMutationCoordinatorProvider)
      .run(
        () => ref
            .read(importedSoundImportServiceProvider)
            .prepare(ImportedSoundPolicy.standard),
      );

  Future<ImportedSound> confirmImport(PreparedImportedSound prepared) async {
    final ImportedSound imported = await ref
        .read(importedSoundMutationCoordinatorProvider)
        .run(
          () => ref.read(importedSoundImportServiceProvider).confirm(prepared),
        );
    await reload();
    return imported;
  }

  Future<void> cancelImport(PreparedImportedSound prepared) => ref
      .read(importedSoundMutationCoordinatorProvider)
      .run(() => ref.read(importedSoundImportServiceProvider).cancel(prepared));

  String stagingTokenOf(PreparedImportedSound prepared) =>
      ref.read(importedSoundImportServiceProvider).stagingTokenOf(prepared);

  Future<void> rename(ImportedSound sound, String displayName) async {
    final ImportedSound renamed = sound.rename(displayName);
    await ref
        .read(importedSoundMutationCoordinatorProvider)
        .run(() => ref.read(importedSoundRepositoryProvider).upsert(renamed));
    await reload();
  }

  Future<void> delete(String soundId) async {
    await ref
        .read(importedSoundDeletionControllerProvider.notifier)
        .delete(soundId);
    await reload();
  }

  Future<void> reload() async {
    final List<ImportedSound> sounds = await ref
        .read(importedSoundRepositoryProvider)
        .findAll();
    state = AsyncData<List<ImportedSound>>(sounds);
  }
}
