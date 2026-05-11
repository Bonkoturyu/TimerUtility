import 'clock_entry.dart';
import 'exceptions.dart';

/// Aggregate root for the set of pinned clock entries on the world
/// clock screen (Phase 10.5; Phase 11 で `ClockCollection` から
/// `ClockEntryCollection` にリネーム)。
///
/// Pure value type: every mutation returns a new [ClockEntryCollection]
/// rather than mutating in place. The Notifier sits on top of this and
/// owns persistence + GPS detection orchestration.
///
/// Invariants:
///   - At most [maxSize] entries.
///   - All entries have unique `id`.
///   - At most one entry has `isCurrentLocation == true`. [add] /
///     [update] enforce this by demoting any prior holder when a new
///     entry comes in flagged. (フィールド名 `isCurrentLocation` は
///     GPS 由来の概念として valid なため Phase 11 リネームでも据置。)
class ClockEntryCollection {
  const ClockEntryCollection._(this._byId);

  factory ClockEntryCollection.empty() =>
      const ClockEntryCollection._(<String, ClockEntry>{});

  factory ClockEntryCollection.fromList(List<ClockEntry> entries) {
    if (entries.length > maxSize) {
      throw const MaxClockEntryCountExceededException(maxSize);
    }
    final Map<String, ClockEntry> byId = <String, ClockEntry>{};
    bool seenCurrent = false;
    for (final ClockEntry e in entries) {
      ClockEntry entry = e;
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
    return ClockEntryCollection._(Map<String, ClockEntry>.unmodifiable(byId));
  }

  final Map<String, ClockEntry> _byId;

  /// Hard cap on pinned clock entries (Phase 10.5 decision: 6 cities
  /// fit a 2x3 Grid without horizontal overflow on a Pixel 6a).
  /// Bumps require revisiting the design grid in
  /// `presentation/screens/clock_screen.dart`.
  static const int maxSize = 6;

  int get size => _byId.length;
  bool get isEmpty => _byId.isEmpty;
  bool get isFull => _byId.length >= maxSize;

  /// Snapshot of every entry in insertion order.
  List<ClockEntry> get all => List<ClockEntry>.unmodifiable(_byId.values);

  ClockEntry? findById(String id) => _byId[id];

  /// The single entry flagged `isCurrentLocation == true`, or `null`
  /// if none. Caller can rely on at most one match — the invariant is
  /// enforced by [add] / [update] / [fromList].
  ClockEntry? currentEntry() {
    for (final ClockEntry e in _byId.values) {
      if (e.isCurrentLocation) {
        return e;
      }
    }
    return null;
  }

  /// Insert a new clock entry. If `entity.id` already exists, treat
  /// as update — keeps callers simple when re-loading from DB. Throws
  /// [MaxClockEntryCountExceededException] when the collection is
  /// already full and the id is new.
  ///
  /// When `entity.isCurrentLocation == true`, any existing entry with
  /// the same flag is demoted to `false`.
  ClockEntryCollection add(ClockEntry entity) {
    if (_byId.containsKey(entity.id)) {
      return update(entity);
    }
    if (isFull) {
      throw const MaxClockEntryCountExceededException(maxSize);
    }
    final Map<String, ClockEntry> next = Map<String, ClockEntry>.of(_byId);
    if (entity.isCurrentLocation) {
      _demoteOtherCurrentEntries(next, except: entity.id);
    }
    next[entity.id] = entity;
    return ClockEntryCollection._(Map<String, ClockEntry>.unmodifiable(next));
  }

  /// Replace the entry stored under `entity.id`. Throws
  /// [ClockEntryNotFoundException] when no such entry exists.
  ClockEntryCollection update(ClockEntry entity) {
    if (!_byId.containsKey(entity.id)) {
      throw ClockEntryNotFoundException(entity.id);
    }
    final Map<String, ClockEntry> next = Map<String, ClockEntry>.of(_byId);
    if (entity.isCurrentLocation) {
      _demoteOtherCurrentEntries(next, except: entity.id);
    }
    next[entity.id] = entity;
    return ClockEntryCollection._(Map<String, ClockEntry>.unmodifiable(next));
  }

  /// Remove an entry by id. Throws [ClockEntryNotFoundException]
  /// when absent to flag stale UI references.
  ClockEntryCollection remove(String id) {
    if (!_byId.containsKey(id)) {
      throw ClockEntryNotFoundException(id);
    }
    final Map<String, ClockEntry> next = Map<String, ClockEntry>.of(_byId);
    next.remove(id);
    return ClockEntryCollection._(Map<String, ClockEntry>.unmodifiable(next));
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
  ClockEntryCollection reorder(int oldIndex, int newIndex) {
    final List<ClockEntry> ordered = _byId.values.toList();
    RangeError.checkValidIndex(oldIndex, ordered, 'oldIndex');
    RangeError.checkValidIndex(newIndex, ordered, 'newIndex');
    if (oldIndex == newIndex) {
      return this;
    }
    final ClockEntry moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);

    final Map<String, ClockEntry> next = <String, ClockEntry>{};
    for (int i = 0; i < ordered.length; i++) {
      next[ordered[i].id] = ordered[i].copyWith(displayOrder: i);
    }
    return ClockEntryCollection._(Map<String, ClockEntry>.unmodifiable(next));
  }

  void _demoteOtherCurrentEntries(
    Map<String, ClockEntry> map, {
    required String except,
  }) {
    for (final MapEntry<String, ClockEntry> entry in map.entries.toList(
      growable: false,
    )) {
      if (entry.key != except && entry.value.isCurrentLocation) {
        map[entry.key] = entry.value.copyWith(isCurrentLocation: false);
      }
    }
  }
}
