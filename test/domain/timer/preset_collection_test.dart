import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/domain/timer/preset_collection.dart';
import 'package:timer_utility/domain/timer/preset_exceptions.dart';

Preset _preset(String id, {String label = ''}) => Preset(
  id: id,
  label: label,
  duration: const Duration(minutes: 1),
  soundId: null,
  createdAt: DateTime(2026, 5, 2),
);

void main() {
  group('PresetCollection.empty', () {
    test('starts empty, not full', () {
      final c = PresetCollection.empty();
      expect(c.size, 0);
      expect(c.isEmpty, isTrue);
      expect(c.isFull, isFalse);
      expect(c.all, isEmpty);
    });
  });

  group('PresetCollection.add', () {
    test('adds a new preset', () {
      final c0 = PresetCollection.empty();
      final c1 = c0.add(_preset('a'));
      expect(c1.size, 1);
      expect(c1.findById('a')?.id, 'a');
      expect(c1.isEmpty, isFalse);
    });

    test('adding an existing id updates instead of duplicating', () {
      final c0 = PresetCollection.empty().add(_preset('a', label: 'old'));
      final c1 = c0.add(_preset('a', label: 'new'));
      expect(c1.size, 1);
      expect(c1.findById('a')?.label, 'new');
    });

    test('throws MaxPresetCountExceededException when adding the 11th', () {
      PresetCollection c = PresetCollection.empty();
      for (int i = 0; i < 10; i++) {
        c = c.add(_preset('p$i'));
      }
      expect(c.isFull, isTrue);
      expect(
        () => c.add(_preset('p10')),
        throwsA(isA<MaxPresetCountExceededException>()),
      );
    });
  });

  group('PresetCollection.update', () {
    test('replaces the entity stored under the same id', () {
      final c0 = PresetCollection.empty().add(_preset('a', label: 'before'));
      final c1 = c0.update(_preset('a', label: 'after'));
      expect(c1.findById('a')?.label, 'after');
      expect(c1.size, 1);
    });

    test('throws PresetNotFoundException for unknown id', () {
      final c = PresetCollection.empty();
      expect(
        () => c.update(_preset('missing')),
        throwsA(isA<PresetNotFoundException>()),
      );
    });
  });

  group('PresetCollection.remove', () {
    test('removes the entity by id', () {
      final c0 = PresetCollection.empty().add(_preset('a')).add(_preset('b'));
      final c1 = c0.remove('a');
      expect(c1.findById('a'), isNull);
      expect(c1.findById('b')?.id, 'b');
      expect(c1.size, 1);
    });

    test('throws PresetNotFoundException for unknown id', () {
      final c = PresetCollection.empty();
      expect(() => c.remove('ghost'), throwsA(isA<PresetNotFoundException>()));
    });
  });

  group('PresetCollection.fromList', () {
    test('builds from a list of entities', () {
      final c = PresetCollection.fromList(<Preset>[_preset('a'), _preset('b')]);
      expect(c.size, 2);
      expect(c.findById('a')?.id, 'a');
      expect(c.findById('b')?.id, 'b');
    });

    test('throws when the source list exceeds maxSize', () {
      final tooMany = <Preset>[for (int i = 0; i < 11; i++) _preset('p$i')];
      expect(
        () => PresetCollection.fromList(tooMany),
        throwsA(isA<MaxPresetCountExceededException>()),
      );
    });
  });

  group('PresetCollection immutability', () {
    test('add returns a new collection without mutating the original', () {
      final c0 = PresetCollection.empty();
      final c1 = c0.add(_preset('a'));
      expect(c0.size, 0);
      expect(c1.size, 1);
      expect(identical(c0, c1), isFalse);
    });

    test('all returns an unmodifiable view', () {
      final c = PresetCollection.empty().add(_preset('a'));
      expect(() => c.all.add(_preset('b')), throwsA(isA<UnsupportedError>()));
    });
  });
}
