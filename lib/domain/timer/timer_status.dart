/// Lifecycle status of a single timer.
///
/// Transitions are enforced by `TimerService`; see `docs/domain-model.md`
/// (Timer Aggregate / 状態遷移) for the diagram.
enum TimerStatus {
  /// Created, never started yet.
  idle,

  /// Counting down toward `endAt`.
  running,

  /// Counting suspended; remaining duration is preserved in
  /// `TimerEntity.pausedRemaining`.
  paused,

  /// Reached zero, alarm should be ringing (sound is wired in Phase 5).
  ringing,

  /// Stopped after ringing (terminal state, can be reset to idle).
  completed,

  /// Cancelled by the user (terminal state, can be reset to idle).
  cancelled,
}
