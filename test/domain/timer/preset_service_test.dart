import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/domain/timer/preset_service.dart';

PresetService _service({DateTime? now, String Function()? idGen}) {
  return PresetService(
    clock: Clock(() => now ?? DateTime(2026, 5, 2, 12)),
    idGenerator: idGen ?? () => 'fixed-id',
  );
}

void main() {
  group('PresetService.create', () {
    test('creates a preset with provided values + auto id / createdAt', () {
      final s = _service(now: DateTime(2026, 5, 2, 12));
      final p = s.create(
        label: 'Tea',
        duration: const Duration(minutes: 3),
        soundId: 'gentle',
      );
      expect(p.id, 'fixed-id');
      expect(p.label, 'Tea');
      expect(p.duration, const Duration(minutes: 3));
      expect(p.soundId, 'gentle');
      expect(p.createdAt, DateTime(2026, 5, 2, 12));
    });

    test('honors caller-supplied id and createdAt', () {
      final s = _service();
      final p = s.create(
        label: 'L',
        duration: const Duration(seconds: 30),
        id: 'manual',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(p.id, 'manual');
      expect(p.createdAt, DateTime(2025, 1, 1));
    });

    test('accepts empty label', () {
      final s = _service();
      final p = s.create(label: '', duration: const Duration(minutes: 1));
      expect(p.label, '');
    });

    test('accepts null soundId (means catalog default)', () {
      final s = _service();
      final p = s.create(label: 'x', duration: const Duration(minutes: 1));
      expect(p.soundId, isNull);
    });

    test('rejects zero duration', () {
      final s = _service();
      expect(
        () => s.create(label: '', duration: Duration.zero),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative duration', () {
      final s = _service();
      expect(
        () => s.create(label: '', duration: const Duration(seconds: -1)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects duration over 99 hours', () {
      final s = _service();
      expect(
        () => s.create(
          label: '',
          duration: const Duration(hours: 99, seconds: 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts exactly 99 hours', () {
      final s = _service();
      final p = s.create(label: '', duration: const Duration(hours: 99));
      expect(p.duration, const Duration(hours: 99));
    });

    test('rejects label longer than 50 chars', () {
      final s = _service();
      final tooLong = 'x' * 51;
      expect(
        () => s.create(label: tooLong, duration: const Duration(minutes: 1)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts label of exactly 50 chars', () {
      final s = _service();
      final p = s.create(label: 'x' * 50, duration: const Duration(minutes: 1));
      expect(p.label, 'x' * 50);
    });
  });

  group('PresetService.update', () {
    Preset seed() => Preset(
      id: 'p-1',
      label: 'orig',
      duration: const Duration(minutes: 5),
      soundId: 'default',
      createdAt: DateTime(2026, 5, 1),
    );

    test('updates label only, preserving id and createdAt', () {
      final s = _service();
      final updated = s.update(seed(), label: 'renamed');
      expect(updated.id, 'p-1');
      expect(updated.label, 'renamed');
      expect(updated.duration, const Duration(minutes: 5));
      expect(updated.soundId, 'default');
      expect(updated.createdAt, DateTime(2026, 5, 1));
    });

    test('updates duration only', () {
      final s = _service();
      final updated = s.update(seed(), duration: const Duration(minutes: 7));
      expect(updated.duration, const Duration(minutes: 7));
      expect(updated.label, 'orig');
      expect(updated.soundId, 'default');
    });

    test('updates soundId to a new value', () {
      final s = _service();
      final updated = s.update(seed(), soundId: 'urgent');
      expect(updated.soundId, 'urgent');
    });

    test('updates soundId to null (clears default override)', () {
      final s = _service();
      final updated = s.update(seed(), soundId: null);
      expect(updated.soundId, isNull);
    });

    test('omitting soundId preserves the existing value', () {
      final s = _service();
      final updated = s.update(seed(), label: 'just rename');
      expect(updated.soundId, 'default');
    });

    test('rejects invalid new duration', () {
      final s = _service();
      expect(
        () => s.update(seed(), duration: Duration.zero),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid new label length', () {
      final s = _service();
      expect(
        () => s.update(seed(), label: 'y' * 51),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
