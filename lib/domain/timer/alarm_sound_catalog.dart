import 'alarm_sound.dart';

/// Static catalog of bundled alarm sounds.
///
/// Phase 5 ships three sounds (default / gentle / urgent). The catalog
/// is the only authority on which sounds exist; persisted preferences
/// store [AlarmSound.id] strings and resolve back to sounds via
/// [findById]. If a stored id ever vanishes (asset removed in a future
/// release), callers should fall back to [defaultSound].
class AlarmSoundCatalog {
  const AlarmSoundCatalog();

  static const List<AlarmSound> all = <AlarmSound>[
    AlarmSound(
      id: 'default',
      displayName: 'デフォルト',
      assetPath: 'assets/sounds/alarm_default.mp3',
    ),
    AlarmSound(
      id: 'gentle',
      displayName: 'やさしい',
      assetPath: 'assets/sounds/alarm_gentle.mp3',
    ),
    AlarmSound(
      id: 'urgent',
      displayName: '急ぎ',
      assetPath: 'assets/sounds/alarm_urgent.mp3',
    ),
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
