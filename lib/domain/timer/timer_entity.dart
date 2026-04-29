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
///
/// Phase 4 adds `notificationId`. `alarmSound` and `snooze` are added in
/// Phases 5 / 7 respectively.
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
  }) = _TimerEntity;
}
