import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/exceptions.dart';
import 'package:timer_utility/infrastructure/clock/tz_database_timezone_resolver.dart';

void main() {
  group('TzDatabaseTimezoneResolver', () {
    final TzDatabaseTimezoneResolver resolver = TzDatabaseTimezoneResolver();

    test('Asia/Tokyo: UTC 00:00 → 09:00 (固定 +9h、DST なし)', () {
      final DateTime wall = resolver.computeAt(
        DateTime.utc(2026, 1, 15),
        'Asia/Tokyo',
      );
      expect(wall.hour, 9);
      expect(wall.minute, 0);
      expect(wall.day, 15);
    });

    test('Asia/Seoul は Asia/Tokyo と同じ wall clock を返す (UTC+9 同オフセット)', () {
      // IANA TZDB が Seoul / Tokyo を別 ID で同オフセットに解決することを
      // resolver レベルで担保する。widget 側はこれに依存して "Seoul も
      // Tokyo と同じ表示" を成立させる。
      final DateTime utc = DateTime.utc(2026, 1, 15, 12);
      final DateTime tokyo = resolver.computeAt(utc, 'Asia/Tokyo');
      final DateTime seoul = resolver.computeAt(utc, 'Asia/Seoul');
      expect(seoul.hour, tokyo.hour);
      expect(seoul.minute, tokyo.minute);
      expect(seoul.hour, 21);
    });

    test('America/Los_Angeles: UTC 12:00 が PST 04:00 / PDT 05:00 に変換される', () {
      // 冬 (PST = UTC-8): 2026-01-15 12:00 UTC → 04:00 LA local
      final DateTime winter = resolver.computeAt(
        DateTime.utc(2026, 1, 15, 12),
        'America/Los_Angeles',
      );
      expect(winter.hour, 4);
      // 夏 (PDT = UTC-7): 2026-06-15 12:00 UTC → 05:00 LA local
      final DateTime summer = resolver.computeAt(
        DateTime.utc(2026, 6, 15, 12),
        'America/Los_Angeles',
      );
      expect(summer.hour, 5);
    });

    test('未知の timezoneId で InvalidTimezoneIdException を throw', () {
      expect(
        () => resolver.computeAt(DateTime.utc(2026, 1, 15), 'Not/A_Zone'),
        throwsA(isA<InvalidTimezoneIdException>()),
      );
    });
  });
}
