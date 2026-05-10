import 'dart:async';

import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../domain/clock/clock_collection.dart';
import '../domain/clock/clock_location.dart';
import '../domain/clock/timezone_catalog.dart';
import '../domain/ports/clock_location_repository.dart';
import '../domain/ports/location_detector.dart';
import 'clock_location_repository_provider.dart';
import 'clock_provider.dart';
import 'location_detector_provider.dart';

part 'clock_collection_notifier.g.dart';

/// Phase 10.5 single source of truth for pinned world-clock locations.
///
/// Mirrors `PresetCollectionNotifier`:
///   - State = immutable aggregate ([ClockCollection]).
///   - Mutations: validate via the aggregate, update [state], persist
///     via [ClockLocationRepository] in a fire-and-forget pattern.
///   - Restore on build: asynchronously load the persisted collection.
///     On a fresh install (DB empty) we additionally call
///     [LocationDetector.detectTimezoneId] to seed a single
///     "current location" entry so the first launch shows local time.
@Riverpod(keepAlive: true)
class ClockCollectionNotifier extends _$ClockCollectionNotifier {
  String Function()? _idGenerator;
  bool _initialDetectionAttempted = false;

  @override
  ClockCollection build() {
    Future<void>.microtask(_loadAndMaybeDetect);
    return ClockCollection.empty();
  }

  Future<void> _loadAndMaybeDetect() async {
    // Race guard: a mutation may have already populated the state via
    // a faster code path (e.g. direct `addPreset` from a deeplink).
    if (state.size > 0) return;

    final List<ClockLocation> persisted = await ref
        .read(clockLocationRepositoryProvider)
        .findAll();
    // Re-check after the await: another mutation may have populated
    // `state` while `findAll` was in flight. Overwriting it would clobber
    // the user-visible change.
    if (state.size > 0) return;
    if (persisted.isNotEmpty) {
      state = ClockCollection.fromList(persisted);
      return;
    }

    // First launch (or after a "wipe all" UX): synthesise a single
    // `isCurrentLocation` entry from the device's detected timezone.
    if (_initialDetectionAttempted) return;
    _initialDetectionAttempted = true;

    final String tzId = await ref
        .read(locationDetectorProvider)
        .detectTimezoneId();
    // Re-check after the detection await: a mutation may have raced in
    // and made the seed redundant (size > 0) or impossible (isFull, which
    // would otherwise throw `MaxClockLocationCountExceededException` from
    // an unawaited microtask).
    if (state.size > 0) return;
    final Clock clock = ref.read(clockProvider);
    final ClockLocation seeded = ClockLocation(
      id: _newId(),
      displayName: _deriveDisplayName(tzId),
      timezoneId: tzId,
      isCurrentLocation: true,
      displayOrder: 0,
      createdAt: clock.now(),
    );
    state = state.add(seeded);
    unawaited(ref.read(clockLocationRepositoryProvider).upsert(seeded));
  }

  /// Add a user-picked preset city. The aggregate enforces the 6-entry
  /// cap by throwing [MaxClockLocationCountExceededException] which the
  /// notifier surfaces unchanged for the UI to translate to a SnackBar.
  ClockLocation addPreset({
    required String timezoneId,
    required String displayName,
  }) {
    final Clock clock = ref.read(clockProvider);
    final ClockLocation entity = ClockLocation(
      id: _newId(),
      displayName: displayName,
      timezoneId: timezoneId,
      isCurrentLocation: false,
      displayOrder: state.size,
      createdAt: clock.now(),
    );
    state = state.add(entity);
    unawaited(ref.read(clockLocationRepositoryProvider).upsert(entity));
    return entity;
  }

  /// Remove a clock location by id. No-op (gracefully) if absent so
  /// callers don't have to guard against double-tap races.
  void remove(String id) {
    final ClockLocation? existing = state.findById(id);
    if (existing == null) return;
    state = state.remove(id);
    unawaited(ref.read(clockLocationRepositoryProvider).delete(id));
  }

  /// Reorder by destination indices (not Flutter's post-removal
  /// convention — the caller translates `ReorderableListView.onReorder`
  /// before calling this). `displayOrder` is recomputed 0..N-1, then
  /// persisted atomically via `replaceAll` so a partial failure can
  /// never leave the table out of order.
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    state = state.reorder(oldIndex, newIndex);
    unawaited(ref.read(clockLocationRepositoryProvider).replaceAll(state.all));
  }

  /// Lightweight rename (timezoneId edits go through "remove + add"
  /// so the Application layer doesn't need a separate validation seam).
  /// No-op when the id is gone (mirrors `remove`) so a double-tap or
  /// stale UI reference can't crash the notifier.
  void update(String id, {String? displayName}) {
    final ClockLocation? existing = state.findById(id);
    if (existing == null) return;
    final ClockLocation next = existing.copyWith(
      displayName: displayName ?? existing.displayName,
    );
    state = state.update(next);
    unawaited(ref.read(clockLocationRepositoryProvider).upsert(next));
  }

  /// Test seam: lets unit tests inject a deterministic id sequence.
  /// Must be called before the first mutation; matches the
  /// `PresetCollectionNotifier.debugSetIdGenerator` shape.
  // ignore: use_setters_to_change_properties
  void debugSetIdGenerator(String Function() idGen) {
    _idGenerator = idGen;
  }

  String _newId() => _idGenerator?.call() ?? const Uuid().v4();

  /// Best-effort display name for the auto-detected timezone:
  ///   1. If `timezoneId` is in [TimezoneCatalog.presets], use the
  ///      curated `displayName` (e.g. `Asia/Tokyo` → `Tokyo`).
  ///   2. Otherwise take the last `/`-segment and replace `_` with
  ///      space (e.g. `America/Sao_Paulo` → `Sao Paulo`).
  ///   3. Truncate to 30 chars to honour the entity's invariant.
  String _deriveDisplayName(String timezoneId) {
    for (final TimezoneCatalogEntry e in TimezoneCatalog.presets) {
      if (e.timezoneId == timezoneId) return e.displayName;
    }
    final String tail = timezoneId.split('/').last.replaceAll('_', ' ');
    if (tail.length > 30) return tail.substring(0, 30);
    return tail;
  }
}
