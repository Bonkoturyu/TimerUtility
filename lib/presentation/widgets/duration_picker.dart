import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/timer/alarm_sound.dart';
import '../../domain/timer/alarm_sound_catalog.dart';
import '../../l10n/app_localizations.dart';

/// Resolve a localized display name for the given alarm sound id.
/// Falls back to the raw id (so adapters dropping ARB keys don't crash
/// the picker).
String soundDisplayName(AppLocalizations l, String soundId) {
  return switch (soundId) {
    'default' => l.alarmSoundDefault,
    'gentle' => l.alarmSoundGentle,
    'urgent' => l.alarmSoundWarning,
    _ => soundId,
  };
}

/// Modal-friendly hours/minutes/seconds wheel picker.
///
/// Returns the chosen [Duration] via `Navigator.pop` when the user
/// confirms, or `null` when cancelled. The Confirm button is disabled
/// while the chosen duration is zero or exceeds [maxDuration]
/// (mirroring `TimerService` / `PresetService` invariants).
///
/// Phase 9 deliberately keeps this picker sound-agnostic: trying to
/// stack a Cupertino wheel cluster, a sound dropdown, and the
/// confirm row inside a non-scrollable bottom sheet was causing
/// hit-test issues on the cancel button. Sound is left at the
/// catalog default for "create with custom time" and the user
/// changes it from the timer card's sound icon afterwards.
class DurationPicker extends StatefulWidget {
  const DurationPicker({super.key, this.initial = const Duration(minutes: 1)});

  final Duration initial;

  /// Mirrors `TimerService.maxDuration` (99 hours). Kept as a local
  /// constant to avoid importing the domain layer from a widget.
  static const Duration maxDuration = Duration(hours: 99);

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.initial.isNegative ? Duration.zero : widget.initial;
  }

  bool get _confirmEnabled =>
      _duration > Duration.zero && _duration <= DurationPicker.maxDuration;

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
            DurationPickerWheels(
              initial: widget.initial,
              onChanged: (Duration v) => setState(() => _duration = v),
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
                      ? () => Navigator.of(context).pop(_duration)
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
}

/// Reusable HH/MM/SS Cupertino wheel cluster. Extracted from
/// [DurationPicker] so the preset-edit sheet (and any future flow
/// that needs a duration input) can drop it in without inheriting
/// the modal chrome.
class DurationPickerWheels extends StatefulWidget {
  const DurationPickerWheels({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final Duration initial;

  /// Called every time the user spins any of the three wheels. The
  /// argument is the *currently shown* total — the parent decides
  /// when to commit it (e.g. on confirm tap).
  final ValueChanged<Duration> onChanged;

  @override
  State<DurationPickerWheels> createState() => _DurationPickerWheelsState();
}

class _DurationPickerWheelsState extends State<DurationPickerWheels> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  /// CupertinoPicker fires `onSelectedItemChanged` while it's animating
  /// to its `initialItem` on first paint. Without this guard those
  /// transient values would clobber `widget.initial` in the parent's
  /// state — most visibly: the confirm button briefly disables when
  /// the wheel passes through 0. We flip the flag from a post-frame
  /// callback so any later genuine user scroll still emits.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final Duration initial = widget.initial.isNegative
        ? Duration.zero
        : widget.initial;
    _hours = initial.inHours.clamp(0, 99);
    _minutes = initial.inMinutes.remainder(60);
    _seconds = initial.inSeconds.remainder(60);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  void _emit() {
    if (!_ready) return;
    widget.onChanged(
      Duration(hours: _hours, minutes: _minutes, seconds: _seconds),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return SizedBox(
      height: 180,
      child: Row(
        children: <Widget>[
          _column(
            keyName: 'duration_picker_hours',
            label: l.durationPickerHours,
            max: 100,
            initial: _hours,
            onChanged: (int v) {
              setState(() => _hours = v);
              _emit();
            },
          ),
          _column(
            keyName: 'duration_picker_minutes',
            label: l.durationPickerMinutes,
            max: 60,
            initial: _minutes,
            onChanged: (int v) {
              setState(() => _minutes = v);
              _emit();
            },
          ),
          _column(
            keyName: 'duration_picker_seconds',
            label: l.durationPickerSeconds,
            max: 60,
            initial: _seconds,
            onChanged: (int v) {
              setState(() => _seconds = v);
              _emit();
            },
          ),
        ],
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

/// Dropdown bound to `AlarmSoundCatalog.all`. Auto-scales as the
/// catalog grows (Phase 11 plans up to ~10 sounds), no hard-coded
/// list of 3.
class SoundDropdown extends StatelessWidget {
  const SoundDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return DropdownButton<String>(
      isExpanded: true,
      value: value,
      onChanged: (String? v) {
        if (v != null) onChanged(v);
      },
      items: <DropdownMenuItem<String>>[
        for (final AlarmSound s in AlarmSoundCatalog.all)
          DropdownMenuItem<String>(
            value: s.id,
            child: Text(soundDisplayName(l, s.id)),
          ),
      ],
    );
  }
}
