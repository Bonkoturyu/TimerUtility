import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/alarm_ringing_notifier.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/timer/alarm_sound.dart';
import 'package:timer_utility/domain/timer/alarm_sound_catalog.dart';

class _StubAlarmSoundPlayer implements AlarmSoundPlayer {
  bool _isPlaying = false;
  AlarmSound? lastPlayed;
  int playCalls = 0;
  int stopCalls = 0;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> play(AlarmSound sound) async {
    playCalls++;
    lastPlayed = sound;
    _isPlaying = true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {}
}

ProviderContainer _container(_StubAlarmSoundPlayer player) {
  final c = ProviderContainer(
    overrides: <Override>[alarmSoundPlayerProvider.overrideWithValue(player)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('AlarmRingingNotifier', () {
    test('initial state is idle (not playing, no current timer)', () {
      final player = _StubAlarmSoundPlayer();
      final c = _container(player);

      final state = c.read(alarmRingingNotifierProvider);
      expect(state.isPlaying, isFalse);
      expect(state.snoozeRequested, isFalse);
      expect(state.currentTimerId, isNull);
      expect(state.currentSoundId, isNull);
    });

    test(
      'start sets isPlaying and tells the player to play the sound',
      () async {
        final player = _StubAlarmSoundPlayer();
        final c = _container(player);
        final sound = AlarmSoundCatalog.defaultSound;

        await c
            .read(alarmRingingNotifierProvider.notifier)
            .start(timerId: 't-1', sound: sound);
        // Allow the unawaited play call to settle.
        await Future<void>.delayed(Duration.zero);

        final state = c.read(alarmRingingNotifierProvider);
        expect(state.isPlaying, isTrue);
        expect(state.currentTimerId, 't-1');
        expect(state.currentSoundId, sound.id);
        expect(player.playCalls, 1);
        expect(player.lastPlayed, sound);
      },
    );

    test('stop resets state and tells the player to stop', () async {
      final player = _StubAlarmSoundPlayer();
      final c = _container(player);
      await c
          .read(alarmRingingNotifierProvider.notifier)
          .start(timerId: 't-1', sound: AlarmSoundCatalog.defaultSound);
      await Future<void>.delayed(Duration.zero);

      await c.read(alarmRingingNotifierProvider.notifier).stop();
      await Future<void>.delayed(Duration.zero);

      final state = c.read(alarmRingingNotifierProvider);
      expect(state.isPlaying, isFalse);
      expect(state.currentTimerId, isNull);
      expect(state.currentSoundId, isNull);
      expect(state.snoozeRequested, isFalse);
      expect(player.stopCalls, 1);
    });

    test('snoozeRequested flips the flag and stops audio', () async {
      final player = _StubAlarmSoundPlayer();
      final c = _container(player);
      await c
          .read(alarmRingingNotifierProvider.notifier)
          .start(timerId: 't-1', sound: AlarmSoundCatalog.defaultSound);
      await Future<void>.delayed(Duration.zero);

      await c.read(alarmRingingNotifierProvider.notifier).snoozeRequested();
      await Future<void>.delayed(Duration.zero);

      final state = c.read(alarmRingingNotifierProvider);
      expect(state.snoozeRequested, isTrue);
      expect(state.isPlaying, isFalse);
      expect(player.stopCalls, 1);
    });
  });
}
