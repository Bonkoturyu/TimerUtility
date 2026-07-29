import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/imported_sound_import_service.dart';
import 'package:timer_utility/domain/ports/imported_sound_file_store.dart';
import 'package:timer_utility/domain/ports/imported_sound_picker.dart';
import 'package:timer_utility/domain/ports/imported_sound_probe.dart';
import 'package:timer_utility/domain/ports/imported_sound_repository.dart';
import 'package:timer_utility/domain/ports/storage_capacity_reader.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/domain/sound/imported_sound_exceptions.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';
import 'package:timer_utility/domain/sound/imported_sound_policy.dart';

class _MockPicker extends Mock implements ImportedSoundPicker {}

class _MockFileStore extends Mock implements ImportedSoundFileStore {}

class _MockProbe extends Mock implements ImportedSoundProbe {}

class _MockCapacityReader extends Mock implements StorageCapacityReader {}

class _MockRepository extends Mock implements ImportedSoundRepository {}

class _FakeImportedSound extends Fake implements ImportedSound {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeImportedSound());
    registerFallbackValue(const Stream<List<int>>.empty());
    registerFallbackValue(ImportedSoundFormat.mp3);
  });

  const String hash =
      '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a';
  final DateTime now = DateTime.utc(2026, 7, 16, 12);

  late _MockPicker picker;
  late _MockFileStore fileStore;
  late _MockProbe probe;
  late _MockCapacityReader capacityReader;
  late _MockRepository repository;
  late ImportedSoundImportService service;

  SelectedImportedSoundFile selected() => SelectedImportedSoundFile(
    name: 'my_alarm.mp3',
    mimeType: 'audio/mpeg',
    byteLength: 4,
    openRead: () => Stream<List<int>>.value(<int>[1, 2, 3, 4]),
  );

  setUp(() {
    picker = _MockPicker();
    fileStore = _MockFileStore();
    probe = _MockProbe();
    capacityReader = _MockCapacityReader();
    repository = _MockRepository();
    service = ImportedSoundImportService(
      picker: picker,
      fileStore: fileStore,
      probe: probe,
      storageCapacityReader: capacityReader,
      repository: repository,
      clock: Clock.fixed(now),
      idGenerator: () => 'sound-1',
    );

    when(() => picker.pickOne()).thenAnswer((_) async => selected());
    when(
      () => capacityReader.getAvailableBytes(),
    ).thenAnswer((_) async => 20_000_000_000);
    when(
      () => fileStore.stage(
        source: any(named: 'source'),
        expectedByteLength: any(named: 'expectedByteLength'),
      ),
    ).thenAnswer(
      (_) async => const StagedImportedSoundFile(
        token: 'stage-1',
        byteLength: 4,
        contentHash: hash,
      ),
    );
    when(() => probe.probe('stage-1')).thenAnswer(
      (_) async => const ImportedSoundProbeResult(
        format: ImportedSoundFormat.mp3,
        duration: Duration(seconds: 3),
      ),
    );
    when(() => repository.findAll()).thenAnswer((_) async => <ImportedSound>[]);
    when(
      () => fileStore.commit(
        token: any(named: 'token'),
        soundId: any(named: 'soundId'),
        format: any(named: 'format'),
      ),
    ).thenAnswer((_) async {});
    when(() => repository.upsert(any())).thenAnswer((_) async {});
    when(() => fileStore.discard(any())).thenAnswer((_) async {});
    when(() => fileStore.delete(any(), any())).thenAnswer((_) async {});
  });

  group('ImportedSoundImportService', () {
    test('prepareは検証済みstagingを確定せず返す', () async {
      final PrepareImportedSoundResult? result = await service.prepare(
        ImportedSoundPolicy.standard,
      );

      expect(result, isA<PreparedImportedSound>());
      final PreparedImportedSound prepared = result! as PreparedImportedSound;
      expect(prepared.candidate.displayName, 'my_alarm');
      expect(service.stagingTokenOf(prepared), 'stage-1');
      verifyNever(
        () => fileStore.commit(
          token: any(named: 'token'),
          soundId: any(named: 'soundId'),
          format: any(named: 'format'),
        ),
      );
      verifyNever(() => repository.upsert(any()));
      verifyNever(() => fileStore.discard(any()));
    });

    test('confirmはstagingとDBを原子的に確定する', () async {
      final PreparedImportedSound prepared =
          await service.prepare(ImportedSoundPolicy.standard)
              as PreparedImportedSound;

      final ImportedSound imported = await service.confirm(prepared);

      expect(imported.id, 'sound-1');
      verify(
        () => fileStore.commit(
          token: 'stage-1',
          soundId: 'sound-1',
          format: ImportedSoundFormat.mp3,
        ),
      ).called(1);
      verify(() => repository.upsert(imported)).called(1);
    });

    test('cancelは未確定stagingを破棄し、再実行しても安全', () async {
      final PreparedImportedSound prepared =
          await service.prepare(ImportedSoundPolicy.standard)
              as PreparedImportedSound;

      await service.cancel(prepared);
      await service.cancel(prepared);

      verify(() => fileStore.discard('stage-1')).called(1);
      verifyNever(
        () => fileStore.commit(
          token: any(named: 'token'),
          soundId: any(named: 'soundId'),
          format: any(named: 'format'),
        ),
      );
    });

    test('検証済みファイルとDBを確定する', () async {
      final ImportedSound? imported = await service.importOne(
        ImportedSoundPolicy.standard,
      );

      expect(imported?.id, 'sound-1');
      expect(imported?.displayName, 'my_alarm');
      expect(imported?.contentHash, hash);
      expect(imported?.createdAt, now);
      verify(
        () => fileStore.commit(
          token: 'stage-1',
          soundId: 'sound-1',
          format: ImportedSoundFormat.mp3,
        ),
      ).called(1);
      verify(() => repository.upsert(imported!)).called(1);
      verifyNever(() => fileStore.discard(any()));
    });

    test('ピッカーのキャンセルは更新を行わない', () async {
      when(() => picker.pickOne()).thenAnswer((_) async => null);

      expect(await service.importOne(ImportedSoundPolicy.standard), isNull);

      verifyNever(() => capacityReader.getAvailableBytes());
      verifyNever(
        () => fileStore.stage(
          source: any(named: 'source'),
          expectedByteLength: any(named: 'expectedByteLength'),
        ),
      );
    });

    test('上限超過ファイルは内部コピー前に拒否する', () async {
      when(() => picker.pickOne()).thenAnswer(
        (_) async => SelectedImportedSoundFile(
          name: 'too_large.mp3',
          mimeType: 'audio/mpeg',
          byteLength: ImportedSoundPolicy.standard.maxFileBytes + 1,
          openRead: () => const Stream<List<int>>.empty(),
        ),
      );

      await expectLater(
        service.prepare(ImportedSoundPolicy.standard),
        throwsA(isA<ImportedSoundFileSizeLimitException>()),
      );

      verifyNever(() => capacityReader.getAvailableBytes());
      verifyNever(
        () => fileStore.stage(
          source: any(named: 'source'),
          expectedByteLength: any(named: 'expectedByteLength'),
        ),
      );
      verifyNever(() => probe.probe(any()));
    });

    test('重複内容は確定せずstagingを破棄して既存音源を返す', () async {
      final ImportedSound existing = ImportedSound.create(
        id: 'existing',
        displayName: 'existing',
        format: ImportedSoundFormat.mp3,
        byteLength: 4,
        duration: const Duration(seconds: 3),
        contentHash: hash,
        createdAt: now,
      );
      when(
        () => repository.findAll(),
      ).thenAnswer((_) async => <ImportedSound>[existing]);

      final PrepareImportedSoundResult? result = await service.prepare(
        ImportedSoundPolicy.standard,
      );

      expect(result, isA<DuplicateImportedSound>());
      expect((result! as DuplicateImportedSound).existingSound.id, 'existing');
      verify(() => fileStore.discard('stage-1')).called(1);
      verifyNever(
        () => fileStore.commit(
          token: any(named: 'token'),
          soundId: any(named: 'soundId'),
          format: any(named: 'format'),
        ),
      );
    });

    test('DB更新失敗時は確定ファイルをロールバックする', () async {
      when(() => repository.upsert(any())).thenThrow(StateError('database'));

      await expectLater(
        service.importOne(ImportedSoundPolicy.standard),
        throwsA(isA<StateError>()),
      );

      verify(
        () => fileStore.delete('sound-1', ImportedSoundFormat.mp3),
      ).called(1);
    });

    test('コピー前に10 GBの残存容量を検証する', () async {
      when(
        () => capacityReader.getAvailableBytes(),
      ).thenAnswer((_) async => 10_000_000_003);

      await expectLater(
        service.importOne(ImportedSoundPolicy.standard),
        throwsA(isA<InsufficientImportedSoundStorageException>()),
      );

      verifyNever(
        () => fileStore.stage(
          source: any(named: 'source'),
          expectedByteLength: any(named: 'expectedByteLength'),
        ),
      );
    });
  });
}
