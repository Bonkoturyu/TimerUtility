import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/presentation/widgets/utc_offset_formatter.dart';

void main() {
  group('formatUtcOffset', () {
    test('Duration.zero → "UTC+0"', () {
      expect(formatUtcOffset(Duration.zero), 'UTC+0');
    });

    test('正の整数時 (Tokyo, UTC+9)', () {
      expect(formatUtcOffset(const Duration(hours: 9)), 'UTC+9');
    });

    test('負の整数時 (NY EST, UTC-5)', () {
      expect(formatUtcOffset(const Duration(hours: -5)), 'UTC-5');
    });

    test('正の 30 分オフセット (Kolkata, UTC+5:30)', () {
      expect(
        formatUtcOffset(const Duration(hours: 5, minutes: 30)),
        'UTC+5:30',
      );
    });

    test('正の 30 分オフセット (Adelaide, UTC+9:30)', () {
      expect(
        formatUtcOffset(const Duration(hours: 9, minutes: 30)),
        'UTC+9:30',
      );
    });

    test('正の 45 分オフセット (Kathmandu, UTC+5:45)', () {
      expect(
        formatUtcOffset(const Duration(hours: 5, minutes: 45)),
        'UTC+5:45',
      );
    });

    test('負の 30 分オフセット (Newfoundland NST, UTC-3:30)', () {
      // 構築時は両成分を負にして -210 分 (= -3h30m) を作る。
      expect(
        formatUtcOffset(const Duration(hours: -3, minutes: -30)),
        'UTC-3:30',
      );
    });

    test('1 桁分の 0 埋め (UTC+5:05 — 防御的ケース、実 TZ には該当なし)', () {
      expect(formatUtcOffset(const Duration(hours: 5, minutes: 5)), 'UTC+5:05');
    });

    test('正の 14 時 (Kiribati Line Islands, UTC+14)', () {
      // 最大 IANA オフセットの境界確認。
      expect(formatUtcOffset(const Duration(hours: 14)), 'UTC+14');
    });
  });
}
