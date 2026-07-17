import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/drift_imported_sound_reference_store.dart';

void main() {
  late AppDatabase db;
  late DriftImportedSoundReferenceStore store;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = DriftImportedSoundReferenceStore(db);
    await db
        .into(db.timers)
        .insert(
          TimersCompanion.insert(
            id: 'timer',
            notificationId: 1,
            label: '',
            durationMs: 1000,
            status: 'idle',
            soundId: const Value<String?>('imported'),
            createdAtUtcMs: 0,
          ),
        );
    await db
        .into(db.alarms)
        .insert(
          AlarmsCompanion.insert(
            id: 'alarm',
            notificationId: 2,
            label: '',
            targetTimeMinutes: 0,
            repeatKind: 'once',
            repeatDaysBitmask: 0,
            snoozeMinutes: 5,
            enabled: true,
            soundId: const Value<String?>('imported'),
            createdAtUtcMs: 0,
          ),
        );
    await db
        .into(db.presets)
        .insert(
          PresetsCompanion.insert(
            id: 'preset',
            label: '',
            durationMs: 1000,
            soundId: const Value<String?>('imported'),
            createdAtUtcMs: 0,
          ),
        );
    await db
        .into(db.importedSounds)
        .insert(
          ImportedSoundsCompanion.insert(
            id: 'imported',
            displayName: 'Imported',
            format: 'mp3',
            byteLength: 1,
            durationMs: 1000,
            contentHash: List<String>.filled(64, 'a').join(),
            createdAtUtcMs: 0,
          ),
        );
  });

  tearDown(() => db.close());

  test('3テーブルの参照置換とメタデータ削除を一括実行する', () async {
    await store.replaceReferencesAndDeleteMetadata(
      soundId: 'imported',
      fallbackSoundId: 'default',
    );

    expect((await db.select(db.timers).getSingle()).soundId, 'default');
    expect((await db.select(db.alarms).getSingle()).soundId, 'default');
    expect(
      (await (db.select(db.presets)
                ..where(($PresetsTable table) => table.id.equals('preset')))
              .getSingle())
          .soundId,
      'default',
    );
    expect(await db.select(db.importedSounds).get(), isEmpty);
  });

  test('途中の更新が失敗した場合は全変更をrollbackする', () async {
    await db.customStatement('''
      CREATE TRIGGER fail_preset_update
      BEFORE UPDATE ON presets
      BEGIN
        SELECT RAISE(ABORT, 'forced failure');
      END
    ''');

    await expectLater(
      store.replaceReferencesAndDeleteMetadata(
        soundId: 'imported',
        fallbackSoundId: 'default',
      ),
      throwsA(anything),
    );

    expect((await db.select(db.timers).getSingle()).soundId, 'imported');
    expect((await db.select(db.alarms).getSingle()).soundId, 'imported');
    expect(
      (await (db.select(db.presets)
                ..where(($PresetsTable table) => table.id.equals('preset')))
              .getSingle())
          .soundId,
      'imported',
    );
    expect(await db.select(db.importedSounds).get(), hasLength(1));
  });
}
