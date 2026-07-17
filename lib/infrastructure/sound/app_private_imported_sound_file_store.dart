import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ports/imported_sound_file_store.dart';
import '../../domain/sound/imported_sound_exceptions.dart';
import '../../domain/sound/imported_sound_format.dart';
import 'imported_sound_file_extension.dart';
import 'imported_sound_storage_layout.dart';

typedef ImportedSoundTokenGenerator = String Function();

String _newImportedSoundToken() => const Uuid().v4();

class AppPrivateImportedSoundFileStore implements ImportedSoundFileStore {
  AppPrivateImportedSoundFileStore({
    ImportedSoundStorageLayout? layout,
    ImportedSoundTokenGenerator? tokenGenerator,
  }) : _layout = layout ?? ImportedSoundStorageLayout(),
       _tokenGenerator = tokenGenerator ?? _newImportedSoundToken;

  final ImportedSoundStorageLayout _layout;
  final ImportedSoundTokenGenerator _tokenGenerator;

  @override
  Future<StagedImportedSoundFile> stage({
    required Stream<List<int>> source,
    required int expectedByteLength,
  }) async {
    if (expectedByteLength <= 0) {
      throw const ImportedSoundReadException();
    }
    final String token = _tokenGenerator();
    final File staged = await _layout.stagedFile(token);
    await staged.parent.create(recursive: true);
    final IOSink output = staged.openWrite();
    final List<Digest> digests = <Digest>[];
    final ByteConversionSink hashSink = sha256.startChunkedConversion(
      ChunkedConversionSink<Digest>.withCallback(digests.addAll),
    );
    int actualByteLength = 0;
    try {
      await for (final List<int> chunk in source) {
        actualByteLength += chunk.length;
        if (actualByteLength > expectedByteLength) {
          throw const ImportedSoundReadException();
        }
        output.add(chunk);
        hashSink.add(chunk);
      }
      await output.flush();
      await output.close();
      hashSink.close();
      if (actualByteLength != expectedByteLength || digests.length != 1) {
        throw const ImportedSoundReadException();
      }
      return StagedImportedSoundFile(
        token: token,
        byteLength: actualByteLength,
        contentHash: digests.single.toString(),
      );
    } catch (_) {
      await output.close();
      hashSink.close();
      if (await staged.exists()) await staged.delete();
      rethrow;
    }
  }

  @override
  Future<void> commit({
    required String token,
    required String soundId,
    required ImportedSoundFormat format,
  }) async {
    final File staged = await _layout.stagedFile(token);
    final File destination = await _layout.committedFile(
      soundId,
      importedSoundFileExtension(format),
    );
    await destination.parent.create(recursive: true);
    await staged.rename(destination.path);
  }

  @override
  Future<void> discard(String token) async {
    final File staged = await _layout.stagedFile(token);
    if (await staged.exists()) await staged.delete();
  }

  @override
  Future<void> delete(String soundId, ImportedSoundFormat format) async {
    final File file = await _layout.committedFile(
      soundId,
      importedSoundFileExtension(format),
    );
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> quarantine(String soundId, ImportedSoundFormat format) async {
    final String extension = importedSoundFileExtension(format);
    final File source = await _layout.committedFile(soundId, extension);
    final File destination = await _layout.quarantinedFile(soundId, extension);
    if (await destination.exists()) return;
    // Metadata may outlive bytes after external storage corruption or a
    // previous cleanup. Deletion must remain possible and idempotent.
    if (!await source.exists()) return;
    await destination.parent.create(recursive: true);
    await source.rename(destination.path);
  }

  @override
  Future<void> restoreQuarantined(
    String soundId,
    ImportedSoundFormat format,
  ) async {
    final String extension = importedSoundFileExtension(format);
    final File source = await _layout.quarantinedFile(soundId, extension);
    if (!await source.exists()) return;
    final File destination = await _layout.committedFile(soundId, extension);
    if (await destination.exists()) {
      await source.delete();
      return;
    }
    await destination.parent.create(recursive: true);
    await source.rename(destination.path);
  }

  @override
  Future<void> purgeQuarantined(
    String soundId,
    ImportedSoundFormat format,
  ) async {
    final File file = await _layout.quarantinedFile(
      soundId,
      importedSoundFileExtension(format),
    );
    if (await file.exists()) await file.delete();
  }

  @override
  Future<List<QuarantinedImportedSoundFile>> findQuarantined() async {
    final Directory directory = await _layout.quarantineDirectory();
    if (!await directory.exists()) {
      return const <QuarantinedImportedSoundFile>[];
    }
    final List<QuarantinedImportedSoundFile> result =
        <QuarantinedImportedSoundFile>[];
    await for (final FileSystemEntity entry in directory.list()) {
      if (entry is! File) continue;
      final String name = entry.uri.pathSegments.last;
      final int dot = name.lastIndexOf('.');
      if (dot <= 0 || dot == name.length - 1) continue;
      final ImportedSoundFormat? format = importedSoundFormatFromExtension(
        name.substring(dot + 1),
      );
      if (format == null) continue;
      result.add(
        QuarantinedImportedSoundFile(
          soundId: name.substring(0, dot),
          format: format,
        ),
      );
    }
    return List<QuarantinedImportedSoundFile>.unmodifiable(result);
  }
}
