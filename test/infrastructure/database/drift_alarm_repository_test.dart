import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/alarm/alarm_repeat.dart';
import 'package:timer_utility/domain/alarm/day_of_week.dart';
import 'package:timer_utility/domain/alarm/time_of_day_value.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/drift_alarm_repository.dart';

void main() {
  late AppDatabase db;
  late DriftAlarmRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftAlarmRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  AlarmEntity entity({
    String id = 'a1',
    int notificationId = 100,
    String label = '',
    TimeOfDayValue? targetTime,
    AlarmRepeat? repeat,
    int snoozeMinutes = 5,
    bool enabled = true,
    String? soundId,
    DateTime? createdAt,
  }) {
    return AlarmEntity(
      id: id,
      notificationId: notificationId,
      label: label,
      targetTime: targetTime ?? const TimeOfDayValue.unsafe(hour: 7, minute: 0),
      repeat: repeat ?? const AlarmRepeatOnce(),
      snoozeMinutes: snoozeMinutes,
      enabled: enabled,
      soundId: soundId,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 1),
    );
  }

  test('findAll: 空 DB は空リストを返す', () async {
    expect(await repo.findAll(), isEmpty);
  });

  test('upsert + findAll: 1 件挿入できる', () async {
    final input = entity();
    await repo.upsert(input);
    final List<AlarmEntity> all = await repo.findAll();
    expect(all, <AlarmEntity>[input]);
  });

  test('findById: 存在しない id は null', () async {
    expect(await repo.findById('missing'), isNull);
  });

  test('findById: 既存 id を返す', () async {
    final input = entity(id: 'target');
    await repo.upsert(input);
    expect(await repo.findById('target'), input);
  });

  test('upsert は同 id で上書き (update セマンティクス)', () async {
    await repo.upsert(entity(id: 'a1', label: 'before'));
    await repo.upsert(entity(id: 'a1', label: 'after'));
    final AlarmEntity? fetched = await repo.findById('a1');
    expect(fetched?.label, 'after');
    final List<AlarmEntity> all = await repo.findAll();
    expect(all.length, 1);
  });

  test('delete: 既存 id を削除', () async {
    await repo.upsert(entity(id: 'a1'));
    await repo.delete('a1');
    expect(await repo.findById('a1'), isNull);
  });

  test('delete: 存在しない id は no-op', () async {
    // 例外なしで通ること。
    await repo.delete('missing');
    expect(await repo.findAll(), isEmpty);
  });

  test('weekly + 複数曜日が永続化を経て復元される', () async {
    final input = entity(
      id: 'weekly-1',
      repeat: AlarmRepeatWeekly.create(<DayOfWeek>{
        DayOfWeek.monday,
        DayOfWeek.wednesday,
        DayOfWeek.friday,
      }),
    );
    await repo.upsert(input);
    final AlarmEntity? restored = await repo.findById('weekly-1');
    expect(restored, input);
  });

  test('複数件の upsert と findAll の order-independent 比較', () async {
    final a = entity(id: 'a');
    final b = entity(id: 'b');
    final c = entity(id: 'c');
    await repo.upsert(a);
    await repo.upsert(b);
    await repo.upsert(c);
    final List<AlarmEntity> all = await repo.findAll();
    expect(all.toSet(), <AlarmEntity>{a, b, c});
  });
}
