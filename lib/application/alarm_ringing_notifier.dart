import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/diagnostics/diagnostic_event.dart';
import '../domain/timer/alarm_sound.dart';
import 'alarm_sound_player_provider.dart';
import 'clock_provider.dart';
import 'diagnostic_logger_provider.dart';
import 'notification_scheduler_provider.dart';

part 'alarm_ringing_notifier.freezed.dart';
part 'alarm_ringing_notifier.g.dart';

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
///   - cancels ONLY the OS notification it is taking over from, so the
///     bundled-sound notification does not double up with the audioplayers
///     loop. Other lifecycle (scheduling, cancelAll) stays with
///     NotificationScheduler / TimerNotifier.
///
/// Phase 5 implements `start` and `stop`. `snoozeRequested` records intent
/// only — the actual reschedule happens in Phase 7 once `SnoozeCalculator`
/// is in place.
@Riverpod(keepAlive: true)
class AlarmRingingNotifier extends _$AlarmRingingNotifier {
  @override
  AlarmRingingState build() => AlarmRingingState.idle();

  /// Begin playing [sound] for the timer identified by [timerId].
  /// Replaces any in-progress playback.
  ///
  /// [notificationId] is the OS notification id for the firing timer. We
  /// cancel it here so the channel-bundled alarm tone (which the OS plays
  /// while Flutter was asleep) stops the moment audioplayers takes over —
  /// otherwise the user hears the same tone twice, slightly out of phase.
  /// Required because every entry path into the ringing state has a
  /// corresponding scheduled notification (foreground tick, FSI, cold
  /// launch).
  ///
  /// Phase 9.5: [source] で「タイマー由来」「アラーム由来」を区別する。
  /// 省略時は `AlarmSource.timer` (Phase 8 までの既存挙動を維持し、
  /// 既存呼び出し側 / テストとの後方互換を保つ)。
  Future<void> start({
    required String timerId,
    required AlarmSound sound,
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
    state = state.copyWith(
      isPlaying: true,
      snoozeRequested: false,
      currentTimerId: timerId,
      currentSoundId: sound.id,
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
    // Sequencing matters: cancel the OS notification first, wait briefly
    // so Pixel / Android 16 actually releases the alarm-stream tone (the
    // banner disappears immediately but the tone keeps going on its own
    // lifecycle for a few seconds), then start the audioplayers loop.
    // Without the delay the user hears a double tone on the snooze-fired
    // / heads-up-tap paths (#2 verification, 2026-05-02). 500 ms is the
    // empirical sweet spot — long enough for the OS tone to drop, short
    // enough that the foreground path (where cancel is a no-op) is not
    // perceptibly slower.
    await ref.read(notificationSchedulerProvider).cancel(notificationId);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await ref.read(alarmSoundPlayerProvider).play(sound);
  }

  /// Stop the ringing alarm and reset state to idle.
  Future<void> stop() async {
    state = AlarmRingingState.idle();
    unawaited(ref.read(alarmSoundPlayerProvider).stop());
  }

  /// Mark the snooze button as pressed and stop the audio.
  ///
  /// Phase 5 only flips the [AlarmRingingState.snoozeRequested] flag and
  /// stops playback. The downstream "reschedule the timer for N minutes
  /// later" behaviour is wired up in Phase 7.
  Future<void> snoozeRequested() async {
    state = state.copyWith(isPlaying: false, snoozeRequested: true);
    unawaited(ref.read(alarmSoundPlayerProvider).stop());
  }
}
