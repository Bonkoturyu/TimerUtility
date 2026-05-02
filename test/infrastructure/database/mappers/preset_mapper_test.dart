import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/mappers/preset_mapper.dart';

void main() {
  const PresetMapper mapper = PresetMapper();

  Preset makeEntity({
    String id = 'p-1',
    String label = 'Tea',
    Duration duration = const Duration(minutes: 3),
    String? soundId = 'gentle',
    DateTime? createdAt,
  }) {
    return Preset(
      id: id,
      label: label,
      duration: duration,
      soundId: soundId,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 2, 12),
    );
  }

  group('PresetMapper roundtrip', () {
    test('preset with all fields survives roundtrip', () {
      final Preset original = makeEntity();
      final PresetRow row = mapper.toRow(original);
      final Preset back = mapper.toEntity(row);
      expect(back, original);
    });

    test('preset with empty label roundtrips correctly', () {
      final Preset original = makeEntity(label: '');
      final back = mapper.toEntity(mapper.toRow(original));
      expect(back.label, '');
      expect(back, original);
    });

    test('preset with null soundId roundtrips correctly', () {
      final Preset original = makeEntity(soundId: null);
      final back = mapper.toEntity(mapper.toRow(original));
      expect(back.soundId, isNull);
      expect(back, original);
    });

    test('local-time createdAt is normalised to UTC after roundtrip', () {
      final DateTime local = DateTime(2026, 5, 2, 12);
      final Preset original = makeEntity(createdAt: local);
      final back = mapper.toEntity(mapper.toRow(original));
      expect(back.createdAt.isUtc, isTrue);
      expect(back.createdAt, local.toUtc());
    });

    test('Duration is preserved in milliseconds', () {
      final Preset original = makeEntity(
        duration: const Duration(seconds: 137),
      );
      final back = mapper.toEntity(mapper.toRow(original));
      expect(back.duration, const Duration(seconds: 137));
    });
  });

  group('PresetMapper.toCompanion', () {
    test('non-null optional fields produce Value(...) instead of absent', () {
      final Preset p = makeEntity(soundId: 'warning');
      final companion = mapper.toCompanion(p);
      expect(companion.id.value, 'p-1');
      expect(companion.soundId.value, 'warning');
      expect(companion.label.value, 'Tea');
    });

    test('null soundId produces Value<String?>(null), not absent', () {
      final Preset p = makeEntity(soundId: null);
      final companion = mapper.toCompanion(p);
      expect(companion.soundId.present, isTrue);
      expect(companion.soundId.value, isNull);
    });
  });
}
