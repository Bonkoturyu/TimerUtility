import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_ringing_notifier.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/application/alarm_repository_provider.dart';
import 'package:timer_utility/application/diagnostic_logger_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/screen_lock_query_provider.dart';
import 'package:timer_utility/application/timer_repository_provider.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/alarm/alarm_repeat.dart';
import 'package:timer_utility/domain/alarm/time_of_day_value.dart';
import 'package:timer_utility/domain/diagnostics/diagnostic_event.dart';
import 'package:timer_utility/domain/diagnostics/diagnostic_logger.dart';
import 'package:timer_utility/domain/ports/alarm_repository.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/ports/diagnostic_sink.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/screen_lock_query.dart';
import 'package:timer_utility/domain/ports/timer_repository.dart';
import 'package:timer_utility/domain/timer/alarm_sound.dart';
import 'package:timer_utility/domain/timer/alarm_sound_catalog.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';

class _StubAlarmSoundPlayer implements AlarmSoundPlayer {
  bool _isPlaying = false;
  AlarmSound? lastPlayed;
  AlarmSound? lastPrepared;
  int prepareCalls = 0;
  int playCalls = 0;
  int stopCalls = 0;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> prepare(AlarmSound sound) async {
    prepareCalls++;
    lastPrepared = sound;
  }

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
  Future<void> prepare(AlarmSound sound) async {}

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

class _CapturingHandoffPlayer extends _StubAlarmSoundPlayer
    implements HandoffAlarmSoundPlayer {
  String? requestedSoundId;
  int handoffPrepareCalls = 0;
  int playPreparedCalls = 0;

  @override
  Future<void> prepareForHandoff({
    required Future<String> requestedSoundId,
    required Duration selectionTimeout,
  }) async {
    handoffPrepareCalls++;
    this.requestedSoundId = await requestedSoundId;
  }

  @override
  Future<void> playPrepared() async {
    playPreparedCalls++;
    _isPlaying = true;
  }
}

class _SilentHandoffPlayer extends _CapturingHandoffPlayer {
  @override
  Future<void> playPrepared() async {
    playPreparedCalls++;
  }
}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _MockTimerRepository extends Mock implements TimerRepository {}

class _MockAlarmRepository extends Mock implements AlarmRepository {}

/// Stub [ScreenLockQuery] for tests. Issue #74 fix: `AlarmRingingNotifier.start`
/// reads this to pick the cancel→play delay (500 ms unlocked / 1800 ms locked).
class _StubScreenLockQuery implements ScreenLockQuery {
  _StubScreenLockQuery({this.locked = false});

  final bool locked;

  @override
  Future<bool> isScreenLocked() async => locked;
}

/// In-test [DiagnosticSink] that records every event the logger forwards,
/// so the Issue #86 playback breadcrumb can be asserted.
class _RecordingSink implements DiagnosticSink {
  final List<DiagnosticEvent> events = <DiagnosticEvent>[];

  @override
  void write(DiagnosticEvent event) => events.add(event);

