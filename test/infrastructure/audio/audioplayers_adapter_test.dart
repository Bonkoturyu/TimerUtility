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

  void stubPlayer(_MockAudioPlayer target) {
    when(() => target.stop()).thenAnswer((_) async {});
    when(() => target.setAudioContext(any())).thenAnswer((_) async {});
    when(() => target.setReleaseMode(any())).thenAnswer((_) async {});
    when(() => target.setSource(any())).thenAnswer((_) async {});
    when(() => target.resume()).thenAnswer((_) async {});
    when(() => target.dispose()).thenAnswer((_) async {});
  }

  setUp(() {
    player = _MockAudioPlayer();
    stubPlayer(player);
  });

  group('AudioplayersAdapter', () {
    // The adapter intentionally does not subscribe to onPlayerStateChanged.
    // Construction would throw MissingStubError if that listener returned.
    test('初期状態では再生中ではない', () {
      final AudioplayersAdapter adapter = AudioplayersAdapter(player: player);

      expect(adapter.isPlaying, isFalse);
    });

    test('prepareはassets接頭辞を除いた音源を無音で準備する', () async {
      final AudioplayersAdapter adapter = AudioplayersAdapter(player: player);
      final sound = AlarmSoundCatalog.defaultSound;

      await adapter.prepare(sound);

      expect(adapter.isPlaying, isFalse);
      verify(() => player.setReleaseMode(ReleaseMode.loop)).called(1);
      final List<dynamic> captured = verify(
        () => player.setSource(captureAny()),
      ).captured;
      final AssetSource source = captured.single as AssetSource;
      final String expectedPath = sound.assetPath.startsWith('assets/')
          ? sound.assetPath.substring('assets/'.length)
          : sound.assetPath;
      expect(source.path, expectedPath);
      verifyNever(() => player.resume());
    });

    test('playは準備済み音源をalarm用途で再生する', () async {
      final AudioplayersAdapter adapter = AudioplayersAdapter(player: player);
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

    test('stopは再生状態を解除する', () async {
      final AudioplayersAdapter adapter = AudioplayersAdapter(player: player);
      await adapter.play(AlarmSoundCatalog.defaultSound);
      expect(adapter.isPlaying, isTrue);

      await adapter.stop();

      expect(adapter.isPlaying, isFalse);
    });

    test('prepareが停止中でもstopはキューを待たず世代を無効化する', () async {
      final Completer<void> sourceGate = Completer<void>();
      when(() => player.setSource(any())).thenAnswer((_) => sourceGate.future);
      final AudioplayersAdapter adapter = AudioplayersAdapter(player: player);

      final Future<void> preparing = adapter.prepare(
        AlarmSoundCatalog.defaultSound,
      );
      await Future<void>.delayed(Duration.zero);
      final Future<void> stopping = adapter.stop();

      await stopping;
      verify(() => player.stop()).called(2);
      sourceGate.complete();
      await preparing;

      expect(adapter.isPlaying, isFalse);
    });

    test('disposeはプレイヤーを解放して再生状態を解除する', () async {
      final AudioplayersAdapter adapter = AudioplayersAdapter(player: player);
      await adapter.play(AlarmSoundCatalog.defaultSound);

      await adapter.dispose();

      expect(adapter.isPlaying, isFalse);
      verify(() => player.dispose()).called(1);
    });

    test('取り込みIDは独立slotへDeviceFileSourceとして準備して再生する', () async {
      final _MockAudioPlayer selected = _MockAudioPlayer();
      stubPlayer(selected);
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selected,
        importedPathLookup: (String id) async => '/private/$id.mp3',
      );

      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('imported-1'),
        selectionTimeout: const Duration(seconds: 1),
      );
      await adapter.playPrepared();

      final Source selectedSource =
          verify(() => selected.setSource(captureAny())).captured.single
              as Source;
      expect(selectedSource, isA<DeviceFileSource>());
      expect(
        (selectedSource as DeviceFileSource).path,
        '/private/imported-1.mp3',
      );
      verify(() => selected.resume()).called(1);
      verifyNever(() => player.resume());
    });

    test('未確定stagingはalarm AudioContextで試聴する', () async {
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        stagedPathLookup: (String token) async => '/staging/$token.tmp',
      );

      await adapter.playStaged('stage-1');

      final Source source =
          verify(() => player.setSource(captureAny())).captured.single
              as Source;
      expect(source, isA<DeviceFileSource>());
      expect((source as DeviceFileSource).path, '/staging/stage-1.tmp');
      final AudioContext context =
          verify(() => player.setAudioContext(captureAny())).captured.single
              as AudioContext;
      expect(context.android.usageType, AndroidUsageType.alarm);
      verify(() => player.resume()).called(1);
    });

    test('取り込みファイル欠損時は準備済みdefaultを再生する', () async {
      final _MockAudioPlayer selected = _MockAudioPlayer();
      stubPlayer(selected);
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selected,
        importedPathLookup: (_) async => null,
      );

      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('missing'),
        selectionTimeout: const Duration(seconds: 1),
      );
      await adapter.playPrepared();

      verify(() => player.resume()).called(1);
      verifyNever(() => selected.resume());
      final Source fallback =
          verify(() => player.setSource(captureAny())).captured.single
              as Source;
      expect(fallback, isA<AssetSource>());
    });

    test('fallbackとselectedが停止中でも締切完了後は待たずに戻る', () async {
      final _MockAudioPlayer selected = _MockAudioPlayer();
      stubPlayer(selected);
      final Completer<void> fallbackGate = Completer<void>();
      final Completer<void> selectedGate = Completer<void>();
      final Completer<bool> deadlineGate = Completer<bool>();
      when(
        () => player.setSource(any()),
      ).thenAnswer((_) => fallbackGate.future);
      when(
        () => selected.setSource(any()),
      ).thenAnswer((_) => selectedGate.future);
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selected,
        importedPathLookup: (_) async => '/private/slow.mp3',
        selectionDeadline: (_, _) => deadlineGate.future,
      );

      final Future<void> preparing = adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('slow'),
        selectionTimeout: const Duration(seconds: 1),
      );
      await Future<void>.delayed(Duration.zero);
      deadlineGate.complete(false);

      await preparing.timeout(const Duration(seconds: 1));
      await adapter.playPrepared();
      verifyNever(() => player.resume());
      verifyNever(() => selected.resume());

      fallbackGate.complete();
      selectedGate.complete();
      await Future<void>.delayed(Duration.zero);
    });

    test('fallbackは選択締切後でもhandoff前に準備できれば再生する', () async {
      final _MockAudioPlayer selected = _MockAudioPlayer();
      stubPlayer(selected);
      final Completer<void> fallbackGate = Completer<void>();
      final Completer<void> selectedGate = Completer<void>();
      when(
        () => player.setSource(any()),
      ).thenAnswer((_) => fallbackGate.future);
      when(
        () => selected.setSource(any()),
      ).thenAnswer((_) => selectedGate.future);
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selected,
        importedPathLookup: (_) async => '/private/slow.mp3',
        selectionDeadline: (_, _) async => false,
      );

      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('slow'),
        selectionTimeout: const Duration(seconds: 1),
      );
      fallbackGate.complete();
      await Future<void>.delayed(Duration.zero);
      await adapter.playPrepared();

      verify(() => player.resume()).called(1);
      verifyNever(() => selected.resume());
      selectedGate.complete();
      await Future<void>.delayed(Duration.zero);
    });

    test('fallbackが停止中でも締切時点でreadyのselectedを再生する', () async {
      final _MockAudioPlayer selected = _MockAudioPlayer();
      stubPlayer(selected);
      final Completer<void> fallbackGate = Completer<void>();
      final Completer<void> selectedPrepared = Completer<void>();
      final Completer<bool> deadlineGate = Completer<bool>();
      when(
        () => player.setSource(any()),
      ).thenAnswer((_) => fallbackGate.future);
      when(() => selected.setSource(any())).thenAnswer((_) async {
        selectedPrepared.complete();
      });
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selected,
        importedPathLookup: (_) async => '/private/selected.mp3',
        selectionDeadline: (_, _) => deadlineGate.future,
      );

      final Future<void> preparing = adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('selected'),
        selectionTimeout: const Duration(seconds: 1),
      );
      await selectedPrepared.future;
      await Future<void>.delayed(Duration.zero);
      deadlineGate.complete(false);
      await preparing;
      await adapter.playPrepared();

      verify(() => selected.resume()).called(1);
      verifyNever(() => player.resume());
      fallbackGate.complete();
      await Future<void>.delayed(Duration.zero);
    });

    test('selectedのresume失敗時は境界時点でreadyのdefaultへfallbackする', () async {
      final _MockAudioPlayer selected = _MockAudioPlayer();
      stubPlayer(selected);
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selected,
      );
      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('gentle'),
        selectionTimeout: const Duration(seconds: 1),
      );
      when(() => selected.resume()).thenThrow(StateError('decode failure'));

      await adapter.playPrepared();

      verify(() => selected.resume()).called(1);
      verify(() => player.resume()).called(1);
      expect(adapter.isPlaying, isTrue);
    });

    test('selectedが停止中でも締切時点でreadyのfallbackを再生する', () async {
      final _MockAudioPlayer selected = _MockAudioPlayer();
      stubPlayer(selected);
      final Completer<void> fallbackPrepared = Completer<void>();
      final Completer<void> selectedGate = Completer<void>();
      final Completer<bool> deadlineGate = Completer<bool>();
      when(() => player.setSource(any())).thenAnswer((_) async {
        fallbackPrepared.complete();
      });
      when(
        () => selected.setSource(any()),
      ).thenAnswer((_) => selectedGate.future);
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selected,
        importedPathLookup: (_) async => '/private/selected.mp3',
        selectionDeadline: (_, _) => deadlineGate.future,
      );

      final Future<void> preparing = adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('selected'),
        selectionTimeout: const Duration(seconds: 1),
      );
      await fallbackPrepared.future;
      await Future<void>.delayed(Duration.zero);
      deadlineGate.complete(false);
      await preparing;
      await adapter.playPrepared();

      verify(() => player.resume()).called(1);
      verifyNever(() => selected.resume());
      selectedGate.complete();
      await Future<void>.delayed(Duration.zero);
    });

    test('締切後にselected準備が完了してもfallbackを上書きしない', () async {
      final _MockAudioPlayer selected = _MockAudioPlayer();
      stubPlayer(selected);
      final Completer<void> sourceGate = Completer<void>();
      when(
        () => selected.setSource(any()),
      ).thenAnswer((_) => sourceGate.future);
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selected,
        importedPathLookup: (_) async => '/private/slow.mp3',
        selectionDeadline: (_, _) async => false,
      );

      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('slow'),
        selectionTimeout: const Duration(seconds: 1),
      );
      sourceGate.complete();
      await Future<void>.delayed(Duration.zero);
      await adapter.playPrepared();

      verify(() => player.resume()).called(1);
      verifyNever(() => selected.resume());
    });

    test('resume停止中のstopは待たずに世代を無効化する', () async {
      final _MockAudioPlayer selected = _MockAudioPlayer();
      stubPlayer(selected);
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selected,
        importedPathLookup: (_) async => null,
      );
      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('missing'),
        selectionTimeout: const Duration(seconds: 1),
      );
      final Completer<void> resumeGate = Completer<void>();
      when(() => player.resume()).thenAnswer((_) => resumeGate.future);

      final Future<void> playing = adapter.playPrepared();
      await Future<void>.delayed(Duration.zero);
      final Future<void> stopping = adapter.stop();

      await stopping.timeout(const Duration(seconds: 1));
      expect(adapter.isPlaying, isFalse);
      resumeGate.complete();
      await playing;
      await Future<void>.delayed(Duration.zero);
      expect(adapter.isPlaying, isFalse);
      verify(() => player.resume()).called(1);
      verify(() => player.stop()).called(greaterThanOrEqualTo(3));
    });

    test('candidate破棄競合によるstop例外をUIへ伝播しない', () async {
      final _MockAudioPlayer selected = _MockAudioPlayer();
      stubPlayer(selected);
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selected,
      );
      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('gentle'),
        selectionTimeout: const Duration(seconds: 1),
      );
      when(() => player.stop()).thenThrow(StateError('fallback disposed'));
      when(() => selected.stop()).thenThrow(StateError('selected disposed'));

      await adapter.stop();

      expect(adapter.isPlaying, isFalse);
    });

    test('古いresume完了時のcleanupは新しいfallback再生を停止しない', () async {
      final _MockAudioPlayer firstSelected = _MockAudioPlayer();
      final _MockAudioPlayer secondSelected = _MockAudioPlayer();
      stubPlayer(firstSelected);
      stubPlayer(secondSelected);
      final List<_MockAudioPlayer> selectedPlayers = <_MockAudioPlayer>[
        firstSelected,
        secondSelected,
      ];
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => selectedPlayers.removeAt(0),
        importedPathLookup: (_) async => null,
      );
      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('missing-first'),
        selectionTimeout: const Duration(seconds: 1),
      );
      final Completer<void> firstResumeGate = Completer<void>();
      int resumeCalls = 0;
      when(() => player.resume()).thenAnswer((_) {
        resumeCalls++;
        return resumeCalls == 1 ? firstResumeGate.future : Future<void>.value();
      });

      final Future<void> stalePlay = adapter.playPrepared();
      await Future<void>.delayed(Duration.zero);
      await adapter.stop();
      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('missing-second'),
        selectionTimeout: const Duration(seconds: 1),
      );
      await adapter.playPrepared();
      expect(adapter.isPlaying, isTrue);
      clearInteractions(player);

      firstResumeGate.complete();
      await stalePlay;
      await Future<void>.delayed(Duration.zero);

      expect(adapter.isPlaying, isTrue);
      verifyNever(() => player.stop());
    });

    test('旧selectedのdispose失敗は次のhandoffを中断しない', () async {
      final _MockAudioPlayer firstSelected = _MockAudioPlayer();
      final _MockAudioPlayer secondSelected = _MockAudioPlayer();
      stubPlayer(firstSelected);
      stubPlayer(secondSelected);
      when(
        () => firstSelected.dispose(),
      ).thenAnswer((_) => Future<void>.error(StateError('dispose failure')));
      final List<_MockAudioPlayer> players = <_MockAudioPlayer>[
        firstSelected,
        secondSelected,
      ];
      final AudioplayersAdapter adapter = AudioplayersAdapter(
        player: player,
        playerFactory: () => players.removeAt(0),
      );

      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('gentle'),
        selectionTimeout: const Duration(seconds: 1),
      );
      await adapter.prepareForHandoff(
        requestedSoundId: Future<String>.value('warning'),
        selectionTimeout: const Duration(seconds: 1),
      );
      await adapter.playPrepared();

      verify(() => firstSelected.dispose()).called(1);
      verify(() => secondSelected.resume()).called(1);
    });
  });
}
