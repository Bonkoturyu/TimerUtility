import 'package:drift/drift.dart';

import '../../domain/clock/clock_entry.dart';
import '../../domain/ports/clock_entry_repository.dart';
import 'app_database.dart';
import 'mappers/clock_entry_mapper.dart';

/// Drift-backed [ClockEntryRepository] (Phase 10.5、Phase 11 で
/// `clock_locations` → `clock_entries` リネーム)。
///
/// DriftPresetRepository と同じく `entity.id` を主キーとした upsert
/// セマンティクス。`findAll` は `displayOrder` 昇順で返す
/// (port doc の契約)。
class DriftClockEntryRepository implements ClockEntryRepository {
  DriftClockEntryRepository(this._db, {ClockEntryMapper? mapper})
    : _mapper = mapper ?? const ClockEntryMapper();

  final AppDatabase _db;
  final ClockEntryMapper _mapper;

  @override
  Future<List<ClockEntry>> findAll() async {
    final List<ClockEntryRow> rows =
        await (_db.select(_db.clockEntries)
              ..orderBy(<OrderClauseGenerator<$ClockEntriesTable>>[
                ($ClockEntriesTable t) =>
                    OrderingTerm(expression: t.displayOrder),
              ]))
            .get();
    return rows.map(_mapper.toEntity).toList(growable: false);
  }

  @override
  Future<ClockEntry?> findById(String id) async {
    final ClockEntryRow? row = await (_db.select(
      _db.clockEntries,
    )..where(($ClockEntriesTable t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapper.toEntity(row);
  }

  @override
  Future<void> upsert(ClockEntry entity) async {
    await _db
        .into(_db.clockEntries)
        .insertOnConflictUpdate(_mapper.toCompanion(entity));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(
      _db.clockEntries,
    )..where(($ClockEntriesTable t) => t.id.equals(id))).go();
  }

  /// Atomically replace the entire `clock_entries` table contents.
  /// transaction 内で delete → batch insert することで、部分失敗時に
  /// 「古い行が消えたが新しい行はまだ入っていない」という中間状態を
  /// 避ける (DriftPresetRepository.replaceAll と同パターン)。
  @override
  Future<void> replaceAll(List<ClockEntry> entities) async {
    await _db.transaction(() async {
      await _db.delete(_db.clockEntries).go();
      if (entities.isEmpty) return;
      await _db.batch((Batch b) {
        for (final ClockEntry e in entities) {
          b.insert(_db.clockEntries, _mapper.toCompanion(e));
        }
      });
    });
  }
}
