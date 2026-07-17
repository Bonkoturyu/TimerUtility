import 'package:file_selector/file_selector.dart';

import '../../domain/ports/imported_sound_picker.dart';

typedef OpenImportedSoundFile =
    Future<XFile?> Function({required List<XTypeGroup> acceptedTypeGroups});
typedef ReadImportedSoundFileLength = Future<int> Function(XFile file);
typedef OpenImportedSoundFileStream = Stream<List<int>> Function(XFile file);

Future<XFile?> _openImportedSoundFile({
  required List<XTypeGroup> acceptedTypeGroups,
}) => openFile(acceptedTypeGroups: acceptedTypeGroups);

Future<int> _readImportedSoundFileLength(XFile file) => file.length();

Stream<List<int>> _openImportedSoundFileStream(XFile file) => file.openRead();

/// Selects one audio document using Flutter's endorsed system picker.
class FileSelectorImportedSoundPicker implements ImportedSoundPicker {
  FileSelectorImportedSoundPicker({
    OpenImportedSoundFile? openFile,
    ReadImportedSoundFileLength? readLength,
    OpenImportedSoundFileStream? openRead,
  }) : _openFile = openFile ?? _openImportedSoundFile,
       _readLength = readLength ?? _readImportedSoundFileLength,
       _openRead = openRead ?? _openImportedSoundFileStream;

  static const XTypeGroup _supportedAudio = XTypeGroup(
    label: 'audio',
    extensions: <String>['mp3', 'ogg', 'opus', 'wav', 'm4a', 'aac'],
    mimeTypes: <String>[
      'audio/mpeg',
      'audio/ogg',
      'audio/opus',
      'audio/wav',
      'audio/x-wav',
      'audio/aac',
      'audio/mp4',
      'audio/x-m4a',
    ],
  );

  final OpenImportedSoundFile _openFile;
  final ReadImportedSoundFileLength _readLength;
  final OpenImportedSoundFileStream _openRead;

  @override
  Future<SelectedImportedSoundFile?> pickOne() async {
    final XFile? file = await _openFile(
      acceptedTypeGroups: const <XTypeGroup>[_supportedAudio],
    );
    if (file == null) return null;
    return SelectedImportedSoundFile(
      name: file.name,
      mimeType: file.mimeType,
      byteLength: await _readLength(file),
      openRead: () => _openRead(file),
    );
  }
}
