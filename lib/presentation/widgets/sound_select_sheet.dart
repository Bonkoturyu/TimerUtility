import 'package:flutter/material.dart';

import '../../domain/timer/alarm_sound.dart';
import '../../domain/timer/alarm_sound_catalog.dart';
import '../../l10n/app_localizations.dart';
import 'duration_picker.dart' show soundDisplayName;

/// Bottom sheet for picking an alarm sound id. Returns the chosen id
/// via `Navigator.pop`, or `null` when dismissed.
///
/// Uses a `ListView` of `RadioListTile` so it scales smoothly as the
/// catalog grows (Phase 11 will likely add more sounds). The `null`
/// caller-supplied initial value selects the catalog's first entry.
class SoundSelectSheet extends StatelessWidget {
  const SoundSelectSheet({super.key, required this.initialSoundId});

  final String? initialSoundId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    const List<AlarmSound> catalog = AlarmSoundCatalog.all;
    final String selected =
        initialSoundId != null &&
            catalog.any((AlarmSound s) => s.id == initialSoundId)
        ? initialSoundId!
        : catalog.first.id;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l.timerSoundSheetTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: catalog.length,
              itemBuilder: (BuildContext context, int index) {
                final AlarmSound s = catalog[index];
                final bool isSelected = s.id == selected;
                return ListTile(
                  key: Key('sound_select_${s.id}'),
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(soundDisplayName(l, s.id)),
                  onTap: () => Navigator.of(context).pop(s.id),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