  @override
  Future<void> flush() async {}
}

({ProviderContainer container, _MockNotificationScheduler scheduler})
_container(
  AlarmSoundPlayer player, {
  bool screenLocked = false,
  DiagnosticSink? diagnosticSink,
  Duration handoffDelay = Duration.zero,
  Duration selectionTimeout = const Duration(seconds: 1),
  TimerRepository? timerRepository,
  AlarmRepository? alarmRepository,
}) {
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
      alarmSoundHandoffDelayProvider.overrideWithValue(handoffDelay),
      alarmSoundSelectionTimeoutProvider.overrideWithValue(selectionTimeout),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      if (timerRepository != null)
        timerRepositoryProvider.overrideWithValue(timerRepository),
      if (alarmRepository != null)
        alarmRepositoryProvider.overrideWithValue(alarmRepository),
      screenLockQueryProvider.overrideWithValue(
        _StubScreenLockQuery(locked: screenLocked),
      ),
      if (diagnosticSink != null)
        diagnosticLoggerProvider.overrideWithValue(
          DiagnosticLogger(
            sink: diagnosticSink,
            isEnabled: () => true,
            threshold: DiagnosticSeverity.debug,
          ),
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

    test(
      'cold timer launch resolves the persisted imported sound id',
      () async {
        final TimerRepository repository = _MockTimerRepository();
        when(() => repository.findById('timer-cold')).thenAnswer(
          (_) async => TimerEntity(
            id: 'timer-cold',
            notificationId: 4321,
            label: 'Cold timer',
            duration: const Duration(minutes: 1),
            endAt: null,
            pausedRemaining: null,
            status: TimerStatus.ringing,
            createdAt: DateTime.utc(2026, 7, 16),
            soundId: 'imported-cold-timer',
          ),
        );
        final player = _CapturingHandoffPlayer();
        final h = _container(player, timerRepository: repository);

        await h.container
            .read(alarmRingingNotifierProvider.notifier)
            .start(
              timerId: 'timer-cold',
              notificationId: -1,
              source: AlarmSource.timer,
            );
        await Future<void>.delayed(Duration.zero);

        expect(player.requestedSoundId, 'imported-cold-timer');
        expect(player.handoffPrepareCalls, 1);
        expect(player.playPreparedCalls, 1);
        expect(
          h.container.read(alarmRingingNotifierProvider).currentSoundId,
          'imported-cold-timer',
        );
        verify(() => h.scheduler.cancel(4321)).called(1);
      },
    );

    test(
      'cold alarm launch resolves the persisted imported sound id',
      () async {
        final AlarmRepository repository = _MockAlarmRepository();
        when(() => repository.findById('alarm-cold')).thenAnswer(
          (_) async => AlarmEntity(
            id: 'alarm-cold',
            notificationId: 9876,
            label: 'Cold alarm',
            targetTime: const TimeOfDayValue.unsafe(hour: 7, minute: 30),
            repeat: const AlarmRepeatOnce(),
            snoozeMinutes: 5,
            enabled: true,
            createdAt: DateTime.utc(2026, 7, 16),
            soundId: 'imported-cold-alarm',
          ),
        );
        final player = _CapturingHandoffPlayer();
        final h = _container(player, alarmRepository: repository);

        await h.container
            .read(alarmRingingNotifierProvider.notifier)
            .start(
              timerId: 'alarm-cold',
              notificationId: -1,
              source: AlarmSource.alarm,
            );
        await Future<void>.delayed(Duration.zero);

        expect(player.requestedSoundId, 'imported-cold-alarm');
        expect(player.handoffPrepareCalls, 1);
        expect(player.playPreparedCalls, 1);
        expect(
          h.container.read(alarmRingingNotifierProvider).currentSoundId,
          'imported-cold-alarm',
        );
        verify(() => h.scheduler.cancel(9876)).called(1);
      },
    );

    test('音源選択timeout後もcold lookupを継続し、保存済み通知IDをcancelする', () {
      fakeAsync((FakeAsync async) {
        final Completer<TimerEntity?> lookup = Completer<TimerEntity?>();
        final TimerRepository repository = _MockTimerRepository();
        when(
          () => repository.findById('timer-slow-cold'),
        ).thenAnswer((_) => lookup.future);
        final player = _CapturingHandoffPlayer();
        final h = _container(
          player,
          timerRepository: repository,
          selectionTimeout: const Duration(seconds: 1),
        );

        unawaited(
          h.container
              .read(alarmRingingNotifierProvider.notifier)
              .start(
                timerId: 'timer-slow-cold',
                notificationId: -1,
                source: AlarmSource.timer,
              ),
        );
        async.flushMicrotasks();

        async.elapse(const Duration(milliseconds: 999));
        async.flushMicrotasks();
        expect(player.requestedSoundId, isNull);
        verifyNever(() => h.scheduler.cancel(any()));

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(player.requestedSoundId, AlarmSoundCatalog.defaultSound.id);
        expect(player.playPreparedCalls, 1);
        expect(
          h.container.read(alarmRingingNotifierProvider).currentSoundId,
          AlarmSoundCatalog.defaultSound.id,
        );
        verifyNever(() => h.scheduler.cancel(any()));

        lookup.complete(
          TimerEntity(
            id: 'timer-slow-cold',
            notificationId: 24680,
            label: 'Slow cold timer',
            duration: const Duration(minutes: 1),
            endAt: null,
            pausedRemaining: null,
            status: TimerStatus.ringing,
            createdAt: DateTime.utc(2026, 7, 16),
            soundId: 'late-imported-sound',
          ),
        );
        async.flushMicrotasks();

        verify(() => h.scheduler.cancel(24680)).called(1);
        expect(
          h.container.read(alarmRingingNotifierProvider).currentSoundId,
          AlarmSoundCatalog.defaultSound.id,
          reason: 'deadline後に到着した音源へ再ハンドオフしない',
        );
      });
    });

    for (final bool snooze in <bool>[false, true]) {
      test(
        'cold lookup完了前に${snooze ? 'snooze' : 'stop'}しても保存済み通知IDをcancelする',
        () {
          fakeAsync((FakeAsync async) {
            final Completer<TimerEntity?> lookup = Completer<TimerEntity?>();
            final TimerRepository repository = _MockTimerRepository();
            when(
              () => repository.findById('timer-dismissed-cold'),
            ).thenAnswer((_) => lookup.future);
            final player = _CapturingHandoffPlayer();
            final h = _container(player, timerRepository: repository);
            final AlarmRingingNotifier notifier = h.container.read(
              alarmRingingNotifierProvider.notifier,
            );

            unawaited(
              notifier.start(
                timerId: 'timer-dismissed-cold',
                notificationId: -1,
                source: AlarmSource.timer,
              ),
            );
            async.flushMicrotasks();

            unawaited(snooze ? notifier.snoozeRequested() : notifier.stop());
            async.flushMicrotasks();

            lookup.complete(
              TimerEntity(
                id: 'timer-dismissed-cold',
                notificationId: 24681,
                label: 'Dismissed cold timer',
                duration: const Duration(minutes: 1),
                endAt: null,
                pausedRemaining: null,
                status: TimerStatus.ringing,
                createdAt: DateTime.utc(2026, 7, 16),
                soundId: 'late-imported-sound',
              ),
            );
            async.flushMicrotasks();

            verify(() => h.scheduler.cancel(24681)).called(1);
          });
        },
      );
    }

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

    test('prepared slotを再生できない場合はisPlayingをfalseへ戻す', () async {
      final player = _SilentHandoffPlayer();
      final h = _container(player);

      await h.container
          .read(alarmRingingNotifierProvider.notifier)
          .start(
            timerId: 'timer-silent',
            soundId: AlarmSoundCatalog.defaultSound.id,
            notificationId: 123,
          );

      expect(h.container.read(alarmRingingNotifierProvider).isPlaying, isFalse);
      expect(player.playPreparedCalls, 1);
      expect(player.stopCalls, 1);
    });

    test('通知音の再生中に prepare し、3200ms の固定ハンドオフ後に play する', () {
      fakeAsync((FakeAsync async) {
        final player = _StubAlarmSoundPlayer();
        final h = _container(
          player,
          handoffDelay: const Duration(milliseconds: 3200),
        );

        unawaited(
          h.container
              .read(alarmRingingNotifierProvider.notifier)
              .start(
                timerId: 't-unlocked',
                sound: AlarmSoundCatalog.defaultSound,
                notificationId: 100,
              ),
        );
        async.flushMicrotasks();
        expect(player.prepareCalls, 1, reason: '通知音の再生中に音源を準備する');
        expect(player.lastPrepared, AlarmSoundCatalog.defaultSound);
        expect(player.playCalls, 0, reason: 'play は delay 中はまだ走らない');

        async.elapse(const Duration(milliseconds: 3199));
        async.flushMicrotasks();
        expect(player.playCalls, 0);

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(player.playCalls, 1);
      });
    });

    test('ロック状態に依存せず同じ3200msのハンドオフ境界を使う', () {
      fakeAsync((FakeAsync async) {
        final player = _StubAlarmSoundPlayer();
        final h = _container(
          player,
          screenLocked: true,
          handoffDelay: const Duration(milliseconds: 3200),
        );

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
        expect(player.prepareCalls, 1);
        expect(player.playCalls, 0);

        async.elapse(const Duration(milliseconds: 3199));
        async.flushMicrotasks();
        expect(player.playCalls, 0);

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(player.playCalls, 1);
      });
    });

    test(
      'stop() during the cue handoff invalidates the pending play generation',
      () {
        fakeAsync((FakeAsync async) {
          final player = _StubAlarmSoundPlayer();
          final h = _container(
            player,
            screenLocked: true,
            handoffDelay: const Duration(milliseconds: 3200),
          );

          unawaited(
            h.container
                .read(alarmRingingNotifierProvider.notifier)
                .start(
                  timerId: 't-race',
                  sound: AlarmSoundCatalog.defaultSound,
                  notificationId: 200,
                ),
          );
          async.elapse(const Duration(milliseconds: 1000));
          async.flushMicrotasks();
          expect(player.playCalls, 0);

          unawaited(
            h.container.read(alarmRingingNotifierProvider.notifier).stop(),
          );
          async.flushMicrotasks();

          async.elapse(const Duration(milliseconds: 2500));
          async.flushMicrotasks();
          expect(player.playCalls, 0, reason: 'stop() 後は delay 完了しても play しない');
          expect(player.stopCalls, 1);
        });
      },
    );

    test(
      'snoozeRequested() during the cue handoff invalidates pending play',
      () {
        // snoozeRequested も state.isPlaying = false に落とすので、
        // stop と同じガードで play() への到達が阻止されることを確認。
        fakeAsync((FakeAsync async) {
          final player = _StubAlarmSoundPlayer();
          final h = _container(
            player,
            screenLocked: true,
            handoffDelay: const Duration(milliseconds: 3200),
          );

          unawaited(
            h.container
                .read(alarmRingingNotifierProvider.notifier)
                .start(
                  timerId: 't-race-snooze',
                  sound: AlarmSoundCatalog.defaultSound,
                  notificationId: 201,
                ),
          );
          async.elapse(const Duration(milliseconds: 2500));
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
          final h = _container(
            player,
            handoffDelay: const Duration(milliseconds: 3200),
          );

          unawaited(
            h.container
                .read(alarmRingingNotifierProvider.notifier)
                .start(
                  timerId: 't-gap',
                  sound: AlarmSoundCatalog.defaultSound,
                  notificationId: 300,
                ),
          );
          // Clear the cue handoff delay; start() now enters play() and
          // parks on the gate.
          async.elapse(const Duration(milliseconds: 3200));
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
        final h = _container(
          player,
          handoffDelay: const Duration(milliseconds: 3200),
        );
        final notifier = h.container.read(
          alarmRingingNotifierProvider.notifier,
        );
        final soundA = AlarmSoundCatalog.all[0]; // default
        final soundB = AlarmSoundCatalog.all[1]; // gentle

        // t-1 rings and parks inside its cue handoff delay.
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
        async.elapse(const Duration(milliseconds: 3300));
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

    test('Issue #86 breadcrumb: play 到達時に alarmPlaybackStart を timerId 付きで '
        '記録する', () {
      fakeAsync((FakeAsync async) {
        final player = _StubAlarmSoundPlayer();
        final sink = _RecordingSink();
        final h = _container(
          player,
          screenLocked: true,
          diagnosticSink: sink,
          handoffDelay: const Duration(milliseconds: 3200),
        );

        unawaited(
          h.container
              .read(alarmRingingNotifierProvider.notifier)
              .start(
                timerId: 't-bc',
                sound: AlarmSoundCatalog.defaultSound,
                notificationId: 400,
              ),
        );

        // 3200 ms handoff 完了前は play 前 → breadcrumb なし。
        async.elapse(const Duration(milliseconds: 3199));
        async.flushMicrotasks();
        expect(
          sink.events.whereType<DiagnosticTimerAction>().where(
            (DiagnosticTimerAction e) =>
                e.action == TimerActionKind.alarmPlaybackStart,
          ),
          isEmpty,
          reason: 'play 到達前は playback breadcrumb を出さない',
        );

        // 3200 ms 到達で play() → breadcrumb 1 件記録。
        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(player.playCalls, 1);
        final List<DiagnosticTimerAction> playbackEvents = sink.events
            .whereType<DiagnosticTimerAction>()
            .where(
              (DiagnosticTimerAction e) =>
                  e.action == TimerActionKind.alarmPlaybackStart,
            )
            .toList();
        expect(playbackEvents, hasLength(1));
        expect(playbackEvents.single.timerId, 't-bc');
      });
    });

    test('Issue #86 breadcrumb: delay 中の stop で play に到達しない場合は '
        'alarmPlaybackStart を記録しない', () {
      fakeAsync((FakeAsync async) {
        final player = _StubAlarmSoundPlayer();
        final sink = _RecordingSink();
        final h = _container(
          player,
          screenLocked: true,
          diagnosticSink: sink,
          handoffDelay: const Duration(milliseconds: 3200),
        );

        unawaited(
          h.container
              .read(alarmRingingNotifierProvider.notifier)
              .start(
                timerId: 't-bc-stop',
                sound: AlarmSoundCatalog.defaultSound,
                notificationId: 401,
              ),
        );
        async.elapse(const Duration(milliseconds: 2500));
        async.flushMicrotasks();

        unawaited(
          h.container.read(alarmRingingNotifierProvider.notifier).stop(),
        );
        async.flushMicrotasks();

        async.elapse(const Duration(milliseconds: 1000));
        async.flushMicrotasks();

        expect(player.playCalls, 0);
        expect(
          sink.events.whereType<DiagnosticTimerAction>().where(
            (DiagnosticTimerAction e) =>
                e.action == TimerActionKind.alarmPlaybackStart,
          ),
          isEmpty,
        );
      });
    });
  });
}
