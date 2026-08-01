import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timer_utility/domain/ports/on_device_speech_recognizer.dart';
import 'package:timer_utility/domain/voice/voice_stop_command_matcher.dart';
import 'package:timer_utility/infrastructure/platform/method_channel_on_device_speech_recognizer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Pixelの実MethodChannelで日本語をunsupportedと誤判定しない', (
    WidgetTester _,
  ) async {
    final MethodChannelOnDeviceSpeechRecognizer recognizer =
        MethodChannelOnDeviceSpeechRecognizer();
    addTearDown(recognizer.dispose);

    if (!await recognizer.isAvailable()) return;

    final OnDeviceSpeechSupportStatus status = await recognizer.checkSupport(
      localeTag: 'ja-JP',
      biasingPhrases: VoiceStopCommandMatcher.biasingPhrases,
    );

    expect(
      status,
      anyOf(
        OnDeviceSpeechSupportStatus.ready,
        OnDeviceSpeechSupportStatus.downloadRequired,
        OnDeviceSpeechSupportStatus.downloadPending,
      ),
    );
  });
}
