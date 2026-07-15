import 'dart:async';

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
    registerFallbackValue(AudioContext());
  });

  late _MockAudioPlayer player;

  setUp(() {
    player = _MockAudioPlayer();
    when(() => player.stop()).thenAnswer((_) async {});
    when(() => player.setAudioContext(any())).thenAnswer((_) async {});
    when(() => player.setReleaseMode(any())).thenAnswer((_) async {});
    when(() => player.setSource(any())).thenAnswer((_) async {});
    when(() => player.resume()).thenAnswer((_) async {});
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

    test('prepare() loads the de-prefixed asset without playing', () async {
      final adapter = AudioplayersAdapter(player: player);
      final sound = AlarmSoundCatalog.defaultSound;

      await adapter.prepare(sound);

      expect(adapter.isPlaying, isFalse);
      verify(() => player.setReleaseMode(ReleaseMode.loop)).called(1);
      final List<dynamic> captured = verify(
        () => player.setSource(captureAny()),
      ).captured;
      final source = captured.single as AssetSource;
      final String expectedPath = sound.assetPath.startsWith('assets/')
          ? sound.assetPath.substring('assets/'.length)
          : sound.assetPath;
      expect(source.path, expectedPath);
      verifyNever(() => player.resume());
    });

    test('play() resumes a prepared source with alarm usage', () async {
      final adapter = AudioplayersAdapter(player: player);
      final sound = AlarmSoundCatalog.defaultSound;

      await adapter.prepare(sound);
      await adapter.play(sound);

      expect(adapter.isPlaying, isTrue);
      final AudioContext context =
          verify(() => player.setAudioContext(captureAny())).captured.single
              as AudioContext;
      expect(context.android.usageType, AndroidUsageType.alarm);
      verify(() => player.resume()).called(1);
      verify(() => player.setSource(any())).called(1);
    });

    test('stop() marks not playing', () async {
      final adapter = AudioplayersAdapter(player: player);
      await adapter.play(AlarmSoundCatalog.defaultSound);
      expect(adapter.isPlaying, isTrue);

      await adapter.stop();
      expect(adapter.isPlaying, isFalse);
    });

    test('prepare中のstopを直列化し、古いprepare完了後に停止する', () async {
      final Completer<void> sourceGate = Completer<void>();
      when(() => player.setSource(any())).thenAnswer((_) => sourceGate.future);
      final adapter = AudioplayersAdapter(player: player);

      final Future<void> preparing = adapter.prepare(
        AlarmSoundCatalog.defaultSound,
      );
      await Future<void>.delayed(Duration.zero);
      final Future<void> stopping = adapter.stop();

      verify(() => player.stop()).called(1);
      sourceGate.complete();
      await preparing;
      await stopping;

      verify(() => player.stop()).called(1);
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
