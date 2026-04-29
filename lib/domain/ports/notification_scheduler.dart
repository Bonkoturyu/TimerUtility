/// Port for scheduling and cancelling timer-end notifications.
///
/// The implementation lives in `infrastructure/notification/` and is wired
/// up via Riverpod. Domain / application code must not depend on
/// `flutter_local_notifications` directly.
abstract class NotificationScheduler {
  /// Schedule a notification to fire at the given absolute time.
  ///
  /// [exact] selects between an exact (Doze-bypassing) alarm and an
  /// inexact one. The caller decides based on permission state — when
  /// `SCHEDULE_EXACT_ALARM` is unavailable, pass `false` to fall back to
  /// the heads-up inexact alarm.
  Future<void> schedule({
    required int notificationId,
    required DateTime fireAt,
    required String title,
    required String body,
    required bool exact,
  });

  /// Cancel a previously scheduled notification by id. No-op if no such
  /// notification exists.
  Future<void> cancel(int notificationId);

  /// Cancel every scheduled / displayed notification owned by this app.
  Future<void> cancelAll();
}
