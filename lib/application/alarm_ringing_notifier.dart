import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/timer/alarm_sound.dart';
import 'alarm_sound_player_provider.dart';

part 'alarm_ringing_notifier.freezed.dart';
part 'alarm_ringing_notifier.g.dart';

/// State for [AlarmRingingNotifier]. Phase 5 only models a single ringing
/// timer at a time; multi-timer ringing is a Phase 8 concern.
@freezed
class AlarmRingingState with _$AlarmRingingState {
  const factory AlarmRingingState({
    required bool isPlaying,
    required bool snoozeRequested,
    String? currentTimerId,
    String? currentSoundId,
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
///   - does NOT cancel notifications (NotificationScheduler owns that)
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
  Future<void> start({
    required String timerId,
    required AlarmSound sound,
  }) async {
    state = state.copyWith(
      isPlaying: true,
      snoozeRequested: false,
      currentTimerId: timerId,
      currentSoundId: sound.id,
    );
    unawaited(ref.read(alarmSoundPlayerProvider).play(sound));
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
