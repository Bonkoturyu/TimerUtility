import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/preset.dart';
import 'package:timer_utility/domain/timer/preset_templates.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/drift_preset_repository.dart';

void main() {
  late AppDatabase db;
  late DriftPresetRepository repo;

  /// Predictable id sequence so seed assertions can compare against
  /// known values rather than UUID strings that change every run.
  int idCounter = 0;
  String fakeId() {
    final String id = 'seed-${idCounter.toString().padLeft(2, '0')}';
    idCounter++;
    return id;
  }

  setUp(() {
    idCounter = 0;
    db = AppDatabase.forTesting(
      NativeDatabase.memory(),
      clock: Clock(() => DateTime.utc(2026, 5, 2, 12)),
      idGenerator: fakeId,
    );
    repo = DriftPresetRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Preset makeEntity({
    String id = 'p-custom',
    String label = 'Custom',
    Duration duration = const Duration(minutes: 7),
    String? soundId = 'urgent',
    DateTime? createdAt,
  }) {
    return Preset(
      id: id,
      label: label,
      duration: duration,
      soundId: soundId,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 2, 12),
    );
  }

  group('onCreate seed (fresh install)', () {
    test('findAll returns the 6 default profile presets', () async {
      final List<Preset> all = await repo.findAll();
      expect(all, hasLength(6));
      // All seeded entries match general profile durations & sound id.
      final List<Duration> seedDurations = all.map((p) => p.duration).toList();
      final List<Duration> expected = PresetTemplates.general.templates
          .map((t) => t.duration)
          .toList();
      expect(seedDurations, expected);
      for (final Preset p in all) {
        expect(p.soundId, 'default');
        expect(p.createdAt, DateTime.utc(2026, 5, 2, 12));
      }
    });

    test('seeded ids come from the injected idGenerator', () async {
      final List<Preset> all = await repo.findAll();
      // Order is insertion order; our fake generator yields seed-00..05.
      final List<String> ids = all.map((p) => p.id).toList();
      expect(ids, <String>[
        'seed-00',
        'seed-01',
        'seed-02',
        'seed-03',
        'seed-04',
        'seed-05',
      ]);
    });
  });

  group('CRUD on top of seeded data', () {
    test('upsert + findById returns the inserted entity', () async {
      final Preset e = makeEntity(id: 'manual');
      await repo.upsert(e);
      expect(await repo.findById('manual'), e);
    });

    test('upsert is idempotent on the same id (replaces row)', () async {
      final Preset first = makeEntity(id: 'm', label: 'before');
      await repo.upsert(first);
      final Preset updated = first.copyWith(label: 'after');
      await repo.upsert(updated);
      expect((await repo.findById('m'))!.label, 'after');
    });

    test('findById returns null for missing id', () async {
      expect(await repo.findById('does-not-exist'), isNull);
    });

    test('delete removes only the matching row', () async {
      await repo.upsert(makeEntity(id: 'a'));
      await repo.upsert(makeEntity(id: 'b'));
      await repo.delete('a');
      expect(await repo.findById('a'), isNull);
      expect(await repo.findById('b'), isNotNull);
    });

    test('delete is a no-op for missing id', () async {
      final int before = (await repo.findAll()).length;
      await repo.delete('ghost');
      expect((await repo.findAll()).length, before);
    });
  });

  group('replaceAll', () {
    test('overwrites the entire table atomically', () async {
      final List<Preset> seeded = await repo.findAll();
      expect(seeded, hasLength(6));

      final List<Preset> replacement = <Preset>[
        makeEntity(id: 'r1', label: 'r1'),
        makeEntity(id: 'r2', label: 'r2'),
      ];
      await repo.replaceAll(replacement);
      final List<Preset> after = await repo.findAll();
      expect(after.map((p) => p.id), <String>['r1', 'r2']);
    });

    test('replaceAll with an empty list clears the table', () async {
      await repo.replaceAll(<Preset>[]);
      expect(await repo.findAll(), isEmpty);
    });
  });
}
