import 'package:drift/drift.dart' show Value;

import '../../../domain/alarm/alarm_entity.dart';
import '../../../domain/alarm/alarm_repeat.dart';
import '../../../domain/alarm/day_of_week.dart';
import '../../../domain/alarm/time_of_day_value.dart';
import '../app_database.dart';

/// [AlarmEntity] (domain) と [AlarmRow] (Drift) の相互変換ブリッジ。
///
/// 永続化のエンコード規約:
///   - `targetTime` → `targetTimeMinutes` (0..1439 分単位)
///   - `repeat` → 専用 2 列 `repeatKind` (text) + `repeatDaysBitmask` (int)。
///     * `AlarmRepeatOnce` → ('once', 0)
///     * `AlarmRepeatWeekly(days)` → ('weekly', daysBitmask(days))
///     ビットマスクは Mon=1<<0, Tue=1<<1, …, Sun=1<<6 (最大値 127)。
///   - `enabled` → BoolColumn にそのまま (SQLite では INTEGER 0/1)。
///   - `DateTime` → epoch-ms UTC (Timer/Preset と同じ規約)。
///   - 不明な `repeatKind` や bitmask=0 の weekly 行は `AlarmRepeatOnce` に
///     defensive fallback (Forward compat: 将来 repeat 種別が増えても
///     既存 DB が破損しないようにする)。
class AlarmMapper {
  const AlarmMapper();

  AlarmRow toRow(AlarmEntity entity) {
    final (String kind, int bitmask) = _encodeRepeat(entity.repeat);
    return AlarmRow(
      id: entity.id,
      notificationId: entity.notificationId,
      label: entity.label,
      targetTimeMinutes: entity.targetTime.toMinutesFromMidnight(),
      repeatKind: kind,
      repeatDaysBitmask: bitmask,
      snoozeMinutes: entity.snoozeMinutes,
      enabled: entity.enabled,
      soundId: entity.soundId,
      createdAtUtcMs: entity.createdAt.toUtc().millisecondsSinceEpoch,
    );
  }

  AlarmsCompanion toCompanion(AlarmEntity entity) {
    final (String kind, int bitmask) = _encodeRepeat(entity.repeat);
    return AlarmsCompanion(
      id: Value<String>(entity.id),
      notificationId: Value<int>(entity.notificationId),
      label: Value<String>(entity.label),
      targetTimeMinutes: Value<int>(entity.targetTime.toMinutesFromMidnight()),
      repeatKind: Value<String>(kind),
      repeatDaysBitmask: Value<int>(bitmask),
      snoozeMinutes: Value<int>(entity.snoozeMinutes),
      enabled: Value<bool>(entity.enabled),
      soundId: Value<String?>(entity.soundId),
      createdAtUtcMs: Value<int>(
        entity.createdAt.toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  AlarmEntity toEntity(AlarmRow row) {
    return AlarmEntity(
      id: row.id,
      notificationId: row.notificationId,
      label: row.label,
      targetTime: TimeOfDayValue.fromMinutesFromMidnight(row.targetTimeMinutes),
      repeat: _decodeRepeat(row.repeatKind, row.repeatDaysBitmask),
      snoozeMinutes: row.snoozeMinutes,
      enabled: row.enabled,
      soundId: row.soundId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtUtcMs,
        isUtc: true,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // ビットマスク ⇔ Set<DayOfWeek>
  // ---------------------------------------------------------------------

  /// `Set<DayOfWeek>` をビットマスクに変換。
  /// Mon=1<<0, Tue=1<<1, …, Sun=1<<6 — `weekday - 1` シフト。
  static int daysToBitmask(Set<DayOfWeek> days) {
    int mask = 0;
    for (final DayOfWeek d in days) {
      mask |= 1 << (d.weekday - 1);
    }
    return mask;
  }

  /// ビットマスクから `Set<DayOfWeek>` を復元。
  /// 不正なビット (>1<<6) は無視する (Forward compat)。
  static Set<DayOfWeek> bitmaskToDays(int mask) {
    final Set<DayOfWeek> result = <DayOfWeek>{};
    for (final DayOfWeek d in DayOfWeek.values) {
      if ((mask & (1 << (d.weekday - 1))) != 0) {
        result.add(d);
      }
    }
    return result;
  }

  (String, int) _encodeRepeat(AlarmRepeat repeat) {
    return switch (repeat) {
      AlarmRepeatOnce() => ('once', 0),
      AlarmRepeatWeekly(days: final Set<DayOfWeek> days) => (
        'weekly',
        daysToBitmask(days),
      ),
    };
  }

  AlarmRepeat _decodeRepeat(String kind, int bitmask) {
    switch (kind) {
      case 'weekly':
        final Set<DayOfWeek> days = bitmaskToDays(bitmask);
        // bitmask=0 だと `AlarmRepeatWeekly.create` が ArgumentError を
        // 投げる。DB 破損や将来の不整合に備えて defensive に once へ落とす。
        if (days.isEmpty) return const AlarmRepeatOnce();
        return AlarmRepeatWeekly.create(days);
      case 'once':
        return const AlarmRepeatOnce();
      default:
        // 不明な種別 (将来追加される予定の monthly 等) は once として扱う。
        // ユーザは UI から再保存すれば適切な値に上書きできる。
        return const AlarmRepeatOnce();
    }
  }
}
