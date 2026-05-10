import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/timezone_catalog.dart';
import 'package:timer_utility/infrastructure/location/country_to_timezone.dart';

void main() {
  group('CountryToTimezone.lookup', () {
    test(
      'every single-country catalog preset is reachable from at least one ISO code',
      () {
        // 1 国 1 TZ ルール (US→NY / CA→Toronto / RU→Moscow / AU→Sydney /
        // BR→Sao Paulo / CN→Shanghai) のため、その国のサブ区画 TZ
        // (例: America/Los_Angeles = US Pacific) は alpha-2 経由では
        // 到達不能 — そちらは picker からの手動選択でカバーする。
        // 本テストは「単一 TZ 国の catalog エントリ」が必ず lookup
        // で拾えることを保証する。
        const Set<String> pickerOnlyTzs = <String>{
          // US subdivisions
          'America/Chicago',
          'America/Denver',
          'America/Los_Angeles',
          'America/Anchorage',
          'Pacific/Honolulu',
          // CA subdivision
          'America/Vancouver',
        };
        final Set<String> catalogTzs = TimezoneCatalog.presets
            .map((TimezoneCatalogEntry e) => e.timezoneId)
            .toSet();
        // ASCII 範囲の全 alpha-2 を総当たりで lookup し、得られた値域を集める。
        final Set<String> reachableTzs = <String>{};
        for (int a = 'A'.codeUnitAt(0); a <= 'Z'.codeUnitAt(0); a++) {
          for (int b = 'A'.codeUnitAt(0); b <= 'Z'.codeUnitAt(0); b++) {
            final String iso = String.fromCharCodes(<int>[a, b]);
            final String? tz = CountryToTimezone.lookup(iso);
            if (tz != null) {
              reachableTzs.add(tz);
            }
          }
        }
        final Set<String> shouldBeReachable = catalogTzs.difference(
          pickerOnlyTzs,
        );
        final Set<String> missing = shouldBeReachable.difference(reachableTzs);
        expect(
          missing,
          isEmpty,
          reason:
              'TimezoneCatalog presets not reachable via CountryToTimezone: '
              '$missing',
        );
      },
    );

    test('lookup is case-insensitive', () {
      expect(CountryToTimezone.lookup('JP'), 'Asia/Tokyo');
      expect(CountryToTimezone.lookup('jp'), 'Asia/Tokyo');
      expect(CountryToTimezone.lookup('Jp'), 'Asia/Tokyo');
      expect(CountryToTimezone.lookup('uS'), 'America/New_York');
    });

    test('returns null for codes not in the table', () {
      // 'ZZ' は ISO 3166-1 で「ユーザ割当領域」、本マップでは未登録。
      expect(CountryToTimezone.lookup('ZZ'), isNull);
      // 空文字 / 単一文字も未登録扱い (無理に正規化しない)。
      expect(CountryToTimezone.lookup(''), isNull);
      expect(CountryToTimezone.lookup('X'), isNull);
    });
  });
}
