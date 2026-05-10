import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/timezone_catalog.dart';

void main() {
  group('TimezoneCatalog.presets', () {
    test('件数は 20-30 の範囲 (主要都市プリセットの設計上限)', () {
      expect(TimezoneCatalog.presets.length, inInclusiveRange(20, 30));
    });

    test('timezoneId は一意 (重複登録なし)', () {
      final List<String> ids = TimezoneCatalog.presets
          .map((TimezoneCatalogEntry e) => e.timezoneId)
          .toList();
      expect(ids.toSet().length, ids.length);
    });

    test('displayName は全件非空', () {
      for (final TimezoneCatalogEntry e in TimezoneCatalog.presets) {
        expect(e.displayName, isNotEmpty, reason: 'tz=${e.timezoneId}');
      }
    });

    test('timezoneId は IANA 形式 (Region/City にスラッシュを含む)', () {
      // 厳密な IANA validator は重いので、最低限の形式チェックだけ。
      // 実際の妥当性は TimezoneResolver adapter が render 時に弾く。
      for (final TimezoneCatalogEntry e in TimezoneCatalog.presets) {
        expect(
          e.timezoneId.contains('/'),
          isTrue,
          reason: 'IANA 形式 (Region/City) を想定: ${e.timezoneId}',
        );
        expect(e.timezoneId.trim(), e.timezoneId);
      }
    });

    test('Tokyo (Asia/Tokyo) が含まれる (国内ユーザの最低保証)', () {
      final bool found = TimezoneCatalog.presets.any(
        (TimezoneCatalogEntry e) => e.timezoneId == 'Asia/Tokyo',
      );
      expect(found, isTrue);
    });
  });
}
