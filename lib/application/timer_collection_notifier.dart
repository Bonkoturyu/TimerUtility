import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/permission_manager.dart';
import '../domain/timer/timer_collection.dart';
import '../domain/timer/timer_entity.dart';
import '../domain/timer/timer_service.dart';
import '../domain/timer/timer_status.dart';
import 'clock_provider.dart';
import 'notification_scheduler_provider.dart';
import 'permission_notifier.dart';
import 'timer_repository_provider.dart';
import 'timer_service_provider.dart';

part 'timer_collection_notifier.g.dart';

/// Phase 8 single source of truth for every active timer.
///
/// Replaces the Phase 3 single-timer `TimerNotifier`. State is the full
/// [TimerCollection] (immutable aggregate). Each mutation:
///   1. Computes the next [TimerEntity] via [TimerService].
///   2. Writes the new collection to [state].
///   3. Persists the changed entity via [TimerRepository.upsert] /
///      `delete`, fire-and-forget.
///   4. Coordinates with [NotificationScheduler] (schedule on running,
///      cancel on pause / cancel / delete / reset / clear).
///
/// A single 200 ms ticker drives every running timer; tick walks the
/// collection and only re-emits state when at least one timer flipped
/// to `ringing`. The ticker stops itself once `runningCount == 0` and
/// is restarted by any operation that produces a running timer.
///
/// Restoration semantics: at `build()` we asynchronously load the
/// stored collection. Any timer whose `status == running` and whose
/// `endAt` already passed is rewritten to `completed`, persisted, and
/// surfaced via [NotificationScheduler.show] exactly once. The alarm
/// screen is intentionally NOT launched and audio is NOT played for
/// these — see Phase 8 plan #4.
@Riverpod(keepAlive: true)
class TimerCollectionNotifier extends _$TimerCollectionNotifier {
  Timer? _ticker;

  @override
  TimerCollection build() {
    ref.onDispose(_stopTicker);
    // Kick off restore asynchronously so build() can return synchronously.
    Future<void>.microtask(_restoreFromRepository);
    return TimerCollection.empty();
  }

  Future<void> _restoreFromRepository() async {
    final List<TimerEntity> persisted = await ref
        .read(timerRepositoryProvider)
        .findAll();
    if (persisted.isEmpty) return;

    final DateTime now = ref.read(clockProvider).now();
    final List<TimerEntity> restored = <TimerEntity>[];
    final List<TimerEntity> overdue = <TimerEntity>[];
    for (final TimerEntity t in persisted) {
      if (t.status == TimerStatus.running &&
          t.endAt != null &&
          !t.endAt!.isAfter(now)) {
        final TimerEntity completed = t.copyWith(
          endAt: null,
          pausedRemaining: null,
          status: TimerStatus.completed,
        );
        restored.add(completed);
        overdue.add(completed);
      } else {
        restored.add(t);
      }
    }

    state = TimerCollection.fromList(restored);

    // Persist the rewritten overdue entries and surface a single notification
    // each so the user knows the timer fired while the app was away.
    final TimerRepositoryFireAndForget repo = TimerRepositoryFireAndForget(ref);
    for (final TimerEntity t in overdue) {
      repo.upsert(t);
      _showRestoredCompletionNotification(t);
    }
    // If anything was running before restore (and didn't expire), the
    // ticker needs to come back on so the in-flight countdown keeps
    // updating after a warm-launch resume.
    if (state.runningCount > 0) {
      _startTicker();
    }
  }

  /// Add a brand-new idle timer to the collection. Returns the created
  /// entity so the UI can immediately call [start] with the right id.
  ///
  /// Throws [MaxTimerCountExceededException] when the collection is
  /// full (10 timers). Caller must surface as a SnackBar / banner.
  TimerEntity create({
    required String label,
    required Duration duration,
    String? soundId,
  }) {
    final TimerEntity created = ref
        .read(timerServiceProvider)
        .createIdle(label: label, duration: duration, soundId: soundId);
    state = state.add(created);
    _persist(created);
    return created;
  }

  void start(String id) {
    final TimerEntity current = _require(id);
    final TimerEntity next = ref.read(timerServiceProvider).start(current);
    state = state.update(next);
    _startTicker();
    _scheduleNotification(next);
    _persist(next);
  }

  void pause(String id) {
    final TimerEntity current = _require(id);
    final TimerEntity next = ref.read(timerServiceProvider).pause(current);
    state = state.update(next);
    _cancelNotification(current.notificationId);
    _maybeStopTicker();
    _persist(next);
  }

