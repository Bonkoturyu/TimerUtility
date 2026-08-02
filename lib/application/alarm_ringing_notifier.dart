import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/diagnostics/diagnostic_event.dart';
import '../domain/ports/alarm_sound_player.dart';
import '../domain/ports/notification_scheduler.dart';
import '../domain/timer/alarm_sound.dart';
import '../domain/timer/alarm_sound_catalog.dart';
import 'alarm_repository_provider.dart';
import 'alarm_sound_player_provider.dart';
import 'clock_provider.dart';
import 'diagnostic_logger_provider.dart';
import 'notification_scheduler_provider.dart';
import 'timer_repository_provider.dart';

part 'alarm_ringing_notifier.freezed.dart';
part 'alarm_ringing_notifier.g.dart';

/// Fixed OS cue → app-player handoff policy.
///
/// Pixel 6a / Android 16 measurements on 2026-07-15 placed OS cue completion
/// 2.97–3.12 seconds after the Flutter handoff sequence began. The extra
/// margin keeps decoder / scheduler jitter from reintroducing overlap. This
/// value depends only on the bundled cue, never on the selected loop length.
/// The provider also lets tests use a zero-duration boundary.
final Provider<Duration> alarmSoundHandoffDelayProvider = Provider<Duration>(
  (Ref ref) => const Duration(milliseconds: 3200),
);

/// Maximum time allowed for selected-source resolution and preparation.
///
/// A cold-start repository lookup may continue beyond this boundary so its
/// persisted notification id can still be cancelled. Only sound selection
/// falls back at the deadline. The bundled fallback is prepared independently,
/// so expiry never moves the fixed 3200 ms handoff boundary.
final Provider<Duration> alarmSoundSelectionTimeoutProvider =
    Provider<Duration>((Ref ref) => const Duration(milliseconds: 1000));

/// 鳴動の起動元 (Phase 9.5、ADR 0005 の payload prefix 方針に対応)。
/// - `timer`: 既存のカウントダウンタイマーが満了して鳴った場合
/// - `alarm`: 指定時刻アラームが鳴った場合
///
/// `AlarmRingingScreen` の Stop / Snooze ボタンはこの値で
/// `TimerCollectionNotifier` / `AlarmCollectionNotifier` のどちらに
/// 引き渡すかを分岐する。
enum AlarmSource { timer, alarm }

/// State for [AlarmRingingNotifier]. Phase 5 only models a single ringing
/// timer at a time; multi-timer ringing is a Phase 8 concern.
///
/// Phase 9.5: `currentSource` を追加 ([AlarmSource])。`currentTimerId`
/// はそのまま維持しつつ、source が alarm のときは alarm の id を保持する
/// ように使い分ける (フィールド名は ADR 0005 で「リネームしない」方針)。
@freezed
class AlarmRingingState with _$AlarmRingingState {
  const factory AlarmRingingState({
    required bool isPlaying,
    required bool snoozeRequested,
    String? currentTimerId,
    String? currentSoundId,
    AlarmSource? currentSource,
  }) = _AlarmRingingState;

  factory AlarmRingingState.idle() =>
      const AlarmRingingState(isPlaying: false, snoozeRequested: false);
}

/// Coordinates the alarm ringing experience: tells the [AlarmSoundPlayer]
/// what to play when a timer reaches `ringing`, and exposes user actions
/// (stop / snooze) to the UI.
///
/// Responsibilities are intentionally narrow per `docs/state-management.md`:
///   - manages the currently ringing timer's metadata and player state
///   - does NOT modify timer state (TimerNotifier owns that)
///   - cancels ONLY the OS notification it is taking over from, prepares the
///     selected sound during the fixed OS cue, and starts it after handoff.
///     Other lifecycle (scheduling, cancelAll) stays with
///     NotificationScheduler / TimerNotifier.
///
/// Phase 5 implements `start` and `stop`. `snoozeRequested` records intent
/// only — the actual reschedule happens in Phase 7 once `SnoozeCalculator`
/// is in place.
@Riverpod(keepAlive: true)
class AlarmRingingNotifier extends _$AlarmRingingNotifier {
  int _playbackGeneration = 0;

  @override
  AlarmRingingState build() => AlarmRingingState.idle();

