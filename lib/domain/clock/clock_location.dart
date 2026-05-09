import 'package:freezed_annotation/freezed_annotation.dart';

part 'clock_location.freezed.dart';

/// A user-pinned timezone location displayed on the world clock screen
/// (Phase 10.5).
///
/// Field invariants (enforced at construction sites in the application
/// layer — `ClockCollectionNotifier.addPreset` / `update`, not by this
/// freezed VO):
///   - `displayName.length >= 1 && displayName.length <= 30`
///   - `timezoneId` resolves via the IANA Time Zone Database
///     (`InvalidTimezoneIdException` otherwise — checked by the
///     `TimezoneResolver` adapter at render time, not at construction)
///   - `displayOrder >= 0 && displayOrder <= 5`
///   - `isCurrentLocation == true` for at most one entry across the
///     enclosing [ClockCollection] — enforced by the aggregate root
///     (`ClockCollection.add` / `update` demote any prior holder).
@freezed
class ClockLocation with _$ClockLocation {
  const factory ClockLocation({
    required String id,
    required String displayName,
    required String timezoneId,
    required bool isCurrentLocation,
    required int displayOrder,
    required DateTime createdAt,
  }) = _ClockLocation;
}
