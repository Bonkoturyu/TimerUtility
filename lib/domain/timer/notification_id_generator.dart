/// Maps a timer's UUID-style String id to a 31-bit positive integer suitable
/// for `flutter_local_notifications` notification IDs.
///
/// Phase 4 design: pure-Dart, deterministic, no persistence. The same
/// `timerId` always produces the same notification id within the same
/// Dart VM. Collision probability for the project's 10-timer cap is on
/// the order of 1e-8, which we accept.
///
/// In Phase 8 (Drift persistence), the produced `notificationId` is meant
/// to be stored alongside `TimerEntity` so we never have to recompute it
/// across SDK versions or app restarts.
class NotificationIdGenerator {
  const NotificationIdGenerator();

  /// Returns a stable 31-bit non-negative int derived from [timerId].
  int idFor(String timerId) => timerId.hashCode & 0x7FFFFFFF;
}
