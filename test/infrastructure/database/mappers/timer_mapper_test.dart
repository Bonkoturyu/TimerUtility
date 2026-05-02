import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/mappers/timer_mapper.dart';

void main() {
  const TimerMapper mapper = TimerMapper();

  TimerEntity makeEntity({
    String id = 'timer-1',
    int notificationId = 12345,
    String label = 'Focus',
    Duration duration = const Duration(minutes: 25),
    DateTime? endAt,
    Duration? pausedRemaining,
    TimerStatus status = TimerStatus.idle,
    String? soundId,
    DateTime? createdAt,
  }) {
    return TimerEntity(
      id: id,
      notificationId: notificationId,
      label: label,
      duration: duration,
      endAt: endAt,
      pausedRemaining: pausedRemaining,
      status: status,
      soundId: soundId,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 1, 10, 0, 0),
    );
  }

  group('TimerMapper roundtrip', () {
    test('idle timer with no optional fields survives roundtrip', () {
      final TimerEntity original = makeEntity();
      final TimerRow row = mapper.toRow(original);
      final TimerEntity restored = mapper.toEntity(row);
      expect(restored, original);
    });

    test('running timer roundtrip preserves endAt as UTC', () {
      final DateTime endAt = DateTime.utc(2026, 5, 1, 10, 25, 0);
      final TimerEntity original = makeEntity(
        endAt: endAt,
        status: TimerStatus.running,
      );
      final TimerEntity restored = mapper.toEntity(mapper.toRow(original));
      expect(restored.endAt!.isUtc, isTrue);
      expect(restored.endAt, endAt);
      expect(restored.status, TimerStatus.running);
    });

    test('paused timer roundtrip preserves pausedRemaining', () {
      final TimerEntity original = makeEntity(
        pausedRemaining: const Duration(minutes: 12, seconds: 34),
        status: TimerStatus.paused,
      );
      final TimerEntity restored = mapper.toEntity(mapper.toRow(original));
      expect(
        restored.pausedRemaining,
        const Duration(minutes: 12, seconds: 34),
      );
      expect(restored.status, TimerStatus.paused);
    });

    test('soundId roundtrip preserves null and non-null', () {
      final TimerEntity withSound = makeEntity(soundId: 'gentle');
      expect(mapper.toEntity(mapper.toRow(withSound)).soundId, 'gentle');
      final TimerEntity withoutSound = makeEntity(soundId: null);
      expect(mapper.toEntity(mapper.toRow(withoutSound)).soundId, isNull);
    });

    test('local-time createdAt is normalised to UTC after roundtrip', () {
      final DateTime localCreated = DateTime(2026, 5, 1, 19, 0, 0);
      final TimerEntity original = makeEntity(createdAt: localCreated);
      final TimerEntity restored = mapper.toEntity(mapper.toRow(original));
      expect(restored.createdAt.isUtc, isTrue);
      expect(
        restored.createdAt.millisecondsSinceEpoch,
        localCreated.millisecondsSinceEpoch,
      );
    });

    test('all TimerStatus values roundtrip via name', () {
      for (final TimerStatus s in TimerStatus.values) {
        final TimerEntity original = makeEntity(status: s);
        final TimerEntity restored = mapper.toEntity(mapper.toRow(original));
        expect(restored.status, s, reason: 'roundtrip for $s');
      }
    });

    test('unknown status name in DB falls back to cancelled', () {
      final TimerRow corrupted = TimerRow(
        id: 'x',
        notificationId: 1,
        label: '',
        durationMs: 60000,
        endAtUtcMs: null,
        pausedRemainingMs: null,
        status: 'unknown_future_status',
        soundId: null,
        createdAtUtcMs: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
      );
      expect(mapper.toEntity(corrupted).status, TimerStatus.cancelled);
    });
  });

  group('TimerMapper.toCompanion', () {
    test('non-null optional fields produce Value(...) instead of absent', () {
      final TimerEntity entity = makeEntity(
        endAt: DateTime.utc(2026, 5, 1, 10, 25),
        soundId: 'warning',
        status: TimerStatus.running,
      );
      final TimersCompanion companion = mapper.toCompanion(entity);
      expect(companion.id.value, 'timer-1');
      expect(companion.endAtUtcMs.value, isNotNull);
      expect(companion.soundId.value, 'warning');
      expect(companion.status.value, 'running');
    });
  });
}
