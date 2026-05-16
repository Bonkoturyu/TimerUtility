import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notifications/notification_strings.dart';
import '../../domain/ports/notification_scheduler.dart';
import '../platform/permission_channel.dart';

/// Channel id constants. Centralised here so callers don't repeat them.
///
/// Channel id bumps (`_v2`, `_v3`, …) are intentional: Android does not let
/// an app re-configure an existing channel's importance / sound / vibration
/// after it's been created. Each id bump bundles a delete + recreate so the
/// new settings actually take effect on devices that already had an older
/// channel.
///
/// Channel **name** and **description** are no longer constants — they
/// are locale-aware and supplied via [NotificationStrings] (passed into
/// [FlutterLocalNotificationAdapter.initialize] and refreshed via
/// [FlutterLocalNotificationAdapter.updateChannelNames]). Re-calling
/// `createNotificationChannel` with the same id is the documented way
/// to update name/description after a language switch.
const List<String> _legacyTimerAlarmChannelIds = <String>[
  'timer_alarm',
  'timer_alarm_v2',
  'timer_alarm_v3',
  'timer_alarm_v4',
  'timer_alarm_v5',
];
const String timerAlarmChannelId = 'timer_alarm_v6';

/// Silent channel used by [FlutterLocalNotificationAdapter.show] for the
/// Phase 8 background-restore notification path. The alarm channel above
/// plays the bundled tone at alarm-stream volume — that is wrong for
/// "you missed the timer while away", which should be a low-key
/// heads-up only. We keep this channel on a separate id so the user can
/// also toggle it independently in OS settings.
const String timerCompletedChannelId = 'timer_completed_v1';

/// Resource id of the default alarm sound bundled at
/// `android/app/src/main/res/raw/alarm_default.mp3`. This is what the
/// notification layer plays when the OS fires the alarm while the Flutter
/// engine is asleep (background or cold start) AND the user is in a
/// state where Android only emits a heads-up (no FullScreenIntent) —
/// that path has no other way to make sound.
const String _alarmRawResource = 'alarm_default';

/// Concrete [NotificationScheduler] backed by `flutter_local_notifications`.
///
/// Scope:
///   - schedule / cancel / cancelAll
///   - exact-vs-inexact toggle (`AndroidScheduleMode.exactAllowWhileIdle`
///     vs `AndroidScheduleMode.inexactAllowWhileIdle`) decided by the
///     caller based on permission state
///   - fullScreenIntent + max importance/priority (Phase 6a)
///   - per-schedule fullScreenIntent fallback (Phase 6c): when the OS
///     denies USE_FULL_SCREEN_INTENT we drop the flag so the plugin emits
///     a heads-up notification instead. Importance/priority stay at max,
///     so the user still sees the banner over their current screen.
///
/// Channel sound rationale (Phase 8.5 follow-ups, 2026-05-02):
///
/// The OS-level channel sound is intentionally ON. Android does not
/// always honor FullScreenIntent — when the screen is on and the user
/// is actively in another app or on the home screen, Pixel 6a / Android
/// 16 emits a heads-up notification only (QoS gate) and never starts
/// AlarmRingingScreen. In that path the OS-played alarm tone is the
/// only thing that makes sound until the user taps the heads-up.
///
/// The downside: when FullScreenIntent does fire, the OS-played tone
/// continues on its own lifecycle for a few seconds after
/// `_plugin.cancel(notificationId)` (alarm-stream behavior on Pixel),
/// which would overlap with the audioplayers loop kicked off by the
/// alarm screen and produce a double-tone. We mitigate that in
/// [AlarmRingingNotifier.start] by sequencing cancel → small delay →
/// play, giving the OS a window to release the tone before audioplayers
/// takes over.
///
/// We tried `playSound: false` (Phase 8.5 first attempt) to suppress
/// the channel tone entirely and own audio from audioplayers only, but
/// that left heads-up paths silent until the user tapped — losing the
/// "I hear my timer go off in the background" property.
class FlutterLocalNotificationAdapter implements NotificationScheduler {
  FlutterLocalNotificationAdapter({
    FlutterLocalNotificationsPlugin? plugin,
    PermissionChannel? permissionChannel,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _permissionChannel = permissionChannel ?? PermissionChannel();

  final FlutterLocalNotificationsPlugin _plugin;
  final PermissionChannel _permissionChannel;

  /// Locale-resolved channel name/description. Set by [initialize] and
  /// refreshed via [updateChannelNames] when the user switches language.
  /// Held as a field (rather than read from `notificationStringsNotifierProvider`
  /// on each call) because adapter calls happen from contexts without a
  /// `ProviderContainer` (Phase 4 design: pure-Dart Port impl). Channel
  /// names also feed into `schedule()` / `show()` per-notification
  /// `AndroidNotificationDetails`, where same-id channels make the OS
  /// ignore the values — but we still pass the live ones so logs /
  /// debugger inspection stays consistent.
  late NotificationStrings _strings;

  /// Initialise the plugin and create the timer alarm channel.
  ///
  /// Must be called before any `schedule()` call. Typically invoked from
  /// `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  ///
  /// [strings] supplies the locale-aware channel name/description used
  /// on the OS settings UI. Call [updateChannelNames] after a language
  /// switch to re-push the values without re-running the rest of
  /// initialisation.
  ///
  /// [onNotificationTap] is invoked with the notification's payload (the
  /// timer id encoded as String) when the user taps a notification.
  /// Used by the deep-link handler to navigate to the alarm ringing
  /// screen.
  Future<void> initialize({
    required NotificationStrings strings,
    void Function(String? payload)? onNotificationTap,
  }) async {
    _strings = strings;
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
    await _recreateChannels(android);
  }

  /// Re-push the channel name and description after a locale change.
  ///
  /// Android's documented behaviour: calling `createNotificationChannel`
  /// with an existing id updates the user-facing `name` and
  /// `description` while leaving importance / sound / vibration locked
  /// (the OS protects those because the user can override them in
  /// Settings). That's exactly what we want — the OS-settings label
  /// tracks the current language while audio behaviour stays stable.
  ///
  /// Idempotent: safe to call multiple times. No-op on non-Android
  /// platforms because `resolvePlatformSpecificImplementation` returns
  /// null there.
  @override
  Future<void> updateChannelNames(NotificationStrings strings) async {
    _strings = strings;
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await _recreateChannels(android);
  }

  Future<void> _recreateChannels(
    AndroidFlutterLocalNotificationsPlugin? android,
  ) async {
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        timerAlarmChannelId,
        _strings.timerAlarmChannelName,
        description: _strings.timerAlarmChannelDescription,
        importance: Importance.max,
        enableVibration: true,
        showBadge: false,
        playSound: true,
        // Bundled tone, alarm stream. Required so heads-up paths (FSI
        // not granted by Android) still produce sound. See class doc.
        sound: const RawResourceAndroidNotificationSound(_alarmRawResource),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        timerCompletedChannelId,
        _strings.timerCompletedChannelName,
        description: _strings.timerCompletedChannelDescription,
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
          _strings.timerAlarmChannelName,
          channelDescription: _strings.timerAlarmChannelDescription,
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          timerCompletedChannelId,
          _strings.timerCompletedChannelName,
          channelDescription: _strings.timerCompletedChannelDescription,
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
