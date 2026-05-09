import 'package:drift/drift.dart';

import '../../domain/clock/clock_location.dart';
import '../../domain/ports/clock_location_repository.dart';
import 'app_database.dart';
import 'mappers/clock_location_mapper.dart';

/// Drift-backed [ClockLocationRepository] (Phase 10.5)。
///
/// DriftPresetRepository と同じく `entity.id` を主キーとした upsert
/// セマンティクス。`findAll` は `displayOrder` 昇順で返す
/// (port doc の契約)。
class DriftClockLocationRepository implements ClockLocationRepository {
  DriftClockLocationRepository(this._db, {ClockLocationMapper? mapper})
    : _mapper = mapper ?? const ClockLocationMapper();

  final AppDatabase _db;
  final ClockLocationMapper _mapper;

  @override
  Future<List<ClockLocation>> findAll() async {
    final List<ClockLocationRow> rows =
        await (_db.select(_db.clockLocations)
              ..orderBy(<OrderClauseGenerator<$ClockLocationsTable>>[
                ($ClockLocationsTable t) =>
                    OrderingTerm(expression: t.displayOrder),
              ]))
            .get();
    return rows.map(_mapper.toEntity).toList(growable: false);
  }

  @override
  Future<ClockLocation?> findById(String id) async {
    final ClockLocationRow? row = await (_db.select(
      _db.clockLocations,
    )..where(($ClockLocationsTable t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapper.toEntity(row);
  }

  @override
  Future<void> upsert(ClockLocation entity) async {
    await _db
        .into(_db.clockLocations)
        .insertOnConflictUpdate(_mapper.toCompanion(entity));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(
      _db.clockLocations,
    )..where(($ClockLocationsTable t) => t.id.equals(id))).go();
  }

  /// Atomically replace the entire `clock_locations` table contents.
  /// transaction 内で delete → batch insert することで、部分失敗時に
  /// 「古い行が消えたが新しい行はまだ入っていない」という中間状態を
  /// 避ける (DriftPresetRepository.replaceAll と同パターン)。
  @override
  Future<void> replaceAll(List<ClockLocation> entities) async {
    await _db.transaction(() async {
      await _db.delete(_db.clockLocations).go();
      if (entities.isEmpty) return;
      await _db.batch((Batch b) {
        for (final ClockLocation e in entities) {
          b.insert(_db.clockLocations, _mapper.toCompanion(e));
        }
      });
    });
  }
}
