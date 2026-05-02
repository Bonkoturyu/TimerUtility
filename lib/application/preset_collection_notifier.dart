import 'dart:async';

import 'package:clock/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../domain/timer/preset.dart';
import '../domain/timer/preset_collection.dart';
import '../domain/timer/preset_exceptions.dart';
import '../domain/timer/preset_service.dart';
import '../domain/timer/preset_templates.dart';
import 'clock_provider.dart';
import 'preset_repository_provider.dart';

part 'preset_collection_notifier.g.dart';

/// Modes for `replaceFromTemplate`.
///
///   - [overwrite]: drop every existing preset, then insert the
///     template's 6 entries.
///   - [append]: keep existing presets and append the template's
///     entries up to the collection's `maxSize` cap. Anything past the
///     cap is silently dropped; the count is reported back to the
///     caller so the UI can surface a SnackBar.
enum ReplaceTemplateMode { overwrite, append }

/// Result of a `replaceFromTemplate(append)` call: how many entries
/// from the template were skipped because they would have pushed the
/// collection past `PresetCollection.maxSize`. Always 0 for the
/// `overwrite` mode (which clears existing entries first).
class ReplaceTemplateResult {
  const ReplaceTemplateResult({required this.discardedCount});
  final int discardedCount;
}

/// Phase 9 single source of truth for every saved preset.
///
/// Mirrors `TimerCollectionNotifier`:
///   - State = immutable aggregate ([PresetCollection]).
///   - Mutations: validate via [PresetService], update [state],
///     persist via [PresetRepository], all in one go.
///   - Restore on build: asynchronously load the persisted collection
///     so the UI can render an empty list while the DB call resolves.
///
/// `replaceFromTemplate` is unique to this notifier: it implements the
/// "Replace from template" UX. The two supported modes are described
/// on [ReplaceTemplateMode].
@Riverpod(keepAlive: true)
class PresetCollectionNotifier extends _$PresetCollectionNotifier {
  PresetService? _service;
  String Function()? _idGenerator;

  @override
  PresetCollection build() {
    Future<void>.microtask(_restoreFromRepository);
    return PresetCollection.empty();
  }

  Future<void> _restoreFromRepository() async {
    final List<Preset> persisted = await ref
        .read(presetRepositoryProvider)
        .findAll();
    if (persisted.isEmpty) {
      // Migration's onCreate / onUpgrade should have seeded the
      // default profile, but we tolerate an empty DB (e.g. user
      // wiped via "Replace from template" → empty path) and just
      // keep the empty collection.
      return;
    }
    state = PresetCollection.fromList(persisted);
  }

  /// Add a brand-new preset. Returns the created entity so callers
  /// can keep working with it (selection state, navigation, etc.).
  ///
  /// Throws [MaxPresetCountExceededException] when the collection is
  /// already full (10 entries). Caller must surface as a SnackBar.
  Preset create({
    required String label,
    required Duration duration,
    String? soundId,
  }) {
    final Preset created = _serviceInstance().create(
      label: label,
      duration: duration,
      soundId: soundId,
    );
    state = state.add(created);
    _persist(created);
    return created;
  }

  /// Replace an existing preset's mutable fields. Pass `null` for
  /// `soundId` to clear the override; omit a parameter to keep the
  /// existing value (matches `PresetService.update`).
  void update(
    String id, {
    String? label,
    Duration? duration,
    Object? soundId = _kSentinel,
  }) {
    final Preset existing = _require(id);
    final Preset next = _serviceInstance().update(
      existing,
      label: label,
      duration: duration,
      soundId: soundId,
    );
    state = state.update(next);
    _persist(next);
  }

  /// Remove a preset by id. No-op (gracefully) if absent so callers
  /// don't have to guard against double-tap races.
  void delete(String id) {
    final Preset? existing = state.findById(id);
    if (existing == null) return;
    state = state.remove(id);
    unawaited(ref.read(presetRepositoryProvider).delete(id));
  }

  /// Apply a profile from `PresetTemplates`. See [ReplaceTemplateMode]
  /// for the two supported modes.
  ///
  /// Throws [ArgumentError] when [profileId] doesn't match a known
  /// profile — the UI only ever passes ids from the curated list, so
  /// this is a programmer-error path, not a user-facing one.
  Future<ReplaceTemplateResult> replaceFromTemplate(
    String profileId, {
    required ReplaceTemplateMode mode,
  }) async {
    final PresetProfile? profile = PresetTemplates.findById(profileId);
    if (profile == null) {
      throw ArgumentError.value(
        profileId,
        'profileId',
        'unknown preset profile id',
      );
    }
    final PresetService service = _serviceInstance();

    switch (mode) {
      case ReplaceTemplateMode.overwrite:
        final List<Preset> next = profile.templates
            .map(
              (PresetTemplate t) => service.create(
                label: t.label,
                duration: t.duration,
                soundId: t.soundId,
              ),
            )
            .toList(growable: false);
        state = PresetCollection.fromList(next);
        await ref.read(presetRepositoryProvider).replaceAll(next);
        return const ReplaceTemplateResult(discardedCount: 0);
      case ReplaceTemplateMode.append:
        final int slots = PresetCollection.maxSize - state.size;
        final List<PresetTemplate> toAdd = profile.templates
            .take(slots < 0 ? 0 : slots)
            .toList(growable: false);
        final int discarded = profile.templates.length - toAdd.length;
        for (final PresetTemplate t in toAdd) {
          final Preset created = service.create(
            label: t.label,
            duration: t.duration,
            soundId: t.soundId,
          );
          state = state.add(created);
          _persist(created);
        }
        return ReplaceTemplateResult(discardedCount: discarded);
    }
  }

  Preset _require(String id) {
    final Preset? entity = state.findById(id);
    if (entity == null) {
      throw PresetNotFoundException(id);
    }
    return entity;
  }

  /// Lazy because `ref.read(clockProvider)` is only available after
  /// `build()` runs; constructing the service eagerly there would
  /// rebind clock-injection on every Notifier rebuild.
  PresetService _serviceInstance() {
    final PresetService? existing = _service;
    if (existing != null) return existing;
    final Clock clock = ref.read(clockProvider);
    final String Function() idGen = _idGenerator ?? () => const Uuid().v4();
    final PresetService created = PresetService(
      clock: clock,
      idGenerator: idGen,
    );
    _service = created;
    return created;
  }

  /// Test seam: lets unit tests inject a deterministic id sequence
  /// (and any clock override comes from `clockProvider.overrideWith`).
  /// Must be called before the first mutation; the lazy service is
  /// memoised after first use.
  // ignore: use_setters_to_change_properties
  void debugSetIdGenerator(String Function() idGen) {
    _idGenerator = idGen;
    _service = null; // force rebuild on next mutation
  }

  void _persist(Preset entity) {
    unawaited(ref.read(presetRepositoryProvider).upsert(entity));
  }

  /// Sentinel that mirrors `PresetService.update`'s "omitted vs
  /// explicit null" trick so the same calling convention reaches all
  /// the way up from the UI to the domain service.
  static const Object _kSentinel = Object();
}
