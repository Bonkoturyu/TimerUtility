import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/mappers/imported_sound_mapper.dart';

void main() {
  group('ImportedSoundMapper', () {
    const ImportedSoundMapper mapper = ImportedSoundMapper();

    test('DomainとDrift rowのround-tripで全メタデータを維持する', () {
      final ImportedSound original = ImportedSound.create(
        id: 'sound-1',
        displayName: 'Wake up',
        format: ImportedSoundFormat.opus,
        byteLength: 2_000_000,
        duration: const Duration(seconds: 45),
        contentHash:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        createdAt: DateTime.utc(2026, 7, 16, 1, 2, 3),
      );

      final ImportedSoundRow row = ImportedSoundRow(
        id: original.id,
        displayName: original.displayName,
        format: original.format.name,
        byteLength: original.byteLength,
        durationMs: original.duration.inMilliseconds,
        contentHash: original.contentHash,
        createdAtUtcMs: original.createdAt.millisecondsSinceEpoch,
      );

      expect(mapper.toEntity(row), original);
      expect(mapper.toCompanion(original).toColumns(false), isNotEmpty);
    });
  });
}
