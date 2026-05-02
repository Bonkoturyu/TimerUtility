import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/preset_collection_notifier.dart';
import '../../application/user_preferences_provider.dart';
import '../../domain/ports/user_preferences.dart';
import '../../domain/timer/preset.dart';
import '../../domain/timer/preset_exceptions.dart';
import '../../domain/timer/preset_templates.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/duration_picker.dart' show soundDisplayName;
import '../widgets/preset_delete_confirm_dialog.dart';
import '../widgets/preset_edit_sheet.dart';
import '../widgets/preset_label_formatter.dart';
import '../widgets/sound_select_sheet.dart';

/// Phase 9 preset management screen. Reached from
/// `TimerListScreen`'s AppBar overflow menu (`案 P`).
///
/// Features:
///   - List of saved presets (label / duration / sound chip), each
///     with edit / delete row buttons.
///   - FAB to add a new preset (opens [PresetEditSheet] in "Add" mode).
///   - AppBar overflow → "Replace from template" launches the
///     profile picker → mode picker (3-way dialog) flow.
///   - Empty state surfaces a hint pointing the user at both add
///     paths.
class PresetManageScreen extends ConsumerWidget {
  const PresetManageScreen({super.key});

  static const String routeLocation = '/presets';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<Preset> presets = ref
        .watch(presetCollectionNotifierProvider)
        .all;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.presetManageAppBarTitle),
        actions: <Widget>[
          PopupMenuButton<String>(
            key: const Key('preset_manage_menu'),
            onSelected: (String value) {
              if (value == 'replace_template') {
                _onReplaceTemplate(context, ref);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                key: const Key('preset_manage_menu_replace'),
                value: 'replace_template',
                child: Text(l.presetManageReplaceTemplate),
              ),
            ],
          ),
        ],
      ),
      body: presets.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.presetManageEmptyHint,
                  key: const Key('preset_manage_empty_hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            )
          : ListView.separated(
              // Bottom padding keeps the last card clear of the FAB —
              // FloatingActionButton is ~56dp; 96dp leaves headroom
              // for the action row icons inside the bottom card.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: presets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final Preset p = presets[index];
                return _PresetCard(preset: p);
              },
            ),
      floatingActionButton: FloatingActionButton(
        key: const Key('preset_manage_add_fab'),
        onPressed: () => _onAdd(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _onAdd(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final notifier = ref.read(presetCollectionNotifierProvider.notifier);
    final result = await showModalBottomSheet<PresetEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PresetEditSheet(),
    );
    if (result == null) return;
    try {
      notifier.create(
        label: result.label,
        duration: result.duration,
        soundId: result.soundId,
      );
    } on MaxPresetCountExceededException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.timerListLimitReached(e.maxSize))),
      );
    }
  }

  Future<void> _onReplaceTemplate(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final notifier = ref.read(presetCollectionNotifierProvider.notifier);
    final bool collectionEmpty = ref
        .read(presetCollectionNotifierProvider)
        .isEmpty;

    // Step 1: pick a profile.
    final String? profileId = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return SimpleDialog(
          title: Text(l.presetTemplateReplaceTitle),
          children: <Widget>[
            for (final PresetProfile p in PresetTemplates.all)
              SimpleDialogOption(
                key: Key('preset_template_profile_${p.id}'),
                onPressed: () => Navigator.of(ctx).pop(p.id),
                child: Text(_profileLabel(l, p.id)),
              ),
          ],
        );
      },
    );
    if (profileId == null) return;
    if (!context.mounted) return;

    // Step 2: pick a mode (skip the dialog when the collection is
    // empty — there's nothing to overwrite, so "append" is the only
    // sensible option and we run it directly).
    ReplaceTemplateMode? mode;
    if (collectionEmpty) {
      mode = ReplaceTemplateMode.append;
    } else {
      mode = await showDialog<ReplaceTemplateMode>(
        context: context,
        builder: (BuildContext ctx) {
          // Append is the safe / primary action → FilledButton.
          // Overwrite is destructive → TextButton with the
          // colorScheme.error foreground so the user pauses.
          // Earlier this was reversed and a real-device tester tapped
          // Overwrite thinking it was the confirm CTA — keep this
          // emphasis to avoid a repeat.
          final ColorScheme cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: Text(l.presetTemplateReplaceTitle),
            content: Text(l.presetTemplateReplaceMode),
            actions: <Widget>[
              TextButton(
                key: const Key('preset_template_mode_cancel'),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l.presetTemplateReplaceModeCancel),
              ),
              TextButton(
                key: const Key('preset_template_mode_overwrite'),
                style: TextButton.styleFrom(foregroundColor: cs.error),
                onPressed: () =>
                    Navigator.of(ctx).pop(ReplaceTemplateMode.overwrite),
                child: Text(l.presetTemplateReplaceModeOverwrite),
              ),
              FilledButton(
                key: const Key('preset_template_mode_append'),
                onPressed: () =>
                    Navigator.of(ctx).pop(ReplaceTemplateMode.append),
                child: Text(l.presetTemplateReplaceModeAppend),
              ),
            ],
          );
        },
      );
    }
    if (mode == null) return;
    if (!context.mounted) return;

    final ReplaceTemplateResult result = await notifier.replaceFromTemplate(
      profileId,
      mode: mode,
    );
    if (!context.mounted) return;
    if (result.discardedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.presetTemplateReplaceLimitWarning(result.discardedCount),
          ),
        ),
      );
    }
  }

  String _profileLabel(AppLocalizations l, String profileId) {
    return switch (profileId) {
      'general' => l.presetTemplateReplaceProfileGeneral,
      'cooking' => l.presetTemplateReplaceProfileCooking,
      'pomodoro' => l.presetTemplateReplaceProfilePomodoro,
      _ => profileId,
    };
  }
}

