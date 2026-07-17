import 'package:drift/drift.dart';

import '../../domain/ports/imported_sound_repository.dart';
import '../../domain/sound/imported_sound.dart';
import 'app_database.dart';
import 'mappers/imported_sound_mapper.dart';

/// Drift-backed imported sound metadata repository (Phase 13).
class DriftImportedSoundRepository implements ImportedSoundRepository {
  DriftImportedSoundRepository(this._db, {ImportedSoundMapper? mapper})
    : _mapper = mapper ?? const ImportedSoundMapper();

  final AppDatabase _db;
  final ImportedSoundMapper _mapper;

  @override
  Future<List<ImportedSound>> findAll() async {
    final List<ImportedSoundRow> rows =
        await (_db.select(_db.importedSounds)
              ..orderBy(<OrderClauseGenerator<$ImportedSoundsTable>>[
                ($ImportedSoundsTable table) =>
                    OrderingTerm(expression: table.createdAtUtcMs),
              ]))
            .get();
    return rows.map(_mapper.toEntity).toList(growable: false);
  }

  @override
  Future<ImportedSound?> findById(String id) async {
    final ImportedSoundRow? row =
        await (_db.select(_db.importedSounds)
              ..where(($ImportedSoundsTable table) => table.id.equals(id)))
            .getSingleOrNull();
    return row == null ? null : _mapper.toEntity(row);
  }

  @override
  Future<ImportedSound?> findByContentHash(String contentHash) async {
    final ImportedSoundRow? row =
        await (_db.select(_db.importedSounds)..where(
              ($ImportedSoundsTable table) =>
                  table.contentHash.equals(contentHash),
            ))
            .getSingleOrNull();
    return row == null ? null : _mapper.toEntity(row);
  }

  @override
  Future<void> upsert(ImportedSound sound) async {
    await _db
        .into(_db.importedSounds)
        .insertOnConflictUpdate(_mapper.toCompanion(sound));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(
      _db.importedSounds,
    )..where(($ImportedSoundsTable table) => table.id.equals(id))).go();
  }
}
