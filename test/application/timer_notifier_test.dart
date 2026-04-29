import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/timer_notifier.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';

class _ClockHolder {
  _ClockHolder(this.now);
  DateTime now;
}

/// Helper that runs [body] inside `fakeAsync`, advancing both the
/// `fake_async` virtual time and a manually-tracked clock. The
/// `clockProvider` reads from the manual clock so domain code computes
/// `endAt - now` correctly even though `DateTime.now()` itself is not
/// patched by `fake_async`.
void _runWithFakeTime(
  void Function(FakeAsync async, ProviderContainer container, _ClockHolder now)
  body,
) {
  fakeAsync((async) {
    final now = _ClockHolder(DateTime(2026, 1, 1, 12));
    final container = ProviderContainer(
      overrides: <Override>[
        clockProvider.overrideWithValue(Clock(() => now.now)),
      ],
    );
    try {
      body(async, container, now);
    } finally {
      container.dispose();
    }
  });
}

void _advance(FakeAsync async, _ClockHolder now, Duration d) {
  now.now = now.now.add(d);
  async.elapse(d);
}

void main() {
  group('TimerNotifier', () {
    test('initial state is null', () {
      _runWithFakeTime((async, container, now) {
        expect(container.read(timerNotifierProvider), isNull);
      });
    });

    test('create configures an idle timer', () {
      _runWithFakeTime((async, container, now) {
        container
            .read(timerNotifierProvider.notifier)
            .create(label: 'work', duration: const Duration(seconds: 5));

        final state = container.read(timerNotifierProvider);
        expect(state, isNotNull);
        expect(state!.status, TimerStatus.idle);
        expect(state.label, 'work');
        expect(state.duration, const Duration(seconds: 5));
      });
    });

    test('start transitions idle → running and ticks to ringing', () {
      _runWithFakeTime((async, container, now) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.start();

        // Halfway: still running
        _advance(async, now, const Duration(seconds: 3));
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.running,
        );

        // Past endAt: should be ringing after the next 200ms tick fires
        _advance(async, now, const Duration(seconds: 3));
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.ringing,
        );
      });
    });

    test('pause then resume preserves remaining duration', () {
      _runWithFakeTime((async, container, now) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 10));
        notifier.start();

        _advance(async, now, const Duration(seconds: 4));
        notifier.pause();

        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.paused,
        );
        expect(
          container.read(timerNotifierProvider)!.pausedRemaining,
          const Duration(seconds: 6),
        );

        // Time passes while paused - should not affect remaining
        _advance(async, now, const Duration(minutes: 5));
        expect(
          container.read(timerNotifierProvider)!.pausedRemaining,
          const Duration(seconds: 6),
        );

        notifier.resume();
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.running,
        );

        // 6 more seconds reaches ringing
        _advance(async, now, const Duration(seconds: 7));
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.ringing,
        );
      });
    });

    test('cancel transitions to cancelled and stops ticker', () {
      _runWithFakeTime((async, container, now) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.start();

        notifier.cancel();
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.cancelled,
        );

        // Advancing time should not change state
        _advance(async, now, const Duration(minutes: 1));
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.cancelled,
        );
      });
    });

    test('cancelled.start throws StateError', () {
      _runWithFakeTime((async, container, now) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.cancel();

        expect(notifier.start, throwsStateError);
      });
    });

    test('reset returns cancelled timer to idle preserving duration', () {
      _runWithFakeTime((async, container, now) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.cancel();
        notifier.reset();

        final state = container.read(timerNotifierProvider)!;
        expect(state.status, TimerStatus.idle);
        expect(state.duration, const Duration(seconds: 5));
      });
    });

    test('start without create throws StateError', () {
      _runWithFakeTime((async, container, now) {
        expect(
          container.read(timerNotifierProvider.notifier).start,
          throwsStateError,
        );
      });
    });

    test('clear drops the timer entirely', () {
      _runWithFakeTime((async, container, now) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.clear();
        expect(container.read(timerNotifierProvider), isNull);
      });
    });

    test('background recovery: long elapse jumps directly to ringing', () {
      // Simulates the app being suspended for longer than the timer's
      // remaining duration. After the next tick (200ms) the running state
      // is detected as past-due and flips to ringing.
      _runWithFakeTime((async, container, now) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 30));
        notifier.start();

        _advance(async, now, const Duration(minutes: 5));

        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.ringing,
        );
      });
    });
  });
}