  void resume(String id) {
    final TimerEntity current = _require(id);
    final TimerEntity next = ref.read(timerServiceProvider).resume(current);
    state = state.update(next);
    _startTicker();
    _scheduleNotification(next);
    _persist(next);
  }

  void cancel(String id) {
    final TimerEntity current = _require(id);
    final TimerEntity next = ref.read(timerServiceProvider).cancel(current);
    state = state.update(next);
    _cancelNotification(current.notificationId);
    _maybeStopTicker();
    _persist(next);
  }

  void reset(String id) {
    final TimerEntity current = _require(id);
    final TimerEntity next = ref.read(timerServiceProvider).reset(current);
    state = state.update(next);
    _cancelNotification(current.notificationId);
    _persist(next);
  }

  /// Re-arm a `ringing` timer for [snoozeMinutes] more minutes.
  void snooze(String id, int snoozeMinutes) {
    final TimerEntity current = _require(id);
    final TimerEntity next = ref
        .read(timerServiceProvider)
        .snooze(current, snoozeMinutes);
    state = state.update(next);
    _startTicker();
    _scheduleNotification(next);
    _persist(next);
  }

  /// Permanently remove a timer from the collection (and DB).
  void delete(String id) {
    final TimerEntity? current = state.findById(id);
    if (current == null) return;
    state = state.remove(id);
    _cancelNotification(current.notificationId);
    _maybeStopTicker();
    unawaited(ref.read(timerRepositoryProvider).delete(id));
  }

  /// Returns the first timer currently in [TimerStatus.ringing], or
  /// `null` if none. Used by `AlarmRingingScreen` to bootstrap audio
  /// and find the snooze target.
  TimerEntity? findRinging() {
    for (final TimerEntity t in state.all) {
      if (t.status == TimerStatus.ringing) return t;
    }
    return null;
  }

  TimerEntity _require(String id) {
    final TimerEntity? entity = state.findById(id);
    if (entity == null) {
      throw StateError('No timer with id $id');
    }
    return entity;
  }

  void _persist(TimerEntity entity) {
    unawaited(ref.read(timerRepositoryProvider).upsert(entity));
  }

  void _scheduleNotification(TimerEntity entity) {
    if (entity.status != TimerStatus.running || entity.endAt == null) return;
    final DomainPermissionStatus exact = ref
        .read(permissionNotifierProvider)
        .scheduleExactAlarm;
    final bool useExact =
        exact == DomainPermissionStatus.granted ||
        exact == DomainPermissionStatus.notRequired;
    final String title = entity.label.isEmpty ? 'Timer' : entity.label;
    unawaited(
      ref
          .read(notificationSchedulerProvider)
          .schedule(
            notificationId: entity.notificationId,
            fireAt: entity.endAt!,
            title: title,
            body: 'Time is up.',
            exact: useExact,
            payload: entity.id,
          ),
    );
  }

  void _cancelNotification(int notificationId) {
    unawaited(ref.read(notificationSchedulerProvider).cancel(notificationId));
  }

  void _showRestoredCompletionNotification(TimerEntity entity) {
    final String title = entity.label.isEmpty ? 'Timer' : entity.label;
    unawaited(
      ref
          .read(notificationSchedulerProvider)
          .show(
            notificationId: entity.notificationId,
            title: title,
            body: 'Timer ended while the app was in the background.',
            payload: entity.id,
          ),
    );
  }

  void _startTicker() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _onTick(),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _maybeStopTicker() {
    if (state.runningCount == 0) {
      _stopTicker();
    }
  }

  void _onTick() {
    final TimerService service = ref.read(timerServiceProvider);
    TimerCollection working = state;
    final List<TimerEntity> ringingTransitions = <TimerEntity>[];
    for (final TimerEntity t in state.all) {
      if (t.status != TimerStatus.running) continue;
      final TimerEntity next = service.tick(t);
      if (!identical(next, t)) {
        working = working.update(next);
        if (next.status == TimerStatus.ringing) {
          ringingTransitions.add(next);
        }
      }
    }
    if (!identical(working, state)) {
      state = working;
      for (final TimerEntity t in ringingTransitions) {
        _persist(t);
      }
    }
    if (state.runningCount == 0) {
      _stopTicker();
    }
  }
}

/// Tiny helper that holds a `Ref` so `_restoreFromRepository` can call
/// `repo.upsert` outside of the synchronous build window without
/// rebinding the provider on every call.
class TimerRepositoryFireAndForget {
  TimerRepositoryFireAndForget(this._ref);
  final Ref _ref;

  void upsert(TimerEntity entity) {
    unawaited(_ref.read(timerRepositoryProvider).upsert(entity));
  }
}
