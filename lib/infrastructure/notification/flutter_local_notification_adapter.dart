import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/notifications/notification_strings.dart';
import '../../domain/ports/notification_scheduler.dart';
import '../platform/native_alarm_channel.dart';
import '../platform/permission_channel.dart';

typedef ImportedAlarmSoundPathLookup = Future<String?> Function(String soundId);

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
  'timer_alarm_v6',
];
const String timerAlarmChannelId = 'timer_alarm_v7';

/// Silent channel used by [FlutterLocalNotificationAdapter.show] for the
/// Phase 8 background-restore notification path. The alarm channel above
/// plays the bundled tone at alarm-stream volume — that is wrong for
/// "you missed the timer while away", which should be a low-key
/// heads-up only. We keep this channel on a separate id so the user can
/// also toggle it independently in OS settings.
const String timerCompletedChannelId = 'timer_completed_v1';

/// Resource id of the short, self-terminating notification cue bundled at
/// `android/app/src/main/res/raw/notif_alert.mp3`.
///
/// Android owns channel-sound playback independently from the notification,
/// so cancelling the notification does not stop a cue already in progress.
/// Keeping this resource fixed and short gives the Application layer a stable
/// handoff boundary before it starts the selected looping alarm sound.
const String _channelCueRawResource = 'notif_alert';

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
/// Channel sound rationale (Phase 8.5 → Issue #86 Phase A):
///
/// The OS-level channel sound is intentionally ON. Android does not
/// always honor FullScreenIntent — when the screen is on and the user
/// is actively in another app or on the home screen, Pixel 6a / Android
/// 16 emits a heads-up notification only (QoS gate) and never starts
/// AlarmRingingScreen. In that path the OS-played cue is the only thing
/// that makes sound until the user taps the heads-up.
///
/// We tried `playSound: false` (Phase 8.5 first attempt) to suppress
/// the channel tone entirely and own audio from audioplayers only, but
/// that left heads-up paths silent until the user tapped — losing the
/// "I hear my timer go off in the background" property. The adopted design
/// uses a short OS cue followed by an explicitly delayed app-player handoff.
class FlutterLocalNotificationAdapter
    implements
        NotificationScheduler,
        AlarmVolumeController,
        NativeAlarmPlaybackController {
  FlutterLocalNotificationAdapter({
    FlutterLocalNotificationsPlugin? plugin,
    PermissionChannel? permissionChannel,
    NativeAlarmChannel? nativeAlarmChannel,
    ImportedAlarmSoundPathLookup? importedSoundPathLookup,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _permissionChannel = permissionChannel ?? PermissionChannel(),
       _nativeAlarmChannel = nativeAlarmChannel ?? NativeAlarmChannel(),
       _importedSoundPathLookup = importedSoundPathLookup;

  final FlutterLocalNotificationsPlugin _plugin;
  final PermissionChannel _permissionChannel;
  final NativeAlarmChannel _nativeAlarmChannel;
  final ImportedAlarmSoundPathLookup? _importedSoundPathLookup;

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
    _nativeAlarmChannel.initialize(
      onAlarmTap: (String? payload) => onNotificationTap?.call(payload),
    );
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
        sound: const RawResourceAndroidNotificationSound(
          _channelCueRawResource,
        ),
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
    String? soundId,
    String? payload,
  }) async {
    if (exact && soundId != null && payload != null) {
      String? soundPath;
      try {
        soundPath = await _importedSoundPathLookup?.call(soundId);
      } catch (_) {
        // A deleted or temporarily unreadable imported source falls back to
        // the bundled default inside the Native service.
      }
      try {
        await _nativeAlarmChannel.schedule(
          notificationId: notificationId,
          fireAt: fireAt,
          title: title,
          body: body,
          payload: payload,
          soundId: soundId,
          soundPath: soundPath,
        );
        await _plugin.cancel(notificationId);
        return;
      } on MissingPluginException {
        // Non-Android/test hosts retain the plugin scheduling path.
      } on PlatformException {
        // A Native boundary failure must not lose the alarm entirely.
      }
    } else {
      await _cancelNativeBestEffort(notificationId);
    }

    await _schedulePlugin(
      notificationId: notificationId,
      fireAt: fireAt,
      title: title,
      body: body,
      exact: exact,
      payload: payload,
    );
  }

  Future<void> _schedulePlugin({
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
          sound: const RawResourceAndroidNotificationSound(
            _channelCueRawResource,
          ),
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
  Future<void> cancel(int notificationId) async {
    await _cancelNativeBestEffort(notificationId);
    await _plugin.cancel(notificationId);
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _nativeAlarmChannel.cancelAll();
    } on MissingPluginException {
      // Non-Android/test host.
    } on PlatformException {
      // Plugin-owned notifications still need cleanup.
    }
    await _plugin.cancelAll();
  }

  Future<void> _cancelNativeBestEffort(int notificationId) async {
    try {
      await _nativeAlarmChannel.cancel(notificationId);
    } on MissingPluginException {
      // Non-Android/test host.
    } on PlatformException {
      // Continue with plugin cleanup.
    }
  }

  @override
  Future<void> setAlarmVolumePercent(int percent) async {
    try {
      await _nativeAlarmChannel.setAlarmVolumePercent(percent);
    } on MissingPluginException {
      // Non-Android/test host.
    } on PlatformException {
      // Flutter playback still receives the same setting independently.
    }
  }

  @override
  Future<bool> ensureNativePlayback(int notificationId) async {
    try {
      return await _nativeAlarmChannel.ensurePlayback(notificationId);
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> stopNativePlayback() async {
    try {
      await _nativeAlarmChannel.stopPlayback();
    } on MissingPluginException {
      // Non-Android/test host.
    } on PlatformException {
      // Flutter player cleanup still runs in the notifier.
    }
  }

  /// Returns the payload of the notification that launched the app, or
  /// `null` if the app was started normally. Used by `main()` to pick the
  /// initial route so a cold-start tap on the alarm notification lands on
  /// `/alarm-ringing` instead of the home screen.
  Future<String?> coldLaunchPayload() async {
    try {
      final String? launchPayload = await _nativeAlarmChannel
          .takeLaunchPayload();
      if (launchPayload != null) return launchPayload;
      final String? activePayload = await _nativeAlarmChannel.activePayload();
      if (activePayload != null) return activePayload;
    } on MissingPluginException {
      // Continue with flutter_local_notifications.
    } on PlatformException {
      // Continue with flutter_local_notifications.
    }
    final NotificationAppLaunchDetails? details = await _plugin
        .getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }
}