class _PresetCard extends ConsumerWidget {
  const _PresetCard({required this.preset});
  final Preset preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final notifier = ref.read(presetCollectionNotifierProvider.notifier);
    return Card(
      key: Key('preset_card_${preset.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    formatPresetLabel(
                      duration: preset.duration,
                      l: l,
                      userLabel: preset.label,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(soundDisplayName(l, preset.soundId ?? 'default')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  key: Key('preset_card_${preset.id}_edit'),
                  tooltip: l.presetEditTitleEdit,
                  icon: const Icon(Icons.edit),
                  onPressed: () => _onEdit(context, ref, notifier),
                ),
                IconButton(
                  key: Key('preset_card_${preset.id}_sound'),
                  tooltip: l.timerCardSoundChange,
                  icon: const Icon(Icons.music_note),
                  onPressed: () => _onChangeSound(context, notifier),
                ),
                IconButton(
                  key: Key('preset_card_${preset.id}_delete'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _onDelete(context, ref, notifier),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onChangeSound(
    BuildContext context,
    PresetCollectionNotifier notifier,
  ) async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SoundSelectSheet(initialSoundId: preset.soundId),
    );
    if (picked == null) return;
    notifier.update(preset.id, soundId: picked);
  }

  Future<void> _onEdit(
    BuildContext context,
    WidgetRef ref,
    PresetCollectionNotifier notifier,
  ) async {
    final result = await showModalBottomSheet<PresetEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PresetEditSheet(editing: preset),
    );
    if (result == null) return;
    notifier.update(
      preset.id,
      label: result.label,
      duration: result.duration,
      soundId: result.soundId,
    );
  }

  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    PresetCollectionNotifier notifier,
  ) async {
    final UserPreferences prefs = ref.read(userPreferencesProvider);
    final bool? skip = await prefs.getBool(
      UserPreferenceKeys.skipPresetDeleteConfirm,
    );
    if (skip == true) {
      notifier.delete(preset.id);
      return;
    }

    if (!context.mounted) return;
    final result = await showPresetDeleteConfirmDialog(context);
    if (!result.confirmed) {
      // Even when the user cancelled, persist a "don't ask again"
      // tick if they checked the box — the box is independent of the
      // primary action so it can be set without committing the
      // deletion.
      if (result.dontAskAgain) {
        await prefs.setBool(UserPreferenceKeys.skipPresetDeleteConfirm, true);
      }
      return;
    }
    if (result.dontAskAgain) {
      await prefs.setBool(UserPreferenceKeys.skipPresetDeleteConfirm, true);
    }
    notifier.delete(preset.id);
  }
}
