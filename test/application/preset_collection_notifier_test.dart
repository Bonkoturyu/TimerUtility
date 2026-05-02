import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/clock_provider.dart';
import 'package:timer_utility/application/preset_collection_notifier.dart';
import 'package:timer_utility/application/preset_repository_provider.dart';
import 'package:timer_utility/domain/ports/preset_repository.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/domain/timer/preset_collection.dart';
import 'package:timer_utility/domain/timer/preset_exceptions.dart';
import 'package:timer_utility/domain/timer/preset_templates.dart';

class _InMemoryPresetRepo implements PresetRepository {
  final Map<String, Preset> store = <String, Preset>{};
  int replaceAllCalls = 0;

  @override
  Future<void> delete(String id) async {
    store.remove(id);
  }

  @override
  Future<List<Preset>> findAll() async => store.values.toList();

  @override
  Future<Preset?> findById(String id) async => store[id];

  @override
  Future<void> upsert(Preset entity) async {
    store[entity.id] = entity;
  }

  @override
  Future<void> replaceAll(List<Preset> entities) async {
    replaceAllCalls++;
    store.clear();
    for (final Preset p in entities) {
      store[p.id] = p;
    }
  }
}

({ProviderContainer container, _InMemoryPresetRepo repo}) makeContainer({
  Clock? clock,
  Map<String, Preset>? seeded,
}) {
  final repo = _InMemoryPresetRepo();
  if (seeded != null) {
    repo.store.addAll(seeded);
  }
  final c = ProviderContainer(
    overrides: <Override>[
      clockProvider.overrideWithValue(
        clock ?? Clock(() => DateTime.utc(2026, 5, 2, 12)),
      ),
      presetRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  return (container: c, repo: repo);
}

/// Pumps any pending microtask `_restoreFromRepository` queued in
/// `build()`. Callers wait on this before asserting state to make sure
/// the in-memory repo's seed has been loaded.
Future<void> settleRestore() => Future<void>.delayed(Duration.zero);

/// Deterministic id sequence for the notifier under test.
class _IdSequence {
  int _i = 0;
  String next() {
    final String id = 'p-${_i.toString().padLeft(2, '0')}';
    _i++;
    return id;
  }
}

void main() {
  group('PresetCollectionNotifier basic CRUD', () {
    test('build() starts empty before restore', () {
      final h = makeContainer();
      final state = h.container.read(presetCollectionNotifierProvider);
      expect(state.isEmpty, isTrue);
    });

    test('restore loads persisted presets into state', () async {
      final Preset seeded = Preset(
        id: 'r1',
        label: 'Coffee',
        duration: const Duration(minutes: 4),
        soundId: 'gentle',
        createdAt: DateTime.utc(2026, 5, 1),
      );
      final h = makeContainer(seeded: <String, Preset>{'r1': seeded});
      h.container.read(presetCollectionNotifierProvider);
      await settleRestore();
      final state = h.container.read(presetCollectionNotifierProvider);
      expect(state.size, 1);
      expect(state.findById('r1'), seeded);
    });

    test('create adds a preset with auto id and persists it', () async {
      final h = makeContainer();
      final notifier = h.container.read(
        presetCollectionNotifierProvider.notifier,
      );
      notifier.debugSetIdGenerator(_IdSequence().next);
      // Drive build()'s microtask through.
      h.container.read(presetCollectionNotifierProvider);
      await settleRestore();

      final Preset created = notifier.create(
        label: 'Tea',
        duration: const Duration(minutes: 3),
        soundId: 'gentle',
      );
      expect(created.id, 'p-00');
      expect(created.label, 'Tea');
      final state = h.container.read(presetCollectionNotifierProvider);
      expect(state.size, 1);
      // Persistence is fire-and-forget; let the microtask resolve.
      await settleRestore();
      expect(h.repo.store.containsKey('p-00'), isTrue);
    });

    test('create throws when at max capacity', () async {
      final Map<String, Preset> seeded = <String, Preset>{
        for (int i = 0; i < 10; i++)
          'p$i': Preset(
            id: 'p$i',
            label: 'l$i',
            duration: const Duration(minutes: 1),
            soundId: null,
            createdAt: DateTime.utc(2026, 5, 1),
          ),
      };
      final h = makeContainer(seeded: seeded);
      h.container.read(presetCollectionNotifierProvider);
      await settleRestore();
      final notifier = h.container.read(
        presetCollectionNotifierProvider.notifier,
      );
      expect(
        () => notifier.create(
          label: 'overflow',
          duration: const Duration(minutes: 1),
        ),
        throwsA(isA<MaxPresetCountExceededException>()),
      );
    });

    test('update changes only the requested fields', () async {
      final Preset orig = Preset(
        id: 'a',
        label: 'orig',
        duration: const Duration(minutes: 5),
        soundId: 'default',
        createdAt: DateTime.utc(2026, 5, 1),
      );
      final h = makeContainer(seeded: <String, Preset>{'a': orig});
      h.container.read(presetCollectionNotifierProvider);
      await settleRestore();
      final notifier = h.container.read(
        presetCollectionNotifierProvider.notifier,
      );
      notifier.update('a', label: 'renamed');
      final updated = h.container
          .read(presetCollectionNotifierProvider)
          .findById('a')!;
      expect(updated.label, 'renamed');
      expect(updated.duration, const Duration(minutes: 5));
      expect(updated.soundId, 'default');
    });

    test('update can clear soundId by passing explicit null', () async {
      final Preset orig = Preset(
        id: 'a',
        label: 'orig',
        duration: const Duration(minutes: 5),
        soundId: 'gentle',
        createdAt: DateTime.utc(2026, 5, 1),
      );
      final h = makeContainer(seeded: <String, Preset>{'a': orig});
      h.container.read(presetCollectionNotifierProvider);
      await settleRestore();
      h.container
          .read(presetCollectionNotifierProvider.notifier)
          .update('a', soundId: null);
      final updated = h.container
          .read(presetCollectionNotifierProvider)
          .findById('a')!;
      expect(updated.soundId, isNull);
    });

    test('delete removes the preset and is a no-op for missing id', () async {
      final Preset orig = Preset(
        id: 'a',
        label: 'l',
        duration: const Duration(minutes: 1),
        soundId: null,
        createdAt: DateTime.utc(2026, 5, 1),
      );
      final h = makeContainer(seeded: <String, Preset>{'a': orig});
      h.container.read(presetCollectionNotifierProvider);
      await settleRestore();
      final notifier = h.container.read(
        presetCollectionNotifierProvider.notifier,
      );
      notifier.delete('a');
      await settleRestore();
      expect(
        h.container.read(presetCollectionNotifierProvider).findById('a'),
        isNull,
      );
      expect(h.repo.store.containsKey('a'), isFalse);
      // Idempotent on missing id.
      notifier.delete('ghost');
    });
  });

  group('PresetCollectionNotifier replaceFromTemplate', () {
    test('overwrite replaces existing presets with the profile', () async {
      final Map<String, Preset> seeded = <String, Preset>{
        'old1': Preset(
          id: 'old1',
          label: 'old',
          duration: const Duration(minutes: 11),
          soundId: null,
          createdAt: DateTime.utc(2026, 5, 1),
        ),
      };
      final h = makeContainer(seeded: seeded);
      h.container.read(presetCollectionNotifierProvider);
      await settleRestore();
      final notifier = h.container.read(
        presetCollectionNotifierProvider.notifier,
      );
      notifier.debugSetIdGenerator(_IdSequence().next);
      final result = await notifier.replaceFromTemplate(
        'cooking',
        mode: ReplaceTemplateMode.overwrite,
      );
      expect(result.discardedCount, 0);
      final state = h.container.read(presetCollectionNotifierProvider);
      expect(state.size, 6);
      // All durations should match the cooking profile.
      final List<Duration> got = state.all.map((p) => p.duration).toList();
      final List<Duration> want = PresetTemplates.cooking.templates
          .map((t) => t.duration)
          .toList();
      expect(got, want);
      // Repository was atomically replaced.
      expect(h.repo.replaceAllCalls, 1);
      expect(h.repo.store.containsKey('old1'), isFalse);
    });

    test('append fits remaining slots and reports discarded count', () async {
      // Pre-seed 7 presets so only 3 slots remain (cap=10). The cooking
      // profile has 6 entries → 3 fit, 3 are discarded.
      final Map<String, Preset> seeded = <String, Preset>{
        for (int i = 0; i < 7; i++)
          'e$i': Preset(
            id: 'e$i',
            label: 'l$i',
            duration: const Duration(minutes: 1),
            soundId: null,
            createdAt: DateTime.utc(2026, 5, 1),
          ),
      };
      final h = makeContainer(seeded: seeded);
      h.container.read(presetCollectionNotifierProvider);
      await settleRestore();
      final notifier = h.container.read(
        presetCollectionNotifierProvider.notifier,
      );
      notifier.debugSetIdGenerator(_IdSequence().next);
      final result = await notifier.replaceFromTemplate(
        'cooking',
        mode: ReplaceTemplateMode.append,
      );
      expect(result.discardedCount, 3);
      expect(
        h.container.read(presetCollectionNotifierProvider).size,
        PresetCollection.maxSize,
      );
    });

    test('append onto an empty collection adds the full profile', () async {
      final h = makeContainer();
      h.container.read(presetCollectionNotifierProvider);
      await settleRestore();
      final notifier = h.container.read(
        presetCollectionNotifierProvider.notifier,
      );
      notifier.debugSetIdGenerator(_IdSequence().next);
      final result = await notifier.replaceFromTemplate(
        'pomodoro',
        mode: ReplaceTemplateMode.append,
      );
      expect(result.discardedCount, 0);
      expect(h.container.read(presetCollectionNotifierProvider).size, 6);
    });

    test('throws ArgumentError for unknown profile id', () async {
      final h = makeContainer();
      h.container.read(presetCollectionNotifierProvider);
      await settleRestore();
      final notifier = h.container.read(
        presetCollectionNotifierProvider.notifier,
      );
      expect(
        () => notifier.replaceFromTemplate(
          'unknown',
          mode: ReplaceTemplateMode.overwrite,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
