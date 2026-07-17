import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/drift_imported_sound_repository.dart';

void main() {
  late AppDatabase db;
  late DriftImportedSoundRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftImportedSoundRepository(db);
  });

  tearDown(() => db.close());

  ImportedSound sound({
    required String id,
    String? hash,
    DateTime? createdAt,
  }) => ImportedSound.create(
    id: id,
    displayName: id,
    format: ImportedSoundFormat.mp3,
    byteLength: 1_000_000,
    duration: const Duration(seconds: 30),
    contentHash: hash ?? id.codeUnits.first.toRadixString(16).padLeft(64, '0'),
    createdAt: createdAt ?? DateTime.utc(2026, 7, 16),
  );

  test('空DBは空リストを返す', () async {
    expect(await repository.findAll(), isEmpty);
  });

  test('upsertしたメタデータをIDで取得できる', () async {
    final ImportedSound input = sound(id: 'a');
    await repository.upsert(input);

    expect(await repository.findById('a'), input);
  });

  test('同じIDのupsertは表示名を更新する', () async {
    final ImportedSound input = sound(id: 'a');
    await repository.upsert(input);
    await repository.upsert(input.rename('renamed'));

    expect((await repository.findById('a'))?.displayName, 'renamed');
    expect(await repository.findAll(), hasLength(1));
  });

  test('SHA-256内容ハッシュから既存音源を取得できる', () async {
    final ImportedSound input = sound(id: 'a');
    await repository.upsert(input);

    expect(await repository.findByContentHash(input.contentHash), input);
    expect(
      await repository.findByContentHash(List<String>.filled(64, 'f').join()),
      isNull,
    );
  });

  test('findAllは作成日時順で返す', () async {
    await repository.upsert(
      sound(id: 'b', createdAt: DateTime.utc(2026, 7, 16, 2)),
    );
    await repository.upsert(
      sound(id: 'a', createdAt: DateTime.utc(2026, 7, 16, 1)),
    );

    expect(
      (await repository.findAll()).map((ImportedSound value) => value.id),
      <String>['a', 'b'],
    );
  });

  test('deleteは対象だけを削除し存在しないIDはno-op', () async {
    await repository.upsert(sound(id: 'a'));
    await repository.delete('missing');
    await repository.delete('a');

    expect(await repository.findAll(), isEmpty);
  });

  test('異なるIDで同じ内容ハッシュを登録できない', () async {
    final ImportedSound first = sound(id: 'a');
    await repository.upsert(first);

    expect(
      () => repository.upsert(sound(id: 'b', hash: first.contentHash)),
      throwsA(anything),
    );
  });
}
