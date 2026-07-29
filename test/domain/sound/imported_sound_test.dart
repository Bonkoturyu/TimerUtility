import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';

void main() {
  group('ImportedSound', () {
    ImportedSound create({
      String id = 'sound-1',
      String displayName = 'Bell',
      int byteLength = 1_000_000,
      Duration duration = const Duration(seconds: 30),
      String contentHash =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    }) => ImportedSound.create(
      id: id,
      displayName: displayName,
      format: ImportedSoundFormat.mp3,
      byteLength: byteLength,
      duration: duration,
      contentHash: contentHash,
      createdAt: DateTime.utc(2026, 7, 16),
    );

    test('有効なメタデータからEntityを生成する', () {
      final ImportedSound sound = create(displayName: '  Bell  ');

      expect(sound.displayName, 'Bell');
      expect(sound.byteLength, 1_000_000);
    });

    test('空のIDを拒否する', () {
      expect(() => create(id: ' '), throwsArgumentError);
    });

    test('空の表示名を拒否する', () {
      expect(() => create(displayName: '  '), throwsArgumentError);
    });

    test('1秒未満の音源を拒否する', () {
      expect(
        () => create(duration: const Duration(milliseconds: 999)),
        throwsArgumentError,
      );
    });

    test('内部上限25MBを超える音源を拒否する', () {
      expect(
        () => create(byteLength: ImportedSound.maxInternalFileBytes + 1),
        throwsArgumentError,
      );
    });

    test('小文字SHA-256形式でないハッシュを拒否する', () {
      expect(() => create(contentHash: 'ABC'), throwsArgumentError);
    });

    test('renameは音源IDとメタデータを維持して表示名だけを変更する', () {
      final ImportedSound original = create();

      final ImportedSound renamed = original.rename('Wake up');

      expect(renamed.displayName, 'Wake up');
      expect(renamed.id, original.id);
      expect(renamed.contentHash, original.contentHash);
      expect(renamed.createdAt, original.createdAt);
    });
  });
}
