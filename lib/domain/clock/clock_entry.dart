import 'package:freezed_annotation/freezed_annotation.dart';

part 'clock_entry.freezed.dart';

/// A user-pinned timezone entry displayed on the world clock screen
/// (Phase 10.5; Phase 11 で `ClockLocation` から `ClockEntry` にリネーム)。
///
/// Field invariants (enforced at construction sites in the application
/// layer, not by this freezed VO):
///   - `displayName.length >= 1 && displayName.length <= 30`
///   - `timezoneId` resolves via the IANA Time Zone Database
///     (`InvalidTimezoneIdException` otherwise — checked by the
///     `TimezoneResolver` adapter at render time, not at construction)
///   - `displayOrder >= 0 && displayOrder <= 5`
///   - `isCurrentLocation == true` for at most one entry across the
///     enclosing [ClockEntryCollection] — enforced by the aggregate root
///     (`ClockEntryCollection.add` / `update` demote any prior holder).
///     フィールド名は GPS 由来の「現在地」概念を表すため Phase 11
///     リネームでも `isCurrentLocation` のまま据置。
@freezed
class ClockEntry with _$ClockEntry {
  const factory ClockEntry({
    required String id,
    required String displayName,
    required String timezoneId,
    required bool isCurrentLocation,
    required int displayOrder,
    required DateTime createdAt,
  }) = _ClockEntry;
}
