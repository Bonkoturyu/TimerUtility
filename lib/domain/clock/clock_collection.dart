import 'clock_location.dart';
import 'exceptions.dart';

/// Aggregate root for the set of pinned clock locations on the world
/// clock screen (Phase 10.5).
///
/// Pure value type: every mutation returns a new [ClockCollection]
/// rather than mutating in place. The Notifier sits on top of this and
/// owns persistence + GPS detection orchestration.
///
/// Invariants:
///   - At most [maxSize] entries.
///   - All entries have unique `id`.
///   - At most one entry has `isCurrentLocation == true`. [add] /
///     [update] enforce this by demoting any prior holder when a new
///     entry comes in flagged.
class ClockCollection {
  const ClockCollection._(this._byId);

  factory ClockCollection.empty() =>
      const ClockCollection._(<String, ClockLocation>{});

  factory ClockCollection.fromList(List<ClockLocation> locations) {
    if (locations.length > maxSize) {
      throw const MaxClockLocationCountExceededException(maxSize);
    }
    final Map<String, ClockLocation> byId = <String, ClockLocation>{};
    bool seenCurrent = false;
    for (final ClockLocation l in locations) {
      ClockLocation entry = l;
      if (entry.isCurrentLocation) {
        if (seenCurrent) {
          // Persisted state contains more than one current-location
          // entry (should never happen, but defend the invariant).
          // Demote later duplicates so the surviving record is the
          // first one in the source list.
          entry = entry.copyWith(isCurrentLocation: false);
        } else {
          seenCurrent = true;
        }
      }
      byId[entry.id] = entry;
    }
    return ClockCollection._(Map<String, ClockLocation>.unmodifiable(byId));
  }

  final Map<String, ClockLocation> _byId;

  /// Hard cap on pinned clock locations (Phase 10.5 decision: 6 cities
  /// fit a 2x3 Grid without horizontal overflow on a Pixel 6a).
  /// Bumps require revisiting the design grid in
  /// `presentation/screens/clock_screen.dart`.
  static const int maxSize = 6;

  int get size => _byId.length;
  bool get isEmpty => _byId.isEmpty;
  bool get isFull => _byId.length >= maxSize;

  /// Snapshot of every location in insertion order.
  List<ClockLocation> get all => List<ClockLocation>.unmodifiable(_byId.values);

  ClockLocation? findById(String id) => _byId[id];

  /// The single entry flagged `isCurrentLocation == true`, or `null`
  /// if none. Caller can rely on at most one match — the invariant is
  /// enforced by [add] / [update] / [fromList].
  ClockLocation? currentLocation() {
    for (final ClockLocation l in _byId.values) {
      if (l.isCurrentLocation) {
        return l;
      }
    }
    return null;
  }

  /// Insert a new clock location. If `entity.id` already exists, treat
  /// as update — keeps callers simple when re-loading from DB. Throws
  /// [MaxClockLocationCountExceededException] when the collection is
  /// already full and the id is new.
  ///
  /// When `entity.isCurrentLocation == true`, any existing entry with
  /// the same flag is demoted to `false`.
  ClockCollection add(ClockLocation entity) {
    if (_byId.containsKey(entity.id)) {
      return update(entity);
    }
    if (isFull) {
      throw const MaxClockLocationCountExceededException(maxSize);
    }
    final Map<String, ClockLocation> next = Map<String, ClockLocation>.of(
      _byId,
    );
    if (entity.isCurrentLocation) {
      _demoteOtherCurrentLocations(next, except: entity.id);
    }
    next[entity.id] = entity;
    return ClockCollection._(Map<String, ClockLocation>.unmodifiable(next));
  }

  /// Replace the location stored under `entity.id`. Throws
  /// [ClockLocationNotFoundException] when no such entry exists.
  ClockCollection update(ClockLocation entity) {
    if (!_byId.containsKey(entity.id)) {
      throw ClockLocationNotFoundException(entity.id);
    }
    final Map<String, ClockLocation> next = Map<String, ClockLocation>.of(
      _byId,
    );
    if (entity.isCurrentLocation) {
      _demoteOtherCurrentLocations(next, except: entity.id);
    }
    next[entity.id] = entity;
    return ClockCollection._(Map<String, ClockLocation>.unmodifiable(next));
  }

  /// Remove a location by id. Throws [ClockLocationNotFoundException]
  /// when absent to flag stale UI references.
  ClockCollection remove(String id) {
    if (!_byId.containsKey(id)) {
      throw ClockLocationNotFoundException(id);
    }
    final Map<String, ClockLocation> next = Map<String, ClockLocation>.of(
      _byId,
    );
    next.remove(id);
    return ClockCollection._(Map<String, ClockLocation>.unmodifiable(next));
  }

  /// Reorder entries by list position (0-indexed). Recalculates
  /// `displayOrder` for every entry as `0..size-1` so the ordering is
  /// stable across persistence round-trips.
  ///
  /// `oldIndex` and `newIndex` are *destination indices* — the simple
  /// "remove from oldIndex, insert at newIndex" semantics, not the
  /// `ReorderableListView.onReorder` post-removal convention. The
  /// Notifier layer is responsible for translating the Flutter widget
  /// callback into these indices.
  ///
  /// Throws [RangeError] when either index is out of bounds.
  /// `oldIndex == newIndex` is a no-op and returns `this` unchanged.
  ClockCollection reorder(int oldIndex, int newIndex) {
    final List<ClockLocation> ordered = _byId.values.toList();
    RangeError.checkValidIndex(oldIndex, ordered, 'oldIndex');
    RangeError.checkValidIndex(newIndex, ordered, 'newIndex');
    if (oldIndex == newIndex) {
      return this;
    }
    final ClockLocation moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);

    final Map<String, ClockLocation> next = <String, ClockLocation>{};
    for (int i = 0; i < ordered.length; i++) {
      next[ordered[i].id] = ordered[i].copyWith(displayOrder: i);
    }
    return ClockCollection._(Map<String, ClockLocation>.unmodifiable(next));
  }

  void _demoteOtherCurrentLocations(
    Map<String, ClockLocation> map, {
    required String except,
  }) {
    for (final MapEntry<String, ClockLocation> entry in map.entries.toList(
      growable: false,
    )) {
      if (entry.key != except && entry.value.isCurrentLocation) {
        map[entry.key] = entry.value.copyWith(isCurrentLocation: false);
      }
    }
  }
}
