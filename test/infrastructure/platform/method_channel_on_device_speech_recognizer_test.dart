import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/ports/on_device_speech_recognizer.dart';
import 'package:timer_utility/infrastructure/platform/method_channel_on_device_speech_recognizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel(
    MethodChannelOnDeviceSpeechRecognizer.channelName,
  );

  late List<MethodCall> calls;
  late String nativeCheckSupportStatus;

  setUp(() {
    calls = <MethodCall>[];
    nativeCheckSupportStatus = 'ready';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return switch (call.method) {
            'isAvailable' => true,
            'checkSupport' => nativeCheckSupportStatus,
            'requestModelDownload' => 'download_pending',
            _ => null,
          };
        });
  });

  test('Native がモデル取得可能と判定した場合は downloadRequired を復元する', () async {
    nativeCheckSupportStatus = 'download_required';
    final MethodChannelOnDeviceSpeechRecognizer recognizer =
        MethodChannelOnDeviceSpeechRecognizer(channel: channel);

    final status = await recognizer.checkSupport(
      localeTag: 'ja-JP',
      biasingPhrases: const <String>['停止', 'stop'],
    );

    expect(status, OnDeviceSpeechSupportStatus.downloadRequired);

    await recognizer.dispose();
  });

  test('Native の明示的な言語非対応だけを unsupported として復元する', () async {
    nativeCheckSupportStatus = 'unsupported';
    final MethodChannelOnDeviceSpeechRecognizer recognizer =
        MethodChannelOnDeviceSpeechRecognizer(channel: channel);

    final status = await recognizer.checkSupport(
      localeTag: 'ja-JP',
      biasingPhrases: const <String>['停止'],
    );

    expect(status, OnDeviceSpeechSupportStatus.unsupported);

    await recognizer.dispose();
  });

  test('checkSupport は locale と bias phrase を渡して状態を復元する', () async {
    final MethodChannelOnDeviceSpeechRecognizer recognizer =
        MethodChannelOnDeviceSpeechRecognizer(channel: channel);

    final status = await recognizer.checkSupport(
      localeTag: 'ja-JP',
      biasingPhrases: const <String>['停止'],
    );

    expect(status, OnDeviceSpeechSupportStatus.ready);
    expect(calls.single.method, 'checkSupport');
    expect(calls.single.arguments, <String, Object>{
      'localeTag': 'ja-JP',
      'biasingPhrases': <String>['停止'],
    });

    await recognizer.dispose();
  });

  test('requestModelDownload は準備中状態を復元する', () async {
    final MethodChannelOnDeviceSpeechRecognizer recognizer =
        MethodChannelOnDeviceSpeechRecognizer(channel: channel);

    final status = await recognizer.requestModelDownload(
      localeTag: 'ja-JP',
      biasingPhrases: const <String>['停止'],
    );

    expect(status, OnDeviceSpeechSupportStatus.downloadPending);
    expect(calls.single.method, 'requestModelDownload');

    await recognizer.dispose();
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
