import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/voice/voice_stop_command_matcher.dart';

void main() {
  const VoiceStopCommandMatcher matcher = VoiceStopCommandMatcher();

  test('日本語の停止コマンドと表記差を認識する', () {
    for (final String command in <String>[
      '停 止！',
      '止めて',
      'とめて',
      'ストップ。',
      'すとっぷ',
      'アラーム停止',
    ]) {
      expect(
        matcher.matchesAny(<String>[command]),
        isTrue,
        reason: '$command は停止コマンド',
      );
    }
  });

  test('英語の単語とフレーズの大小文字・句読点差を吸収する', () {
    for (final String command in <String>[
      'STOP',
      'Dismiss.',
      'Stop alarm!',
      'stop timer',
    ]) {
      expect(
        matcher.matchesAny(<String>[command]),
        isTrue,
        reason: '$command is a stop command',
      );
    }
  });

  test('中国語・韓国語の停止コマンドを認識する', () {
    expect(matcher.matchesAny(<String>['停止闹钟']), isTrue);
    expect(matcher.matchesAny(<String>['停止鬧鐘']), isTrue);
    expect(matcher.matchesAny(<String>['알람 정지']), isTrue);
  });

  test('長い無関係な文章や部分一致では停止しない', () {
    expect(matcher.matchesAny(<String>['停止ボタンを探しています']), isFalse);
    expect(matcher.matchesAny(<String>['please stop the music']), isFalse);
    expect(matcher.matchesAny(<String>['スタッフ']), isFalse);
    expect(matcher.matchesAny(<String>['ストップウォッチ']), isFalse);
    expect(matcher.matchesAny(<String>['スヌーズ']), isFalse);
  });
}
