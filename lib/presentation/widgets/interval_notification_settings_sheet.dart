import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Bottom-sheet editor for a timer's fixed-interval notification mode.
class IntervalNotificationSettingsSheet extends StatefulWidget {
  const IntervalNotificationSettingsSheet({
    super.key,
    required this.initialEnabled,
    required this.onChanged,
  });

  final bool initialEnabled;
  final ValueChanged<bool> onChanged;

  @override
  State<IntervalNotificationSettingsSheet> createState() =>
      _IntervalNotificationSettingsSheetState();
}

class _IntervalNotificationSettingsSheetState
    extends State<IntervalNotificationSettingsSheet> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l.timerIntervalNotificationLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(l.timerIntervalNotificationDescription),
            const SizedBox(height: 12),
            SwitchListTile(
              key: const Key('interval_notification_sheet_toggle'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.timerIntervalNotificationLabel),
              value: _enabled,
              onChanged: (bool value) {
                setState(() => _enabled = value);
                widget.onChanged(value);
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('interval_notification_sheet_close'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.commonClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
