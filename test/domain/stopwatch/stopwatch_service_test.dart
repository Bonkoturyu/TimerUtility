import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/stopwatch/stopwatch_service.dart';
import 'package:timer_utility/domain/stopwatch/stopwatch_state.dart';

/// Mutable wall-clock time for tests. Update [now] then any [Clock] instance
/// returned by [makeClock] will reflect the new value.
class _MutableNow {
  _MutableNow(this.now);
  DateTime now;
}

Clock _makeClock(_MutableNow holder) => Clock(() => holder.now);

void main() {
  group('StopwatchService.start', () {
    test('returns Running with zero accumulated and empty laps', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final service = StopwatchService(clock: _makeClock(now));

      final running = service.start();

      expect(running.startedAt, DateTime(2026, 1, 1, 12));
      expect(running.accumulatedBefore, Duration.zero);
      expect(running.laps, isEmpty);
    });
  });

  group('StopwatchService.elapsed', () {
    test('Idle returns Duration.zero', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final service = StopwatchService(clock: _makeClock(now));

      expect(service.elapsed(const StopwatchIdle()), Duration.zero);
    });

    test('Running returns accumulatedBefore + (now - startedAt)', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final service = StopwatchService(clock: _makeClock(now));

      final running = service.start();
      now.now = DateTime(2026, 1, 1, 12, 0, 5);

      expect(service.elapsed(running), const Duration(seconds: 5));
    });

    test('Running counts accumulatedBefore from prior session', () {
      final running = StopwatchRunning(
        startedAt: DateTime(2026, 1, 1, 12),
        accumulatedBefore: const Duration(seconds: 10),
        laps: const <LapRecord>[],
      );
      final now = _MutableNow(DateTime(2026, 1, 1, 12, 0, 3));
      final service = StopwatchService(clock: _makeClock(now));

      expect(service.elapsed(running), const Duration(seconds: 13));
    });

    test('Paused returns accumulated regardless of clock', () {
      final paused = StopwatchPaused(
        pausedAt: DateTime(2026, 1, 1, 12, 0, 5),
        accumulated: const Duration(seconds: 5),
        laps: const <LapRecord>[],
      );
      final now = _MutableNow(DateTime(2026, 1, 1, 13));
      final service = StopwatchService(clock: _makeClock(now));

      expect(service.elapsed(paused), const Duration(seconds: 5));
    });
  });

  group('StopwatchService.pause', () {
    test('Running → Paused with computed accumulated', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final service = StopwatchService(clock: _makeClock(now));

      final running = service.start();
      now.now = DateTime(2026, 1, 1, 12, 0, 7);
      final paused = service.pause(running);

      expect(paused.pausedAt, DateTime(2026, 1, 1, 12, 0, 7));
      expect(paused.accumulated, const Duration(seconds: 7));
      expect(paused.laps, isEmpty);
    });

    test('Idle.pause throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final service = StopwatchService(clock: _makeClock(now));

      expect(() => service.pause(const StopwatchIdle()), throwsStateError);
    });

    test('Paused.pause throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final service = StopwatchService(clock: _makeClock(now));
      final paused = StopwatchPaused(
        pausedAt: DateTime(2026, 1, 1),
        accumulated: const Duration(seconds: 1),
        laps: const <LapRecord>[],
      );

      expect(() => service.pause(paused), throwsStateError);
    });
  });

  group('StopwatchService.resume', () {
    test('Paused → Running with new startedAt and prior accumulated', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12, 0, 30));
      final service = StopwatchService(clock: _makeClock(now));
      final paused = StopwatchPaused(
        pausedAt: DateTime(2026, 1, 1, 12, 0, 5),
        accumulated: const Duration(seconds: 5),
        laps: const <LapRecord>[],
      );

      final running = service.resume(paused);

      expect(running.startedAt, DateTime(2026, 1, 1, 12, 0, 30));
      expect(running.accumulatedBefore, const Duration(seconds: 5));
      expect(running.laps, isEmpty);
    });

    test('elapsed after resume includes prior accumulated', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12, 0, 30));
      final service = StopwatchService(clock: _makeClock(now));
      final paused = StopwatchPaused(
        pausedAt: DateTime(2026, 1, 1, 12, 0, 5),
        accumulated: const Duration(seconds: 5),
        laps: const <LapRecord>[],
      );

      final running = service.resume(paused);
      now.now = DateTime(2026, 1, 1, 12, 0, 33);

      expect(service.elapsed(running), const Duration(seconds: 8));
    });

    test('Idle.resume throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final service = StopwatchService(clock: _makeClock(now));

      expect(() => service.resume(const StopwatchIdle()), throwsStateError);
    });

    test('Running.resume throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final service = StopwatchService(clock: _makeClock(now));
      final running = service.start();

      expect(() => service.resume(running), throwsStateError);
    });
  });

  group('StopwatchService.lap', () {
    test('first lap split equals total', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final service = StopwatchService(clock: _makeClock(now));

      final running = service.start();
      now.now = DateTime(2026, 1, 1, 12, 0, 3);
      final updated = service.lap(running);

      expect(updated.laps, hasLength(1));
      expect(updated.laps.first.index, 1);
      expect(updated.laps.first.splitTime, const Duration(seconds: 3));
      expect(updated.laps.first.totalTime, const Duration(seconds: 3));
    });

    test('subsequent laps compute split from last total', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final service = StopwatchService(clock: _makeClock(now));

      var running = service.start();
      now.now = DateTime(2026, 1, 1, 12, 0, 3);
      running = service.lap(running);
      now.now = DateTime(2026, 1, 1, 12, 0, 7);
      running = service.lap(running);

      expect(running.laps, hasLength(2));
      expect(running.laps[1].index, 2);
      expect(running.laps[1].splitTime, const Duration(seconds: 4));
      expect(running.laps[1].totalTime, const Duration(seconds: 7));
    });

    test('Idle.lap throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final service = StopwatchService(clock: _makeClock(now));

      expect(() => service.lap(const StopwatchIdle()), throwsStateError);
    });

    test('Paused.lap throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final service = StopwatchService(clock: _makeClock(now));
      final paused = StopwatchPaused(
        pausedAt: DateTime(2026, 1, 1),
        accumulated: const Duration(seconds: 1),
        laps: const <LapRecord>[],
      );

      expect(() => service.lap(paused), throwsStateError);
    });
  });

  group('StopwatchService.reset', () {
    test('returns idle from any state', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final service = StopwatchService(clock: _makeClock(now));

      expect(service.reset(), isA<StopwatchIdle>());
    });
  });
}
