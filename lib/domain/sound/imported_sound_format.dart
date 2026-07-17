/// Audio formats accepted for user-imported alarm sounds.
///
/// Container and codec distinctions that affect validation are kept as
/// separate values. Infrastructure is responsible for mapping MIME types and
/// decoded file metadata to this enum.
enum ImportedSoundFormat { mp3, oggVorbis, opus, pcmWav, aac, m4a }
