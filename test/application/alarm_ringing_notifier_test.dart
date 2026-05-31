import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_ringing_notifier.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/screen_lock_query_provider.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/screen_lock_query.dart';
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

/// Player whose [play] parks on a gate so a test can interleave a stop()
/// during the `await play()` async gap (post-play guard regression).
class _BlockingAlarmSoundPlayer implements AlarmSoundPlayer {
  final Completer<void> _gate = Completer<void>();
  bool _isPlaying = false;
  int playCalls = 0;
  int stopCalls = 0;

  void completePlay() => _gate.complete();

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> play(AlarmSound sound) async {
    playCalls++;
    await _gate.future;
    _isPlaying = true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {
    _isPlaying = false;
  }
}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

/// Stub [ScreenLockQuery] for tests. Issue #74 fix: `AlarmRingingNotifier.start`
/// reads this to pick the cancel→play delay (500 ms unlocked / 1800 ms locked).
class _StubScreenLockQuery implements ScreenLockQuery {
  _StubScreenLockQuery({this.locked = false});

  final bool locked;

  @override
  Future<bool> isScreenLocked() async => locked;
}

({ProviderContainer container, _MockNotificationScheduler scheduler})
_container(AlarmSoundPlayer player, {bool screenLocked = false}) {
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
      screenLockQueryProvider.overrideWithValue(
        _StubScreenLockQuery(locked: screenLocked),
      ),
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
      'unlocked path: cancel→play delay is ~500ms (Phase 8.5 sweet spot)',
      () {
        // foreground / Home (unlock 済) を想定。
        // ScreenLockQuery.isScreenLocked() = false → 500 ms 経過で play。
        fakeAsync((FakeAsync async) {
          final player = _StubAlarmSoundPlayer();
          final h = _container(player);

          unawaited(
            h.container
                .read(alarmRingingNotifierProvider.notifier)
                .start(
                  timerId: 't-unlocked',
                  sound: AlarmSoundCatalog.defaultSound,
                  notificationId: 100,
                ),
          );
          // cancel() + isScreenLocked() 完了 → 500 ms 待機開始までの
          // microtask を流す。
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

    test(
      'locked path: cancel→play delay is ~1800ms (Issue #74 fix, lock-screen)',
      () {
        // Lock 画面表示中 (cold-launch FSI / warm-launch FSI snooze 再鳴動
        // など) を想定。ScreenLockQuery.isScreenLocked() = true →
        // 1800 ms 経過で play。
        fakeAsync((FakeAsync async) {
          final player = _StubAlarmSoundPlayer();
          final h = _container(player, screenLocked: true);

          unawaited(
            h.container
                .read(alarmRingingNotifierProvider.notifier)
                .start(
                  timerId: 't-locked',
                  sound: AlarmSoundCatalog.defaultSound,
                  notificationId: 101,
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
            reason: 'Lock 画面では 500 ms では足りない (二重音 fix)',
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
      },
    );

    test(
      'stop() during the cancel→play delay drops the pending play '
      '(PR #75 Copilot review: race window widened by 1800ms locked branch)',
      () {
        // Lock 経路で stop() が delay 中に呼ばれた場合、delay 後の
        // play() に到達してしまうと「ユーザが止めた直後に音が鳴り始める」
        // 競合になる。`if (!state.isPlaying) return;` ガードで防ぐ。
        fakeAsync((FakeAsync async) {
          final player = _StubAlarmSoundPlayer();
          final h = _container(player, screenLocked: true);

          unawaited(
            h.container
                .read(alarmRingingNotifierProvider.notifier)
                .start(
                  timerId: 't-race',
                  sound: AlarmSoundCatalog.defaultSound,
                  notificationId: 200,
                ),
          );
          // 1000 ms 経過 (1800 ms delay の途中) で stop() を呼ぶ。
          async.elapse(const Duration(milliseconds: 1000));
          async.flushMicrotasks();
          expect(player.playCalls, 0, reason: '1000ms < 1800ms なのでまだ play 前');

          unawaited(
            h.container.read(alarmRingingNotifierProvider.notifier).stop(),
          );
          async.flushMicrotasks();

          // 残り 1000 ms 進めて 1800 ms delay 完了 → ガードが効いて
          // play() に到達しないことを確認。
          async.elapse(const Duration(milliseconds: 1000));
          async.flushMicrotasks();
          expect(player.playCalls, 0, reason: 'stop() 後は delay 完了しても play しない');
          expect(player.stopCalls, 1);
        });
      },
    );

    test(
      'snoozeRequested() during the cancel→play delay drops the pending play '
      '(PR #75 Copilot review)',
      () {
        // snoozeRequested も state.isPlaying = false に落とすので、
        // stop と同じガードで play() への到達が阻止されることを確認。
        fakeAsync((FakeAsync async) {
          final player = _StubAlarmSoundPlayer();
          final h = _container(player, screenLocked: true);

          unawaited(
            h.container
                .read(alarmRingingNotifierProvider.notifier)
                .start(
                  timerId: 't-race-snooze',
                  sound: AlarmSoundCatalog.defaultSound,
                  notificationId: 201,
                ),
          );
          async.elapse(const Duration(milliseconds: 1000));
          async.flushMicrotasks();
          expect(player.playCalls, 0);

          unawaited(
            h.container
                .read(alarmRingingNotifierProvider.notifier)
                .snoozeRequested(),
          );
          async.flushMicrotasks();

          async.elapse(const Duration(milliseconds: 1000));
          async.flushMicrotasks();
          expect(player.playCalls, 0);
          final state = h.container.read(alarmRingingNotifierProvider);
          expect(state.snoozeRequested, isTrue);
        });
      },
    );

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

    test(
      'stop() during play()\'s async gap stops the player (post-play guard)',
      () {
        // The pre-play guard on L151 only covers the window *before*
        // play() starts. This exercises the second window: stop() arriving
        // while `await play(sound)` is in flight.
        fakeAsync((FakeAsync async) {
          final player = _BlockingAlarmSoundPlayer();
          final h = _container(player); // unlocked → 500 ms delay

          unawaited(
            h.container
                .read(alarmRingingNotifierProvider.notifier)
                .start(
                  timerId: 't-gap',
                  sound: AlarmSoundCatalog.defaultSound,
                  notificationId: 300,
                ),
          );
          // Clear the cancel→play delay; start() now enters play() and
          // parks on the gate.
          async.elapse(const Duration(milliseconds: 500));
          async.flushMicrotasks();
          expect(player.playCalls, 1);
          expect(player.isPlaying, isFalse, reason: 'play() is still parked');

          // User taps Stop *during* the play() async gap.
          unawaited(
            h.container.read(alarmRingingNotifierProvider.notifier).stop(),
          );
          async.flushMicrotasks();
          expect(
            h.container.read(alarmRingingNotifierProvider).isPlaying,
            isFalse,
          );

          // play() resolves; without the post-play guard the loop would be
          // running while state is idle. The guard must stop it.
          player.completePlay();
          async.flushMicrotasks();

          expect(player.isPlaying, isFalse);
          expect(player.stopCalls, greaterThanOrEqualTo(1));
          expect(player.playCalls, 1);
        });
      },
    );

    test('stale start() does not overwrite audio after the ringing slot '
        'switched timers (PR #84 gemini review: pre-play id guard)', () {
      fakeAsync((FakeAsync async) {
        final player = _StubAlarmSoundPlayer();
        final h = _container(player); // unlocked → 500 ms delay
        final notifier = h.container.read(
          alarmRingingNotifierProvider.notifier,
        );
        final soundA = AlarmSoundCatalog.all[0]; // default
        final soundB = AlarmSoundCatalog.all[1]; // gentle

        // t-1 rings and parks inside its 500 ms cancel→play delay.
        unawaited(
          notifier.start(timerId: 't-1', sound: soundA, notificationId: 1),
        );
        async.elapse(const Duration(milliseconds: 250));
        async.flushMicrotasks();
        expect(player.playCalls, 0);

        // User dismisses t-1, then a second timer (t-2) takes the slot.
        unawaited(notifier.stop());
        async.flushMicrotasks();
        unawaited(
          notifier.start(timerId: 't-2', sound: soundB, notificationId: 2),
        );
        async.flushMicrotasks();

        // Advance past both the original t-1 window and t-2's window.
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        // Only t-2 plays; t-1's stale play() is dropped by the
        // currentTimerId guard (without it, t-1 would overwrite t-2).
        expect(player.playCalls, 1);
        expect(player.lastPlayed, soundB);
        expect(
          h.container.read(alarmRingingNotifierProvider).currentTimerId,
          't-2',
        );
      });
    });
  });
}
