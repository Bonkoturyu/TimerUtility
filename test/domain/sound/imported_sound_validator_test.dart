import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/domain/sound/imported_sound_exceptions.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';
import 'package:timer_utility/domain/sound/imported_sound_policy.dart';
import 'package:timer_utility/domain/sound/imported_sound_validator.dart';

void main() {
  group('ImportedSoundValidator', () {
    const ImportedSoundValidator validator = ImportedSoundValidator();

    ImportedSound sound({
      required String id,
      int byteLength = 1_000_000,
      Duration duration = const Duration(seconds: 30),
      ImportedSoundFormat format = ImportedSoundFormat.mp3,
      String? hash,
    }) => ImportedSound.create(
      id: id,
      displayName: id,
      format: format,
      byteLength: byteLength,
      duration: duration,
      contentHash:
          hash ?? id.codeUnits.first.toRadixString(16).padLeft(64, '0'),
      createdAt: DateTime.utc(2026, 7, 16),
    );

    test('通常枠内の音源追加を許可する', () {
      expect(
        () => validator.validateAddition(
          candidate: sound(id: 'a'),
          existingSounds: <ImportedSound>[],
          policy: ImportedSoundPolicy.standard,
          availableStorageBytes: 11_000_000_000,
        ),
        returnsNormally,
      );
    });

    test('通常枠の5MB上限超過を拒否する', () {
      expect(
        () => validator.validateAddition(
          candidate: sound(id: 'a', byteLength: 5_000_001),
          existingSounds: <ImportedSound>[],
          policy: ImportedSoundPolicy.standard,
          availableStorageBytes: 11_000_000_000,
        ),
        throwsA(isA<ImportedSoundFileSizeLimitException>()),
      );
    });

    test('通常枠の3分上限超過を拒否する', () {
      expect(
        () => validator.validateAddition(
          candidate: sound(
            id: 'a',
            duration: const Duration(minutes: 3, milliseconds: 1),
          ),
          existingSounds: <ImportedSound>[],
          policy: ImportedSoundPolicy.standard,
          availableStorageBytes: 11_000_000_000,
        ),
        throwsA(isA<ImportedSoundDurationLimitException>()),
      );
    });

    test('同一内容ハッシュの重複登録を拒否して既存IDを返す', () {
      final ImportedSound existing = sound(id: 'a');

      expect(
        () => validator.validateAddition(
          candidate: sound(id: 'b', hash: existing.contentHash),
          existingSounds: <ImportedSound>[existing],
          policy: ImportedSoundPolicy.standard,
          availableStorageBytes: 11_000_000_000,
        ),
        throwsA(
          isA<DuplicateImportedSoundContentException>().having(
            (DuplicateImportedSoundContentException e) => e.existingSoundId,
            'existingSoundId',
            'a',
          ),
        ),
      );
    });

    test('通常枠の3件上限で4件目を拒否する', () {
      expect(
        () => validator.validateAddition(
          candidate: sound(id: 'd'),
          existingSounds: <ImportedSound>[
            sound(id: 'a'),
            sound(id: 'b'),
            sound(id: 'c'),
          ],
          policy: ImportedSoundPolicy.standard,
          availableStorageBytes: 11_000_000_000,
        ),
        throwsA(isA<ImportedSoundCountLimitException>()),
      );
    });

    test('取り込み後の空き容量が10GB未満になる場合を拒否する', () {
      expect(
        () => validator.validateAddition(
          candidate: sound(id: 'a', byteLength: 1_000_000),
          existingSounds: <ImportedSound>[],
          policy: ImportedSoundPolicy.standard,
          availableStorageBytes: 10_000_999_999,
        ),
        throwsA(isA<InsufficientImportedSoundStorageException>()),
      );
    });

    test('置換時は旧音源を件数と合計容量の判定から除外する', () {
      final List<ImportedSound> existing = <ImportedSound>[
        sound(id: 'a', byteLength: 5_000_000),
        sound(id: 'b', byteLength: 5_000_000),
        sound(id: 'c', byteLength: 5_000_000),
      ];

      expect(
        () => validator.validateReplacement(
          candidate: sound(id: 'replacement', byteLength: 5_000_000),
          replacedSoundId: 'a',
          existingSounds: existing,
          policy: ImportedSoundPolicy.standard,
          availableStorageBytes: 11_000_000_000,
        ),
        returnsNormally,
      );
    });

    test('存在しない音源の置換を拒否する', () {
      expect(
        () => validator.validateReplacement(
          candidate: sound(id: 'replacement'),
          replacedSoundId: 'missing',
          existingSounds: <ImportedSound>[sound(id: 'a')],
          policy: ImportedSoundPolicy.standard,
          availableStorageBytes: 11_000_000_000,
        ),
        throwsA(isA<ImportedSoundNotFoundException>()),
      );
    });

    test('ポリシーが許可しない形式を拒否する', () {
      final ImportedSoundPolicy mp3Only = ImportedSoundPolicy(
        maxFileBytes: 5_000_000,
        maxDuration: const Duration(minutes: 3),
        maxCount: 3,
        supportedFormats: <ImportedSoundFormat>{ImportedSoundFormat.mp3},
      );

      expect(
        () => validator.validateAddition(
          candidate: sound(id: 'a', format: ImportedSoundFormat.opus),
          existingSounds: <ImportedSound>[],
          policy: mp3Only,
          availableStorageBytes: 11_000_000_000,
        ),
        throwsA(isA<UnsupportedImportedSoundFormatException>()),
      );
    });
  });
}
