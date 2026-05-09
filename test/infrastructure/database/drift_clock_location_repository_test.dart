import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/clock/clock_location.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/drift_clock_location_repository.dart';

void main() {
  late AppDatabase db;
  late DriftClockLocationRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftClockLocationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  ClockLocation entity({
    String id = 'c1',
    String displayName = 'Tokyo',
    String timezoneId = 'Asia/Tokyo',
    bool isCurrentLocation = false,
    int displayOrder = 0,
    DateTime? createdAt,
  }) {
    return ClockLocation(
      id: id,
      displayName: displayName,
      timezoneId: timezoneId,
      isCurrentLocation: isCurrentLocation,
      displayOrder: displayOrder,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 9),
    );
  }

  test('findAll: 空 DB は空リストを返す (seed なし)', () async {
    expect(await repo.findAll(), isEmpty);
  });

  test('upsert + findAll: 1 件挿入できる', () async {
    final ClockLocation input = entity();
    await repo.upsert(input);
    final List<ClockLocation> all = await repo.findAll();
    expect(all, <ClockLocation>[input]);
  });

  test('findAll: displayOrder 昇順で返る (挿入順と無関係)', () async {
    // 意図的に挿入順を逆にして、order by が効くことを検証する。
    final ClockLocation a = entity(id: 'a', displayOrder: 2);
    final ClockLocation b = entity(id: 'b', displayOrder: 0);
    final ClockLocation c = entity(id: 'c', displayOrder: 1);
    await repo.upsert(a);
    await repo.upsert(b);
    await repo.upsert(c);
    final List<ClockLocation> all = await repo.findAll();
    expect(all.map((ClockLocation e) => e.id).toList(), <String>[
      'b',
      'c',
      'a',
    ]);
  });

  test('findById: 存在しない id は null', () async {
    expect(await repo.findById('missing'), isNull);
  });

  test('findById: 既存 id を返す', () async {
    final ClockLocation input = entity(id: 'target');
    await repo.upsert(input);
    expect(await repo.findById('target'), input);
  });

  test('upsert は同 id で上書き (update セマンティクス)', () async {
    await repo.upsert(entity(id: 'c1', displayName: 'before'));
    await repo.upsert(entity(id: 'c1', displayName: 'after'));
    final ClockLocation? fetched = await repo.findById('c1');
    expect(fetched?.displayName, 'after');
    final List<ClockLocation> all = await repo.findAll();
    expect(all.length, 1);
  });

  test('delete: 既存 id を削除', () async {
    await repo.upsert(entity(id: 'c1'));
    await repo.delete('c1');
    expect(await repo.findById('c1'), isNull);
  });

  test('delete: 存在しない id は no-op', () async {
    // 例外なしで通ること。
    await repo.delete('missing');
    expect(await repo.findAll(), isEmpty);
  });

  test('isCurrentLocation=true が永続化を経て復元される', () async {
    final ClockLocation input = entity(id: 'home', isCurrentLocation: true);
    await repo.upsert(input);
    final ClockLocation? restored = await repo.findById('home');
    expect(restored, isNotNull);
    expect(restored!.isCurrentLocation, isTrue);
  });

  group('replaceAll', () {
    test('既存全消し → 新規 batch insert', () async {
      await repo.upsert(entity(id: 'old1', displayOrder: 0));
      await repo.upsert(entity(id: 'old2', displayOrder: 1));
      expect((await repo.findAll()).length, 2);

      final List<ClockLocation> replacement = <ClockLocation>[
        entity(
          id: 'r1',
          displayName: 'NY',
          timezoneId: 'America/New_York',
          displayOrder: 0,
        ),
        entity(
          id: 'r2',
          displayName: 'London',
          timezoneId: 'Europe/London',
          displayOrder: 1,
        ),
      ];
      await repo.replaceAll(replacement);
      final List<ClockLocation> after = await repo.findAll();
      expect(after.map((ClockLocation e) => e.id).toList(), <String>[
        'r1',
        'r2',
      ]);
    });

    test('空 list で全消し', () async {
      await repo.upsert(entity(id: 'a'));
      await repo.upsert(entity(id: 'b'));
      await repo.replaceAll(<ClockLocation>[]);
      expect(await repo.findAll(), isEmpty);
    });
  });

  test(
    'onCreate (fresh install, schemaVersion=4) で clock_locations テーブルが作成される',
    () async {
      // 本テストは fresh install 経路 (Migrator.createAll) のスモーク。
      // テーブルへの insert/select が例外なく成立すれば onCreate は
      // スキーマを通せている。
      // v3 → v4 の onUpgrade 経路は SchemaPerVersion test (drift verify
      // ヘルパ) が必要となるため導入見送り (既存の v1→v2 / v2→v3
      // upgrade テストも未導入で一貫)。
      await repo.upsert(entity(id: 'smoke'));
      final ClockLocation? row = await repo.findById('smoke');
      expect(row, isNotNull);
    },
  );
}
