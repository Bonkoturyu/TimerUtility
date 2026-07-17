/// A user-selected file exposed without leaking a platform URI or path.
class SelectedImportedSoundFile {
  const SelectedImportedSoundFile({
    required this.name,
    required this.mimeType,
    required this.byteLength,
    required this.openRead,
  });

  final String name;
  final String? mimeType;
  final int byteLength;
  final Stream<List<int>> Function() openRead;
}

abstract class ImportedSoundPicker {
  /// Opens the OS picker and returns `null` when the user cancels.
  Future<SelectedImportedSoundFile?> pickOne();
}
