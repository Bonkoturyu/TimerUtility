import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/infrastructure/platform/interval_notification_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(IntervalNotificationChannel.channelName);
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('scheduleはUTC基準時刻と周期をNativeへ渡す', () async {
    await IntervalNotificationChannel().schedule(
      notificationId: 42,
      firstFireAt: DateTime.utc(2026, 7, 12, 3, 2),
      interval: const Duration(minutes: 2),
      title: 'pace',
      body: 'boundary',
      exact: true,
      payload: 'timer:id-1',
    );

    expect(calls.single.method, 'schedule');
    expect(calls.single.arguments, <String, Object>{
      'notificationId': 42,
      'firstFireAtUtcMs': DateTime.utc(
        2026,
        7,
        12,
        3,
        2,
      ).millisecondsSinceEpoch,
      'intervalMs': 120000,
      'title': 'pace',
      'body': 'boundary',
      'exact': true,
      'payload': 'timer:id-1',
    });
  });

  test('cancelは対象notificationIdをNativeへ渡す', () async {
    await IntervalNotificationChannel().cancel(42);

    expect(calls.single.method, 'cancel');
    expect(calls.single.arguments, <String, Object>{'notificationId': 42});
  });
}
