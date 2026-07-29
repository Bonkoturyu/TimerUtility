import 'package:drift/drift.dart' show Value;

import '../../../domain/sound/imported_sound.dart';
import '../../../domain/sound/imported_sound_format.dart';
import '../app_database.dart';

/// Maps Phase 13 imported sound metadata between Domain and Drift.
class ImportedSoundMapper {
  const ImportedSoundMapper();

  ImportedSoundsCompanion toCompanion(ImportedSound entity) =>
      ImportedSoundsCompanion(
        id: Value<String>(entity.id),
        displayName: Value<String>(entity.displayName),
        format: Value<String>(entity.format.name),
        byteLength: Value<int>(entity.byteLength),
        durationMs: Value<int>(entity.duration.inMilliseconds),
        contentHash: Value<String>(entity.contentHash),
        createdAtUtcMs: Value<int>(
          entity.createdAt.toUtc().millisecondsSinceEpoch,
        ),
      );

  ImportedSound toEntity(ImportedSoundRow row) => ImportedSound.create(
    id: row.id,
    displayName: row.displayName,
    format: ImportedSoundFormat.values.byName(row.format),
    byteLength: row.byteLength,
    duration: Duration(milliseconds: row.durationMs),
    contentHash: row.contentHash,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      row.createdAtUtcMs,
      isUtc: true,
    ),
  );
}
