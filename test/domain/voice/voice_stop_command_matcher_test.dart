import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/voice/voice_stop_command_matcher.dart';

void main() {
  const VoiceStopCommandMatcher matcher = VoiceStopCommandMatcher();

  test('日本語の停止コマンドを空白・句読点差を吸収して認識する', () {
    expect(matcher.matchesAny(<String>['停 止！']), isTrue);
    expect(matcher.matchesAny(<String>['ストップ。']), isTrue);
    expect(matcher.matchesAny(<String>['アラーム停止']), isTrue);
  });

  test('英語は大小文字と空白差を吸収する', () {
    expect(matcher.matchesAny(<String>['STOP']), isTrue);
    expect(matcher.matchesAny(<String>['Stop alarm!']), isTrue);
  });

  test('中国語・韓国語の停止コマンドを認識する', () {
    expect(matcher.matchesAny(<String>['停止闹钟']), isTrue);
    expect(matcher.matchesAny(<String>['停止鬧鐘']), isTrue);
    expect(matcher.matchesAny(<String>['알람 정지']), isTrue);
  });

  test('長い無関係な文章や部分一致では停止しない', () {
    expect(matcher.matchesAny(<String>['停止ボタンを探しています']), isFalse);
    expect(matcher.matchesAny(<String>['please stop the music']), isFalse);
    expect(matcher.matchesAny(<String>['スヌーズ']), isFalse);
  });
}
