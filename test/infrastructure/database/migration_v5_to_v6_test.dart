import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';

void main() {
  late Directory tmpDir;
  late File tmpFile;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('timer_migration_v5_to_v6_');
    tmpFile = File('${tmpDir.path}/db.sqlite');
  });

  tearDown(() {
    try {
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('v5の既存タイマーは定間隔通知OFFのままv6へ移行する', () async {
    final setup = AppDatabase.forTesting(NativeDatabase(tmpFile));
    await setup.customStatement('ALTER TABLE timers RENAME TO timers_v6');
    await setup.customStatement(
      'CREATE TABLE timers ('
      'id TEXT NOT NULL PRIMARY KEY, notification_id INTEGER NOT NULL, '
      'label TEXT NOT NULL, duration_ms INTEGER NOT NULL, '
      'end_at_utc_ms INTEGER NULL, paused_remaining_ms INTEGER NULL, '
      'status TEXT NOT NULL, sound_id TEXT NULL, '
      'created_at_utc_ms INTEGER NOT NULL)',
    );
    await setup.customStatement(
      "INSERT INTO timers VALUES ('legacy', 7, 'pace', 120000, NULL, NULL, "
      "'idle', NULL, 1700000000000)",
    );
    await setup.customStatement('DROP TABLE timers_v6');
    await setup.customStatement('PRAGMA user_version = 5');
    await setup.close();

    final db = AppDatabase.forTesting(NativeDatabase(tmpFile));
    addTearDown(db.close);
    final row = await (db.select(
      db.timers,
    )..where((t) => t.id.equals('legacy'))).getSingle();

    expect(row.intervalNotificationEnabled, isFalse);
  });
}
