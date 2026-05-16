import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/domain/notifications/notification_strings.dart';
import 'package:timer_utility/infrastructure/notification/flutter_local_notification_adapter.dart';
import 'package:timer_utility/infrastructure/platform/permission_channel.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockPermissionChannel extends Mock implements PermissionChannel {}

class _FakeAndroidNotificationChannel extends Fake
    implements AndroidNotificationChannel {}

const NotificationStrings _englishStrings = NotificationStrings(
  timerEndedTitle: 'Timer',
  timerEndedBody: 'Time is up.',
  timerCompletedBackgroundBody:
      'Timer ended while the app was in the background.',
  alarmRingingTitle: 'Alarm',
  alarmRingingBody: 'It is time for your alarm.',
  timerAlarmChannelName: 'Timer Alarm',
  timerAlarmChannelDescription: 'Alarm notification when a timer ends',
  timerCompletedChannelName: 'Timer Completed (Background)',
  timerCompletedChannelDescription:
      'Silent notification when a timer ends while the app is in the background',
);

const NotificationStrings _japaneseStrings = NotificationStrings(
  timerEndedTitle: 'タイマー',
  timerEndedBody: '時間になりました。',
  timerCompletedBackgroundBody: 'アプリのバックグラウンド中にタイマーが終了しました。',
  alarmRingingTitle: 'アラーム',
  alarmRingingBody: 'アラームの時刻になりました。',
  timerAlarmChannelName: 'タイマーアラーム',
  timerAlarmChannelDescription: 'タイマー終了時のアラーム通知',
  timerCompletedChannelName: 'タイマー完了（バックグラウンド）',
  timerCompletedChannelDescription: 'バックグラウンド中にタイマーが終了したことを知らせる無音通知',
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeAndroidNotificationChannel());
  });

  group('FlutterLocalNotificationAdapter.updateChannelNames', () {
    late _MockPlugin plugin;
    late _MockAndroidPlugin android;
    late FlutterLocalNotificationAdapter adapter;

    setUp(() {
      plugin = _MockPlugin();
      android = _MockAndroidPlugin();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.createNotificationChannel(any()),
      ).thenAnswer((_) async {});
      adapter = FlutterLocalNotificationAdapter(
        plugin: plugin,
        permissionChannel: _MockPermissionChannel(),
      );
    });

    test('re-creates both channels with the supplied strings', () async {
      await adapter.updateChannelNames(_japaneseStrings);

      final List<dynamic> captured = verify(
        () => android.createNotificationChannel(captureAny()),
      ).captured;
      // Two channels: alarm + silent background-completion. Order matches
      // the order they're registered in `_recreateChannels` — alarm first.
      expect(captured.length, 2);

      final AndroidNotificationChannel alarmCh =
          captured[0] as AndroidNotificationChannel;
      expect(alarmCh.id, timerAlarmChannelId);
      expect(alarmCh.name, _japaneseStrings.timerAlarmChannelName);
      expect(
        alarmCh.description,
        _japaneseStrings.timerAlarmChannelDescription,
      );

      final AndroidNotificationChannel completedCh =
          captured[1] as AndroidNotificationChannel;
      expect(completedCh.id, timerCompletedChannelId);
      expect(completedCh.name, _japaneseStrings.timerCompletedChannelName);
      expect(
        completedCh.description,
        _japaneseStrings.timerCompletedChannelDescription,
      );
    });

    test('two consecutive calls use the latest strings on the second call '
        '(locale switch scenario)', () async {
      await adapter.updateChannelNames(_englishStrings);
      clearInteractions(android);
      await adapter.updateChannelNames(_japaneseStrings);

      final List<dynamic> captured = verify(
        () => android.createNotificationChannel(captureAny()),
      ).captured;
      expect(captured.length, 2);
      expect(
        (captured[0] as AndroidNotificationChannel).name,
        _japaneseStrings.timerAlarmChannelName,
      );
      expect(
        (captured[1] as AndroidNotificationChannel).name,
        _japaneseStrings.timerCompletedChannelName,
      );
    });

    test('preserves importance / vibration / sound flags '
        '(only name and description should differ between calls)', () async {
      await adapter.updateChannelNames(_englishStrings);

      final List<dynamic> captured = verify(
        () => android.createNotificationChannel(captureAny()),
      ).captured;

      // Alarm channel keeps Importance.max + vibration on + alarm-stream
      // sound — those are the values we lock in at first-create time
      // (Android then protects them from later updates even if we tried).
      final AndroidNotificationChannel alarmCh =
          captured[0] as AndroidNotificationChannel;
      expect(alarmCh.importance, Importance.max);
      expect(alarmCh.enableVibration, true);
      expect(alarmCh.playSound, true);

      // Background-completion channel stays silent + no vibration —
      // it's a "you missed a timer" reminder, not a re-ring.
      final AndroidNotificationChannel completedCh =
          captured[1] as AndroidNotificationChannel;
      expect(completedCh.importance, Importance.high);
      expect(completedCh.enableVibration, false);
      expect(completedCh.playSound, false);
    });
  });
}
