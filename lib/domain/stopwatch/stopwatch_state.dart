import 'package:freezed_annotation/freezed_annotation.dart';

part 'stopwatch_state.freezed.dart';

/// Immutable state of a stopwatch.
///
/// Three discrete states:
///   - [StopwatchIdle]    : not started.
///   - [StopwatchRunning] : actively counting up.
///   - [StopwatchPaused]  : paused mid-run.
///
/// Elapsed time computation lives in `StopwatchService`, not on the state
/// itself, to keep this type a pure value object with no time dependency.
@freezed
sealed class StopwatchState with _$StopwatchState {
  const factory StopwatchState.idle() = StopwatchIdle;

  const factory StopwatchState.running({
    required DateTime startedAt,
    required Duration accumulatedBefore,
    required List<LapRecord> laps,
  }) = StopwatchRunning;

  const factory StopwatchState.paused({
    required DateTime pausedAt,
    required Duration accumulated,
    required List<LapRecord> laps,
  }) = StopwatchPaused;
}

/// Single lap entry recorded during stopwatch operation.
///
/// Invariants (enforced by `StopwatchService.lap`, not by this VO):
///   - [index] >= 1 (1-indexed)
///   - [splitTime] >= [Duration.zero]
///   - [totalTime] >= [splitTime]
@freezed
class LapRecord with _$LapRecord {
  const factory LapRecord({
    required int index,
    required Duration splitTime,
    required Duration totalTime,
    required DateTime recordedAt,
  }) = _LapRecord;
}
