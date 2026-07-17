import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/domain/sound/imported_sound_exceptions.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';
import 'package:timer_utility/infrastructure/sound/audioplayers_imported_sound_probe.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _FakeSource extends Fake implements Source {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeSource()));

  late _MockAudioPlayer player;

  AudioplayersImportedSoundProbe probeWith(List<int> header) =>
      AudioplayersImportedSoundProbe(
        playerFactory: () => player,
        pathResolver: (_) async => 'staged.tmp',
        headerReader: (_) async => header,
      );

  setUp(() {
    player = _MockAudioPlayer();
    when(() => player.setSource(any())).thenAnswer((_) async {});
    when(
      () => player.getDuration(),
    ).thenAnswer((_) async => const Duration(seconds: 3));
    when(() => player.dispose()).thenAnswer((_) async {});
  });

  group('AudioplayersImportedSoundProbe', () {
    test('MP3ヘッダーと実デコード結果を返す', () async {
      final result = await probeWith(<int>[0x49, 0x44, 0x33]).probe('token');

      expect(result.format, ImportedSoundFormat.mp3);
      expect(result.duration, const Duration(seconds: 3));
      verify(
        () => player.setSource(any(that: isA<DeviceFileSource>())),
      ).called(1);
      verify(() => player.dispose()).called(1);
    });

    test('Ogg内のOpusHeadからOpusを判定する', () async {
      final List<int> header = <int>[
        ...'OggS'.codeUnits,
        ...List<int>.filled(20, 0),
        ...'OpusHead'.codeUnits,
      ];

      final result = await probeWith(header).probe('token');

      expect(result.format, ImportedSoundFormat.opus);
    });

    test('8/16-bit以外のPCM WAVを拒否する', () async {
      final List<int> header = List<int>.filled(44, 0)
        ..setRange(0, 4, 'RIFF'.codeUnits)
        ..setRange(8, 12, 'WAVE'.codeUnits)
        ..setRange(12, 16, 'fmt '.codeUnits)
        ..[20] = 1
        ..[34] = 24;

      await expectLater(
        () => probeWith(header).probe('token'),
        throwsA(isA<UnsupportedImportedSoundFormatException>()),
      );
      verifyNever(() => player.setSource(any()));
    });

    test('プレイヤーがデコードできない場合は変換して破棄する', () async {
      when(() => player.setSource(any())).thenThrow(StateError('decode'));

      await expectLater(
        () => probeWith(<int>[0x49, 0x44, 0x33]).probe('token'),
        throwsA(isA<ImportedSoundDecodeException>()),
      );
      verify(() => player.dispose()).called(1);
    });
  });
}
