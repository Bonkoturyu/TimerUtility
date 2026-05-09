import 'package:drift/drift.dart' show Value;

import '../../../domain/clock/clock_location.dart';
import '../app_database.dart';

/// [ClockLocation] (domain) と [ClockLocationRow] (Drift) の相互変換ブリッジ。
///
/// 永続化のエンコード規約 (Timer/Preset/Alarm と同一):
///   - `DateTime` → epoch-ms UTC。
///   - `bool` (`isCurrentLocation`) → BoolColumn にそのまま (SQLite は
///     INTEGER 0/1)。
///   - 他は scalar をそのまま転写。null になりうる列はないため
///     `Value<...?>(null)` の defensive 取り回しは不要。
class ClockLocationMapper {
  const ClockLocationMapper();

  ClockLocationRow toRow(ClockLocation entity) => ClockLocationRow(
    id: entity.id,
    displayName: entity.displayName,
    timezoneId: entity.timezoneId,
    isCurrentLocation: entity.isCurrentLocation,
    displayOrder: entity.displayOrder,
    createdAtUtcMs: entity.createdAt.toUtc().millisecondsSinceEpoch,
  );

  ClockLocationsCompanion toCompanion(ClockLocation entity) =>
      ClockLocationsCompanion(
        id: Value<String>(entity.id),
        displayName: Value<String>(entity.displayName),
        timezoneId: Value<String>(entity.timezoneId),
        isCurrentLocation: Value<bool>(entity.isCurrentLocation),
        displayOrder: Value<int>(entity.displayOrder),
        createdAtUtcMs: Value<int>(
          entity.createdAt.toUtc().millisecondsSinceEpoch,
        ),
      );

  ClockLocation toEntity(ClockLocationRow row) => ClockLocation(
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
