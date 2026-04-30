import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/alarm_sound_player.dart';
import '../infrastructure/audio/audioplayers_adapter.dart';

part 'alarm_sound_player_provider.g.dart';

/// Default-bound alarm sound player. Override in tests via
/// `alarmSoundPlayerProvider.overrideWithValue(fakePlayer)`.
@Riverpod(keepAlive: true)
AlarmSoundPlayer alarmSoundPlayer(Ref ref) {
  final AudioplayersAdapter adapter = AudioplayersAdapter();
  ref.onDispose(adapter.dispose);
  return adapter;
}
