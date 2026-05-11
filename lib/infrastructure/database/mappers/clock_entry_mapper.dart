import 'package:drift/drift.dart' show Value;

import '../../../domain/clock/clock_entry.dart';
import '../app_database.dart';

/// [ClockEntry] (domain) と [ClockEntryRow] (Drift) の相互変換ブリッジ。
///
/// 永続化のエンコード規約 (Timer/Preset/Alarm と同一):
///   - `DateTime` → epoch-ms UTC。
///   - `bool` (`isCurrentLocation`) → BoolColumn にそのまま (SQLite は
///     INTEGER 0/1)。
///   - 他は scalar をそのまま転写。null になりうる列はないため
///     `Value<...?>(null)` の defensive 取り回しは不要。
class ClockEntryMapper {
  const ClockEntryMapper();

  ClockEntryRow toRow(ClockEntry entity) => ClockEntryRow(
    id: entity.id,
    displayName: entity.displayName,
    timezoneId: entity.timezoneId,
    isCurrentLocation: entity.isCurrentLocation,
    displayOrder: entity.displayOrder,
    createdAtUtcMs: entity.createdAt.toUtc().millisecondsSinceEpoch,
  );

  ClockEntriesCompanion toCompanion(ClockEntry entity) => ClockEntriesCompanion(
    id: Value<String>(entity.id),
    displayName: Value<String>(entity.displayName),
    timezoneId: Value<String>(entity.timezoneId),
    isCurrentLocation: Value<bool>(entity.isCurrentLocation),
    displayOrder: Value<int>(entity.displayOrder),
    createdAtUtcMs: Value<int>(entity.createdAt.toUtc().millisecondsSinceEpoch),
  );

  ClockEntry toEntity(ClockEntryRow row) => ClockEntry(
    id: row.id,
    displayName: row.displayName,
    timezoneId: row.timezoneId,
    isCurrentLocation: row.isCurrentLocation,
    displayOrder: row.displayOrder,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtUtcMs,
      isUtc: true,
    ),
  );
}
