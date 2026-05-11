import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/clock_entry.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/drift_clock_entry_repository.dart';

/// Drift v4 → v5 migration test: `clock_locations` → `clock_entries`
/// リネーム (Phase 11)。
///
/// 戦略: 一時ファイル DB を 2 回 open する。
///   1. 1 回目 (seedV4Database): schemaVersion=4 ユーザを模擬。
///      [AppDatabase] を一度 open すると v5 schema が作られるので、
///      `customStatement` で `clock_entries` を DROP し直して、v4 当時の
///      `clock_locations` を生 SQL で再構築する。最後に
///      `PRAGMA user_version = 4` を打ち、close。
///   2. 2 回目: 同じファイルに対して通常の [AppDatabase] を open する。
///      Drift が `user_version=4` を読み取って onUpgrade(from: 4, to: 5)
///      を実行 → v5 migration の INSERT…SELECT + DROP が走る。
///
/// in-memory DB 方式 (NativeDatabase.memory()) は 2 回目 open で別 DB に
/// なってしまい migration を検証できないため一時ファイル方式を採用。
/// `package:sqlite3` を直接 import すると pubspec.yaml への依存追加が
/// 必要 (transitive のままでは lint info 扱い) なので、Drift 公開 API の
/// `customStatement` 経由に統一している。
void main() {
  late Directory tmpDir;
  late File tmpFile;

  setUp(() {
    // OS 任せの一意 temp ディレクトリ生成。`DateTime.now()` 直接呼び出しを
    // 避ける (`.gemini/styleguide.md` L50 禁止事項) と同時に、並列テスト
    // 実行時のファイル名衝突も完全に避けられる。
    tmpDir = Directory.systemTemp.createTempSync('clock_migration_v4_to_v5_');
    tmpFile = File('${tmpDir.path}/db.sqlite');
  });

  tearDown(() {
    try {
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    } catch (_) {
      // Best-effort: Windows can hold a transient lock on sqlite
      // shared-cache files even after close(); not worth failing
      // the test over.
    }
  });

  /// 一時ファイルを「v4 ユーザが直前まで使っていた状態」にする。
  /// AppDatabase を 1 度 open すれば onCreate が走って v5 schema が
  /// できるので、それを巻き戻して v4 当時のテーブル形に置き換える。
  Future<void> seedV4Database(List<List<Object?>> rows) async {
    final AppDatabase setup = AppDatabase.forTesting(NativeDatabase(tmpFile));
    try {
      // 1. v5 で作られた clock_entries を DROP。
      await setup.customStatement('DROP TABLE clock_entries');
      // 2. v4 schema の clock_locations を生 SQL で再構築。
      //    本番 app_database.dart の table 定義と同じカラム列。
      await setup.customStatement(
        'CREATE TABLE clock_locations ('
        'id TEXT NOT NULL PRIMARY KEY, '
        'display_name TEXT NOT NULL, '
        'timezone_id TEXT NOT NULL, '
        'is_current_location INTEGER NOT NULL '
        'CHECK (is_current_location IN (0, 1)), '
        'display_order INTEGER NOT NULL, '
        'created_at_utc_ms INTEGER NOT NULL)',
      );
      // 3. 行投入。customStatement の bind args は素のスカラー
      //    (String / int / bool / num / null / List<int>) を直接渡す。
      for (final List<Object?> row in rows) {
        await setup.customStatement(
          'INSERT INTO clock_locations '
          '(id, display_name, timezone_id, is_current_location, '
          'display_order, created_at_utc_ms) VALUES (?, ?, ?, ?, ?, ?)',
          row,
        );
      }
      // 4. user_version を 4 に巻き戻し、次回 open で Migrator が
      //    from=4 と認識するようにする。
      await setup.customStatement('PRAGMA user_version = 4');
    } finally {
      await setup.close();
    }
  }

  test('v4 で投入した 2 行は v5 open 後の clock_entries にコピーされる', () async {
    await seedV4Database(<List<Object?>>[
      <Object?>['id-1', 'Tokyo', 'Asia/Tokyo', 1, 0, 1700000000000],
      <Object?>['id-2', 'New York', 'America/New_York', 0, 1, 1700000010000],
    ]);

    final AppDatabase db = AppDatabase.forTesting(NativeDatabase(tmpFile));
    addTearDown(db.close);
    final DriftClockEntryRepository repo = DriftClockEntryRepository(db);

    final List<ClockEntry> all = await repo.findAll();
    expect(all.length, 2);
    expect(all.map((ClockEntry e) => e.id).toList(), <String>['id-1', 'id-2']);
    expect(all[0].displayName, 'Tokyo');
    expect(all[0].timezoneId, 'Asia/Tokyo');
    expect(all[1].displayName, 'New York');
    expect(all[1].timezoneId, 'America/New_York');

    // 旧テーブルが DROP されていることを確認 (sqlite_master を直接覗く)。
    final List<dynamic> legacy = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type='table' AND name='clock_locations'",
        )
        .get();
    expect(legacy, isEmpty, reason: 'clock_locations が DROP されていない');
  });

  test('v4 で空 clock_locations の場合、v5 では空 clock_entries になる', () async {
    await seedV4Database(<List<Object?>>[]);

    final AppDatabase db = AppDatabase.forTesting(NativeDatabase(tmpFile));
    addTearDown(db.close);
    final DriftClockEntryRepository repo = DriftClockEntryRepository(db);

    expect(await repo.findAll(), isEmpty);

    final List<dynamic> legacy = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type='table' AND name='clock_locations'",
        )
        .get();
    expect(legacy, isEmpty, reason: 'clock_locations が DROP されていない');
  });

  test('is_current_location=1 の行は isCurrentLocation == true で読める', () async {
    await seedV4Database(<List<Object?>>[
      <Object?>['home', 'Tokyo', 'Asia/Tokyo', 1, 0, 1700000000000],
    ]);

    final AppDatabase db = AppDatabase.forTesting(NativeDatabase(tmpFile));
    addTearDown(db.close);
    final DriftClockEntryRepository repo = DriftClockEntryRepository(db);

    final ClockEntry? row = await repo.findById('home');
    expect(row, isNotNull);
    expect(row!.isCurrentLocation, isTrue);
  });
}
