import 'imported_sound_format.dart';

/// Metadata for an alarm sound copied into app-private storage.
///
/// This entity deliberately contains no URI, absolute path, or `File`. The
/// infrastructure repository resolves [id] to the app-private copy.
class ImportedSound {
  const ImportedSound._({
    required this.id,
    required this.displayName,
    required this.format,
    required this.byteLength,
    required this.duration,
    required this.contentHash,
    required this.createdAt,
  });

  factory ImportedSound.create({
    required String id,
    required String displayName,
    required ImportedSoundFormat format,
    required int byteLength,
    required Duration duration,
    required String contentHash,
    required DateTime createdAt,
  }) {
    final String normalizedName = displayName.trim();
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        displayName,
        'displayName',
        'must not be empty',
      );
    }
    if (byteLength <= 0 || byteLength > maxInternalFileBytes) {
      throw ArgumentError.value(
        byteLength,
        'byteLength',
        'must be between 1 and $maxInternalFileBytes',
      );
    }
    if (duration < minDuration || duration > maxInternalDuration) {
      throw ArgumentError.value(
        duration,
        'duration',
        'must be between $minDuration and $maxInternalDuration',
      );
    }
    if (!_sha256Pattern.hasMatch(contentHash)) {
      throw ArgumentError.value(
        contentHash,
        'contentHash',
        'must be a lowercase SHA-256 digest',
      );
    }
    return ImportedSound._(
      id: id,
      displayName: normalizedName,
      format: format,
      byteLength: byteLength,
      duration: duration,
      contentHash: contentHash,
      createdAt: createdAt,
    );
  }

  static const int maxInternalFileBytes = 25_000_000;
  static const Duration minDuration = Duration(seconds: 1);
  static const Duration maxInternalDuration = Duration(minutes: 15);

  final String id;
  final String displayName;
  final ImportedSoundFormat format;
  final int byteLength;
  final Duration duration;

  /// Lowercase SHA-256 digest encoded as 64 hexadecimal characters.
  final String contentHash;
  final DateTime createdAt;

  ImportedSound rename(String name) => ImportedSound.create(
    id: id,
    displayName: name,
    format: format,
    byteLength: byteLength,
    duration: duration,
    contentHash: contentHash,
    createdAt: createdAt,
  );

  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportedSound &&
          other.id == id &&
          other.displayName == displayName &&
          other.format == format &&
          other.byteLength == byteLength &&
          other.duration == duration &&
          other.contentHash == contentHash &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    format,
    byteLength,
    duration,
    contentHash,
    createdAt,
  );
}
