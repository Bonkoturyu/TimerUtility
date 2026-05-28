/// Issue #74 fix (2026-05-28): port for querying whether the device is
/// currently showing the keyguard (lock screen).
///
/// `AlarmRingingNotifier.start` consults this to pick the cancel→play
/// delay. Pixel / Android 16 releases the channel-bundled alarm-stream
/// tone slower while the keyguard is up, so the longer delay only
/// applies on lock-screen paths and the foreground / unlocked-home
/// paths stay snappy (Phase 8.5 sweet-spot 500 ms vs cold/warm-launch
/// lock-screen 1800 ms — see dev-log "Issue #74").
///
/// Implementations live under `infrastructure/platform/` and wrap the
/// native MethodChannel that calls `KeyguardManager.isKeyguardLocked()`.
abstract class ScreenLockQuery {
  /// Returns `true` when the device is currently showing the keyguard,
  /// `false` otherwise. Implementations should report `false` on any
  /// platform error (safe default — applies the short 500 ms delay,
  /// matching the foreground path).
  Future<bool> isScreenLocked();
}
