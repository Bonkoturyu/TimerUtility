import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/domain/sound/imported_sound_exceptions.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';
import 'package:timer_utility/infrastructure/sound/app_private_imported_sound_file_store.dart';
import 'package:timer_utility/infrastructure/sound/imported_sound_storage_layout.dart';

class _MockIOSink extends Mock implements IOSink {}

void main() {
  late Directory sandbox;
  late ImportedSoundStorageLayout layout;
  late AppPrivateImportedSoundFileStore store;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('imported_sound_store_');
    layout = ImportedSoundStorageLayout(baseDirectory: () async => sandbox);
    store = AppPrivateImportedSoundFileStore(
      layout: layout,
      tokenGenerator: () => 'stage-1',
    );
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test('ストリームをstagingへ保存しSHA-256を返す', () async {
    final staged = await store.stage(
      source: Stream<List<int>>.fromIterable(<List<int>>[
        <int>[1, 2],
        <int>[3, 4],
      ]),
      expectedByteLength: 4,
    );

    expect(staged.token, 'stage-1');
    expect(staged.byteLength, 4);
    expect(
      staged.contentHash,
      '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a',
    );
    expect(await (await layout.stagedFile('stage-1')).readAsBytes(), <int>[
      1,
      2,
      3,
      4,
    ]);
  });

  test('申告サイズと実サイズが異なる場合は一時ファイルを残さない', () async {
    expect(
      () => store.stage(
        source: Stream<List<int>>.value(<int>[1, 2, 3]),
        expectedByteLength: 4,
      ),
      throwsA(isA<ImportedSoundReadException>()),
    );

    expect(await (await layout.stagedFile('stage-1')).exists(), isFalse);
  });

  test('close失敗時も元例外を保持して一時ファイルを削除する', () async {
    final _MockIOSink output = _MockIOSink();
    int closeCalls = 0;
    when(() => output.flush()).thenAnswer((_) async {});
    when(() => output.close()).thenAnswer((_) async {
      closeCalls++;
      throw StateError(closeCalls == 1 ? 'primary close' : 'cleanup close');
    });
    final AppPrivateImportedSoundFileStore failingStore =
        AppPrivateImportedSoundFileStore(
          layout: layout,
          tokenGenerator: () => 'stage-1',
          outputSinkFactory: (File file) {
            file.createSync(recursive: true);
            return output;
          },
        );

    await expectLater(
      () => failingStore.stage(
        source: Stream<List<int>>.value(<int>[1]),
        expectedByteLength: 1,
      ),
      throwsA(
        isA<StateError>().having(
          (StateError error) => error.message,
          'message',
          'primary close',
        ),
      ),
    );

    expect(closeCalls, 2);
    expect(await (await layout.stagedFile('stage-1')).exists(), isFalse);
  });

  test('検証済みファイルをIDと形式で確定できる', () async {
    await store.stage(
      source: Stream<List<int>>.value(<int>[1]),
      expectedByteLength: 1,
    );

    await store.commit(
      token: 'stage-1',
      soundId: 'sound-1',
      format: ImportedSoundFormat.mp3,
    );

    expect(await (await layout.stagedFile('stage-1')).exists(), isFalse);
    final File committed = await layout.committedFile('sound-1', 'mp3');
    expect(await committed.readAsBytes(), <int>[1]);
  });

  test('確定ファイルを削除待ちへ移動し列挙・復元・破棄できる', () async {
    await store.stage(
      source: Stream<List<int>>.value(<int>[1]),
      expectedByteLength: 1,
    );
    await store.commit(
      token: 'stage-1',
      soundId: 'sound-1',
      format: ImportedSoundFormat.mp3,
    );

    await store.quarantine('sound-1', ImportedSoundFormat.mp3);

    expect(
      await (await layout.committedFile('sound-1', 'mp3')).exists(),
      isFalse,
    );
    final quarantined = await store.findQuarantined();
    expect(quarantined.single.soundId, 'sound-1');
    expect(quarantined.single.format, ImportedSoundFormat.mp3);

    await store.restoreQuarantined('sound-1', ImportedSoundFormat.mp3);
    expect(
      await (await layout.committedFile('sound-1', 'mp3')).exists(),
      isTrue,
    );
    await store.quarantine('sound-1', ImportedSoundFormat.mp3);
    await store.purgeQuarantined('sound-1', ImportedSoundFormat.mp3);
    expect(await store.findQuarantined(), isEmpty);
  });

  test('確定ファイルが既に欠損していてもquarantineは冪等に完了する', () async {
    await store.quarantine('missing', ImportedSoundFormat.mp3);

    expect(await store.findQuarantined(), isEmpty);
  });
}
