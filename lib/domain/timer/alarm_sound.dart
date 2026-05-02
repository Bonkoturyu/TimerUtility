import 'package:freezed_annotation/freezed_annotation.dart';

part 'alarm_sound.freezed.dart';

/// Bundled alarm sound metadata.
///
/// Phase 5 ValueObject. Identified by [id] (stable across releases so
/// persisted preferences keep resolving) with [assetPath] for the audio
/// player. Use [AlarmSoundCatalog] to look up the available sounds rather
/// than constructing instances ad hoc.
///
/// Display names (e.g. "Default" / "デフォルト") are intentionally NOT
/// stored on this value object. The domain layer is Pure Dart and must
/// not depend on flutter localization. Resolve display names in the
/// presentation layer via `AppLocalizations` keyed off [id]
/// (`alarmSoundDefault` / `alarmSoundGentle` / `alarmSoundUrgent`).
///
/// Invariants enforced by the [AlarmSound.create] factory:
///   - `id` is non-empty
///   - `assetPath` is non-empty and starts with `assets/sounds/`
@freezed
class AlarmSound with _$AlarmSound {
  const factory AlarmSound({required String id, required String assetPath}) =
      _AlarmSound;

  factory AlarmSound.create({required String id, required String assetPath}) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (assetPath.isEmpty) {
      throw ArgumentError.value(assetPath, 'assetPath', 'must not be empty');
    }
    if (!assetPath.startsWith('assets/sounds/')) {
      throw ArgumentError.value(
        assetPath,
        'assetPath',
        'must start with "assets/sounds/"',
      );
    }
    return AlarmSound(id: id, assetPath: assetPath);
  }
}
