import 'package:drift/drift.dart';

import '../../domain/ports/imported_sound_reference_store.dart';
import 'app_database.dart';

class DriftImportedSoundReferenceStore implements ImportedSoundReferenceStore {
  DriftImportedSoundReferenceStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> replaceReferencesAndDeleteMetadata({
    required String soundId,
    required String fallbackSoundId,
  }) => _db.transaction(() async {
    await (_db.update(_db.timers)
          ..where(($TimersTable table) => table.soundId.equals(soundId)))
        .write(TimersCompanion(soundId: Value<String?>(fallbackSoundId)));
    await (_db.update(_db.alarms)
          ..where(($AlarmsTable table) => table.soundId.equals(soundId)))
        .write(AlarmsCompanion(soundId: Value<String?>(fallbackSoundId)));
    await (_db.update(_db.presets)
          ..where(($PresetsTable table) => table.soundId.equals(soundId)))
        .write(PresetsCompanion(soundId: Value<String?>(fallbackSoundId)));
    await (_db.delete(
      _db.importedSounds,
    )..where(($ImportedSoundsTable table) => table.id.equals(soundId))).go();
  });
}
