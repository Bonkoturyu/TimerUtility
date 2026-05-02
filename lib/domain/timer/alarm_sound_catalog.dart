import 'alarm_sound.dart';

/// Static catalog of bundled alarm sounds.
///
/// Phase 5 ships three sounds (default / gentle / warning). The catalog
/// is the only authority on which sounds exist; persisted preferences
/// store [AlarmSound.id] strings and resolve back to sounds via
/// [findById]. If a stored id ever vanishes (asset removed in a future
/// release), callers should fall back to [defaultSound].
///
/// Display names live in `lib/l10n/app_*.arb` keyed as
/// `alarmSoundDefault` / `alarmSoundGentle` / `alarmSoundWarning`. The
/// presentation layer resolves them via `AppLocalizations` because the
/// domain layer is Pure Dart and may not depend on Flutter localization.
class AlarmSoundCatalog {
  const AlarmSoundCatalog();

  static const List<AlarmSound> all = <AlarmSound>[
    AlarmSound(id: 'default', assetPath: 'assets/sounds/alarm_default.mp3'),
    AlarmSound(id: 'gentle', assetPath: 'assets/sounds/alarm_gentle.mp3'),
    AlarmSound(id: 'warning', assetPath: 'assets/sounds/alarm_warning.mp3'),
  ];

  /// First entry of [all]. Used when a stored id can no longer be
  /// resolved or when no sound has been chosen yet.
  static AlarmSound get defaultSound => all.first;

  /// Returns the sound matching [id] or `null` if no such sound exists.
  static AlarmSound? findById(String id) {
    for (final AlarmSound s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
