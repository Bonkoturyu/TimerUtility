import 'package:freezed_annotation/freezed_annotation.dart';

import 'alarm_repeat.dart';
import 'time_of_day_value.dart';

part 'alarm_entity.freezed.dart';

/// A scheduled-time alarm (Phase 9.5). Separate Aggregate from
/// `TimerEntity` per ADR 0005.
///
/// Field invariants (enforced at construction sites in the application
/// layer — `AlarmCollectionNotifier.create` / `update`, not by this
/// freezed VO):
///   - `label.length <= 50`
///   - `snoozeMinutes ∈ {5, 10, 15}`
///     (`InvalidSnoozeMinutesException` otherwise)
///   - `notificationId` is in `[0, 0x7FFFFFFF]`, assigned at creation
///     by `NotificationIdGenerator`, immutable afterwards (matches
///     Timer's convention so the OS notification id space is shared)
///   - `repeat == AlarmRepeatWeekly` ⇒ `repeat.days` non-empty
///     (`InvalidAlarmRepeatException` otherwise)
///   - `soundId == null` means the alarm plays the catalog default;
///     unknown ids fall back to default rather than throw (same
///     forward-compatibility rule as `TimerEntity.soundId`)
///
/// Mutability semantics: the `enabled` flag is the user-facing on/off
/// toggle. Disabling cancels the OS notification but preserves the
/// entity (and its `notificationId`) so re-enabling reuses the same
/// id. Once a weekly alarm fires, `AlarmService.advanceAfterFire`
/// returns a copy with the same fields (the next-fire time is
/// recomputed by `nextFireAt` — not stored — so the entity stays
/// stable across firings); for `AlarmRepeatOnce`, advance flips
/// `enabled` to false.
@freezed
class AlarmEntity with _$AlarmEntity {
  const factory AlarmEntity({
    required String id,
    required int notificationId,
    required String label,
    required TimeOfDayValue targetTime,
    required AlarmRepeat repeat,
    required int snoozeMinutes,
    required bool enabled,
    required DateTime createdAt,
    String? soundId,
  }) = _AlarmEntity;
}