  /// Begin playing [sound] for the timer identified by [timerId].
  /// Replaces any in-progress playback.
  ///
  /// [notificationId] is the OS notification id for the firing timer. The
  /// notification uses a short, self-terminating cue. While that cue plays,
  /// this notifier prepares [sound], then starts it after a fixed handoff
  /// window so the OS player and audioplayers never own audible output at
  /// the same time.
  ///
  /// Phase 9.5: [source] で「タイマー由来」「アラーム由来」を区別する。
  /// 省略時は `AlarmSource.timer` (Phase 8 までの既存挙動を維持し、
  /// 既存呼び出し側 / テストとの後方互換を保つ)。
  ///
  /// Issue #86 Phase A: `cancel(notificationId)` does not stop a channel
  /// sound already owned by Android. The handoff therefore waits for the
  /// fixed cue to finish instead of inferring completion from notification
  /// cancellation or keyguard state.
  Future<void> start({
    required String timerId,
    AlarmSound? sound,
    String? soundId,
    required int notificationId,
    AlarmSource source = AlarmSource.timer,
  }) async {
    // Idempotent: AlarmRingingScreen self-bootstraps on mount, and
    // TimerNotifier._onTick also calls start when the foreground ticker
    // detects the ringing transition. Whichever fires first wins; the
    // second call is dropped so we don't re-trigger play / cancel.
    if (state.isPlaying) {
      return;
    }
    if (sound == null && soundId == null && timerId == 'unknown') {
      soundId = AlarmSoundCatalog.defaultSound.id;
    }
    final int generation = ++_playbackGeneration;
    final String? knownSoundId = soundId ?? sound?.id;
    state = state.copyWith(
      isPlaying: true,
      snoozeRequested: false,
      currentTimerId: timerId,
      currentSoundId: knownSoundId,
      currentSource: source,
    );
    // Plan の確定仕様: 通知発火ログは AlarmRingingNotifier.start で出す
    // (Infrastructure 層を触らずに済む経路)。`source` を見て timer 由来か
    // alarm 由来かを区別する。
    ref
        .read(diagnosticLoggerProvider)
        .log(
          DiagnosticEvent.notificationFired(
            occurredAt: ref.read(clockProvider).now(),
            payloadId: timerId,
            fireKind: source == AlarmSource.alarm
                ? NotificationFireKind.alarmFired
                : NotificationFireKind.timerFired,
          ),
        );
    final NotificationScheduler scheduler = ref.read(
      notificationSchedulerProvider,
    );
    if (scheduler is NativeAlarmPlaybackController) {
      final bool nativePlayback =
          await (scheduler as NativeAlarmPlaybackController)
              .ensureNativePlayback(notificationId);
      if (!_isCurrent(generation, timerId)) {
        if (nativePlayback) {
          await (scheduler as NativeAlarmPlaybackController)
              .stopNativePlayback();
        }
        return;
      }
      if (nativePlayback) return;
    }
    // Start the cue window immediately. Cancellation only removes the
    // notification UI; Pixel 6a / Android 16 measurements showed that it
    // does not stop the OS-owned sound. Preparing in parallel hides decoder
    // startup latency without producing audible output.
    final Future<void> handoffWindow = Future<void>.delayed(
      ref.read(alarmSoundHandoffDelayProvider),
    );
    final AlarmSoundPlayer player = ref.read(alarmSoundPlayerProvider);
    final Duration selectionTimeout = ref.read(
      alarmSoundSelectionTimeoutProvider,
    );
    // Keep the repository lookup alive beyond the sound-selection deadline.
    // Cold launch does not have an in-memory notification id; discarding this
    // future at the timeout would leave the persisted OS notification active.
    final Future<_AlarmRingingTarget> rawTarget =
        _resolveTarget(
          timerId: timerId,
          source: source,
          knownSoundId: knownSoundId,
          knownNotificationId: notificationId,
        ).catchError(
          (Object _) => _AlarmRingingTarget(
            soundId: knownSoundId ?? AlarmSoundCatalog.defaultSound.id,
            notificationId: notificationId,
          ),
        );
    final Future<String> selectedSoundId = rawTarget
        .then((_AlarmRingingTarget resolved) => resolved.soundId)
        .timeout(
          selectionTimeout,
          onTimeout: () => AlarmSoundCatalog.defaultSound.id,
        )
        .catchError((Object _) => AlarmSoundCatalog.defaultSound.id);
    unawaited(
      selectedSoundId
          .then((String resolvedSoundId) {
            if (!_isCurrent(generation, timerId)) return;
            state = state.copyWith(currentSoundId: resolvedSoundId);
          })
          .catchError((Object _) {}),
    );
    unawaited(
      rawTarget
          .then((_AlarmRingingTarget resolved) async {
            if (resolved.notificationId < 0) return;
            // This notification belongs to the start request that initiated
            // the lookup. Dismissal may make the playback generation stale
            // before a cold-start repository lookup completes, but the OS
            // notification still requires cleanup.
            await ref
                .read(notificationSchedulerProvider)
                .cancel(resolved.notificationId);
          })
          .catchError((Object _) {}),
    );
    AlarmSound? legacyPrepared;
    final HandoffAlarmSoundPlayer? handoffPlayer =
        player is HandoffAlarmSoundPlayer
        ? player as HandoffAlarmSoundPlayer
        : null;
    if (handoffPlayer != null) {
      await handoffPlayer.prepareForHandoff(
        requestedSoundId: selectedSoundId,
        selectionTimeout: selectionTimeout,
      );
    } else {
      final String resolvedId = await selectedSoundId;
      legacyPrepared =
          AlarmSoundCatalog.findById(resolvedId) ??
          AlarmSoundCatalog.defaultSound;
      await player.prepare(legacyPrepared);
    }
    if (!_isCurrent(generation, timerId)) return;
    await handoffWindow;
    if (!_isCurrent(generation, timerId)) return;
    // Issue #86 instrumentation: mark when audioplayers playback is
    // *requested* — the clock reading taken immediately before the
    // `player.play()` call below, after the cancel→delay sequence and the
    // pre-play guard. This is the play-request time, NOT the audible onset
    // (the actual sound lags by the audioplayers / OS playout latency).
    // Paired with the start-of-sequence `notificationFired` log (≈ cancel
    // time) this brackets the cancel→play-request interval, so the
    // double-tone investigation can line up the play request against the OS
    // alarm-stream tone release seen in `dumpsys`. Logged only on the path
    // that actually plays — a dismiss during the delay returns above and
    // emits nothing, keeping the breadcrumb count == real playbacks.
    ref
        .read(diagnosticLoggerProvider)
        .log(
          DiagnosticEvent.timerAction(
            occurredAt: ref.read(clockProvider).now(),
            timerId: timerId,
            action: TimerActionKind.alarmPlaybackStart,
          ),
        );
    if (handoffPlayer != null) {
      await handoffPlayer.playPrepared();
    } else {
      await player.play(legacyPrepared ?? AlarmSoundCatalog.defaultSound);
    }
    if (_isCurrent(generation, timerId) && !player.isPlaying) {
      // Both selected and default can fail at the platform resume boundary.
      // Keep Notifier state truthful so a subsequent start may retry instead
      // of being dropped by the idempotence guard.
      state = state.copyWith(isPlaying: false);
    }
    // Second race window (beyond the pre-play guard on L151): stop() /
    // snoozeRequested() can flip the state back to idle *during* the
    // `await play(sound)` async gap. If that happened, the player is now
    // looping with nobody left to stop it — the alarm would keep ringing
    // even though the user dismissed it. Re-check and stop so the audio
    // can never outlive the ringing state.
    if (!_isCurrent(generation, timerId) && !state.isPlaying) {
      await player.stop();
    }
  }

