import 'package:freezed_annotation/freezed_annotation.dart';

import 'timer_status.dart';

part 'timer_entity.freezed.dart';

/// A single timer instance with its full configuration and live state.
///
/// Field invariants (enforced in `TimerService`, not by this VO):
///   - `duration` is in (Duration.zero, Duration(hours: 99)]
///   - `label.length <= 50`
///   - `status == running`  ⇒ `endAt != null` and `pausedRemaining == null`
///   - `status == paused`   ⇒ `endAt == null` and `pausedRemaining != null`
///   - any other status     ⇒ both `endAt` and `pausedRemaining` are null
///   - `notificationId` is in `[0, 0x7FFFFFFF]`, assigned at creation by
///     `NotificationIdGenerator`, immutable afterwards.
///   - `soundId == null` means the timer plays the catalog's default sound;
///     a non-null value should match an entry in `AlarmSoundCatalog`, but
///     unknown ids must fall back to default rather than throw (so removing
///     a bundled sound across releases stays backwards compatible).
///
/// Phase 4 adds `notificationId`. Phase 5 adds `soundId`. `snooze` is
/// added in Phase 7.
@freezed
class TimerEntity with _$TimerEntity {
  const factory TimerEntity({
    required String id,
    required int notificationId,
    required String label,
    required Duration duration,
    required DateTime? endAt,
    required Duration? pausedRemaining,
    required TimerStatus status,
    required DateTime createdAt,
    String? soundId,
  }) = _TimerEntity;
}
