import 'imported_sound.dart';
import 'imported_sound_exceptions.dart';
import 'imported_sound_policy.dart';

/// Pure domain validation for adding or replacing an imported sound.
class ImportedSoundValidator {
  const ImportedSoundValidator();

  static const int minimumRemainingStorageBytes = 10_000_000_000;

  void validateAddition({
    required ImportedSound candidate,
    required Iterable<ImportedSound> existingSounds,
    required ImportedSoundPolicy policy,
    required int availableStorageBytes,
  }) {
    _validate(
      candidate: candidate,
      existingSounds: existingSounds,
      policy: policy,
      availableStorageBytes: availableStorageBytes,
      replacedSoundId: null,
    );
  }

  void validateReplacement({
    required ImportedSound candidate,
    required String replacedSoundId,
    required Iterable<ImportedSound> existingSounds,
    required ImportedSoundPolicy policy,
    required int availableStorageBytes,
  }) {
    final bool replacementExists = existingSounds.any(
      (ImportedSound sound) => sound.id == replacedSoundId,
    );
    if (!replacementExists) {
      throw ImportedSoundNotFoundException(replacedSoundId);
    }
    _validate(
      candidate: candidate,
      existingSounds: existingSounds,
      policy: policy,
      availableStorageBytes: availableStorageBytes,
      replacedSoundId: replacedSoundId,
    );
  }

  void _validate({
    required ImportedSound candidate,
    required Iterable<ImportedSound> existingSounds,
    required ImportedSoundPolicy policy,
    required int availableStorageBytes,
    required String? replacedSoundId,
  }) {
    final List<ImportedSound> countedSounds = existingSounds
        .where((ImportedSound sound) => sound.id != replacedSoundId)
        .toList(growable: false);

    if (!policy.supportedFormats.contains(candidate.format)) {
      throw const UnsupportedImportedSoundFormatException();
    }
    if (candidate.byteLength > policy.maxFileBytes) {
      throw const ImportedSoundFileSizeLimitException();
    }
    if (candidate.duration > policy.maxDuration) {
      throw const ImportedSoundDurationLimitException();
    }
    if (countedSounds.any((ImportedSound sound) => sound.id == candidate.id)) {
      throw DuplicateImportedSoundIdException(candidate.id);
    }
    for (final ImportedSound sound in countedSounds) {
      if (sound.contentHash == candidate.contentHash) {
        throw DuplicateImportedSoundContentException(sound.id);
      }
    }
    if (countedSounds.length >= policy.maxCount) {
      throw const ImportedSoundCountLimitException();
    }
    final int totalBytes = countedSounds.fold<int>(
      candidate.byteLength,
      (int sum, ImportedSound sound) => sum + sound.byteLength,
    );
    if (totalBytes > policy.maxTotalBytes) {
      throw const ImportedSoundTotalSizeLimitException();
    }
    if (availableStorageBytes < minimumRemainingStorageBytes ||
        availableStorageBytes - candidate.byteLength <
            minimumRemainingStorageBytes) {
      throw const InsufficientImportedSoundStorageException();
    }
  }
}
