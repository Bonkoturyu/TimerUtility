import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Result of [showPresetDeleteConfirmDialog]:
///
///   - `confirmed`: did the user tap Delete?
///   - `dontAskAgain`: did the user tick the "Don't ask again" box?
///     The caller persists this flag to `UserPreferences` and skips
///     the dialog on subsequent deletes when `true`.
class PresetDeleteConfirmResult {
  const PresetDeleteConfirmResult({
    required this.confirmed,
    required this.dontAskAgain,
  });
  final bool confirmed;
  final bool dontAskAgain;

  static const PresetDeleteConfirmResult cancelled = PresetDeleteConfirmResult(
    confirmed: false,
    dontAskAgain: false,
  );
}

/// Show the modal delete-confirm dialog. Returns
/// [PresetDeleteConfirmResult.cancelled] when dismissed by tapping
/// outside the dialog (treated as cancel).
Future<PresetDeleteConfirmResult> showPresetDeleteConfirmDialog(
  BuildContext context,
) async {
  final result = await showDialog<PresetDeleteConfirmResult>(
    context: context,
    builder: (BuildContext context) => const _PresetDeleteConfirmDialog(),
  );
  return result ?? PresetDeleteConfirmResult.cancelled;
}

class _PresetDeleteConfirmDialog extends StatefulWidget {
  const _PresetDeleteConfirmDialog();

  @override
  State<_PresetDeleteConfirmDialog> createState() =>
      _PresetDeleteConfirmDialogState();
}

class _PresetDeleteConfirmDialogState
    extends State<_PresetDeleteConfirmDialog> {
  bool _dontAskAgain = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.presetDeleteConfirmTitle),
      content: Row(
        children: <Widget>[
          Checkbox(
            key: const Key('preset_delete_dont_ask'),
            value: _dontAskAgain,
            onChanged: (bool? v) => setState(() => _dontAskAgain = v ?? false),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(l.presetDeleteConfirmDontAsk)),
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('preset_delete_cancel'),
          onPressed: () => Navigator.of(context).pop(
            PresetDeleteConfirmResult(
              confirmed: false,
              dontAskAgain: _dontAskAgain,
            ),
          ),
          child: Text(l.presetDeleteConfirmCancel),
        ),
        FilledButton(
          key: const Key('preset_delete_confirm'),
          onPressed: () => Navigator.of(context).pop(
            PresetDeleteConfirmResult(
              confirmed: true,
              dontAskAgain: _dontAskAgain,
            ),
          ),
          child: Text(l.presetDeleteConfirmDelete),
        ),
      ],
    );
  }
}
