import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/imported_sound_management_controller.dart';
import '../../domain/sound/imported_sound.dart';
import '../../domain/timer/alarm_sound_catalog.dart';
import '../../l10n/app_localizations.dart';
import 'duration_picker.dart' show soundDisplayName;

/// Displays a bundled or user-imported alarm sound name.
///
/// Unknown ids fall back to the bundled default. This keeps stale references
/// from leaking their internal id into presentation while deletion recovery
/// replaces them in persistence.
class AlarmSoundName extends ConsumerWidget {
  const AlarmSoundName({super.key, required this.soundId});

  final String? soundId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<ImportedSound> importedSounds =
        ref.watch(importedSoundManagementControllerProvider).valueOrNull ??
        const <ImportedSound>[];
    final String id = soundId ?? AlarmSoundCatalog.defaultSound.id;

    if (AlarmSoundCatalog.findById(id) != null) {
      return Text(soundDisplayName(l, id));
    }
    for (final ImportedSound sound in importedSounds) {
      if (sound.id == id) return Text(sound.displayName);
    }
    return Text(soundDisplayName(l, AlarmSoundCatalog.defaultSound.id));
  }
}
