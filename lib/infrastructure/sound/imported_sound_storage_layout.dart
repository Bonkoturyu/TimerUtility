import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef ImportedSoundDirectoryProvider = Future<Directory> Function();

/// Resolves app-private sound paths without exposing them through Domain APIs.
class ImportedSoundStorageLayout {
  ImportedSoundStorageLayout({ImportedSoundDirectoryProvider? baseDirectory})
    : _baseDirectory = baseDirectory ?? getApplicationSupportDirectory;

  final ImportedSoundDirectoryProvider _baseDirectory;

  Future<Directory> root() async =>
      Directory(p.join((await _baseDirectory()).path, 'imported_sounds'));

  Future<File> stagedFile(String token) async =>
      File(p.join((await root()).path, '.staging', '$token.tmp'));

  Future<File> committedFile(String soundId, String extension) async =>
      File(p.join((await root()).path, '$soundId.$extension'));

  Future<File> quarantinedFile(String soundId, String extension) async =>
      File(p.join((await root()).path, '.deleting', '$soundId.$extension'));

  Future<Directory> quarantineDirectory() async =>
      Directory(p.join((await root()).path, '.deleting'));
}
