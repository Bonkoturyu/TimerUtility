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
    String? payload,
  });

  /// Show a notification immediately (no scheduling).
  ///
  /// Used by Phase 8 collection restore to surface a one-shot "timer
  /// ended while you were away" message for timers whose `endAt` was
  /// already in the past when the app came back. The OS heads-up
  /// notification fires with the same channel as `schedule()` so the
  /// user sees a consistent alarm-style banner.
  Future<void> show({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  });

  /// Cancel a previously scheduled notification by id. No-op if no such
  /// notification exists.
  Future<void> cancel(int notificationId);

  /// Cancel every scheduled / displayed notification owned by this app.
  Future<void> cancelAll();
}
