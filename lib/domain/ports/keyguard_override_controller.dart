/// Issue #73 fix (2026-06-01): port for releasing the keyguard-override
/// state that Android sets when [AlarmRingingScreen] is launched via
/// FullScreenIntent.
///
/// `AlarmRingingScreen` calls this when the user leaves the alarm screen so
/// the Activity drops out of "lock-screen overlay" mode and the recents (■)
/// navigation button reappears — without it the button stays suppressed
/// until the process is killed (see `MainActivity.clearShowWhenLockedInternal`).
///
/// This is the command-side counterpart to the read-only [ScreenLockQuery]:
/// both wrap the same native `permission` MethodChannel, but keeping them as
/// separate ports preserves CQS (query vs command). Implementations live
/// under `infrastructure/platform/` and wrap the native MethodChannel that
/// calls `Activity.setShowWhenLocked(false)` / `setTurnScreenOn(false)`.
abstract class KeyguardOverrideController {
  /// Releases the show-when-locked / turn-screen-on override. Best-effort:
  /// implementations swallow platform errors, since failing to clear the
  /// override only affects the recents-button visibility, not the alarm.
  Future<void> clearShowWhenLocked();
}
