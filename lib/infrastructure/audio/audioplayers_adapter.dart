import 'dart:async';

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
    : _player = player ?? AudioPlayer() {
    _stateSub = _player.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSub;
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
    await _stateSub.cancel();
    await _player.dispose();
    _isPlaying = false;
  }
}
