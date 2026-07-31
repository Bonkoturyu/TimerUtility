/// Converts an application locale into the concrete BCP 47 tag requested
/// from Android's on-device speech model.
///
/// Flutter may expose language-only locales such as `ja`. Android speech
/// models are distributed for concrete locales, so language-only tags must
/// not be passed through unchanged.
String resolveOnDeviceSpeechLocaleTag(String localeTag) {
  final String normalized = localeTag.replaceAll('_', '-');
  final List<String> parts = normalized
      .split('-')
      .where((String part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'en-US';

  final String language = parts.first.toLowerCase();
  return switch (language) {
    'ja' => 'ja-JP',
    'ko' => 'ko-KR',
    'zh' when parts.any((String part) => part.toLowerCase() == 'hant') =>
      'zh-TW',
    'zh' => 'zh-CN',
    'en' => 'en-US',
    _ => normalized,
  };
}
