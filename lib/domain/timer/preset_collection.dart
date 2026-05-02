import 'preset.dart';
import 'preset_exceptions.dart';

/// Aggregate root for the set of currently saved presets.
///
/// Pure value type: every mutation returns a new [PresetCollection]
/// rather than mutating in place. The Notifier sits on top of this and
/// owns persistence + template-replace orchestration.
///
/// Invariants:
///   - At most [maxSize] entries.
///   - All entries have unique `id`.
class PresetCollection {
  const PresetCollection._(this._byId);

  factory PresetCollection.empty() =>
      const PresetCollection._(<String, Preset>{});

  factory PresetCollection.fromList(List<Preset> presets) {
    if (presets.length > maxSize) {
      throw const MaxPresetCountExceededException(maxSize);
    }
    final Map<String, Preset> byId = <String, Preset>{};
    for (final Preset p in presets) {
      byId[p.id] = p;
    }
    return PresetCollection._(Map<String, Preset>.unmodifiable(byId));
  }

  final Map<String, Preset> _byId;

  /// Hard cap on saved presets (Phase 9 decision: same as
  /// `TimerCollection.maxSize`). Bumps require considering UX of long
  /// chip lists in the bottom sheet and management screen scroll length.
  static const int maxSize = 10;

  int get size => _byId.length;
  bool get isEmpty => _byId.isEmpty;
  bool get isFull => _byId.length >= maxSize;

  /// Snapshot of every preset in insertion order.
  List<Preset> get all => List<Preset>.unmodifiable(_byId.values);

  Preset? findById(String id) => _byId[id];

  /// Insert a new preset. If `entity.id` already exists, treat as
  /// update — keeps callers simple when re-loading from DB. Throws
  /// [MaxPresetCountExceededException] when the collection is already
  /// full and the id is new.
  PresetCollection add(Preset entity) {
    if (_byId.containsKey(entity.id)) {
      return update(entity);
    }
    if (isFull) {
      throw const MaxPresetCountExceededException(maxSize);
    }
    final Map<String, Preset> next = Map<String, Preset>.of(_byId);
    next[entity.id] = entity;
    return PresetCollection._(Map<String, Preset>.unmodifiable(next));
  }

  /// Replace the preset stored under `entity.id`. Throws
  /// [PresetNotFoundException] when no such entry exists.
  PresetCollection update(Preset entity) {
    if (!_byId.containsKey(entity.id)) {
      throw PresetNotFoundException(entity.id);
    }
    final Map<String, Preset> next = Map<String, Preset>.of(_byId);
    next[entity.id] = entity;
    return PresetCollection._(Map<String, Preset>.unmodifiable(next));
  }

  /// Remove a preset by id. Throws [PresetNotFoundException] when
  /// absent to flag stale UI references.
  PresetCollection remove(String id) {
    if (!_byId.containsKey(id)) {
      throw PresetNotFoundException(id);
    }
    final Map<String, Preset> next = Map<String, Preset>.of(_byId);
    next.remove(id);
    return PresetCollection._(Map<String, Preset>.unmodifiable(next));
  }
}
