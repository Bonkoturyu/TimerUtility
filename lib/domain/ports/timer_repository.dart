import '../timer/timer_entity.dart';

/// Port for [TimerEntity] persistence.
///
/// Implementations live under `infrastructure/database/`. Adapters MUST
/// honour the entity's id as a primary key (upsert by id) so the
/// `TimerCollectionNotifier` can call `upsert` after every state
/// transition without juggling separate "is this new?" branches.
abstract class TimerRepository {
  /// Returns every persisted timer in any state (idle / running /
  /// paused / ringing / completed / cancelled). Caller is responsible
  /// for any subsequent restoration logic — the repository does not
  /// drop terminal states on its own.
  Future<List<TimerEntity>> findAll();

  /// Loads a single timer by id, or `null` if not found.
  Future<TimerEntity?> findById(String id);

  /// Inserts a new row or updates the existing one keyed by
  /// `entity.id`. No diff detection — always rewrites the row.
  Future<void> upsert(TimerEntity entity);

  /// Deletes a timer by id. No-op if absent.
  Future<void> delete(String id);
}
