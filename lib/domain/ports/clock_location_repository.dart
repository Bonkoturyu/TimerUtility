import '../clock/clock_location.dart';

/// Port for [ClockLocation] persistence (Phase 10.5).
///
/// Implementations live under `infrastructure/database/`. Adapters MUST
/// honour the entity's id as a primary key (upsert by id) so the
/// `ClockCollectionNotifier` can call `upsert` after every mutation
/// without juggling separate "is this new?" branches — same convention
/// as `PresetRepository` and `AlarmRepository`.
abstract class ClockLocationRepository {
  /// Returns every persisted clock location, ordered ascending by
  /// `displayOrder`. A fresh install returns an empty list — the
  /// "current location" entry is added at first launch by the
  /// notifier (via [LocationDetector]), not seeded by migration.
  Future<List<ClockLocation>> findAll();

  /// Loads a single clock location by id, or `null` if not found.
  Future<ClockLocation?> findById(String id);

  /// Inserts a new row or updates the existing one keyed by
  /// `entity.id`. No diff detection — always rewrites the row.
  Future<void> upsert(ClockLocation entity);

  /// Deletes a clock location by id. No-op if absent.
  Future<void> delete(String id);

  /// Atomically replace the entire clock location collection in one
  /// transaction so a partial failure can never leave the table in
  /// an inconsistent state.
  Future<void> replaceAll(List<ClockLocation> entities);
}
