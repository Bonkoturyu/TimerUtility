import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/timer/timer_entity.dart';
import 'package:timer_utility/domain/timer/timer_status.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/drift_timer_repository.dart';

void main() {
  late AppDatabase db;
  late DriftTimerRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTimerRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  TimerEntity makeEntity({
    String id = 't1',
    int notificationId = 100,
    String label = 'Focus',
    Duration duration = const Duration(minutes: 5),
    DateTime? endAt,
    Duration? pausedRemaining,
    TimerStatus status = TimerStatus.idle,
    String? soundId,
    DateTime? createdAt,
  }) {
    return TimerEntity(
      id: id,
      notificationId: notificationId,
      label: label,
      duration: duration,
      endAt: endAt,
      pausedRemaining: pausedRemaining,
      status: status,
      soundId: soundId,
      createdAt: createdAt ?? DateTime.utc(2026, 5, 1, 9),
    );
  }

  test('findAll returns empty on a fresh DB', () async {
    expect(await repo.findAll(), isEmpty);
  });

  test('upsert + findAll returns a single inserted entity', () async {
    final TimerEntity e = makeEntity();
    await repo.upsert(e);
    final List<TimerEntity> all = await repo.findAll();
    expect(all, hasLength(1));
    expect(all.first, e);
  });

  test('upsert is idempotent on the same id (replaces row)', () async {
    final TimerEntity first = makeEntity(label: 'before');
    await repo.upsert(first);
    final TimerEntity updated = first.copyWith(
      label: 'after',
      status: TimerStatus.running,
      endAt: DateTime.utc(2026, 5, 1, 9, 5),
    );
    await repo.upsert(updated);
    final List<TimerEntity> all = await repo.findAll();
    expect(all, hasLength(1));
    expect(all.first.label, 'after');
    expect(all.first.status, TimerStatus.running);
  });

  test('findById returns null for missing id', () async {
    expect(await repo.findById('does-not-exist'), isNull);
  });

  test('findById returns the matching entity', () async {
    final TimerEntity a = makeEntity(id: 'a', label: 'A');
    final TimerEntity b = makeEntity(id: 'b', label: 'B');
    await repo.upsert(a);
    await repo.upsert(b);
    expect(await repo.findById('b'), b);
  });

  test('delete removes only the matching row', () async {
    final TimerEntity a = makeEntity(id: 'a');
    final TimerEntity b = makeEntity(id: 'b');
    await repo.upsert(a);
    await repo.upsert(b);
    await repo.delete('a');
    final List<TimerEntity> all = await repo.findAll();
    expect(all.map((TimerEntity e) => e.id), contains('b'));
    expect(all.map((TimerEntity e) => e.id), isNot(contains('a')));
  });

  test('delete is a no-op for missing id', () async {
    final TimerEntity a = makeEntity();
    await repo.upsert(a);
    await repo.delete('missing');
    expect(await repo.findAll(), hasLength(1));
  });

  test('multiple inserts persist across findAll', () async {
    for (int i = 0; i < 5; i++) {
      await repo.upsert(makeEntity(id: 't$i', notificationId: 100 + i));
    }
    expect(await repo.findAll(), hasLength(5));
  });
}
