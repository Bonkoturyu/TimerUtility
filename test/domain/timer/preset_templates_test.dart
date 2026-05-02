import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/preset_templates.dart';

void main() {
  group('PresetTemplates.all', () {
    test('contains exactly 3 profiles in display order', () {
      expect(PresetTemplates.all.length, 3);
      expect(PresetTemplates.all[0].id, 'general');
      expect(PresetTemplates.all[1].id, 'cooking');
      expect(PresetTemplates.all[2].id, 'pomodoro');
    });

    test('every profile has exactly 6 templates', () {
      for (final p in PresetTemplates.all) {
        expect(p.templates.length, 6, reason: 'profile=${p.id}');
      }
    });

    test('every template has positive duration <= 99h', () {
      for (final p in PresetTemplates.all) {
        for (final t in p.templates) {
          expect(t.duration, greaterThan(Duration.zero));
          expect(t.duration, lessThanOrEqualTo(const Duration(hours: 99)));
        }
      }
    });
  });

  group('PresetTemplates.defaultProfile', () {
    test('is the general profile (Phase 9 Plan)', () {
      expect(PresetTemplates.defaultProfile.id, 'general');
      expect(
        identical(PresetTemplates.defaultProfile, PresetTemplates.general),
        isTrue,
      );
    });
  });

  group('PresetTemplates.findById', () {
    test('returns the matching profile for known ids', () {
      expect(PresetTemplates.findById('general')?.id, 'general');
      expect(PresetTemplates.findById('cooking')?.id, 'cooking');
      expect(PresetTemplates.findById('pomodoro')?.id, 'pomodoro');
    });

    test('returns null for unknown ids', () {
      expect(PresetTemplates.findById('unknown'), isNull);
      expect(PresetTemplates.findById(''), isNull);
    });
  });

  group('PresetTemplates.general', () {
    test('contains 30s / 1m / 3m / 5m / 10m / 30m with default sound', () {
      final durations = PresetTemplates.general.templates
          .map((t) => t.duration)
          .toList();
      expect(durations, <Duration>[
        const Duration(seconds: 30),
        const Duration(minutes: 1),
        const Duration(minutes: 3),
        const Duration(minutes: 5),
        const Duration(minutes: 10),
        const Duration(minutes: 30),
      ]);
      for (final t in PresetTemplates.general.templates) {
        expect(t.soundId, 'default');
      }
    });
  });

  group('PresetTemplates.cooking', () {
    test('contains 1m / 3m / 5m / 10m / 15m / 30m with gentle sound', () {
      final durations = PresetTemplates.cooking.templates
          .map((t) => t.duration)
          .toList();
      expect(durations, <Duration>[
        const Duration(minutes: 1),
        const Duration(minutes: 3),
        const Duration(minutes: 5),
        const Duration(minutes: 10),
        const Duration(minutes: 15),
        const Duration(minutes: 30),
      ]);
      for (final t in PresetTemplates.cooking.templates) {
        expect(t.soundId, 'gentle');
      }
    });
  });

  group('PresetTemplates.pomodoro', () {
    test('contains 5s / 30s / 1m / 5m / 10m / 25m with urgent sound', () {
      final durations = PresetTemplates.pomodoro.templates
          .map((t) => t.duration)
          .toList();
      expect(durations, <Duration>[
        const Duration(seconds: 5),
        const Duration(seconds: 30),
        const Duration(minutes: 1),
        const Duration(minutes: 5),
        const Duration(minutes: 10),
        const Duration(minutes: 25),
      ]);
      for (final t in PresetTemplates.pomodoro.templates) {
        expect(t.soundId, 'warning');
      }
    });
  });
}
