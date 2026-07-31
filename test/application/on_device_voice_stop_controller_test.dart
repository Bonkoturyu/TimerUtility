import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/on_device_speech_recognizer_provider.dart';
import 'package:timer_utility/application/on_device_voice_stop_controller.dart';
import 'package:timer_utility/domain/ports/on_device_speech_recognizer.dart';

class _FakeRecognizer implements OnDeviceSpeechRecognizer {
  _FakeRecognizer({this.support = OnDeviceSpeechSupportStatus.ready});

  final OnDeviceSpeechSupportStatus support;
  final StreamController<OnDeviceSpeechEvent> controller =
      StreamController<OnDeviceSpeechEvent>.broadcast(sync: true);
  int startCalls = 0;
  int downloadCalls = 0;
  int cancelCalls = 0;
  String? localeTag;

  @override
  Stream<OnDeviceSpeechEvent> get events => controller.stream;

  @override
  Future<bool> isAvailable() async =>
      support != OnDeviceSpeechSupportStatus.unavailable;

  @override
  Future<OnDeviceSpeechSupportStatus> checkSupport({
    required String localeTag,
    required List<String> biasingPhrases,
  }) async => support;

  @override
  Future<OnDeviceSpeechSupportStatus> requestModelDownload({
    required String localeTag,
    required List<String> biasingPhrases,
  }) async {
    downloadCalls++;
    return OnDeviceSpeechSupportStatus.downloadPending;
  }

  @override
  Future<void> startListening({
    required String localeTag,
    required List<String> biasingPhrases,
  }) async {
    startCalls++;
    this.localeTag = localeTag;
  }

  @override
  Future<void> cancelListening() async {
    cancelCalls++;
  }

  @override
  Future<void> dispose() async {
    await controller.close();
  }
}

ProviderContainer _container(_FakeRecognizer recognizer) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      onDeviceSpeechRecognizerProvider.overrideWithValue(recognizer),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(recognizer.dispose);
  return container;
}

void main() {
  test('端末内認識がなければ unavailable で開始しない', () async {
    final _FakeRecognizer recognizer = _FakeRecognizer(
      support: OnDeviceSpeechSupportStatus.unavailable,
    );
    final ProviderContainer container = _container(recognizer);

    await container
        .read(onDeviceVoiceStopControllerProvider.notifier)
        .start(localeTag: 'ja-JP');

    expect(
      container.read(onDeviceVoiceStopControllerProvider).status,
      OnDeviceVoiceStopStatus.unavailable,
    );
    expect(recognizer.startCalls, 0);
  });

  test('言語だけのロケールをモデル用の具体的な locale に正規化する', () async {
    final _FakeRecognizer recognizer = _FakeRecognizer();
    final ProviderContainer container = _container(recognizer);

    await container
        .read(onDeviceVoiceStopControllerProvider.notifier)
        .start(localeTag: 'ja');

    expect(recognizer.localeTag, 'ja-JP');
  });

  test('モデル未取得ならダウンロードを要求して準備中を表示する', () async {
    final _FakeRecognizer recognizer = _FakeRecognizer(
      support: OnDeviceSpeechSupportStatus.downloadRequired,
    );
    final ProviderContainer container = _container(recognizer);

    await container
        .read(onDeviceVoiceStopControllerProvider.notifier)
        .start(localeTag: 'ja');

    expect(recognizer.downloadCalls, 1);
    expect(recognizer.startCalls, 0);
    expect(
      container.read(onDeviceVoiceStopControllerProvider).status,
      OnDeviceVoiceStopStatus.modelDownloadPending,
    );
  });

  test('端末内認識が言語非対応なら認識を開始しない', () async {
    final _FakeRecognizer recognizer = _FakeRecognizer(
      support: OnDeviceSpeechSupportStatus.unsupported,
    );
    final ProviderContainer container = _container(recognizer);

    await container
        .read(onDeviceVoiceStopControllerProvider.notifier)
        .start(localeTag: 'ja');

    expect(recognizer.startCalls, 0);
    expect(
      container.read(onDeviceVoiceStopControllerProvider).status,
      OnDeviceVoiceStopStatus.languageUnsupported,
    );
  });

  test('許可済み端末では指定ロケールで短時間認識を開始する', () async {
    final _FakeRecognizer recognizer = _FakeRecognizer();
    final ProviderContainer container = _container(recognizer);

    await container
        .read(onDeviceVoiceStopControllerProvider.notifier)
        .start(localeTag: 'ja-JP');

    expect(recognizer.startCalls, 1);
    expect(recognizer.localeTag, 'ja-JP');
    expect(
      container.read(onDeviceVoiceStopControllerProvider).status,
      OnDeviceVoiceStopStatus.listening,
    );
  });

  test('最終候補に停止があれば一度だけ commandSequence を進める', () async {
    final _FakeRecognizer recognizer = _FakeRecognizer();
    final ProviderContainer container = _container(recognizer);
    await container
        .read(onDeviceVoiceStopControllerProvider.notifier)
        .start(localeTag: 'ja-JP');

    recognizer.controller.add(
      const OnDeviceSpeechResult(hypotheses: <String>['停止']),
    );

    final OnDeviceVoiceStopState state = container.read(
      onDeviceVoiceStopControllerProvider,
    );
    expect(state.status, OnDeviceVoiceStopStatus.commandDetected);
    expect(state.commandSequence, 1);
    expect(recognizer.cancelCalls, 1);

    recognizer.controller.add(
      const OnDeviceSpeechResult(hypotheses: <String>['停止']),
    );
    expect(
      container.read(onDeviceVoiceStopControllerProvider).commandSequence,
      1,
    );
  });

  test('マイク権限エラーは再試行せず permissionDenied を表示する', () async {
    final _FakeRecognizer recognizer = _FakeRecognizer();
    final ProviderContainer container = _container(recognizer);
    await container
        .read(onDeviceVoiceStopControllerProvider.notifier)
        .start(localeTag: 'ja-JP');

    recognizer.controller.add(
      const OnDeviceSpeechError(
        OnDeviceSpeechErrorKind.microphonePermissionDenied,
      ),
    );

    expect(
      container.read(onDeviceVoiceStopControllerProvider).status,
      OnDeviceVoiceStopStatus.microphonePermissionDenied,
    );
  });
}
