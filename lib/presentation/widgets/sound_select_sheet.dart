import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/imported_sound_management_controller.dart';
import '../../application/imported_sound_import_service.dart';
import '../../application/alarm_sound_player_provider.dart';
import '../../domain/ports/alarm_sound_player.dart';
import '../../domain/sound/imported_sound.dart';
import '../../domain/timer/alarm_sound.dart';
import '../../domain/timer/alarm_sound_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../screens/imported_sound_manage_screen.dart';
import 'duration_picker.dart' show soundDisplayName;

/// Bottom sheet for picking an alarm sound id. Returns the chosen id
/// via `Navigator.pop`, or `null` when dismissed.
///
/// Uses a `ListView` of `RadioListTile` so it scales smoothly as the
/// catalog grows (Phase 11 will likely add more sounds). The `null`
/// caller-supplied initial value selects the catalog's first entry.
class SoundSelectSheet extends ConsumerStatefulWidget {
  const SoundSelectSheet({
    super.key,
    required this.initialSoundId,
    this.importOnly = false,
    this.startImport = false,
  });

  final String? initialSoundId;
  final bool importOnly;
  final bool startImport;

  @override
  ConsumerState<SoundSelectSheet> createState() => _SoundSelectSheetState();
}

class _SoundSelectSheetState extends ConsumerState<SoundSelectSheet> {
  late final AlarmSoundPlayer _player;
  late final ImportedSoundManagementController _controller;
  PreparedImportedSound? _prepared;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _player = ref.read(alarmSoundPlayerProvider);
    _controller = ref.read(importedSoundManagementControllerProvider.notifier);
    if (widget.startImport) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_prepareImport());
      });
    }
  }

  @override
  void dispose() {
    unawaited(_stopPreviewBestEffort());
    final PreparedImportedSound? prepared = _prepared;
    if (prepared != null) unawaited(_controller.cancelImport(prepared));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    const List<AlarmSound> catalog = AlarmSoundCatalog.all;
    final List<ImportedSound> imported =
        ref.watch(importedSoundManagementControllerProvider).valueOrNull ??
        const <ImportedSound>[];
    final bool hasInitial =
        catalog.any((AlarmSound s) => s.id == widget.initialSoundId) ||
        imported.any((ImportedSound s) => s.id == widget.initialSoundId);
    final String selected = hasInitial
        ? widget.initialSoundId!
        : catalog.first.id;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!widget.importOnly) ...<Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l.timerSoundSheetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: catalog.length + imported.length,
                itemBuilder: (BuildContext context, int index) {
                  if (index >= catalog.length) {
                    final ImportedSound sound =
                        imported[index - catalog.length];
                    return _SoundOptionTile(
                      soundId: sound.id,
                      label: sound.displayName,
                      selected: sound.id == selected,
                      onTap: () => _select(sound.id),
                    );
                  }
                  final AlarmSound sound = catalog[index];
                  return ListTile(
                    key: Key('sound_select_${sound.id}'),
                    leading: Icon(
                      sound.id == selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(soundDisplayName(l, sound.id)),
                    onTap: () => _select(sound.id),
                  );
                },
              ),
            ),
          ],
          if (_prepared case final PreparedImportedSound prepared)
            _PreparedSoundPanel(
              prepared: prepared,
              busy: _busy,
              onPreview: _previewPrepared,
              onCancel: _cancelPreparedAndMaybeClose,
              onConfirm: _confirmPrepared,
            ),
          ListTile(
            key: const Key('sound_select_add_imported'),
            leading: const Icon(Icons.add),
            title: Text(l.importedSoundAdd),
            enabled: !_busy,
            onTap: _prepareImport,
          ),
          if (!widget.importOnly)
            ListTile(
              key: const Key('sound_select_manage_imported'),
              leading: const Icon(Icons.library_music_outlined),
              title: Text(l.importedSoundManageTitle),
              enabled: !_busy,
              onTap: _openManagement,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _prepareImport() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _cancelPrepared(updateUi: false);
      final PrepareImportedSoundResult? result = await _controller
          .prepareImport();
      if (result == null) {
        if (mounted && widget.importOnly) Navigator.of(context).pop();
        return;
      }
      if (!mounted) {
        if (result is PreparedImportedSound) {
          await _controller.cancelImport(result);
        }
        return;
      }
      switch (result) {
        case final PreparedImportedSound prepared:
          setState(() => _prepared = prepared);
        case DuplicateImportedSound(:final existingSound):
          final AppLocalizations l = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l.importedSoundDuplicate(existingSound.displayName),
              ),
            ),
          );
          await _select(existingSound.id);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context).importedSoundImportError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewPrepared() async {
    final PreparedImportedSound? prepared = _prepared;
    if (prepared == null || _busy) return;
    final AlarmSoundPlayer player = _player;
    if (player is! StagedImportedSoundPreviewPlayer) {
      _showMessage(AppLocalizations.of(context).importedSoundPreviewError);
      return;
    }
    final StagedImportedSoundPreviewPlayer previewPlayer =
        player as StagedImportedSoundPreviewPlayer;
    try {
      if (player.isPlaying) {
        await player.stop();
      } else {
        await previewPlayer.playStaged(_controller.stagingTokenOf(prepared));
      }
    } catch (_) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context).importedSoundPreviewError);
      }
    }
  }

  Future<void> _confirmPrepared() async {
    final PreparedImportedSound? prepared = _prepared;
    if (prepared == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _stopPreviewBestEffort();
      final ImportedSound imported = await _controller.confirmImport(prepared);
      _prepared = null;
      if (mounted) Navigator.of(context).pop(imported.id);
    } catch (_) {
      _prepared = null;
      if (mounted) {
        _showMessage(AppLocalizations.of(context).importedSoundImportError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelPrepared({bool updateUi = true}) async {
    final PreparedImportedSound? prepared = _prepared;
    _prepared = null;
    await _stopPreviewBestEffort();
    if (prepared != null) await _controller.cancelImport(prepared);
    if (mounted && updateUi) setState(() {});
  }

  Future<void> _cancelPreparedAndMaybeClose() async {
    await _cancelPrepared(updateUi: !widget.importOnly);
    if (mounted && widget.importOnly) Navigator.of(context).pop();
  }

  Future<void> _select(String soundId) async {
    await _cancelPrepared(updateUi: false);
    if (mounted) Navigator.of(context).pop(soundId);
  }

  Future<void> _openManagement() async {
    await _cancelPrepared(updateUi: false);
    if (mounted) {
      await context.push(ImportedSoundManageScreen.routeLocation);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _stopPreviewBestEffort() async {
    if (!_player.isPlaying) return;
    try {
      await _player.stop();
    } catch (_) {
      // A platform-side stop failure must not block selection or cleanup.
    }
  }
}

class _SoundOptionTile extends StatelessWidget {
  const _SoundOptionTile({
    required this.soundId,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String soundId;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key('sound_select_$soundId'),
    leading: Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
    ),
    title: Text(label),
    onTap: onTap,
  );
}

class _PreparedSoundPanel extends StatelessWidget {
  const _PreparedSoundPanel({
    required this.prepared,
    required this.busy,
    required this.onPreview,
    required this.onCancel,
    required this.onConfirm,
  });

  final PreparedImportedSound prepared;
  final bool busy;
  final VoidCallback onPreview;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                prepared.candidate.displayName,
                key: const Key('sound_import_candidate_name'),
              ),
            ),
            IconButton(
              key: const Key('sound_import_candidate_preview'),
              tooltip: l.importedSoundPreview,
              onPressed: busy ? null : onPreview,
              icon: const Icon(Icons.play_arrow),
            ),
            TextButton(
              key: const Key('sound_import_candidate_cancel'),
              onPressed: busy ? null : onCancel,
              child: Text(l.importedSoundCancel),
            ),
            FilledButton(
              key: const Key('sound_import_candidate_confirm'),
              onPressed: busy ? null : onConfirm,
              child: Text(l.importedSoundAdd),
            ),
          ],
        ),
      ),
    );
  }
}
