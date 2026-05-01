import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';

import 'notification_id_generator.dart';
import 'snooze_calculator.dart';
import 'timer_entity.dart';
import 'timer_status.dart';

/// Default UUID v4 generator (separate from the service so tests can inject
/// a deterministic alternative without implementing the full `Uuid` API).
String _defaultIdGenerator() => const Uuid().v4();

/// Domain service that drives [TimerEntity] state transitions.
///
/// All time-dependent operations go through the injected [Clock]. Invalid
/// transitions throw [StateError]. Construction-time validation throws
/// [ArgumentError].
class TimerService {
  TimerService({
    required Clock clock,
    String Function()? idGenerator,
    NotificationIdGenerator? notificationIdGenerator,
    SnoozeCalculator? snoozeCalculator,
  }) : _clock = clock,
       _idGenerator = idGenerator ?? _defaultIdGenerator,
       _notificationIdGenerator =
           notificationIdGenerator ?? const NotificationIdGenerator(),
       _snoozeCalculator = snoozeCalculator ?? SnoozeCalculator(clock: clock);

  final Clock _clock;
  final String Function() _idGenerator;
  final NotificationIdGenerator _notificationIdGenerator;
  final SnoozeCalculator _snoozeCalculator;

  static const Duration maxDuration = Duration(hours: 99);
  static const int maxLabelLength = 50;

  /// Create a brand-new timer in [TimerStatus.idle].
  ///
  /// Throws [ArgumentError] if `duration` is non-positive, exceeds
  /// `maxDuration`, or `label` exceeds `maxLabelLength`.
  TimerEntity createIdle({
    required String label,
    required Duration duration,
    String? id,
    DateTime? createdAt,
    String? soundId,
  }) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'must be > 0');
    }
    if (duration > maxDuration) {
      throw ArgumentError.value(duration, 'duration', 'must be <= 99 hours');
    }
    if (label.length > maxLabelLength) {
      throw ArgumentError.value(
        label,
        'label',
        'must be <= $maxLabelLength characters',
      );
    }
    final assignedId = id ?? _idGenerator();
    return TimerEntity(
      id: assignedId,
      notificationId: _notificationIdGenerator.idFor(assignedId),
      label: label,
      duration: duration,
      endAt: null,
      pausedRemaining: null,
      status: TimerStatus.idle,
      createdAt: createdAt ?? _clock.now(),
      soundId: soundId,
    );
  }

  /// Begin or restart counting down.
  ///
  /// - From `idle`/`ringing`/`completed`: uses the original `duration`.
  /// - From `paused`: uses `pausedRemaining`.
  /// - From `running`: [StateError] (already running).
  /// - From `cancelled`: [StateError] (create a new timer instead).
  TimerEntity start(TimerEntity entity) {
    final now = _clock.now();
    switch (entity.status) {
      case TimerStatus.idle:
      case TimerStatus.ringing:
      case TimerStatus.completed:
        return entity.copyWith(
          endAt: now.add(entity.duration),
          pausedRemaining: null,
          status: TimerStatus.running,
        );
      case TimerStatus.paused:
        return entity.copyWith(
          endAt: now.add(entity.pausedRemaining!),
          pausedRemaining: null,
          status: TimerStatus.running,
        );
      case TimerStatus.running:
        throw StateError('Cannot start: timer is already running');
      case TimerStatus.cancelled:
        throw StateError('Cannot start cancelled timer; create a new one');
    }
  }

  /// Suspend a running timer, preserving its remaining duration.
  TimerEntity pause(TimerEntity entity) {
    if (entity.status != TimerStatus.running) {
      throw StateError('Cannot pause from ${entity.status}');
    }
    final remaining = entity.endAt!.difference(_clock.now());
    return entity.copyWith(
      endAt: null,
      pausedRemaining: remaining.isNegative ? Duration.zero : remaining,
      status: TimerStatus.paused,
    );
  }

  /// Resume a paused timer.
  TimerEntity resume(TimerEntity entity) {
    if (entity.status != TimerStatus.paused) {
      throw StateError('Cannot resume from ${entity.status}');
    }
    return entity.copyWith(
      endAt: _clock.now().add(entity.pausedRemaining!),
      pausedRemaining: null,
      status: TimerStatus.running,
    );
  }

  /// Cancel a timer from any non-cancelled state. Idempotent if already
  /// cancelled (returns the same entity).
  TimerEntity cancel(TimerEntity entity) {
    if (entity.status == TimerStatus.cancelled) {
      return entity;
    }
    return entity.copyWith(
      endAt: null,
      pausedRemaining: null,
      status: TimerStatus.cancelled,
    );
  }

  /// Advance the clock-based portion of state. Returns a transitioned entity
  /// only when a `running` timer's `endAt` has been reached, otherwise
  /// returns the same instance unchanged.
  TimerEntity tick(TimerEntity entity) {
    if (entity.status != TimerStatus.running) {
      return entity;
    }
    if (!entity.endAt!.isAfter(_clock.now())) {
      return entity.copyWith(
        endAt: null,
        pausedRemaining: null,
        status: TimerStatus.ringing,
      );
    }
    return entity;
  }

  /// Snooze a `ringing` timer for [snoozeMinutes] more minutes.
  ///
  /// Transitions the entity back to `running` with `endAt = now + N min`.
  /// The original `duration` is preserved untouched, so a later `reset`
  /// still returns the timer to its originally-configured length.
  ///
  /// Throws [StateError] when called from any state other than `ringing`,
  /// and [ArgumentError] (via [SnoozeCalculator]) for snoozeMinutes
  /// outside `{3, 5, 10}`.
  TimerEntity snooze(TimerEntity entity, int snoozeMinutes) {
    if (entity.status != TimerStatus.ringing) {
      throw StateError('Cannot snooze from ${entity.status}');
    }
    final newEndAt = _snoozeCalculator.snoozeUntil(snoozeMinutes);
    return entity.copyWith(
      endAt: newEndAt,
      pausedRemaining: null,
      status: TimerStatus.running,
    );
  }

  /// Reset a `completed` or `cancelled` timer back to `idle`, preserving the
  /// configured `duration`.
  TimerEntity reset(TimerEntity entity) {
    if (entity.status != TimerStatus.completed &&
        entity.status != TimerStatus.cancelled) {
      throw StateError('Cannot reset from ${entity.status}');
    }
    return entity.copyWith(
      endAt: null,
      pausedRemaining: null,
      status: TimerStatus.idle,
    );
  }

  /// Live remaining time for any state.
  Duration remaining(TimerEntity entity) {
    switch (entity.status) {
      case TimerStatus.running:
        final diff = entity.endAt!.difference(_clock.now());
        return diff.isNegative ? Duration.zero : diff;
      case TimerStatus.paused:
        return entity.pausedRemaining!;
      case TimerStatus.idle:
      case TimerStatus.ringing:
      case TimerStatus.completed:
      case TimerStatus.cancelled:
        return Duration.zero;
    }
  }
}
