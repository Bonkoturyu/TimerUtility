import 'package:drift/drift.dart';

import '../../domain/ports/preset_repository.dart';
import '../../domain/timer/preset.dart';
import 'app_database.dart';
import 'mappers/preset_mapper.dart';

/// Drift-backed [PresetRepository]. Mirrors the upsert-by-id semantics
/// of `DriftTimerRepository` so the application layer can persist after
/// every mutation without juggling a "create vs update" branch.
class DriftPresetRepository implements PresetRepository {
  DriftPresetRepository(this._db, {PresetMapper? mapper})
    : _mapper = mapper ?? const PresetMapper();

  final AppDatabase _db;
  final PresetMapper _mapper;

  @override
  Future<List<Preset>> findAll() async {
    final List<PresetRow> rows = await _db.select(_db.presets).get();
    return rows.map(_mapper.toEntity).toList(growable: false);
  }

  @override
  Future<Preset?> findById(String id) async {
    final PresetRow? row = await (_db.select(
      _db.presets,
    )..where(($PresetsTable t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapper.toEntity(row);
  }

  @override
  Future<void> upsert(Preset entity) async {
    await _db
        .into(_db.presets)
        .insertOnConflictUpdate(_mapper.toCompanion(entity));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(
      _db.presets,
    )..where(($PresetsTable t) => t.id.equals(id))).go();
  }

  /// Atomically replace the entire `presets` table contents. Used by
  /// "Replace from template" → Overwrite. The transaction prevents an
  /// intermediate state where some old rows are gone but the new
  /// templates haven't landed yet.
  @override
  Future<void> replaceAll(List<Preset> entities) async {
    await _db.transaction(() async {
      await _db.delete(_db.presets).go();
      if (entities.isEmpty) return;
      await _db.batch((Batch b) {
        for (final Preset e in entities) {
          b.insert(_db.presets, _mapper.toCompanion(e));
        }
      });
    });
  }
}
