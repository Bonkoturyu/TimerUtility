import '../timer/alarm_sound.dart';

/// Plays a single bundled [AlarmSound] in a loop until [stop] is called.
///
/// Phase 5 contract:
///   - Only one playback at a time. Calling [play] while another sound is
///     playing should stop the previous one and start the new one.
///   - [prepare] loads [AlarmSound] without producing audible output.
///     A subsequent [play] for the same sound starts the prepared source.
///   - Loops automatically (the implementation owns the loop mode).
///   - [stop] is idempotent.
///   - Calls are serialized by the implementation so a completed stale
///     prepare cannot overwrite a newer stop / prepare request.
///   - [isPlaying] reflects the most recent observed state; it may briefly
///     lag platform events but is good enough for UI display.
abstract class AlarmSoundPlayer {
  Future<void> prepare(AlarmSound sound);
  Future<void> play(AlarmSound sound);
  Future<void> stop();
  bool get isPlaying;

  /// Release native resources. Called when the app shuts down or the
  /// adapter is disposed.
  Future<void> dispose();
}

/// Optional per-player volume control used by the production adapter.
abstract class VolumeControlledAlarmSoundPlayer {
  Future<void> setVolumePercent(int percent);
}

/// Optional alarm-handoff capability used by the production player.
///
/// Kept separate from [AlarmSoundPlayer] so bundled-only adapters and test
/// doubles retain the Phase 5 contract unchanged.
abstract class HandoffAlarmSoundPlayer {
  Future<void> prepareForHandoff({
    required Future<String> requestedSoundId,
    required Duration selectionTimeout,
  });

  /// Plays exactly the source selected by [prepareForHandoff], without a
  /// second repository lookup after the fixed handoff boundary.
  Future<void> playPrepared();
}

/// Optional preview capability for app-private imported audio.
///
/// [soundId] is the stable Domain identifier, never a file path. Keeping this
/// separate preserves the original bundled-only player contract for existing
/// adapters and test doubles.
abstract class ImportedSoundPreviewPlayer {
  Future<void> playImported(String soundId);
}

/// Optional preview capability for a validated, uncommitted staging copy.
///
/// [stagingToken] is opaque storage identity, never a file path or URI.
abstract class StagedImportedSoundPreviewPlayer {
  Future<void> playStaged(String stagingToken);
}
