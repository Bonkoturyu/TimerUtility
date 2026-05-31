import 'package:audioplayers/audioplayers.dart';

import '../../domain/ports/alarm_sound_player.dart';
import '../../domain/timer/alarm_sound.dart';

/// Concrete [AlarmSoundPlayer] backed by the `audioplayers` package.
///
/// Looped playback uses [ReleaseMode.loop]. Asset paths are passed to
/// [AssetSource] without the leading `assets/` segment because that's
/// what audioplayers expects (the prefix is added internally).
class AudioplayersAdapter implements AlarmSoundPlayer {
  AudioplayersAdapter({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  // Single source of truth for `isPlaying`: only play() / stop() /
  // dispose() write it. We deliberately do NOT also subscribe to
  // `onPlayerStateChanged` — a second, asynchronous writer made the
  // flag non-deterministic under rapid play→stop sequencing (a late
  // "playing" event could revive the flag after stop() cleared it).
  // Playback is always ReleaseMode.loop, so the stream never reports a
  // natural completion the explicit sets would miss.
  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> play(AlarmSound sound) async {
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    final String relativePath = sound.assetPath.startsWith('assets/')
        ? sound.assetPath.substring('assets/'.length)
        : sound.assetPath;
    await _player.play(AssetSource(relativePath));
    _isPlaying = true;
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
    _isPlaying = false;
  }
}
