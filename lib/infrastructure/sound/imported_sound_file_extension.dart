import '../../domain/sound/imported_sound_format.dart';

String importedSoundFileExtension(ImportedSoundFormat format) =>
    switch (format) {
      ImportedSoundFormat.mp3 => 'mp3',
      ImportedSoundFormat.oggVorbis => 'ogg',
      ImportedSoundFormat.opus => 'opus',
      ImportedSoundFormat.pcmWav => 'wav',
      ImportedSoundFormat.aac => 'aac',
      ImportedSoundFormat.m4a => 'm4a',
    };

ImportedSoundFormat? importedSoundFormatFromExtension(String extension) =>
    switch (extension.toLowerCase()) {
      'mp3' => ImportedSoundFormat.mp3,
      'ogg' => ImportedSoundFormat.oggVorbis,
      'opus' => ImportedSoundFormat.opus,
      'wav' => ImportedSoundFormat.pcmWav,
      'aac' => ImportedSoundFormat.aac,
      'm4a' => ImportedSoundFormat.m4a,
      _ => null,
    };
