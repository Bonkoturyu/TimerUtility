import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/infrastructure/platform/native_alarm_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel methodChannel = MethodChannel(
    NativeAlarmChannel.channelName,
  );
  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (MethodCall call) async {
          calls.add(call);
          if (call.method == 'ensurePlayback') return true;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  test('scheduleはUTC時刻・payload・音源をNativeへ渡す', () async {
    await NativeAlarmChannel().schedule(
      notificationId: 42,
      fireAt: DateTime.utc(2026, 8, 2, 12, 34),
      title: 'Alarm',
      body: 'Time',
      payload: 'timer:t-1',
      soundId: 'imported-1',
      soundPath: r'C:\sounds\alarm.mp3',
    );

    expect(calls.single.method, 'schedule');
    expect(calls.single.arguments, <String, Object?>{
      'notificationId': 42,
      'fireAtUtcMs': DateTime.utc(2026, 8, 2, 12, 34).millisecondsSinceEpoch,
      'title': 'Alarm',
      'body': 'Time',
      'payload': 'timer:t-1',
      'soundId': 'imported-1',
      'soundPath': r'C:\sounds\alarm.mp3',
    });
  });

  test('音量・再生確認・停止をNativeへ渡す', () async {
    final NativeAlarmChannel channel = NativeAlarmChannel();

    await channel.setAlarmVolumePercent(65);
    expect(await channel.ensurePlayback(42), isTrue);
    await channel.stopPlayback();

    expect(calls.map((MethodCall call) => call.method), <String>[
      'setAlarmVolumePercent',
      'ensurePlayback',
      'stopPlayback',
    ]);
    expect(calls[0].arguments, <String, Object>{'percent': 65});
    expect(calls[1].arguments, <String, Object>{'notificationId': 42});
  });
}