  Future<_AlarmRingingTarget> _resolveTarget({
    required String timerId,
    required AlarmSource source,
    required String? knownSoundId,
    required int knownNotificationId,
  }) async {
    if (knownSoundId != null && knownNotificationId >= 0) {
      return _AlarmRingingTarget(
        soundId: knownSoundId,
        notificationId: knownNotificationId,
      );
    }
    if (source == AlarmSource.alarm) {
      final alarm = await ref.read(alarmRepositoryProvider).findById(timerId);
      return _AlarmRingingTarget(
        soundId:
            knownSoundId ?? alarm?.soundId ?? AlarmSoundCatalog.defaultSound.id,
        notificationId: knownNotificationId >= 0
            ? knownNotificationId
            : alarm?.notificationId ?? knownNotificationId,
      );
    }
    final timer = await ref.read(timerRepositoryProvider).findById(timerId);
    return _AlarmRingingTarget(
      soundId:
          knownSoundId ?? timer?.soundId ?? AlarmSoundCatalog.defaultSound.id,
      notificationId: knownNotificationId >= 0
          ? knownNotificationId
          : timer?.notificationId ?? knownNotificationId,
    );
  }

  bool _isCurrent(int generation, String timerId) =>
      generation == _playbackGeneration &&
      state.isPlaying &&
      state.currentTimerId == timerId;

  /// Stop the ringing alarm and reset state to idle.
  ///
  /// Awaits the player stop (rather than fire-and-forget) so the ordering
  /// is deterministic against a concurrent `start()`: the post-play guard
  /// in `start()` relies on `stop()` having actually settled the player.
  Future<void> stop() async {
    _playbackGeneration++;
    state = AlarmRingingState.idle();
    await _stopPlayers();
  }

  /// Mark the snooze button as pressed and stop the audio.
  ///
  /// Phase 5 only flips the [AlarmRingingState.snoozeRequested] flag and
  /// stops playback. The downstream "reschedule the timer for N minutes
  /// later" behaviour is wired up in Phase 7.
  Future<void> snoozeRequested() async {
    _playbackGeneration++;
    state = state.copyWith(isPlaying: false, snoozeRequested: true);
    await _stopPlayers();
  }

  Future<void> _stopPlayers() async {
    final NotificationScheduler scheduler = ref.read(
      notificationSchedulerProvider,
    );
    await Future.wait<void>(<Future<void>>[
      ref.read(alarmSoundPlayerProvider).stop(),
      if (scheduler is NativeAlarmPlaybackController)
        (scheduler as NativeAlarmPlaybackController).stopNativePlayback(),
    ]);
  }
}

class _AlarmRingingTarget {
  const _AlarmRingingTarget({
    required this.soundId,
    required this.notificationId,
  });

  final String soundId;
  final int notificationId;
}
