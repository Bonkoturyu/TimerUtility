import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timer_utility/domain/timer/alarm_sound_catalog.dart';
import 'package:timer_utility/infrastructure/audio/audioplayers_adapter.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _FakeSource extends Fake implements Source {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSource());
    registerFallbackValue(ReleaseMode.loop);
  });

  late _MockAudioPlayer player;

  setUp(() {
    player = _MockAudioPlayer();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.setReleaseMode(any())).thenAnswer((_) async {});
    when(() => player.play(any())).thenAnswer((_) async {});
    when(() => player.dispose()).thenAnswer((_) async {});
  });

  group('AudioplayersAdapter', () {
    // Regression guard for the single-source-of-truth refactor: the
    // adapter no longer subscribes to `onPlayerStateChanged`. We never
    // stub that getter here, so if a listener were re-introduced the
    // constructor would hit a MissingStubError and every test below would
    // fail at `AudioplayersAdapter(player: player)`. Construction
    // succeeding is itself the proof the listener is gone.
    test('starts not playing', () {
      final adapter = AudioplayersAdapter(player: player);
      expect(adapter.isPlaying, isFalse);
    });

    test('play() loops the de-prefixed asset and marks isPlaying', () async {
      final adapter = AudioplayersAdapter(player: player);
      final sound = AlarmSoundCatalog.defaultSound;

      await adapter.play(sound);

      expect(adapter.isPlaying, isTrue);
      verify(() => player.setReleaseMode(ReleaseMode.loop)).called(1);
      final List<dynamic> captured = verify(
        () => player.play(captureAny()),
      ).captured;
      final source = captured.single as AssetSource;
      final String expectedPath = sound.assetPath.startsWith('assets/')
          ? sound.assetPath.substring('assets/'.length)
          : sound.assetPath;
      expect(source.path, expectedPath);
    });

    test('stop() marks not playing', () async {
      final adapter = AudioplayersAdapter(player: player);
      await adapter.play(AlarmSoundCatalog.defaultSound);
      expect(adapter.isPlaying, isTrue);

      await adapter.stop();
      expect(adapter.isPlaying, isFalse);
    });

    test('dispose() releases the player and clears isPlaying', () async {
      final adapter = AudioplayersAdapter(player: player);
      await adapter.play(AlarmSoundCatalog.defaultSound);

      await adapter.dispose();

      expect(adapter.isPlaying, isFalse);
      verify(() => player.dispose()).called(1);
    });
  });
}
