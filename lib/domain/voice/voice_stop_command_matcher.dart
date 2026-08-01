/// Matches a deliberately small allow-list of stop commands.
///
/// Matching is exact after case, whitespace, and punctuation normalization.
/// This avoids treating a longer unrelated sentence as a stop command.
class VoiceStopCommandMatcher {
  const VoiceStopCommandMatcher();

  static const List<String> biasingPhrases = <String>[
    '停止',
    '止めて',
    'とめて',
    'ストップ',
    'すとっぷ',
    'アラーム停止',
    'タイマー停止',
    'stop',
    'dismiss',
    'stop alarm',
    'stop timer',
    '停止闹钟',
    '停止定时器',
    '停止鬧鐘',
    '停止計時器',
    '정지',
    '멈춰',
    '알람 정지',
    '타이머 정지',
  ];

  static final Set<String> _normalizedCommands = biasingPhrases
      .map(_normalize)
      .toSet();

  bool matchesAny(Iterable<String> hypotheses) {
    for (final String hypothesis in hypotheses) {
      if (_normalizedCommands.contains(_normalize(hypothesis))) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String value) => value.toLowerCase().replaceAll(
    RegExp(r'''[\s\u3000、。,.!?！？「」『』"'’・:：;；]'''),
    '',
  );
}
