import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/ports/notification_scheduler.dart';
import '../platform/permission_channel.dart';

/// Channel constants. Centralised here so callers don't repeat them.
///
/// Channel id bumps (`_v2`, `_v3`, …) are intentional: Android does not let
/// an app re-configure an existing channel's importance / sound / vibration
/// after it's been created. Each id bump bundles a delete + recreate so the
/// new settings actually take effect on devices that already had an older
/// channel.
const List<String> _legacyTimerAlarmChannelIds = <String>[
  'timer_alarm',
  'timer_alarm_v2',
  'timer_alarm_v3',
];
const String timerAlarmChannelId = 'timer_alarm_v4';
const String timerAlarmChannelName = 'Timer Alarm';
const String timerAlarmChannelDescription = 'タイマー終了時のアラーム通知';

/// Silent channel used by [show] for the Phase 8 background-restore
/// notification path. The alarm channel above plays the bundled tone
/// at alarm-stream volume — that is wrong for "you missed the timer
/// while away", which should be a low-key heads-up only. We keep this
/// channel on a separate id so the user can also toggle it
/// independently in OS settings.
const String timerCompletedChannelId = 'timer_completed_v1';
const String timerCompletedChannelName = 'Timer Completed (Background)';
const String timerCompletedChannelDescription =
    'バックグラウンド中にタイマーが終了したことを知らせる無音通知';

/// Resource id of the default alarm sound bundled at
/// `android/app/src/main/res/raw/alarm_default.mp3`. This is what the
/// notification layer plays when the OS fires the alarm while the Flutter
/// engine is asleep (background or cold start). The richer audioplayers
/// playback driven by `AlarmRingingScreen` layers on top once the user
/// brings the app to the foreground.
const String _alarmRawResource = 'alarm_default';

/// Concrete [NotificationScheduler] backed by `flutter_local_notifications`.
///
/// Scope:
///   - schedule / cancel / cancelAll
///   - exact-vs-inexact toggle (`AndroidScheduleMode.exactAllowWhileIdle`
///     vs `AndroidScheduleMode.inexactAllowWhileIdle`) decided by the
///     caller based on permission state
///   - fullScreenIntent + max importance/priority (Phase 6a). Sound is
///     suppressed at the notification layer because the alarm screen
///     plays the custom sound via `audioplayers` (Phase 5).
///   - per-schedule fullScreenIntent fallback (Phase 6c): when the OS
///     denies USE_FULL_SCREEN_INTENT we drop the flag so the plugin emits
///     a heads-up notification instead. Importance/priority stay at max,
///     so the user still sees the banner over their current screen.
class FlutterLocalNotificationAdapter implements NotificationScheduler {
  FlutterLocalNotificationAdapter({
    FlutterLocalNotificationsPlugin? plugin,
    PermissionChannel? permissionChannel,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _permissionChannel = permissionChannel ?? PermissionChannel();

  final FlutterLocalNotificationsPlugin _plugin;
  final PermissionChannel _permissionChannel;

  /// Initialise the plugin and create the timer alarm channel.
  ///
  /// Must be called before any `schedule()` call. Typically invoked from
  /// `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  ///
  /// [onNotificationTap] is invoked with the notification's payload (the
  /// timer id encoded as String) when the user taps a notification.
  /// Used by the deep-link handler to navigate to the alarm ringing
  /// screen.
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    tz_data.initializeTimeZones();
    // `zonedSchedule` requires `tz.local` to be set to the device's actual
    // timezone; without this the AlarmManager bridge can fail to fire on
    // some Android versions even though the absolute time is computed
    // correctly.
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC; absolute scheduling still works for most cases.
    }

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    // Drop legacy channels so users who upgraded from earlier phases pick
    // up the new sound + importance settings without needing to clear data.
    for (final String legacyId in _legacyTimerAlarmChannelIds) {
      await android?.deleteNotificationChannel(legacyId);
    }
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        timerAlarmChannelId,
        timerAlarmChannelName,
        description: timerAlarmChannelDescription,
        importance: Importance.max,
        enableVibration: true,
        showBadge: false,
        playSound: true,
        // Bind the channel to the bundled alarm tone. Without an explicit
        // sound the OS picks an empty / silent default for category=alarm
        // on some Pixel builds, which is what we hit during Phase 6
        // testing.
        sound: RawResourceAndroidNotificationSound(_alarmRawResource),
        // Route the channel through the alarm audio stream rather than
        // the default notification stream. This is what makes Pixel /
        // Android 16 actually play the tone when AlarmManager fires the
        // notification from a killed-app state. Without it the Channel
        // is silent in the cold-launch path even though it works in the
        // foreground / background paths.
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        timerCompletedChannelId,
        timerCompletedChannelName,
        description: timerCompletedChannelDescription,
        importance: Importance.high,
        enableVibration: false,
        showBadge: false,
        // Silent: this path is used to surface a missed-timer message,
        // not to ring the alarm again. The alarm channel above already
        // produced the sound (or would have) at endAt; replaying it here
        // would be jarring after the user opened the app.
        playSound: false,
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
    String? payload,
  }) async {
    final bool canFsi = await _safeCanUseFullScreenIntent();
    final tz.TZDateTime scheduled = tz.TZDateTime.from(fireAt, tz.local);
    final AndroidScheduleMode mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          timerAlarmChannelId,
          timerAlarmChannelName,
          channelDescription: timerAlarmChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: canFsi,
          visibility: NotificationVisibility.public,
          enableVibration: true,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(_alarmRawResource),
        ),
      ),
      androidScheduleMode: mode,
      payload: payload,
    );
  }

  /// Checks whether USE_FULL_SCREEN_INTENT is currently granted. We re-query
  /// per schedule (rather than cache) because the user may toggle the OS
  /// setting at any time. The MethodChannel hop is microseconds.
  /// On test environments where the channel isn't registered we conserve
  /// behaviour by returning false (heads-up fallback).
  Future<bool> _safeCanUseFullScreenIntent() async {
    try {
      return await _permissionChannel.canUseFullScreenIntent();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> show({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Phase 8 background-restore notification: silent heads-up only.
    // No fullScreenIntent, no alarm sound, no vibration — those belong
    // to the live ringing path (`schedule()` + AlarmRingingScreen).
    await _plugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          timerCompletedChannelId,
          timerCompletedChannelName,
          channelDescription: timerCompletedChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          enableVibration: false,
          playSound: false,
        ),
      ),
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(notificationId);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Returns the payload of the notification that launched the app, or
  /// `null` if the app was started normally. Used by `main()` to pick the
  /// initial route so a cold-start tap on the alarm notification lands on
  /// `/alarm-ringing` instead of the home screen.
  Future<String?> coldLaunchPayload() async {
    final NotificationAppLaunchDetails? details = await _plugin
        .getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }
}
