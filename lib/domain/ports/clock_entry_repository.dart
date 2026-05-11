import '../clock/clock_entry.dart';

/// Port for [ClockEntry] persistence (Phase 10.5; Phase 11 で
/// `ClockLocationRepository` → `ClockEntryRepository` にリネーム)。
///
/// Implementations live under `infrastructure/database/`. Adapters MUST
/// honour the entity's id as a primary key (upsert by id) so the
/// `ClockEntryCollectionNotifier` can call `upsert` after every mutation
/// without juggling separate "is this new?" branches — same convention
/// as `PresetRepository` and `AlarmRepository`.
abstract class ClockEntryRepository {
  /// Returns every persisted clock entry, ordered ascending by
  /// `displayOrder`. A fresh install returns an empty list — the
  /// "current location" entry is added at first launch by the
  /// notifier (via [LocationDetector]), not seeded by migration.
  Future<List<ClockEntry>> findAll();

  /// Loads a single clock entry by id, or `null` if not found.
  Future<ClockEntry?> findById(String id);

  /// Inserts a new row or updates the existing one keyed by
  /// `entity.id`. No diff detection — always rewrites the row.
  Future<void> upsert(ClockEntry entity);

  /// Deletes a clock entry by id. No-op if absent.
  Future<void> delete(String id);

  /// Atomically replace the entire clock entry collection in one
  /// transaction so a partial failure can never leave the table in
  /// an inconsistent state.
  Future<void> replaceAll(List<ClockEntry> entities);
}
