import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/alarm_sound_player_provider.dart';
import '../../application/imported_sound_management_controller.dart';
import '../../domain/ports/alarm_sound_player.dart';
import '../../domain/sound/imported_sound.dart';
import '../../domain/sound/imported_sound_format.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/sound_select_sheet.dart';

/// Lists and manages sounds stored in app-private storage.
class ImportedSoundManageScreen extends ConsumerStatefulWidget {
  const ImportedSoundManageScreen({super.key});

  static const String routeLocation = '/imported-sounds';

  @override
  ConsumerState<ImportedSoundManageScreen> createState() =>
      _ImportedSoundManageScreenState();
}

class _ImportedSoundManageScreenState
    extends ConsumerState<ImportedSoundManageScreen> {
  late final AlarmSoundPlayer _player;
  String? _previewingSoundId;

  @override
  void initState() {
    super.initState();
    _player = ref.read(alarmSoundPlayerProvider);
  }

  @override
  void dispose() {
    // A preview must never continue after leaving its management screen.
    _previewingSoundId = null;
    unawaited(_player.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AsyncValue<List<ImportedSound>> sounds = ref.watch(
      importedSoundManagementControllerProvider,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.importedSoundManageTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('imported_sound_add_button'),
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l.importedSoundAdd),
      ),
      body: sounds.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l.importedSoundLoadError)),
        data: (List<ImportedSound> values) {
          if (values.isEmpty) {
            return Center(child: Text(l.importedSoundEmpty));
          }
          return ListView.builder(
            itemCount: values.length,
            itemBuilder: (BuildContext context, int index) => _SoundTile(
              sound: values[index],
              isPreviewing: _previewingSoundId == values[index].id,
              onPreview: () => _preview(values[index]),
              onRename: () => _rename(values[index]),
              onDelete: () => _confirmDelete(values[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _add() async {
    await _stopPreview();
    if (!mounted) return;
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SoundSelectSheet(
        initialSoundId: null,
        importOnly: true,
        startImport: true,
      ),
    );
  }

  Future<void> _preview(ImportedSound sound) async {
    final AlarmSoundPlayer player = _player;
    if (player is! ImportedSoundPreviewPlayer) {
      _showMessage(AppLocalizations.of(context).importedSoundPreviewError);
      return;
    }
    final ImportedSoundPreviewPlayer previewPlayer =
        player as ImportedSoundPreviewPlayer;
    try {
      if (_previewingSoundId == sound.id) {
        await _stopPreview();
        return;
      }
      await _stopPreview();
      await previewPlayer.playImported(sound.id);
      if (!mounted) {
        await player.stop();
        return;
      }
      setState(() => _previewingSoundId = sound.id);
    } catch (_) {
      if (mounted && _previewingSoundId != null) {
        setState(() => _previewingSoundId = null);
      }
      if (mounted) {
        _showMessage(AppLocalizations.of(context).importedSoundPreviewError);
      }
    }
  }

  Future<void> _rename(ImportedSound sound) async {
    final TextEditingController text = TextEditingController(
      text: sound.displayName,
    );
    final AppLocalizations l = AppLocalizations.of(context);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l.importedSoundRenameTitle),
        content: TextField(
          key: const Key('imported_sound_rename_field'),
          controller: text,
          autofocus: true,
          decoration: InputDecoration(labelText: l.importedSoundNameLabel),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.importedSoundCancel),
          ),
          TextButton(
            key: const Key('imported_sound_rename_confirm'),
            onPressed: () => Navigator.of(context).pop(text.text),
            child: Text(l.importedSoundSave),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(importedSoundManagementControllerProvider.notifier)
          .rename(sound, result);
    } on ArgumentError {
      if (mounted) _showMessage(l.importedSoundNameRequired);
    } catch (_) {
      if (mounted) _showMessage(l.importedSoundRenameError);
    }
  }

  Future<void> _confirmDelete(ImportedSound sound) async {
    final AppLocalizations l = AppLocalizations.of(context);
    await _stopPreview();
    if (!mounted) return;
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(l.importedSoundDeleteTitle),
            content: Text(l.importedSoundDeleteDescription),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.importedSoundCancel),
              ),
              TextButton(
                key: const Key('imported_sound_delete_confirm'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.importedSoundDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await ref
          .read(importedSoundManagementControllerProvider.notifier)
          .delete(sound.id);
      if (mounted) _showMessage(l.importedSoundDeleted);
    } catch (_) {
      if (mounted) _showMessage(l.importedSoundDeleteError);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _stopPreview() async {
    if (_previewingSoundId != null) {
      if (mounted) {
        setState(() => _previewingSoundId = null);
      } else {
        _previewingSoundId = null;
      }
    }
    await _player.stop();
  }
}

class _SoundTile extends StatelessWidget {
  const _SoundTile({
    required this.sound,
    required this.isPreviewing,
    required this.onPreview,
    required this.onRename,
    required this.onDelete,
  });

  final ImportedSound sound;
  final bool isPreviewing;
  final VoidCallback onPreview;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return ListTile(
      key: Key('imported_sound_tile_${sound.id}'),
      leading: const Icon(Icons.audio_file_outlined),
      title: Text(sound.displayName),
      subtitle: Text(_metadata(l, sound)),
      trailing: Wrap(
        spacing: 2,
        children: <Widget>[
          IconButton(
            key: Key('imported_sound_preview_${sound.id}'),
            tooltip: isPreviewing ? l.alarmStop : l.importedSoundPreview,
            onPressed: onPreview,
            icon: Icon(isPreviewing ? Icons.stop : Icons.play_arrow),
          ),
          IconButton(
            key: Key('imported_sound_rename_${sound.id}'),
            tooltip: l.importedSoundRename,
            onPressed: onRename,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            key: Key('imported_sound_delete_${sound.id}'),
            tooltip: l.importedSoundDelete,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  String _metadata(AppLocalizations l, ImportedSound sound) {
    final int seconds = sound.duration.inSeconds;
    final String duration =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return '${_formatName(l, sound.format)} · $duration';
  }

  String _formatName(AppLocalizations l, ImportedSoundFormat format) {
    return switch (format) {
      ImportedSoundFormat.mp3 => 'MP3',
      ImportedSoundFormat.oggVorbis => 'Ogg Vorbis',
      ImportedSoundFormat.opus => 'Opus',
      ImportedSoundFormat.pcmWav => 'WAV',
      ImportedSoundFormat.aac => 'AAC',
      ImportedSoundFormat.m4a => 'M4A',
    };
  }
}
