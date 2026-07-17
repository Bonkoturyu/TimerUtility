import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';

void main() {
  late Directory temporaryDirectory;
  late File databaseFile;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'timer_migration_v6_to_v7_',
    );
    databaseFile = File('${temporaryDirectory.path}/db.sqlite');
  });

  tearDown(() {
    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  test('v6からv7へ移行すると既存データを保持して取り込み音源テーブルを追加する', () async {
    final AppDatabase setup = AppDatabase.forTesting(
      NativeDatabase(databaseFile),
    );
    await setup.customStatement(
      'INSERT INTO timers '
      '(id, notification_id, label, duration_ms, status, '
      'interval_notification_enabled, created_at_utc_ms) '
      'VALUES (\'legacy\', 7, \'timer\', 60000, \'idle\', 0, 1700000000000)',
    );
    await setup.customStatement('DROP TABLE imported_sounds');
    await setup.customStatement('PRAGMA user_version = 6');
    await setup.close();

    final AppDatabase migrated = AppDatabase.forTesting(
      NativeDatabase(databaseFile),
    );
    addTearDown(migrated.close);

    expect(await migrated.select(migrated.timers).get(), hasLength(1));
    expect(await migrated.select(migrated.importedSounds).get(), isEmpty);
  });
}
