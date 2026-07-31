import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/voice/on_device_speech_locale.dart';

void main() {
  test(
    'language-only locale is resolved to an Android speech model locale',
    () {
      expect(resolveOnDeviceSpeechLocaleTag('ja'), 'ja-JP');
      expect(resolveOnDeviceSpeechLocaleTag('en'), 'en-US');
      expect(resolveOnDeviceSpeechLocaleTag('ko'), 'ko-KR');
    },
  );

  test('Chinese script is resolved to the corresponding regional model', () {
    expect(resolveOnDeviceSpeechLocaleTag('zh'), 'zh-CN');
    expect(resolveOnDeviceSpeechLocaleTag('zh-Hans'), 'zh-CN');
    expect(resolveOnDeviceSpeechLocaleTag('zh-Hant'), 'zh-TW');
    expect(resolveOnDeviceSpeechLocaleTag('zh_Hant_TW'), 'zh-TW');
  });

  test('an unknown locale remains a normalized BCP 47 tag', () {
    expect(resolveOnDeviceSpeechLocaleTag('fr_CA'), 'fr-CA');
  });
}
