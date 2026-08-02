import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../domain/ports/alarm_sound_player.dart';
import '../../domain/sound/imported_sound_exceptions.dart';
import '../../domain/timer/alarm_sound.dart';
import '../../domain/timer/alarm_sound_catalog.dart';

typedef AudioPlayerFactory = AudioPlayer Function();
typedef ImportedAlarmSoundPathLookup = Future<String?> Function(String soundId);
typedef StagedImportedSoundPathLookup =
    Future<String?> Function(String stagingToken);
typedef AlarmSoundSelectionDeadline =
    Future<bool> Function(Future<bool> operation, Duration timeout);

AudioPlayer _newAudioPlayer() => AudioPlayer();

Future<bool> _defaultSelectionDeadline(
  Future<bool> operation,
  Duration timeout,
) => operation.timeout(timeout, onTimeout: () => false);

/// Concrete [AlarmSoundPlayer] backed by the `audioplayers` package.
///
/// Normal bundled playback keeps the original single-player behavior. The
/// alarm handoff path uses two independent players: the bundled default is
/// prepared immediately, while the requested bundled/imported source gets a
/// bounded candidate slot. A timed-out candidate can finish late only on its
/// own disposed player and therefore cannot overwrite the fallback source.
class AudioplayersAdapter
    implements
        AlarmSoundPlayer,
        VolumeControlledAlarmSoundPlayer,
        HandoffAlarmSoundPlayer,
        ImportedSoundPreviewPlayer,
        StagedImportedSoundPreviewPlayer {
  AudioplayersAdapter({
    AudioPlayer? player,
    AudioPlayerFactory? playerFactory,
    ImportedAlarmSoundPathLookup? importedPathLookup,
    StagedImportedSoundPathLookup? stagedPathLookup,
    AlarmSoundSelectionDeadline? selectionDeadline,
  }) : _player = player ?? AudioPlayer(),
       _playerFactory = playerFactory ?? _newAudioPlayer,
       _importedPathLookup = importedPathLookup,
       _stagedPathLookup = stagedPathLookup,
       _selectionDeadline = selectionDeadline ?? _defaultSelectionDeadline;

  final AudioPlayer _player;
  final AudioPlayerFactory _playerFactory;
  final ImportedAlarmSoundPathLookup? _importedPathLookup;
  final StagedImportedSoundPathLookup? _stagedPathLookup;
  final AlarmSoundSelectionDeadline _selectionDeadline;

  Future<void> _operation = Future<void>.value();
  String? _preparedSoundId;
  AudioPlayer? _selectedPlayer;
  bool _fallbackReady = false;
  bool _selectedReady = false;
  int _selectionGeneration = 0;
  int? _fallbackPlayGeneration;
  bool _isPlaying = false;
  double _volume = 1.0;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> setVolumePercent(int percent) async {
    if (percent < 0 || percent > 100) {
      throw ArgumentError.value(
        percent,
        'percent',
        'must be between 0 and 100',
      );
    }
    _volume = percent / 100;
    final AudioPlayer? selected = _selectedPlayer;
    await Future.wait<void>(<Future<void>>[
      _player.setVolume(_volume),
      if (selected != null && !identical(selected, _player))
        selected.setVolume(_volume),
    ]);
  }

  @override
  Future<void> prepare(AlarmSound sound) {
    final int generation = ++_selectionGeneration;
    return _enqueue(() async {
      await _prepare(sound, generation);
    });
  }

  @override
  Future<void> play(AlarmSound sound) {
    final int generation = ++_selectionGeneration;
    return _enqueue(() async {
      if (generation != _selectionGeneration) return;
      if (_preparedSoundId != sound.id) {
        await _prepare(sound, generation);
      }
      if (generation != _selectionGeneration) return;
      _fallbackPlayGeneration = generation;
      await _player.resume();
      if (generation != _selectionGeneration) {
        if (_fallbackPlayGeneration == generation) {
          _stopBestEffort(_player);
        }
        return;
      }
      _isPlaying = true;
    });
  }

  @override
  Future<void> playImported(String soundId) {
    final int generation = ++_selectionGeneration;
    return _enqueue(() async {
      final ImportedAlarmSoundPathLookup? lookup = _importedPathLookup;
      if (generation != _selectionGeneration) return;
      if (lookup == null) throw ImportedSoundNotFoundException(soundId);
      final String? path = await lookup(soundId);
      if (generation != _selectionGeneration) return;
      if (path == null) throw ImportedSoundNotFoundException(soundId);
      final bool ready = await _prepareSource(
        _player,
        DeviceFileSource(path),
        generation: generation,
      );
      if (!ready || generation != _selectionGeneration) return;
      _fallbackPlayGeneration = generation;
      await _player.resume();
      if (generation != _selectionGeneration) {
        if (_fallbackPlayGeneration == generation) _stopBestEffort(_player);
        return;
      }
      _preparedSoundId = soundId;
      _isPlaying = true;
    });
  }

  @override
  Future<void> playStaged(String stagingToken) {
    final int generation = ++_selectionGeneration;
    return _enqueue(() async {
      final StagedImportedSoundPathLookup? lookup = _stagedPathLookup;
      final String? path = lookup == null ? null : await lookup(stagingToken);
      if (path == null || generation != _selectionGeneration) return;
      final bool ready = await _prepareSource(
        _player,
        DeviceFileSource(path),
        generation: generation,
      );
      if (!ready || generation != _selectionGeneration) return;
      _fallbackPlayGeneration = generation;
      await _player.resume();
      if (generation != _selectionGeneration) {
        if (_fallbackPlayGeneration == generation) _stopBestEffort(_player);
        return;
      }
      _preparedSoundId = stagingToken;
      _isPlaying = true;
    });
  }

  @override
  Future<void> prepareForHandoff({
    required Future<String> requestedSoundId,
    required Duration selectionTimeout,
  }) async {
    final int generation = ++_selectionGeneration;
    _fallbackReady = false;
    _selectedReady = false;
    _preparedSoundId = null;
    _isPlaying = false;
    final AudioPlayer? previousSelected = _selectedPlayer;
    _selectedPlayer = null;
    if (previousSelected != null) _disposeBestEffort(previousSelected);

    final AudioPlayer candidate = _playerFactory();
    _selectedPlayer = candidate;
    bool selectedPreparationOpen = true;
    final Future<bool> fallbackPreparation = _prepareFallback(generation).then((
      bool ready,
    ) {
      // The selected-source deadline must not discard a default source that
      // becomes ready later but still before the fixed 3200 ms handoff.
      // playPrepared() snapshots readiness at the handoff boundary, so this
      // callback never starts playback by itself.
      if (ready && generation == _selectionGeneration) {
        _fallbackReady = true;
        _preparedSoundId = AlarmSoundCatalog.defaultSound.id;
      }
      return ready;
    });
    final Future<bool> selectedPreparation =
        _prepareSelected(candidate, requestedSoundId).then((bool ready) {
          if (ready &&
              selectedPreparationOpen &&
              generation == _selectionGeneration &&
              identical(_selectedPlayer, candidate)) {
            _selectedReady = true;
          }
          return ready;
        });

    try {
      await _selectionDeadline(
        Future.wait<bool>(<Future<bool>>[
          fallbackPreparation,
          selectedPreparation,
        ]).then((_) => true),
        selectionTimeout,
      );
    } finally {
      selectedPreparationOpen = false;
      if (generation != _selectionGeneration || !_selectedReady) {
        if (identical(_selectedPlayer, candidate)) _selectedPlayer = null;
        _disposeBestEffort(candidate);
      }
    }
  }

  @override
  Future<void> playPrepared() async {
    final int generation = _selectionGeneration;
    final AudioPlayer? selected = _selectedReady ? _selectedPlayer : null;
    final AudioPlayer? fallback = _fallbackReady ? _player : null;

    if (selected != null) {
      final bool selectedStarted = await _resumePreparedSlot(
        selected,
        generation,
        usesFallback: false,
      );
      if (generation != _selectionGeneration) return;
      if (selectedStarted) {
        _isPlaying = true;
        return;
      }
      _selectedReady = false;
    }

    if (fallback == null) {
      _isPlaying = false;
      return;
    }
    final bool fallbackStarted = await _resumePreparedSlot(
      fallback,
      generation,
      usesFallback: true,
    );
    if (generation != _selectionGeneration) return;
    _isPlaying = fallbackStarted;
  }

  @override
  Future<void> stop() async {
    _selectionGeneration++;
    _fallbackReady = false;
    _selectedReady = false;
    _isPlaying = false;
    final AudioPlayer? selected = _selectedPlayer;
    await Future.wait<void>(<Future<void>>[
      _stopAndWaitBestEffort(_player),
      if (selected != null && !identical(selected, _player))
        _stopAndWaitBestEffort(selected),
    ]);
  }

  @override
  Future<void> dispose() async {
    _selectionGeneration++;
    final AudioPlayer? selected = _selectedPlayer;
    _selectedPlayer = null;
    _isPlaying = false;
    _fallbackPlayGeneration = null;
    _preparedSoundId = null;
    _fallbackReady = false;
    _selectedReady = false;
    await Future.wait<void>(<Future<void>>[
      _player.dispose(),
      if (selected != null && !identical(selected, _player)) selected.dispose(),
    ]);
  }

  Future<void> _prepare(AlarmSound sound, int generation) async {
    final bool ready = await _prepareSource(
      _player,
      _assetSource(sound),
      generation: generation,
    );
    if (ready && generation == _selectionGeneration) {
      _preparedSoundId = sound.id;
    }
  }

  Future<bool> _prepareFallback(int generation) async {
    try {
      return await _prepareSource(
        _player,
        _assetSource(AlarmSoundCatalog.defaultSound),
        generation: generation,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> _prepareSelected(
    AudioPlayer player,
    Future<String> requestedSoundId,
  ) async {
    try {
      final String soundId = await requestedSoundId;
      final AlarmSound? bundled = AlarmSoundCatalog.findById(soundId);
      if (bundled != null) {
        if (bundled.id == AlarmSoundCatalog.defaultSound.id) return false;
        return await _prepareSource(player, _assetSource(bundled));
      }
      final ImportedAlarmSoundPathLookup? lookup = _importedPathLookup;
      if (lookup == null) return false;
      final String? path = await lookup(soundId);
      if (path == null) return false;
      return await _prepareSource(player, DeviceFileSource(path));
    } catch (_) {
      return false;
    }
  }

  Future<bool> _resumePreparedSlot(
    AudioPlayer player,
    int generation, {
    required bool usesFallback,
  }) async {
    if (usesFallback) _fallbackPlayGeneration = generation;
    try {
      await player.resume();
    } catch (_) {
      return false;
    }
    if (generation != _selectionGeneration) {
      // A stale resume on the shared fallback slot must be stopped unless a
      // newer generation has already started that same slot. Stopping it in
      // the latter case would silence the newly-ringing alarm.
      if (!usesFallback || _fallbackPlayGeneration == generation) {
        _stopBestEffort(player);
      }
      return false;
    }
    return true;
  }

  Future<bool> _prepareSource(
    AudioPlayer player,
    Source source, {
    int? generation,
  }) async {
    bool isCurrent() =>
        generation == null || generation == _selectionGeneration;

    if (!isCurrent()) return false;
    await player.stop();
    if (!isCurrent()) return false;
    await player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
          stayAwake: true,
        ),
      ),
    );
    if (!isCurrent()) return false;
    await player.setReleaseMode(ReleaseMode.loop);
    if (!isCurrent()) return false;
    await player.setVolume(_volume);
    if (!isCurrent()) return false;
    await player.setSource(source);
    return isCurrent();
  }

  AssetSource _assetSource(AlarmSound sound) {
    final String path = sound.assetPath.startsWith('assets/')
        ? sound.assetPath.substring('assets/'.length)
        : sound.assetPath;
    return AssetSource(path);
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final Future<void> result = _operation.then((_) => operation());
    _operation = result.catchError((Object _) {});
    return result;
  }

  void _disposeBestEffort(AudioPlayer player) {
    try {
      unawaited(player.dispose().catchError((Object _, StackTrace _) {}));
    } catch (_) {
      // Cleanup must never abort a newer handoff.
    }
  }

  void _stopBestEffort(AudioPlayer player) {
    try {
      unawaited(player.stop().catchError((Object _, StackTrace _) {}));
    } catch (_) {
      // A stale resume must not change the result of the newer operation.
    }
  }

  Future<void> _stopAndWaitBestEffort(AudioPlayer player) async {
    try {
      await player.stop();
    } catch (_) {
      // A concurrent timeout may already have disposed the candidate slot.
      // Playback state and generation are invalidated synchronously above.
    }
  }
}
