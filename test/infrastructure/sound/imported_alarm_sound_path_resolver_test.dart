import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/domain/ports/imported_sound_repository.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';
import 'package:timer_utility/infrastructure/sound/imported_alarm_sound_path_resolver.dart';
import 'package:timer_utility/infrastructure/sound/imported_sound_storage_layout.dart';

class _MockImportedSoundRepository extends Mock
    implements ImportedSoundRepository {}

void main() {
  late Directory sandbox;
  late ImportedSoundStorageLayout layout;
  late _MockImportedSoundRepository repository;
  late ImportedAlarmSoundPathResolver resolver;

  final ImportedSound sound = ImportedSound.create(
    id: 'imported-1',
    displayName: 'Imported',
    format: ImportedSoundFormat.mp3,
    byteLength: 4,
    duration: const Duration(seconds: 3),
    contentHash:
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    createdAt: DateTime.utc(2026, 7, 16),
  );

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('sound_path_resolver_');
    layout = ImportedSoundStorageLayout(baseDirectory: () async => sandbox);
    repository = _MockImportedSoundRepository();
    resolver = ImportedAlarmSoundPathResolver(
      repository: repository,
      layout: layout,
    );
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test('メタデータが存在しないIDはnullへ解決する', () async {
    when(() => repository.findById('missing')).thenAnswer((_) async => null);

    expect(await resolver.resolve('missing'), isNull);
  });

  test('内部コピーが欠損しているIDはnullへ解決する', () async {
    when(() => repository.findById(sound.id)).thenAnswer((_) async => sound);

    expect(await resolver.resolve(sound.id), isNull);
  });

  test('メタデータと内部コピーが揃う場合だけ絶対パスへ解決する', () async {
    when(() => repository.findById(sound.id)).thenAnswer((_) async => sound);
    final File file = await layout.committedFile(sound.id, 'mp3');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(<int>[1, 2, 3, 4]);

    expect(await resolver.resolve(sound.id), file.path);
  });
}
