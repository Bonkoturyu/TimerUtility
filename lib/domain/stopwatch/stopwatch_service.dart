import 'package:clock/clock.dart';

import 'stopwatch_state.dart';

/// Pure-Dart domain service for stopwatch logic.
///
/// All time-dependent operations go through the injected [Clock]. Invalid
/// state transitions throw [StateError] (e.g. pausing while idle).
class StopwatchService {
  const StopwatchService({required Clock clock}) : _clock = clock;

  final Clock _clock;

  /// Begin counting. Always returns a fresh [StopwatchRunning].
  StopwatchRunning start() {
    return StopwatchRunning(
      startedAt: _clock.now(),
      accumulatedBefore: Duration.zero,
      laps: const <LapRecord>[],
    );
  }

  /// Compute current elapsed time for any state.
  Duration elapsed(StopwatchState state) {
    return switch (state) {
      StopwatchIdle() => Duration.zero,
      StopwatchRunning(:final startedAt, :final accumulatedBefore) =>
        accumulatedBefore + _clock.now().difference(startedAt),
      StopwatchPaused(:final accumulated) => accumulated,
    };
  }

  /// Transition Running → Paused. Throws [StateError] if not running.
  StopwatchPaused pause(StopwatchState state) {
    if (state is! StopwatchRunning) {
      throw StateError('Cannot pause from ${state.runtimeType}');
    }
    final now = _clock.now();
    final accumulated =
        state.accumulatedBefore + now.difference(state.startedAt);
    return StopwatchPaused(
      pausedAt: now,
      accumulated: accumulated,
      laps: state.laps,
    );
  }

  /// Transition Paused → Running. Throws [StateError] if not paused.
  StopwatchRunning resume(StopwatchState state) {
    if (state is! StopwatchPaused) {
      throw StateError('Cannot resume from ${state.runtimeType}');
    }
    return StopwatchRunning(
      startedAt: _clock.now(),
      accumulatedBefore: state.accumulated,
      laps: state.laps,
    );
  }

  /// Record a lap on a running stopwatch. Throws [StateError] otherwise.
  StopwatchRunning lap(StopwatchState state) {
    if (state is! StopwatchRunning) {
      throw StateError('Cannot record lap from ${state.runtimeType}');
    }
    final total =
        state.accumulatedBefore + _clock.now().difference(state.startedAt);
    final lastTotal = state.laps.isEmpty
        ? Duration.zero
        : state.laps.last.totalTime;
    final split = total - lastTotal;
    final newLap = LapRecord(
      index: state.laps.length + 1,
      splitTime: split,
      totalTime: total,
      recordedAt: _clock.now(),
    );
    return state.copyWith(laps: <LapRecord>[...state.laps, newLap]);
  }

  /// Reset to idle. Always returns [StopwatchIdle].
  StopwatchIdle reset() => const StopwatchIdle();
}
