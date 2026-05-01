import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_ringing_notifier.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
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

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

({ProviderContainer container, _MockNotificationScheduler scheduler})
_container(_StubAlarmSoundPlayer player) {
  final scheduler = _MockNotificationScheduler();
  when(() => scheduler.cancel(any())).thenAnswer((_) async {});
  when(() => scheduler.cancelAll()).thenAnswer((_) async {});
  when(
    () => scheduler.schedule(
      notificationId: any(named: 'notificationId'),
      fireAt: any(named: 'fireAt'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      exact: any(named: 'exact'),
      payload: any(named: 'payload'),
    ),
  ).thenAnswer((_) async {});

  final c = ProviderContainer(
    overrides: <Override>[
      alarmSoundPlayerProvider.overrideWithValue(player),
      notificationSchedulerProvider.overrideWithValue(scheduler),
    ],
  );
  addTearDown(c.dispose);
  return (container: c, scheduler: scheduler);
}

void main() {
  group('AlarmRingingNotifier', () {
    test('initial state is idle (not playing, no current timer)', () {
      final player = _StubAlarmSoundPlayer();
      final h = _container(player);

      final state = h.container.read(alarmRingingNotifierProvider);
      expect(state.isPlaying, isFalse);
      expect(state.snoozeRequested, isFalse);
      expect(state.currentTimerId, isNull);
      expect(state.currentSoundId, isNull);
    });

    test(
      'start sets isPlaying and tells the player to play the sound',
      () async {
        final player = _StubAlarmSoundPlayer();
        final h = _container(player);
        final sound = AlarmSoundCatalog.defaultSound;

        await h.container
            .read(alarmRingingNotifierProvider.notifier)
            .start(timerId: 't-1', sound: sound, notificationId: 42);
        // Allow the unawaited play call to settle.
        await Future<void>.delayed(Duration.zero);

        final state = h.container.read(alarmRingingNotifierProvider);
        expect(state.isPlaying, isTrue);
        expect(state.currentTimerId, 't-1');
        expect(state.currentSoundId, sound.id);
        expect(player.playCalls, 1);
        expect(player.lastPlayed, sound);
      },
    );

    test('start cancels the OS notification it is taking over from', () async {
      final player = _StubAlarmSoundPlayer();
      final h = _container(player);

      await h.container
          .read(alarmRingingNotifierProvider.notifier)
          .start(
            timerId: 't-1',
            sound: AlarmSoundCatalog.defaultSound,
            notificationId: 1234,
          );
      await Future<void>.delayed(Duration.zero);

      verify(() => h.scheduler.cancel(1234)).called(1);
    });

    test('stop resets state and tells the player to stop', () async {
      final player = _StubAlarmSoundPlayer();
      final h = _container(player);
      await h.container
          .read(alarmRingingNotifierProvider.notifier)
          .start(
            timerId: 't-1',
            sound: AlarmSoundCatalog.defaultSound,
            notificationId: 7,
          );
      await Future<void>.delayed(Duration.zero);

      await h.container.read(alarmRingingNotifierProvider.notifier).stop();
      await Future<void>.delayed(Duration.zero);

      final state = h.container.read(alarmRingingNotifierProvider);
      expect(state.isPlaying, isFalse);
      expect(state.currentTimerId, isNull);
      expect(state.currentSoundId, isNull);
      expect(state.snoozeRequested, isFalse);
      expect(player.stopCalls, 1);
    });

    test('snoozeRequested flips the flag and stops audio', () async {
      final player = _StubAlarmSoundPlayer();
      final h = _container(player);
      await h.container
          .read(alarmRingingNotifierProvider.notifier)
          .start(
            timerId: 't-1',
            sound: AlarmSoundCatalog.defaultSound,
            notificationId: 7,
          );
      await Future<void>.delayed(Duration.zero);

      await h.container
          .read(alarmRingingNotifierProvider.notifier)
          .snoozeRequested();
      await Future<void>.delayed(Duration.zero);

      final state = h.container.read(alarmRingingNotifierProvider);
      expect(state.snoozeRequested, isTrue);
      expect(state.isPlaying, isFalse);
      expect(player.stopCalls, 1);
    });
  });
}
