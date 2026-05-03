import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/alarm/alarm_entity.dart';
import 'package:timer_utility/domain/alarm/alarm_repeat.dart';
import 'package:timer_utility/domain/alarm/day_of_week.dart';
import 'package:timer_utility/domain/alarm/time_of_day_value.dart';
import 'package:timer_utility/infrastructure/database/app_database.dart';
import 'package:timer_utility/infrastructure/database/mappers/alarm_mapper.dart';

void main() {
  const mapper = AlarmMapper();

  AlarmEntity sample({
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

  group('AlarmMapper.daysToBitmask / bitmaskToDays', () {
    test('Mon → 1, Sun → 64', () {
      expect(AlarmMapper.daysToBitmask(<DayOfWeek>{DayOfWeek.monday}), 1);
      expect(AlarmMapper.daysToBitmask(<DayOfWeek>{DayOfWeek.sunday}), 64);
    });

    test('Mon|Wed|Fri → 0b0010101 = 21', () {
      final int mask = AlarmMapper.daysToBitmask(<DayOfWeek>{
        DayOfWeek.monday,
        DayOfWeek.wednesday,
        DayOfWeek.friday,
      });
      expect(mask, 1 | 4 | 16);
    });

    test('全曜日 → 0b1111111 = 127', () {
      expect(AlarmMapper.daysToBitmask(DayOfWeek.values.toSet()), 127);
    });

    test('bitmaskToDays は daysToBitmask の逆関数', () {
      for (final Set<DayOfWeek> input in <Set<DayOfWeek>>[
        <DayOfWeek>{DayOfWeek.monday},
        <DayOfWeek>{DayOfWeek.tuesday, DayOfWeek.thursday, DayOfWeek.saturday},
        DayOfWeek.values.toSet(),
      ]) {
        final int mask = AlarmMapper.daysToBitmask(input);
        expect(AlarmMapper.bitmaskToDays(mask), input);
      }
    });

    test('上位ビットの不正値は無視される (Forward compat)', () {
      // 1 << 7 (= 128) 以上は曜日に対応しないので無視される
      final Set<DayOfWeek> result = AlarmMapper.bitmaskToDays(0xFF);
      expect(result, DayOfWeek.values.toSet());
    });
  });

  group('AlarmMapper round-trip (Companion / Row 経由)', () {
    test('once + 全フィールド埋め', () {
      final input = sample(
        id: 'a-once',
        notificationId: 12345,
        label: 'Wake up',
        targetTime: const TimeOfDayValue.unsafe(hour: 6, minute: 30),
        repeat: const AlarmRepeatOnce(),
        snoozeMinutes: 10,
        enabled: false,
        soundId: 'gentle',
        createdAt: DateTime.utc(2026, 5, 3, 10, 0),
      );
      final AlarmRow row = mapper.toRow(input);
      final AlarmEntity restored = mapper.toEntity(row);
      expect(restored, input);
    });

    test('weekly + 複数曜日', () {
      final input = sample(
        repeat: AlarmRepeatWeekly.create(<DayOfWeek>{
          DayOfWeek.monday,
          DayOfWeek.wednesday,
          DayOfWeek.friday,
        }),
      );
      final AlarmEntity restored = mapper.toEntity(mapper.toRow(input));
      expect(restored, input);
    });

    test('weekly + 全曜日', () {
      final input = sample(
        repeat: AlarmRepeatWeekly.create(DayOfWeek.values.toSet()),
      );
      expect(mapper.toEntity(mapper.toRow(input)), input);
    });

    test('soundId == null は null のまま round-trip', () {
      final input = sample();
      final AlarmEntity restored = mapper.toEntity(mapper.toRow(input));
      expect(restored.soundId, isNull);
    });

    test('targetTime 00:00 と 23:59 の境界', () {
      for (final TimeOfDayValue t in <TimeOfDayValue>[
        const TimeOfDayValue.unsafe(hour: 0, minute: 0),
        const TimeOfDayValue.unsafe(hour: 23, minute: 59),
      ]) {
        final input = sample(targetTime: t);
        expect(mapper.toEntity(mapper.toRow(input)).targetTime, t);
      }
    });

    test('createdAt は UTC で保存・復元される', () {
      final DateTime jst = DateTime(2026, 5, 3, 7, 30);
      final input = sample(createdAt: jst);
      final AlarmEntity restored = mapper.toEntity(mapper.toRow(input));
      // 比較は UTC ベースで一致すれば OK。toIso8601String の値を見る。
      expect(restored.createdAt.toUtc(), jst.toUtc());
    });
  });

  group('AlarmMapper defensive decode', () {
    test('repeatKind が "weekly" だが bitmask=0 → AlarmRepeatOnce にフォールバック', () {
      const row = AlarmRow(
        id: 'corrupt',
        notificationId: 1,
        label: '',
        targetTimeMinutes: 0,
        repeatKind: 'weekly',
        repeatDaysBitmask: 0,
        snoozeMinutes: 5,
        enabled: true,
        soundId: null,
        createdAtUtcMs: 0,
      );
      expect(mapper.toEntity(row).repeat, const AlarmRepeatOnce());
    });

    test('未知の repeatKind は AlarmRepeatOnce にフォールバック', () {
      const row = AlarmRow(
        id: 'unknown-kind',
        notificationId: 1,
        label: '',
        targetTimeMinutes: 0,
        repeatKind: 'monthly',
        repeatDaysBitmask: 0,
        snoozeMinutes: 5,
        enabled: true,
        soundId: null,
        createdAtUtcMs: 0,
      );
      expect(mapper.toEntity(row).repeat, const AlarmRepeatOnce());
    });
  });
}
