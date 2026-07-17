class ImportedSoundNotFoundException implements Exception {
  const ImportedSoundNotFoundException(this.id);
  final String id;
}

class DuplicateImportedSoundIdException implements Exception {
  const DuplicateImportedSoundIdException(this.id);
  final String id;
}

class DuplicateImportedSoundContentException implements Exception {
  const DuplicateImportedSoundContentException(this.existingSoundId);
  final String existingSoundId;
}

class UnsupportedImportedSoundFormatException implements Exception {
  const UnsupportedImportedSoundFormatException();
}

class ImportedSoundFileSizeLimitException implements Exception {
  const ImportedSoundFileSizeLimitException();
}

class ImportedSoundDurationLimitException implements Exception {
  const ImportedSoundDurationLimitException();
}

class ImportedSoundCountLimitException implements Exception {
  const ImportedSoundCountLimitException();
}

class ImportedSoundTotalSizeLimitException implements Exception {
  const ImportedSoundTotalSizeLimitException();
}

class InsufficientImportedSoundStorageException implements Exception {
  const InsufficientImportedSoundStorageException();
}

class ImportedSoundStorageUnavailableException implements Exception {
  const ImportedSoundStorageUnavailableException();
}

class ImportedSoundReadException implements Exception {
  const ImportedSoundReadException();
}

class ImportedSoundDecodeException implements Exception {
  const ImportedSoundDecodeException();
}
