import 'dart:async';

import 'package:fake_async/fake_async.dart';
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

    test(
      'default path: cancel→play delay is ~500ms (Phase 8.5 sweet spot)',
      () {
        // foreground / Home / warm-launch FSI 経路を想定 (isColdLaunch
        // 既定 = false)。500 ms 経過直後に audioplayers.play() が走る。
        fakeAsync((FakeAsync async) {
          final player = _StubAlarmSoundPlayer();
          final h = _container(player);

          unawaited(
            h.container
                .read(alarmRingingNotifierProvider.notifier)
                .start(
                  timerId: 't-default',
                  sound: AlarmSoundCatalog.defaultSound,
                  notificationId: 100,
                ),
          );
          // cancel() 完了 → 500 ms 待機開始までの microtask を流す。
          async.flushMicrotasks();
          expect(player.playCalls, 0, reason: 'play は delay 中はまだ走らない');

          // 499 ms ではまだ play されない。
          async.elapse(const Duration(milliseconds: 499));
          async.flushMicrotasks();
          expect(player.playCalls, 0);

          // 残り 1 ms 進めて 500 ms 経過。play() が走る。
          async.elapse(const Duration(milliseconds: 1));
          async.flushMicrotasks();
          expect(player.playCalls, 1);
        });
      },
    );

    test('cold-launch path: cancel→play delay is ~1800ms (Issue #74 fix)', () {
      // Lock screen FSI cold-launch を想定。500 ms ではまだ OS Channel
      // sound が release されないため、1800 ms に伸ばす。
      fakeAsync((FakeAsync async) {
        final player = _StubAlarmSoundPlayer();
        final h = _container(player);

        unawaited(
          h.container
              .read(alarmRingingNotifierProvider.notifier)
              .start(
                timerId: 't-cold',
                sound: AlarmSoundCatalog.defaultSound,
                notificationId: 101,
                isColdLaunch: true,
              ),
        );
        async.flushMicrotasks();
        expect(player.playCalls, 0);

        // 500 ms 経過時点ではまだ play されない (既定 delay より長い)。
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();
        expect(
          player.playCalls,
          0,
          reason: 'cold-launch では 500 ms では足りない (二重音 fix)',
        );

        // 1799 ms ではまだ。
        async.elapse(const Duration(milliseconds: 1299));
        async.flushMicrotasks();
        expect(player.playCalls, 0);

        // 1800 ms 経過で play()。
        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(player.playCalls, 1);
      });
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
