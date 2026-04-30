import '../timer/alarm_sound.dart';

/// Plays a single bundled [AlarmSound] in a loop until [stop] is called.
///
/// Phase 5 contract:
///   - Only one playback at a time. Calling [play] while another sound is
///     playing should stop the previous one and start the new one.
///   - Loops automatically (the implementation owns the loop mode).
///   - [stop] is idempotent.
///   - [isPlaying] reflects the most recent observed state; it may briefly
///     lag platform events but is good enough for UI display.
abstract class AlarmSoundPlayer {
  Future<void> play(AlarmSound sound);
  Future<void> stop();
  bool get isPlaying;

  /// Release native resources. Called when the app shuts down or the
  /// adapter is disposed.
  Future<void> dispose();
}
