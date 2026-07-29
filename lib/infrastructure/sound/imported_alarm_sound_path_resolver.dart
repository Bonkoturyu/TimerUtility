import '../../domain/ports/imported_sound_repository.dart';
import 'imported_sound_file_extension.dart';
import 'imported_sound_storage_layout.dart';

/// Resolves an imported id to its existing app-private copy.
///
/// The absolute path stays inside Infrastructure and is consumed only by the
/// audioplayers adapter. Missing metadata or bytes resolve to `null` so the
/// caller can use the bundled fallback.
class ImportedAlarmSoundPathResolver {
  ImportedAlarmSoundPathResolver({
    required ImportedSoundRepository repository,
    required ImportedSoundStorageLayout layout,
  }) : _repository = repository,
       _layout = layout;

  final ImportedSoundRepository _repository;
  final ImportedSoundStorageLayout _layout;

  Future<String?> resolve(String soundId) async {
    final sound = await _repository.findById(soundId);
    if (sound == null) return null;
    final file = await _layout.committedFile(
      sound.id,
      importedSoundFileExtension(sound.format),
    );
    return await file.exists() ? file.path : null;
  }
}
