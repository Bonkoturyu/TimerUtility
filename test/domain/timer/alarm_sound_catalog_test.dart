import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/alarm_sound.dart';
import 'package:timer_utility/domain/timer/alarm_sound_catalog.dart';

void main() {
  group('AlarmSoundCatalog', () {
    test('all is non-empty', () {
      expect(AlarmSoundCatalog.all, isNotEmpty);
    });

    test('every entry has unique id and a sounds asset path', () {
      final Set<String> seen = <String>{};
      for (final AlarmSound s in AlarmSoundCatalog.all) {
        expect(seen.add(s.id), isTrue, reason: 'duplicate id: ${s.id}');
        expect(s.id, isNotEmpty);
        expect(s.displayName, isNotEmpty);
        expect(s.assetPath, startsWith('assets/sounds/'));
      }
    });

    test('defaultSound is the first entry of all', () {
      expect(AlarmSoundCatalog.defaultSound, AlarmSoundCatalog.all.first);
    });

    test('findById returns the matching sound', () {
      final AlarmSound? hit = AlarmSoundCatalog.findById('default');
      expect(hit, isNotNull);
      expect(hit!.id, 'default');
    });

    test('findById returns null for unknown id', () {
      expect(AlarmSoundCatalog.findById('does-not-exist'), isNull);
    });
  });

  group('AlarmSound.create', () {
    test('throws when id is empty', () {
      expect(
        () => AlarmSound.create(
          id: '',
          displayName: 'x',
          assetPath: 'assets/sounds/x.mp3',
        ),
        throwsArgumentError,
      );
    });

    test('throws when assetPath is outside assets/sounds/', () {
      expect(
        () => AlarmSound.create(
          id: 'x',
          displayName: 'x',
          assetPath: 'sounds/x.mp3',
        ),
        throwsArgumentError,
      );
    });
  });
}
