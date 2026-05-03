import '../../domain/alarm/alarm_entity.dart';
import '../../domain/ports/alarm_repository.dart';
import 'app_database.dart';
import 'mappers/alarm_mapper.dart';

/// Drift-backed [AlarmRepository] (Phase 9.5)。
///
/// `entity.id` を主キーとした upsert セマンティクス。
/// `DriftTimerRepository` / `DriftPresetRepository` と同じ流儀で、
/// 「create か update か」の分岐を呼び出し側に持ち込まない。
class DriftAlarmRepository implements AlarmRepository {
  DriftAlarmRepository(this._db, {AlarmMapper? mapper})
    : _mapper = mapper ?? const AlarmMapper();

  final AppDatabase _db;
  final AlarmMapper _mapper;

  @override
  Future<List<AlarmEntity>> findAll() async {
    final List<AlarmRow> rows = await _db.select(_db.alarms).get();
    return rows.map(_mapper.toEntity).toList(growable: false);
  }

  @override
  Future<AlarmEntity?> findById(String id) async {
    final AlarmRow? row = await (_db.select(
      _db.alarms,
    )..where(($AlarmsTable t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapper.toEntity(row);
  }

  @override
  Future<void> upsert(AlarmEntity entity) async {
    await _db
        .into(_db.alarms)
        .insertOnConflictUpdate(_mapper.toCompanion(entity));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(
      _db.alarms,
    )..where(($AlarmsTable t) => t.id.equals(id))).go();
  }
}
