import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_repository_provider.dart';
import 'package:timer_utility/application/imported_sound_deletion_controller.dart';
import 'package:timer_utility/application/imported_sound_deletion_service.dart';
import 'package:timer_utility/application/imported_sound_file_store_provider.dart';
import 'package:timer_utility/application/imported_sound_reference_store_provider.dart';
import 'package:timer_utility/application/imported_sound_repository_provider.dart';
import 'package:timer_utility/application/preset_repository_provider.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/application/user_preferences_provider.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/ports/alarm_repository.dart';
import 'package:timer_utility/domain/ports/imported_sound_file_store.dart';
import 'package:timer_utility/domain/ports/imported_sound_reference_store.dart';
import 'package:timer_utility/domain/ports/imported_sound_repository.dart';
import 'package:timer_utility/domain/ports/preset_repository.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/ports/user_preferences.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';

class _MockImportedRepository extends Mock implements ImportedSoundRepository {}

class _MockReferenceStore extends Mock implements ImportedSoundReferenceStore {}

class _MockFileStore extends Mock implements ImportedSoundFileStore {}

class _MockPreferences extends Mock implements UserPreferences {}

class _EmptyTimerRepository implements TimerRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<TimerEntity>> findAll() async => const <TimerEntity>[];

  @override
  Future<TimerEntity?> findById(String id) async => null;

  @override
  Future<void> upsert(TimerEntity entity) async {}
}

class _EmptyAlarmRepository implements AlarmRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<AlarmEntity>> findAll() async => const <AlarmEntity>[];

  @override
  Future<AlarmEntity?> findById(String id) async => null;

  @override
  Future<void> upsert(AlarmEntity entity) async {}
}

class _EmptyPresetRepository implements PresetRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Preset>> findAll() async => const <Preset>[];

  @override
  Future<Preset?> findById(String id) async => null;

  @override
  Future<void> replaceAll(List<Preset> entities) async {}

  @override
  Future<void> upsert(Preset entity) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('同じIDの並行deleteは同じFutureへcoalesceする', () async {
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
    final Completer<ImportedSound?> lookupGate = Completer<ImportedSound?>();
    final _MockImportedRepository importedRepository =
        _MockImportedRepository();
    final _MockReferenceStore referenceStore = _MockReferenceStore();
    final _MockFileStore fileStore = _MockFileStore();
    final _MockPreferences preferences = _MockPreferences();
    when(
      () => importedRepository.findById('imported'),
    ).thenAnswer((_) => lookupGate.future);
    when(() => preferences.getString(any())).thenAnswer((_) async => null);
    when(() => preferences.getInt(any())).thenAnswer((_) async => null);
    when(
      () => fileStore.quarantine('imported', ImportedSoundFormat.mp3),
    ).thenAnswer((_) async {});
    when(
      () => fileStore.purgeQuarantined('imported', ImportedSoundFormat.mp3),
    ).thenAnswer((_) async {});
    when(
      () => referenceStore.replaceReferencesAndDeleteMetadata(
        soundId: 'imported',
        fallbackSoundId: 'default',
      ),
    ).thenAnswer((_) async {});

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        importedSoundRepositoryProvider.overrideWithValue(importedRepository),
        importedSoundReferenceStoreProvider.overrideWithValue(referenceStore),
        importedSoundFileStoreProvider.overrideWithValue(fileStore),
        userPreferencesProvider.overrideWithValue(preferences),
        timerRepositoryProvider.overrideWithValue(_EmptyTimerRepository()),
        alarmRepositoryProvider.overrideWithValue(_EmptyAlarmRepository()),
        presetRepositoryProvider.overrideWithValue(_EmptyPresetRepository()),
      ],
    );
    addTearDown(container.dispose);
    final ImportedSoundDeletionController controller = container.read(
      importedSoundDeletionControllerProvider.notifier,
    );

    final Future<ImportedSoundDeletionResult> first = controller.delete(
      'imported',
    );
    final Future<ImportedSoundDeletionResult> second = controller.delete(
      'imported',
    );

    expect(identical(first, second), isTrue);
    lookupGate.complete(sound);
    final ImportedSoundDeletionResult result = await first;
    expect(result.deleted, isTrue);
    verify(() => importedRepository.findById('imported')).called(1);
    verify(
      () => referenceStore.replaceReferencesAndDeleteMetadata(
        soundId: 'imported',
        fallbackSoundId: 'default',
      ),
    ).called(1);
    verify(
      () => fileStore.quarantine('imported', ImportedSoundFormat.mp3),
    ).called(1);
    await Future<void>.delayed(Duration.zero);
  });
}
