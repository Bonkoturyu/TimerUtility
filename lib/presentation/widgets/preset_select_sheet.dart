import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/preset_collection_notifier.dart';
import '../../domain/timer/preset.dart';
import '../../l10n/app_localizations.dart';
import 'preset_label_formatter.dart';

/// Result returned from the preset select sheet.
///
///   - `preset != null`: user tapped a preset chip → caller should
///     create a timer using that preset's duration / soundId.
///   - `customRequested == true`: user tapped "Create with custom
///     time" → caller should open the existing [DurationPicker].
///   - `manageRequested == true`: user tapped "Manage presets..." →
///     caller should navigate to [PresetManageScreen].
///   - all `null` / `false`: dismissed.
///
/// The three signal fields are mutually exclusive — at most one may
/// be set per result. The [assert] in the constructor guards against
/// callers (or future contributors) accidentally combining them.
class PresetSelectResult {
  const PresetSelectResult({
    this.preset,
    this.customRequested = false,
    this.manageRequested = false,
  }) : assert(
         (preset != null ? 1 : 0) +
                 (customRequested ? 1 : 0) +
                 (manageRequested ? 1 : 0) <=
             1,
         'PresetSelectResult: at most one of preset / customRequested / '
         'manageRequested may be set.',
       );
  final Preset? preset;
  final bool customRequested;
  final bool manageRequested;
}

/// Phase 9 bottom sheet shown when the user taps the "Add timer" FAB
/// on `TimerListScreen`. Lets the user pick from saved presets in a
/// 2x3-ish grid and falls back to the existing custom-time picker
/// for non-preset durations. Phase 11 follow-up adds a "Manage
/// presets..." entry at the bottom so the management screen is
/// reachable from this sheet (the AppBar overflow menu still works
/// too).
///
/// Empty-state: when no presets exist (user wiped them via overwrite
/// → empty), the preset chip grid and its trailing divider are
/// suppressed, but the "Create with custom time" and "Manage
/// presets..." buttons remain so the user can still create a timer
/// or seed presets from the manage screen.
class PresetSelectSheet extends ConsumerWidget {
  const PresetSelectSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<Preset> presets = ref
        .watch(presetCollectionNotifierProvider)
        .all;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Text(
                l.presetSheetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (presets.isNotEmpty) ...<Widget>[
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: <Widget>[
                  for (final Preset p in presets)
                    FilledButton.tonal(
                      key: Key('preset_chip_${p.id}'),
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(PresetSelectResult(preset: p)),
                      child: Text(
                        formatPresetLabel(
                          duration: p.duration,
                          l: l,
                          userLabel: p.label,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
            ],
            FilledButton(
              key: const Key('preset_sheet_custom_button'),
              onPressed: () => Navigator.of(
                context,
              ).pop(const PresetSelectResult(customRequested: true)),
              child: Text(l.presetSheetCustomButton),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),
            TextButton.icon(
              key: const Key('preset_sheet_manage_button'),
              icon: const Icon(Icons.tune),
              label: Text(l.presetSheetManageButton),
              onPressed: () => Navigator.of(
                context,
              ).pop(const PresetSelectResult(manageRequested: true)),
            ),
          ],
        ),
      ),
    );
  }
}
