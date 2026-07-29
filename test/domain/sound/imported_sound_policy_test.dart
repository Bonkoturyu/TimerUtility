import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/sound/imported_sound_policy.dart';

void main() {
  group('ImportedSoundPolicy', () {
    test('通常枠の合計容量を1ファイル上限と件数から導出する', () {
      expect(ImportedSoundPolicy.standard.maxFileBytes, 5_000_000);
      expect(ImportedSoundPolicy.standard.maxCount, 3);
      expect(ImportedSoundPolicy.standard.maxTotalBytes, 15_000_000);
    });

    test('将来枠も合計容量を同じ規則で導出する', () {
      expect(ImportedSoundPolicy.futureTierA.maxTotalBytes, 50_000_000);
      expect(ImportedSoundPolicy.futureTierB.maxTotalBytes, 150_000_000);
    });
  });
}
