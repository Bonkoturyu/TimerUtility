/// OS boundary for drift-free, repeating timer notifications.
///
/// Implementations must keep scheduling while the Flutter process is absent.
/// Each firing is a short notification sound; it must not launch the regular
/// alarm-ringing flow or stop the continuous timer measurement.
abstract class IntervalNotificationScheduler {
  Future<void> schedule({
    required int notificationId,
    required DateTime firstFireAt,
    required Duration interval,
    required String title,
    required String body,
    required bool exact,
    required String payload,
  });

  Future<void> cancel(int notificationId);
}
