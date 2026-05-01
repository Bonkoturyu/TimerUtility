import '../../domain/ports/timer_repository.dart';
import '../../domain/timer/timer_entity.dart';
import 'app_database.dart';
import 'mappers/timer_mapper.dart';

/// Drift-backed [TimerRepository]. Uses upsert semantics keyed on
/// `TimerEntity.id` so the application layer can persist after every
/// state transition without a separate "create vs update" branch.
class DriftTimerRepository implements TimerRepository {
  DriftTimerRepository(this._db, {TimerMapper? mapper})
    : _mapper = mapper ?? const TimerMapper();

  final AppDatabase _db;
  final TimerMapper _mapper;

  @override
  Future<List<TimerEntity>> findAll() async {
    final List<TimerRow> rows = await _db.select(_db.timers).get();
    return rows.map(_mapper.toEntity).toList(growable: false);
  }

  @override
  Future<TimerEntity?> findById(String id) async {
    final TimerRow? row = await (_db.select(
      _db.timers,
    )..where(($TimersTable t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapper.toEntity(row);
  }

  @override
  Future<void> upsert(TimerEntity entity) async {
    await _db
        .into(_db.timers)
        .insertOnConflictUpdate(_mapper.toCompanion(entity));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(
      _db.timers,
    )..where(($TimersTable t) => t.id.equals(id))).go();
  }
}
