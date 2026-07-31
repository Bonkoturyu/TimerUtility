import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/infrastructure/platform/method_channel_on_device_speech_recognizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel(
    MethodChannelOnDeviceSpeechRecognizer.channelName,
  );

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return switch (call.method) {
            'isAvailable' => true,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('availability は native の true を返す', () async {
    final MethodChannelOnDeviceSpeechRecognizer recognizer =
        MethodChannelOnDeviceSpeechRecognizer(channel: channel);

    expect(await recognizer.isAvailable(), isTrue);
    expect(calls.single.method, 'isAvailable');

    await recognizer.dispose();
  });

  test('startListening は locale と bias phrase だけを native へ渡す', () async {
    final MethodChannelOnDeviceSpeechRecognizer recognizer =
        MethodChannelOnDeviceSpeechRecognizer(channel: channel);

    await recognizer.startListening(
      localeTag: 'ja-JP',
      biasingPhrases: const <String>['停止'],
    );

    final MethodCall call = calls.single;
    expect(call.method, 'startListening');
    expect(call.arguments, <String, Object>{
      'localeTag': 'ja-JP',
      'biasingPhrases': <String>['停止'],
    });

    await recognizer.dispose();
  });

  test('MissingPlugin の availability は false にフォールバックする', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    final MethodChannelOnDeviceSpeechRecognizer recognizer =
        MethodChannelOnDeviceSpeechRecognizer(channel: channel);

    expect(await recognizer.isAvailable(), isFalse);

    await recognizer.dispose();
  });
}
