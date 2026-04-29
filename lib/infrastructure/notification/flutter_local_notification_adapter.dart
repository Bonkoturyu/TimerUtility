import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/ports/notification_scheduler.dart';

/// Channel constants. Centralised here so callers don't repeat them and so
/// upgrades (Phase 6 fullScreenIntent) edit one place.
const String timerAlarmChannelId = 'timer_alarm';
const String timerAlarmChannelName = 'Timer Alarm';
const String timerAlarmChannelDescription = 'タイマー終了時のアラーム通知';

/// Concrete [NotificationScheduler] backed by `flutter_local_notifications`.
///
/// Phase 4 scope:
///   - schedule / cancel / cancelAll
///   - exact-vs-inexact toggle (`AndroidScheduleMode.exactAllowWhileIdle`
///     vs `AndroidScheduleMode.inexactAllowWhileIdle`) decided by the
///     caller based on permission state
///
/// Out of scope (later phases): fullScreenIntent (Phase 6), custom sound
/// (Phase 5), notification taps (Phase 5/6).
class FlutterLocalNotificationAdapter implements NotificationScheduler {
  FlutterLocalNotificationAdapter({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Initialise the plugin and create the timer alarm channel.
  ///
  /// Must be called before any `schedule()` call. Typically invoked from
  /// `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );
    await _plugin.initialize(initSettings);

    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        timerAlarmChannelId,
        timerAlarmChannelName,
        description: timerAlarmChannelDescription,
        importance: Importance.high,
        enableVibration: true,
        showBadge: false,
      ),
    );
  }

  @override
  Future<void> schedule({
    required int notificationId,
    required DateTime fireAt,
    required String title,
    required String body,
    required bool exact,
  }) async {
    final tz.TZDateTime scheduled = tz.TZDateTime.from(fireAt, tz.local);
    final AndroidScheduleMode mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          timerAlarmChannelId,
          timerAlarmChannelName,
          channelDescription: timerAlarmChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: mode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
