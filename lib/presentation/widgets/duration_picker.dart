import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Modal-friendly hours/minutes/seconds wheel picker.
///
/// Returns the chosen [Duration] via `Navigator.pop` when the user confirms,
/// or `null` when cancelled. The Confirm button is disabled while the chosen
/// duration is zero or exceeds [maxDuration] (mirroring `TimerService`'s
/// construction-time invariants so that the caller can pass the result to
/// `TimerNotifier.create` without further validation).
class DurationPicker extends StatefulWidget {
  const DurationPicker({super.key, this.initial = const Duration(minutes: 1)});

  final Duration initial;

  /// Mirrors `TimerService.maxDuration` (99 hours). Kept as a local constant
  /// to avoid importing the domain layer from a presentation widget.
  static const Duration maxDuration = Duration(hours: 99);

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    // Negative is meaningless for a timer; clamp it to zero. We deliberately
    // do NOT clamp values above maxDuration, so a caller passing 99h+1s will
    // see those wheels intact and the Confirm button correctly disabled by
    // the same invariant TimerService enforces.
    final initial = widget.initial.isNegative ? Duration.zero : widget.initial;
    _hours = initial.inHours.clamp(0, 99);
    _minutes = initial.inMinutes.remainder(60);
    _seconds = initial.inSeconds.remainder(60);
  }

  Duration get _selected =>
      Duration(hours: _hours, minutes: _minutes, seconds: _seconds);

  bool get _confirmEnabled =>
      _selected > Duration.zero && _selected <= DurationPicker.maxDuration;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l.durationPickerTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: Row(
                children: <Widget>[
                  _column(
                    keyName: 'duration_picker_hours',
                    label: l.durationPickerHours,
                    max: 100,
                    initial: _hours,
                    onChanged: (v) => setState(() => _hours = v),
                  ),
                  _column(
                    keyName: 'duration_picker_minutes',
                    label: l.durationPickerMinutes,
                    max: 60,
                    initial: _minutes,
                    onChanged: (v) => setState(() => _minutes = v),
                  ),
                  _column(
                    keyName: 'duration_picker_seconds',
                    label: l.durationPickerSeconds,
                    max: 60,
                    initial: _seconds,
                    onChanged: (v) => setState(() => _seconds = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TextButton(
                  key: const Key('duration_picker_cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.durationPickerCancel),
                ),
                FilledButton(
                  key: const Key('duration_picker_confirm'),
                  onPressed: _confirmEnabled
                      ? () => Navigator.of(context).pop(_selected)
                      : null,
                  child: Text(l.durationPickerConfirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _column({
    required String keyName,
    required String label,
    required int max,
    required int initial,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(label),
          Expanded(
            child: CupertinoPicker(
              key: Key(keyName),
              itemExtent: 32,
              scrollController: FixedExtentScrollController(
                initialItem: initial,
              ),
              onSelectedItemChanged: onChanged,
              children: <Widget>[
                for (int i = 0; i < max; i++)
                  Center(child: Text(i.toString().padLeft(2, '0'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
