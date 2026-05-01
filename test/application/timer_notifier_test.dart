import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/notification_scheduler_provider.dart';
import 'package:timer_utility/application/permission_notifier.dart';
import 'package:timer_utility/application/timer_notifier.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/ports/notification_scheduler.dart';
import 'package:timer_utility/domain/ports/permission_manager.dart';
import 'package:timer_utility/domain/timer/alarm_sound.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';

class _ClockHolder {
  _ClockHolder(this.now);
  DateTime now;
}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _StubAlarmSoundPlayer implements AlarmSoundPlayer {
  bool _isPlaying = false;
  AlarmSound? lastPlayed;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> play(AlarmSound sound) async {
    lastPlayed = sound;
    _isPlaying = true;
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
  }

  @override
  Future<void> dispose() async {}
}

/// Helper that runs [body] inside `fakeAsync`, advancing both the
/// `fake_async` virtual time and a manually-tracked clock. The
/// `clockProvider` reads from the manual clock so domain code computes
/// `endAt - now` correctly even though `DateTime.now()` itself is not
/// patched by `fake_async`. A mock NotificationScheduler is wired so that
/// schedule/cancel calls can be verified per test.
void _runWithFakeTime(
  void Function(
    FakeAsync async,
    ProviderContainer container,
    _ClockHolder now,
    _MockNotificationScheduler scheduler,
  )
  body, {
  DomainPermissionStatus exactAlarm = DomainPermissionStatus.granted,
}) {
  fakeAsync((async) {
    final now = _ClockHolder(DateTime(2026, 1, 1, 12));
    final scheduler = _MockNotificationScheduler();
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
    when(() => scheduler.cancel(any())).thenAnswer((_) async {});
    when(() => scheduler.cancelAll()).thenAnswer((_) async {});

    final container = ProviderContainer(
      overrides: <Override>[
        clockProvider.overrideWithValue(Clock(() => now.now)),
        notificationSchedulerProvider.overrideWithValue(scheduler),
        alarmSoundPlayerProvider.overrideWithValue(_StubAlarmSoundPlayer()),
        permissionNotifierProvider.overrideWith(
          () => _FixedPermissionNotifier(
            const PermissionState(
              postNotifications: DomainPermissionStatus.granted,
              scheduleExactAlarm: DomainPermissionStatus.granted,
              fullScreenIntent: DomainPermissionStatus.granted,
            ).copyWith(scheduleExactAlarm: exactAlarm),
          ),
        ),
      ],
    );
    try {
      body(async, container, now, scheduler);
    } finally {
      container.dispose();
    }
  });
}

class _FixedPermissionNotifier extends PermissionNotifier {
  _FixedPermissionNotifier(this._initial);
  final PermissionState _initial;

  @override
  PermissionState build() => _initial;
}

void _advance(FakeAsync async, _ClockHolder now, Duration d) {
  now.now = now.now.add(d);
  async.elapse(d);
}

void main() {
  group('TimerNotifier', () {
    test('initial state is null', () {
      _runWithFakeTime((async, container, now, scheduler) {
        expect(container.read(timerNotifierProvider), isNull);
      });
    });

    test('create configures an idle timer', () {
      _runWithFakeTime((async, container, now, scheduler) {
        container
            .read(timerNotifierProvider.notifier)
            .create(label: 'work', duration: const Duration(seconds: 5));

        final state = container.read(timerNotifierProvider);
        expect(state, isNotNull);
        expect(state!.status, TimerStatus.idle);
        expect(state.label, 'work');
        expect(state.duration, const Duration(seconds: 5));
      });
    });

    test('start transitions idle → running and ticks to ringing', () {
      _runWithFakeTime((async, container, now, scheduler) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.start();

        // Halfway: still running
        _advance(async, now, const Duration(seconds: 3));
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.running,
        );

        // Past endAt: should be ringing after the next 200ms tick fires
        _advance(async, now, const Duration(seconds: 3));
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.ringing,
        );
      });
    });

    test('ringing transition does NOT pre-cancel the OS notification', () {
      // Cancelling here would race AlarmManager and suppress the FSI /
      // heads-up banner in the background path. Cancellation is owned by
      // AlarmRingingScreen.initState (via AlarmRingingNotifier.start)
      // which only runs once the ringing screen is actually mounted.
      _runWithFakeTime((async, container, now, scheduler) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.start();
        final int notificationId = container
            .read(timerNotifierProvider)!
            .notificationId;

        _advance(async, now, const Duration(seconds: 6));
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.ringing,
        );

        verifyNever(() => scheduler.cancel(notificationId));
      });
    });

    test('pause then resume preserves remaining duration', () {
      _runWithFakeTime((async, container, now, scheduler) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 10));
        notifier.start();

        _advance(async, now, const Duration(seconds: 4));
        notifier.pause();

        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.paused,
        );
        expect(
          container.read(timerNotifierProvider)!.pausedRemaining,
          const Duration(seconds: 6),
        );

        // Time passes while paused - should not affect remaining
        _advance(async, now, const Duration(minutes: 5));
        expect(
          container.read(timerNotifierProvider)!.pausedRemaining,
          const Duration(seconds: 6),
        );

        notifier.resume();
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.running,
        );

        // 6 more seconds reaches ringing
        _advance(async, now, const Duration(seconds: 7));
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.ringing,
        );
      });
    });

    test('cancel transitions to cancelled and stops ticker', () {
      _runWithFakeTime((async, container, now, scheduler) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.start();

        notifier.cancel();
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.cancelled,
        );

        // Advancing time should not change state
        _advance(async, now, const Duration(minutes: 1));
        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.cancelled,
        );
      });
    });

    test('cancelled.start throws StateError', () {
      _runWithFakeTime((async, container, now, scheduler) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.cancel();

        expect(notifier.start, throwsStateError);
      });
    });

    test('reset returns cancelled timer to idle preserving duration', () {
      _runWithFakeTime((async, container, now, scheduler) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.cancel();
        notifier.reset();

        final state = container.read(timerNotifierProvider)!;
        expect(state.status, TimerStatus.idle);
        expect(state.duration, const Duration(seconds: 5));
      });
    });

    test('start without create throws StateError', () {
      _runWithFakeTime((async, container, now, scheduler) {
        expect(
          container.read(timerNotifierProvider.notifier).start,
          throwsStateError,
        );
      });
    });

    test('clear drops the timer entirely', () {
      _runWithFakeTime((async, container, now, scheduler) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 5));
        notifier.clear();
        expect(container.read(timerNotifierProvider), isNull);
      });
    });

    test('background recovery: long elapse jumps directly to ringing', () {
      // Simulates the app being suspended for longer than the timer's
      // remaining duration. After the next tick (200ms) the running state
      // is detected as past-due and flips to ringing.
      _runWithFakeTime((async, container, now, scheduler) {
        final notifier = container.read(timerNotifierProvider.notifier);
        notifier.create(label: 'x', duration: const Duration(seconds: 30));
        notifier.start();

        _advance(async, now, const Duration(minutes: 5));

        expect(
          container.read(timerNotifierProvider)!.status,
          TimerStatus.ringing,
        );
      });
    });
  });
}
