import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import '../../domain/ports/imported_sound_probe.dart';
import '../../domain/sound/imported_sound_exceptions.dart';
import '../../domain/sound/imported_sound_format.dart';
import 'imported_sound_storage_layout.dart';

typedef ImportedSoundPlayerFactory = AudioPlayer Function();
typedef StagedSoundPathResolver = Future<String> Function(String token);
typedef StagedSoundHeaderReader = Future<List<int>> Function(String token);

AudioPlayer _newImportedSoundPlayer() => AudioPlayer();

class AudioplayersImportedSoundProbe implements ImportedSoundProbe {
  AudioplayersImportedSoundProbe({
    ImportedSoundStorageLayout? layout,
    ImportedSoundPlayerFactory? playerFactory,
    StagedSoundPathResolver? pathResolver,
    StagedSoundHeaderReader? headerReader,
  }) : _layout = layout ?? ImportedSoundStorageLayout(),
       _playerFactory = playerFactory ?? _newImportedSoundPlayer,
       _pathResolver = pathResolver,
       _headerReader = headerReader;

  static const int _headerLimit = 65_536;

  final ImportedSoundStorageLayout _layout;
  final ImportedSoundPlayerFactory _playerFactory;
  final StagedSoundPathResolver? _pathResolver;
  final StagedSoundHeaderReader? _headerReader;

  @override
  Future<ImportedSoundProbeResult> probe(String stagedToken) async {
    final List<int> header = _headerReader == null
        ? await _readHeader(stagedToken)
        : await _headerReader(stagedToken);
    final ImportedSoundFormat format = _detectFormat(header);
    final String path = _pathResolver == null
        ? (await _layout.stagedFile(stagedToken)).path
        : await _pathResolver(stagedToken);
    final AudioPlayer player = _playerFactory();
    try {
      await player.setSource(DeviceFileSource(path));
      final Duration? duration = await player.getDuration();
      if (duration == null || duration <= Duration.zero) {
        throw const ImportedSoundDecodeException();
      }
      return ImportedSoundProbeResult(format: format, duration: duration);
    } catch (error) {
      if (error is UnsupportedImportedSoundFormatException ||
          error is ImportedSoundDecodeException) {
        rethrow;
      }
      throw const ImportedSoundDecodeException();
    } finally {
      await player.dispose();
    }
  }

  Future<List<int>> _readHeader(String token) async {
    final File file = await _layout.stagedFile(token);
    return file
        .openRead(0, _headerLimit)
        .expand((List<int> chunk) => chunk)
        .toList();
  }

  ImportedSoundFormat _detectFormat(List<int> bytes) {
    if (_startsWith(bytes, <int>[0x49, 0x44, 0x33]) ||
        (bytes.length >= 2 && bytes[0] == 0xff && (bytes[1] & 0xe0) == 0xe0)) {
      if (bytes.length >= 2 &&
          bytes[0] == 0xff &&
          (bytes[1] == 0xf1 || bytes[1] == 0xf9)) {
        return ImportedSoundFormat.aac;
      }
      return ImportedSoundFormat.mp3;
    }
    if (_startsWith(bytes, <int>[0x4f, 0x67, 0x67, 0x53])) {
      if (_containsAscii(bytes, 'OpusHead')) return ImportedSoundFormat.opus;
      if (_containsAscii(bytes, 'vorbis')) {
        return ImportedSoundFormat.oggVorbis;
      }
    }
    if (_startsWith(bytes, <int>[0x52, 0x49, 0x46, 0x46]) &&
        bytes.length >= 36 &&
        _matchesAt(bytes, 8, <int>[0x57, 0x41, 0x56, 0x45]) &&
        _matchesAt(bytes, 12, <int>[0x66, 0x6d, 0x74, 0x20])) {
      final int audioFormat = bytes[20] | (bytes[21] << 8);
      final int bitsPerSample = bytes[34] | (bytes[35] << 8);
      if (audioFormat == 1 && (bitsPerSample == 8 || bitsPerSample == 16)) {
        return ImportedSoundFormat.pcmWav;
      }
    }
    if (bytes.length >= 12 &&
        _matchesAt(bytes, 4, <int>[0x66, 0x74, 0x79, 0x70])) {
      return ImportedSoundFormat.m4a;
    }
    throw const UnsupportedImportedSoundFormatException();
  }

  bool _containsAscii(List<int> bytes, String value) {
    final List<int> pattern = value.codeUnits;
    for (int index = 0; index <= bytes.length - pattern.length; index++) {
      if (_matchesAt(bytes, index, pattern)) return true;
    }
    return false;
  }

  bool _startsWith(List<int> bytes, List<int> pattern) =>
      _matchesAt(bytes, 0, pattern);

  bool _matchesAt(List<int> bytes, int offset, List<int> pattern) {
    if (offset < 0 || offset + pattern.length > bytes.length) return false;
    for (int index = 0; index < pattern.length; index++) {
      if (bytes[offset + index] != pattern[index]) return false;
    }
    return true;
  }
}
