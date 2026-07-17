import 'imported_sound.dart';
import 'imported_sound_format.dart';

/// Entitlement-resolved limits for user-imported alarm sounds.
///
/// Product identifiers and billing state never enter this object. Application
/// code resolves the current entitlement and injects one of these policies.
class ImportedSoundPolicy {
  const ImportedSoundPolicy._({
    required this.maxFileBytes,
    required this.maxDuration,
    required this.maxCount,
    required this.supportedFormats,
  });

  factory ImportedSoundPolicy({
    required int maxFileBytes,
    required Duration maxDuration,
    required int maxCount,
    required Set<ImportedSoundFormat> supportedFormats,
  }) {
    if (maxFileBytes <= 0 ||
        maxFileBytes > ImportedSound.maxInternalFileBytes) {
      throw ArgumentError.value(maxFileBytes, 'maxFileBytes');
    }
    if (maxDuration <= Duration.zero ||
        maxDuration > ImportedSound.maxInternalDuration) {
      throw ArgumentError.value(maxDuration, 'maxDuration');
    }
    if (maxCount <= 0) {
      throw ArgumentError.value(maxCount, 'maxCount');
    }
    if (supportedFormats.isEmpty) {
      throw ArgumentError.value(supportedFormats, 'supportedFormats');
    }
    return ImportedSoundPolicy._(
      maxFileBytes: maxFileBytes,
      maxDuration: maxDuration,
      maxCount: maxCount,
      supportedFormats: Set<ImportedSoundFormat>.unmodifiable(supportedFormats),
    );
  }

  static const Set<ImportedSoundFormat> initialFormats = <ImportedSoundFormat>{
    ImportedSoundFormat.mp3,
    ImportedSoundFormat.oggVorbis,
    ImportedSoundFormat.opus,
    ImportedSoundFormat.pcmWav,
    ImportedSoundFormat.aac,
    ImportedSoundFormat.m4a,
  };

  static final ImportedSoundPolicy standard = ImportedSoundPolicy(
    maxFileBytes: 5_000_000,
    maxDuration: const Duration(minutes: 3),
    maxCount: 3,
    supportedFormats: initialFormats,
  );

  static final ImportedSoundPolicy futureTierA = ImportedSoundPolicy(
    maxFileBytes: 10_000_000,
    maxDuration: const Duration(minutes: 6),
    maxCount: 5,
    supportedFormats: initialFormats,
  );

  static final ImportedSoundPolicy futureTierB = ImportedSoundPolicy(
    maxFileBytes: 15_000_000,
    maxDuration: const Duration(minutes: 9),
    maxCount: 10,
    supportedFormats: initialFormats,
  );

  final int maxFileBytes;
  final Duration maxDuration;
  final int maxCount;
  final Set<ImportedSoundFormat> supportedFormats;

  /// Derived rather than stored independently so count and size limits cannot
  /// drift apart.
  int get maxTotalBytes => maxFileBytes * maxCount;
}
