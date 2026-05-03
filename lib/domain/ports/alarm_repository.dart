import '../alarm/alarm_entity.dart';

/// Port for [AlarmEntity] persistence (Phase 9.5).
///
/// Mirrors `TimerRepository`'s shape: implementations under
/// `infrastructure/database/` upsert by `entity.id`, so
/// `AlarmCollectionNotifier` can call `upsert` after every change
/// without diffing "is this new?".
abstract class AlarmRepository {
  /// Returns every persisted alarm regardless of `enabled` state.
  /// Caller (`AlarmCollectionNotifier.load`) is responsible for any
  /// follow-up restoration like re-scheduling enabled alarms.
  Future<List<AlarmEntity>> findAll();

  /// Loads a single alarm by id, or `null` if not found.
  Future<AlarmEntity?> findById(String id);

  /// Inserts a new row or updates the existing one keyed by
  /// `entity.id`. No diff detection — always rewrites.
  Future<void> upsert(AlarmEntity entity);

  /// Deletes an alarm by id. No-op if absent.
  Future<void> delete(String id);
}
