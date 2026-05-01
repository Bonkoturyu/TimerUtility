import 'package:drift/drift.dart' show Value;

import '../../../domain/timer/timer_entity.dart';
import '../../../domain/timer/timer_status.dart';
import '../app_database.dart';

/// Bridges [TimerEntity] (domain) and [TimerRow] (Drift) representations.
///
/// Encoding decisions:
///   - `DateTime` → epoch ms in UTC. Storing UTC keeps comparisons safe
///     across DST and locale changes.
///   - `Duration` → ms. Drift has no native Duration column.
///   - `TimerStatus` → enum name. The set of names is part of the DB
///     contract; renaming an enum value requires a migration.
///   - `null` Optional fields stay `null` end-to-end (no sentinels).
class TimerMapper {
  const TimerMapper();

  TimerRow toRow(TimerEntity entity) => TimerRow(
    id: entity.id,
    notificationId: entity.notificationId,
    label: entity.label,
    durationMs: entity.duration.inMilliseconds,
    endAtUtcMs: entity.endAt?.toUtc().millisecondsSinceEpoch,
    pausedRemainingMs: entity.pausedRemaining?.inMilliseconds,
    status: entity.status.name,
    soundId: entity.soundId,
    createdAtUtcMs: entity.createdAt.toUtc().millisecondsSinceEpoch,
  );

  TimersCompanion toCompanion(TimerEntity entity) => TimersCompanion(
    id: Value<String>(entity.id),
    notificationId: Value<int>(entity.notificationId),
    label: Value<String>(entity.label),
    durationMs: Value<int>(entity.duration.inMilliseconds),
    endAtUtcMs: Value<int?>(entity.endAt?.toUtc().millisecondsSinceEpoch),
    pausedRemainingMs: Value<int?>(entity.pausedRemaining?.inMilliseconds),
    status: Value<String>(entity.status.name),
    soundId: Value<String?>(entity.soundId),
    createdAtUtcMs: Value<int>(entity.createdAt.toUtc().millisecondsSinceEpoch),
  );

  TimerEntity toEntity(TimerRow row) => TimerEntity(
    id: row.id,
    notificationId: row.notificationId,
    label: row.label,
    duration: Duration(milliseconds: row.durationMs),
    endAt: row.endAtUtcMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.endAtUtcMs!, isUtc: true),
    pausedRemaining: row.pausedRemainingMs == null
        ? null
        : Duration(milliseconds: row.pausedRemainingMs!),
    status: _statusFromName(row.status),
    soundId: row.soundId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtUtcMs,
      isUtc: true,
    ),
  );

  /// Defensive parse: unknown statuses fall back to `cancelled` rather
  /// than throwing so a future enum addition can't brick a user's
  /// existing DB. The ringing screen shouldn't fire for cancelled, so
  /// the worst-case is a stale-looking entry the user can delete.
  TimerStatus _statusFromName(String name) {
    return TimerStatus.values.firstWhere(
      (TimerStatus s) => s.name == name,
      orElse: () => TimerStatus.cancelled,
    );
  }
}
