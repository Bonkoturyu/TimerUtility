import '../sound/imported_sound_format.dart';

/// Metadata proven by opening the staged file with the platform audio stack.
class ImportedSoundProbeResult {
  const ImportedSoundProbeResult({
    required this.format,
    required this.duration,
  });

  final ImportedSoundFormat format;
  final Duration duration;
}

abstract class ImportedSoundProbe {
  Future<ImportedSoundProbeResult> probe(String stagedToken);
}
