import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/stopwatch_notifier.dart';
import 'package:timer_utility/domain/stopwatch/stopwatch_state.dart';

class _MutableNow {
  _MutableNow(this.now);
  DateTime now;
}

ProviderContainer _makeContainer(_MutableNow holder) {
  final container = ProviderContainer(
    overrides: <Override>[
      clockProvider.overrideWithValue(Clock(() => holder.now)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('StopwatchNotifier', () {
    test('initial state is idle', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final container = _makeContainer(now);

      expect(container.read(stopwatchNotifierProvider), const StopwatchIdle());
    });

    test('start transitions idle to running', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final container = _makeContainer(now);

      container.read(stopwatchNotifierProvider.notifier).start();

      final state = container.read(stopwatchNotifierProvider);
      expect(state, isA<StopwatchRunning>());
      expect((state as StopwatchRunning).startedAt, DateTime(2026, 1, 1, 12));
    });

    test('pause then resume preserves accumulated time', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final container = _makeContainer(now);
      final notifier = container.read(stopwatchNotifierProvider.notifier);

      notifier.start();
      now.now = DateTime(2026, 1, 1, 12, 0, 5);
      notifier.pause();
      now.now = DateTime(2026, 1, 1, 12, 0, 30);
      notifier.resume();
      now.now = DateTime(2026, 1, 1, 12, 0, 33);

      expect(notifier.elapsed, const Duration(seconds: 8));
    });

    test('lap appends new entry to running state', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final container = _makeContainer(now);
      final notifier = container.read(stopwatchNotifierProvider.notifier);

      notifier.start();
      now.now = DateTime(2026, 1, 1, 12, 0, 3);
      notifier.lap();
      now.now = DateTime(2026, 1, 1, 12, 0, 7);
      notifier.lap();

      final state = container.read(stopwatchNotifierProvider);
      expect(state, isA<StopwatchRunning>());
      expect((state as StopwatchRunning).laps, hasLength(2));
      expect(state.laps[1].splitTime, const Duration(seconds: 4));
      expect(state.laps[1].totalTime, const Duration(seconds: 7));
    });

    test('reset returns to idle', () {
      final now = _MutableNow(DateTime(2026, 1, 1, 12));
      final container = _makeContainer(now);
      final notifier = container.read(stopwatchNotifierProvider.notifier);

      notifier.start();
      now.now = DateTime(2026, 1, 1, 12, 0, 10);
      notifier.reset();

      expect(container.read(stopwatchNotifierProvider), const StopwatchIdle());
    });

    test('pause from idle throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final container = _makeContainer(now);

      expect(
        () => container.read(stopwatchNotifierProvider.notifier).pause(),
        throwsStateError,
      );
    });

    test('resume from running throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final container = _makeContainer(now);
      final notifier = container.read(stopwatchNotifierProvider.notifier);

      notifier.start();

      expect(notifier.resume, throwsStateError);
    });

    test('lap from paused throws StateError', () {
      final now = _MutableNow(DateTime(2026, 1, 1));
      final container = _makeContainer(now);
      final notifier = container.read(stopwatchNotifierProvider.notifier);

      notifier.start();
      now.now = DateTime(2026, 1, 1, 0, 0, 1);
      notifier.pause();

      expect(notifier.lap, throwsStateError);
    });
  });
}
