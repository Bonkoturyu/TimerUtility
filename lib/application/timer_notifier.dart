import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/permission_manager.dart';
import '../domain/timer/alarm_sound.dart';
import '../domain/timer/alarm_sound_catalog.dart';
import '../domain/timer/timer_entity.dart';
import '../domain/timer/timer_service.dart';
import '../domain/timer/timer_status.dart';
import 'alarm_ringing_notifier.dart';
import 'clock_provider.dart';
import 'notification_scheduler_provider.dart';
import 'permission_notifier.dart';

part 'timer_notifier.g.dart';

/// Timer domain service wired with the application [Clock].
@Riverpod(keepAlive: true)
TimerService timerService(Ref ref) =>
    TimerService(clock: ref.watch(clockProvider));

/// Single-timer state holder for Phase 3.
///
/// State `null` means "no timer configured yet" (initial app state).
/// While a timer is `running`, an internal 200ms ticker calls
/// `TimerService.tick` to detect when `endAt` is reached and transition
/// to `ringing`. The ticker also covers the "returned from background"
/// case naturally: a single tick after resume re-checks `endAt` against
/// the current clock and flips to `ringing` immediately if the deadline
/// has already passed.
@Riverpod(keepAlive: true)
class TimerNotifier extends _$TimerNotifier {
  Timer? _ticker;

  @override
  TimerEntity? build() {
    ref.onDispose(_stopTicker);
    return null;
  }

  /// Configure a brand new timer (state goes from null/anything to idle).
  void create({
    required String label,
    required Duration duration,
    String? soundId,
  }) {
    _stopTicker();
    state = ref
        .read(timerServiceProvider)
        .createIdle(label: label, duration: duration, soundId: soundId);
  }

  void start() {
    final current = _requireState('start');
    final next = ref.read(timerServiceProvider).start(current);
    state = next;
    _startTicker();
    _scheduleNotification(next);
  }

  void pause() {
    final current = _requireState('pause');
    state = ref.read(timerServiceProvider).pause(current);
    _stopTicker();
    _cancelNotification(current.notificationId);
  }

  void resume() {
    final current = _requireState('resume');
    final next = ref.read(timerServiceProvider).resume(current);
    state = next;
    _startTicker();
    _scheduleNotification(next);
  }

  void cancel() {
    final current = state;
    if (current == null) {
      return;
    }
    state = ref.read(timerServiceProvider).cancel(current);
    _stopTicker();
    _cancelNotification(current.notificationId);
    _stopRingingIfActive(current.id);
  }

  void reset() {
    final current = _requireState('reset');
    state = ref.read(timerServiceProvider).reset(current);
    _stopTicker();
    _cancelNotification(current.notificationId);
    _stopRingingIfActive(current.id);
  }

  /// Drop the currently configured timer (returns to the "no timer" state).
  ///
  /// Also cancels any OS notification still in the shade so the user can't
  /// re-tap it after dismissing the alarm and trigger a duplicate
  /// AlarmRingingScreen via the notification deep link.
  void clear() {
    final current = state;
    if (current != null) {
      _cancelNotification(current.notificationId);
    }
    _stopTicker();
    state = null;
  }

  TimerEntity _requireState(String op) {
    final current = state;
    if (current == null) {
      throw StateError('No timer to $op');
    }
    return current;
  }

  /// Schedule the OS notification for the timer's `endAt`. Fire-and-forget;
  /// errors are surfaced via the scheduler's own logging (Phase 4 has no
  /// retry policy beyond what the OS provides).
  void _scheduleNotification(TimerEntity entity) {
    if (entity.status != TimerStatus.running || entity.endAt == null) {
      return;
    }
    final exact =
        ref.read(permissionNotifierProvider).scheduleExactAlarm ==
            DomainPermissionStatus.granted ||
        ref.read(permissionNotifierProvider).scheduleExactAlarm ==
            DomainPermissionStatus.notRequired;
    final title = entity.label.isEmpty ? 'Timer' : entity.label;
    const body = 'Time is up.';
    unawaited(
      ref
          .read(notificationSchedulerProvider)
          .schedule(
            notificationId: entity.notificationId,
            fireAt: entity.endAt!,
            title: title,
            body: body,
            exact: exact,
            payload: entity.id,
          ),
    );
  }

  void _cancelNotification(int notificationId) {
    unawaited(ref.read(notificationSchedulerProvider).cancel(notificationId));
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _onTick(),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onTick() {
    final current = state;
    if (current == null || current.status != TimerStatus.running) {
      _stopTicker();
      return;
    }
    final next = ref.read(timerServiceProvider).tick(current);
    if (!identical(next, current)) {
      state = next;
      if (next.status != TimerStatus.running) {
        _stopTicker();
      }
      if (next.status == TimerStatus.ringing) {
        _startRinging(next);
      }
    }
  }

  void _startRinging(TimerEntity entity) {
    final AlarmSound sound =
        (entity.soundId == null
            ? null
            : AlarmSoundCatalog.findById(entity.soundId!)) ??
        AlarmSoundCatalog.defaultSound;
    unawaited(
      ref
          .read(alarmRingingNotifierProvider.notifier)
          .start(
            timerId: entity.id,
            sound: sound,
            notificationId: entity.notificationId,
          ),
    );
  }

  void _stopRingingIfActive(String timerId) {
    final ringing = ref.read(alarmRingingNotifierProvider);
    if (ringing.currentTimerId == timerId) {
      unawaited(ref.read(alarmRingingNotifierProvider.notifier).stop());
    }
  }
}
