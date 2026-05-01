import 'exceptions.dart';
import 'timer_entity.dart';
import 'timer_status.dart';

/// Aggregate root for the set of currently configured timers.
///
/// Pure value type: every mutation returns a new [TimerCollection]
/// rather than mutating in place. The Notifier sits on top of this and
/// owns persistence + ticker scheduling.
///
/// Invariants:
///   - At most [maxSize] entries.
///   - All entries have unique `id`.
class TimerCollection {
  const TimerCollection._(this._byId);

  factory TimerCollection.empty() =>
      const TimerCollection._(<String, TimerEntity>{});

  factory TimerCollection.fromList(List<TimerEntity> timers) {
    if (timers.length > maxSize) {
      throw const MaxTimerCountExceededException(maxSize);
    }
    final Map<String, TimerEntity> byId = <String, TimerEntity>{};
    for (final TimerEntity t in timers) {
      byId[t.id] = t;
    }
    return TimerCollection._(Map<String, TimerEntity>.unmodifiable(byId));
  }

  final Map<String, TimerEntity> _byId;

  /// Hard cap on simultaneously-managed timers (Phase 8 decision).
  /// Bumps require considering notification ID collision odds and the
  /// UX of multiple alarms ringing concurrently.
  static const int maxSize = 10;

  int get size => _byId.length;
  bool get isEmpty => _byId.isEmpty;
  bool get isFull => _byId.length >= maxSize;

  /// Snapshot of every timer in insertion order.
  List<TimerEntity> get all => List<TimerEntity>.unmodifiable(_byId.values);

  /// Number of timers currently in [TimerStatus.running].
  int get runningCount => _byId.values
      .where((TimerEntity t) => t.status == TimerStatus.running)
      .length;

  TimerEntity? findById(String id) => _byId[id];

  /// Insert a new timer. Throws [MaxTimerCountExceededException] when
  /// the collection is already full. Replacing an existing id is not
  /// supported here — use [update] for that path so callers can't
  /// silently lose state by reusing an id.
  TimerCollection add(TimerEntity entity) {
    if (_byId.containsKey(entity.id)) {
      // Treat as update: keeps the call site simple for the Notifier
      // which sometimes calls add after re-loading from DB.
      return update(entity);
    }
    if (isFull) {
      throw const MaxTimerCountExceededException(maxSize);
    }
    final Map<String, TimerEntity> next = Map<String, TimerEntity>.of(_byId);
    next[entity.id] = entity;
    return TimerCollection._(Map<String, TimerEntity>.unmodifiable(next));
  }

  /// Replace the entity stored under `entity.id`. Throws
  /// [TimerNotFoundException] when no such entry exists — `add` is the
  /// right method for inserts.
  TimerCollection update(TimerEntity entity) {
    if (!_byId.containsKey(entity.id)) {
      throw TimerNotFoundException(entity.id);
    }
    final Map<String, TimerEntity> next = Map<String, TimerEntity>.of(_byId);
    next[entity.id] = entity;
    return TimerCollection._(Map<String, TimerEntity>.unmodifiable(next));
  }

  /// Remove a timer by id. Throws [TimerNotFoundException] when absent
  /// to flag stale UI references rather than silently no-op.
  TimerCollection remove(String id) {
    if (!_byId.containsKey(id)) {
      throw TimerNotFoundException(id);
    }
    final Map<String, TimerEntity> next = Map<String, TimerEntity>.of(_byId);
    next.remove(id);
    return TimerCollection._(Map<String, TimerEntity>.unmodifiable(next));
  }
}
