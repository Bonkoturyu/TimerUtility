import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/imported_sound_deletion_service.dart';
import 'package:timer_utility/application/imported_sound_recovery_service.dart';
import 'package:timer_utility/domain/ports/imported_sound_file_store.dart';
import 'package:timer_utility/domain/ports/imported_sound_reference_store.dart';
import 'package:timer_utility/domain/ports/imported_sound_repository.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';

class _MockRepository extends Mock implements ImportedSoundRepository {}

class _MockReferenceStore extends Mock implements ImportedSoundReferenceStore {}

class _MockFileStore extends Mock implements ImportedSoundFileStore {}

class _MockPreferences extends Mock implements UserPreferences {}

void main() {
  final ImportedSound sound = ImportedSound.create(
    id: 'imported',
    displayName: 'Imported',
    format: ImportedSoundFormat.mp3,
    byteLength: 4,
    duration: const Duration(seconds: 3),
    contentHash:
        '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a',
    createdAt: DateTime.utc(2026, 7, 16),
  );

  late _MockRepository repository;
  late _MockReferenceStore referenceStore;
  late _MockFileStore fileStore;
  late _MockPreferences preferences;
  late ImportedSoundDeletionService service;

  setUp(() {
    repository = _MockRepository();
    referenceStore = _MockReferenceStore();
    fileStore = _MockFileStore();
    preferences = _MockPreferences();
    service = ImportedSoundDeletionService(
      repository: repository,
      referenceStore: referenceStore,
      fileStore: fileStore,
      preferences: preferences,
    );
    when(() => repository.findById('imported')).thenAnswer((_) async => sound);
    when(
      () => preferences.getString(UserPreferenceKeys.defaultAlarmSoundId),
    ).thenAnswer((_) async => 'imported');
    when(() => preferences.setString(any(), any())).thenAnswer((_) async {});
    when(
      () => fileStore.quarantine('imported', ImportedSoundFormat.mp3),
    ).thenAnswer((_) async {});
    when(
      () => fileStore.restoreQuarantined('imported', ImportedSoundFormat.mp3),
    ).thenAnswer((_) async {});
    when(
      () => fileStore.purgeQuarantined('imported', ImportedSoundFormat.mp3),
    ).thenAnswer((_) async {});
    when(() => fileStore.findStagedTokens()).thenAnswer((_) async => const []);
    when(() => fileStore.findCommitted()).thenAnswer((_) async => const []);
    when(() => fileStore.findQuarantined()).thenAnswer((_) async => const []);
    when(
      () => referenceStore.replaceReferencesAndDeleteMetadata(
        soundId: 'imported',
        fallbackSoundId: 'default',
      ),
    ).thenAnswer((_) async {});
  });

  group('ImportedSoundDeletionService', () {
    test('quarantine→DB→設定→purgeの順で削除する', () async {
      final ImportedSoundDeletionResult result = await service.delete(
        'imported',
      );

      expect(result.deleted, isTrue);
      expect(result.defaultSettingChanged, isTrue);
      expect(result.preferenceRepairPending, isFalse);
      expect(result.cleanupPending, isFalse);
      verifyInOrder(<dynamic Function()>[
        () => fileStore.quarantine('imported', ImportedSoundFormat.mp3),
        () => referenceStore.replaceReferencesAndDeleteMetadata(
          soundId: 'imported',
          fallbackSoundId: 'default',
        ),
        () => preferences.setString(
          UserPreferenceKeys.defaultAlarmSoundId,
          'default',
        ),
        () => fileStore.purgeQuarantined('imported', ImportedSoundFormat.mp3),
      ]);
    });

    test('metadata削除済みでも同じIDのquarantineを再purgeする', () async {
      when(
        () => repository.findById('already-deleted'),
      ).thenAnswer((_) async => null);
      when(() => fileStore.findQuarantined()).thenAnswer(
        (_) async => const <QuarantinedImportedSoundFile>[
          QuarantinedImportedSoundFile(
            soundId: 'already-deleted',
            format: ImportedSoundFormat.aac,
          ),
          QuarantinedImportedSoundFile(
            soundId: 'other',
            format: ImportedSoundFormat.mp3,
          ),
        ],
      );
      when(
        () => fileStore.purgeQuarantined(
          'already-deleted',
          ImportedSoundFormat.aac,
        ),
      ).thenAnswer((_) async {});

      final ImportedSoundDeletionResult result = await service.delete(
        'already-deleted',
      );

      expect(result.deleted, isFalse);
      expect(result.cleanupPending, isFalse);
      verify(
        () => fileStore.purgeQuarantined(
          'already-deleted',
          ImportedSoundFormat.aac,
        ),
      ).called(1);
      verifyNever(
        () => fileStore.purgeQuarantined('other', ImportedSoundFormat.mp3),
      );
      verifyZeroInteractions(referenceStore);
      verifyNever(() => preferences.getString(any()));
    });

    test('metadata削除済みの再purge失敗はcleanup pendingで返す', () async {
      when(
        () => repository.findById('already-deleted'),
      ).thenAnswer((_) async => null);
      when(() => fileStore.findQuarantined()).thenAnswer(
        (_) async => const <QuarantinedImportedSoundFile>[
          QuarantinedImportedSoundFile(
            soundId: 'already-deleted',
            format: ImportedSoundFormat.aac,
          ),
        ],
      );
      when(
        () => fileStore.purgeQuarantined(
          'already-deleted',
          ImportedSoundFormat.aac,
        ),
      ).thenThrow(StateError('purge'));

      final ImportedSoundDeletionResult result = await service.delete(
        'already-deleted',
      );

      expect(result.deleted, isFalse);
      expect(result.cleanupPending, isTrue);
    });

    test('quarantine失敗時はDBと設定を変更しない', () async {
      when(
        () => fileStore.quarantine('imported', ImportedSoundFormat.mp3),
      ).thenThrow(StateError('quarantine'));

      await expectLater(service.delete('imported'), throwsStateError);

      verifyNever(
        () => referenceStore.replaceReferencesAndDeleteMetadata(
          soundId: 'imported',
          fallbackSoundId: 'default',
        ),
      );
      verifyNever(() => preferences.setString(any(), any()));
    });

    test('DB失敗時はquarantineを復元し、設定を変更しない', () async {
      when(
        () => referenceStore.replaceReferencesAndDeleteMetadata(
          soundId: 'imported',
          fallbackSoundId: 'default',
        ),
      ).thenThrow(StateError('database'));

      await expectLater(service.delete('imported'), throwsStateError);

      verify(
        () => fileStore.restoreQuarantined('imported', ImportedSoundFormat.mp3),
      ).called(1);
      verifyNever(() => preferences.setString(any(), any()));
    });

    test('DB確定後の設定保存失敗は削除を戻さずrepair pendingで返す', () async {
      when(
        () => preferences.setString(
          UserPreferenceKeys.defaultAlarmSoundId,
          'default',
        ),
      ).thenThrow(StateError('preferences'));

      final ImportedSoundDeletionResult result = await service.delete(
        'imported',
      );

      expect(result.deleted, isTrue);
      expect(result.preferenceRepairPending, isTrue);
      verifyNever(
        () => fileStore.restoreQuarantined('imported', ImportedSoundFormat.mp3),
      );
      verify(
        () => fileStore.purgeQuarantined('imported', ImportedSoundFormat.mp3),
      ).called(1);
    });

    test('purge失敗は安全なcleanup pendingとして返す', () async {
      when(
        () => fileStore.purgeQuarantined('imported', ImportedSoundFormat.mp3),
      ).thenThrow(StateError('purge'));

      final ImportedSoundDeletionResult result = await service.delete(
        'imported',
      );

      expect(result.deleted, isTrue);
      expect(result.cleanupPending, isTrue);
    });
  });

  group('ImportedSoundRecoveryService', () {
    test('中断したstagingとメタデータのない確定ファイルを削除する', () async {
      when(
        () => fileStore.findStagedTokens(),
      ).thenAnswer((_) async => const <String>['stage-orphan']);
      when(() => fileStore.discard('stage-orphan')).thenAnswer((_) async {});
      when(() => fileStore.findCommitted()).thenAnswer(
        (_) async => const <CommittedImportedSoundFile>[
          CommittedImportedSoundFile(
            soundId: 'orphan',
            format: ImportedSoundFormat.aac,
          ),
          CommittedImportedSoundFile(
            soundId: 'imported',
            format: ImportedSoundFormat.mp3,
          ),
        ],
      );
      when(() => repository.findById('orphan')).thenAnswer((_) async => null);
      when(
        () => fileStore.delete('orphan', ImportedSoundFormat.aac),
      ).thenAnswer((_) async {});

      await ImportedSoundRecoveryService(
        repository: repository,
        fileStore: fileStore,
      ).recover();

      verify(() => fileStore.discard('stage-orphan')).called(1);
      verify(
        () => fileStore.delete('orphan', ImportedSoundFormat.aac),
      ).called(1);
      verifyNever(() => fileStore.delete('imported', ImportedSoundFormat.mp3));
    });

    test('metadataの有無に応じて復元または破棄する', () async {
      when(() => fileStore.findQuarantined()).thenAnswer(
        (_) async => const <QuarantinedImportedSoundFile>[
          QuarantinedImportedSoundFile(
            soundId: 'retained',
            format: ImportedSoundFormat.mp3,
          ),
          QuarantinedImportedSoundFile(
            soundId: 'deleted',
            format: ImportedSoundFormat.aac,
          ),
        ],
      );
      when(
        () => repository.findById('retained'),
      ).thenAnswer((_) async => sound);
      when(() => repository.findById('deleted')).thenAnswer((_) async => null);
      when(
        () => fileStore.restoreQuarantined('retained', ImportedSoundFormat.mp3),
      ).thenAnswer((_) async {});
      when(
        () => fileStore.purgeQuarantined('deleted', ImportedSoundFormat.aac),
      ).thenAnswer((_) async {});

      await ImportedSoundRecoveryService(
        repository: repository,
        fileStore: fileStore,
      ).recover();

      verify(
        () => fileStore.restoreQuarantined('retained', ImportedSoundFormat.mp3),
      ).called(1);
      verify(
        () => fileStore.purgeQuarantined('deleted', ImportedSoundFormat.aac),
      ).called(1);
    });

    test('1件失敗しても後続を処理し、最後に失敗件数を報告する', () async {
      when(() => fileStore.findQuarantined()).thenAnswer(
        (_) async => const <QuarantinedImportedSoundFile>[
          QuarantinedImportedSoundFile(
            soundId: 'broken',
            format: ImportedSoundFormat.aac,
          ),
          QuarantinedImportedSoundFile(
            soundId: 'retained',
            format: ImportedSoundFormat.mp3,
          ),
        ],
      );
      when(() => repository.findById('broken')).thenAnswer((_) async => null);
      when(
        () => fileStore.purgeQuarantined('broken', ImportedSoundFormat.aac),
      ).thenThrow(StateError('broken'));
      when(
        () => repository.findById('retained'),
      ).thenAnswer((_) async => sound);
      when(
        () => fileStore.restoreQuarantined('retained', ImportedSoundFormat.mp3),
      ).thenAnswer((_) async {});

      final Future<void> recovery = ImportedSoundRecoveryService(
        repository: repository,
        fileStore: fileStore,
      ).recover();

      await expectLater(
        recovery,
        throwsA(
          isA<ImportedSoundRecoveryException>().having(
            (ImportedSoundRecoveryException error) => error.failureCount,
            'failureCount',
            1,
          ),
        ),
      );
      verify(
        () => fileStore.restoreQuarantined('retained', ImportedSoundFormat.mp3),
      ).called(1);
    });
  });
}
