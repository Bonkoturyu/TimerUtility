import '../timer/preset.dart';

/// Port for [Preset] persistence.
///
/// Implementations live under `infrastructure/database/`. Adapters MUST
/// honour the entity's id as a primary key (upsert by id) so the
/// `PresetCollectionNotifier` can call `upsert` after every mutation
/// without juggling separate "is this new?" branches.
abstract class PresetRepository {
  /// Returns every persisted preset in insertion order. The Phase 9
  /// migration seeds 6 entries on first launch, so a fresh install
  /// returns a non-empty list.
  Future<List<Preset>> findAll();

  /// Loads a single preset by id, or `null` if not found.
  Future<Preset?> findById(String id);

  /// Inserts a new row or updates the existing one keyed by
  /// `entity.id`. No diff detection — always rewrites the row.
  Future<void> upsert(Preset entity);

  /// Deletes a preset by id. No-op if absent.
  Future<void> delete(String id);

  /// Atomically replace the entire preset collection. Used by
  /// `replaceFromTemplate` when the user picks "overwrite": the old
  /// rows go away and the new templates land in a single transaction
  /// so a partial failure can never leave an inconsistent table.
  Future<void> replaceAll(List<Preset> entities);
}
