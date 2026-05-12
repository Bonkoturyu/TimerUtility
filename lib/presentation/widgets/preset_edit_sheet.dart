import 'package:flutter/material.dart';

import '../../domain/timer/preset.dart';
import '../../l10n/app_localizations.dart';
import 'duration_picker.dart' show DurationPickerWheels, SoundDropdown;

/// Plain data result returned by the edit sheet on save. The notifier
/// caller turns this into either `create(...)` (when [editing] is
/// `null`) or `update(...)` (when [editing] is non-null).
class PresetEditResult {
  const PresetEditResult({
    required this.label,
    required this.duration,
    required this.soundId,
  });
  final String label;
  final Duration duration;
  final String? soundId;
}

/// Phase 9 add / edit sheet for a single preset. Shown via
/// `showModalBottomSheet<PresetEditResult>(... builder: PresetEditSheet)`.
///
/// `editing == null` → "Add" mode: empty initial values, "Add preset"
/// title, save creates a new entity. `editing != null` → "Edit"
/// mode: fields prefilled from the existing entity, "Edit preset"
/// title, save returns updated values.
///
/// [defaultSoundId] is consulted only in Add mode (when [editing] is
/// `null`). Edit mode always seeds the sound from the entity. The
/// caller resolves the default from `settingsNotifierProvider` so the
/// Phase 11 settings screen's "Default alarm sound" choice flows in
/// here without coupling the sheet to Riverpod.
class PresetEditSheet extends StatefulWidget {
  const PresetEditSheet({
    super.key,
    this.editing,
    required this.defaultSoundId,
  });

  final Preset? editing;
  final String defaultSoundId;

  @override
  State<PresetEditSheet> createState() => _PresetEditSheetState();
}

class _PresetEditSheetState extends State<PresetEditSheet> {
  late TextEditingController _labelController;
  late Duration _duration;
  late String _soundId;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.editing?.label ?? '');
    _duration = widget.editing?.duration ?? const Duration(minutes: 1);
    _soundId = widget.editing?.soundId ?? widget.defaultSoundId;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool get _saveEnabled =>
      _duration > Duration.zero &&
      _duration <= const Duration(hours: 99) &&
      _labelController.text.length <= 50;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool isEdit = widget.editing != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Text(
                isEdit ? l.presetEditTitleEdit : l.presetEditTitleNew,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('preset_edit_label'),
              controller: _labelController,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: l.presetEditLabelHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.presetEditDurationLabel),
            ),
            DurationPickerWheels(
              initial: _duration,
              onChanged: (Duration v) => setState(() => _duration = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text(l.presetEditSoundLabel),
                const SizedBox(width: 12),
                Expanded(
                  child: SoundDropdown(
                    key: const Key('preset_edit_sound'),
                    value: _soundId,
                    onChanged: (String v) => setState(() => _soundId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TextButton(
                  key: const Key('preset_edit_cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.presetEditCancel),
                ),
                FilledButton(
                  key: const Key('preset_edit_save'),
                  onPressed: _saveEnabled
                      ? () => Navigator.of(context).pop(
                          PresetEditResult(
                            label: _labelController.text,
                            duration: _duration,
                            soundId: _soundId,
                          ),
                        )
                      : null,
                  child: Text(l.presetEditSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
