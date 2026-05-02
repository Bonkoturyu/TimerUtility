import 'package:drift/drift.dart' show Value;

import '../../../domain/timer/preset.dart';
import '../app_database.dart';

/// Bridges [Preset] (domain) and [PresetRow] (Drift) representations.
///
/// Encoding decisions mirror `TimerMapper`:
///   - `DateTime` → epoch ms in UTC.
///   - `Duration` → ms.
///   - `null` Optional fields stay `null` end-to-end.
///
/// Unlike `TimerMapper` there is no enum to defensively decode — Preset
/// has no status field.
class PresetMapper {
  const PresetMapper();

  PresetRow toRow(Preset entity) => PresetRow(
    id: entity.id,
    label: entity.label,
    durationMs: entity.duration.inMilliseconds,
    soundId: entity.soundId,
    createdAtUtcMs: entity.createdAt.toUtc().millisecondsSinceEpoch,
  );

  PresetsCompanion toCompanion(Preset entity) => PresetsCompanion(
    id: Value<String>(entity.id),
    label: Value<String>(entity.label),
    durationMs: Value<int>(entity.duration.inMilliseconds),
    soundId: Value<String?>(entity.soundId),
    createdAtUtcMs: Value<int>(entity.createdAt.toUtc().millisecondsSinceEpoch),
  );

  Preset toEntity(PresetRow row) => Preset(
    id: row.id,
    label: row.label,
    duration: Duration(milliseconds: row.durationMs),
    soundId: row.soundId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtUtcMs,
      isUtc: true,
    ),
  );
}
