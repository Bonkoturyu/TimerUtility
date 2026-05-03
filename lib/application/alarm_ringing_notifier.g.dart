// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_ringing_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$alarmRingingNotifierHash() =>
    r'c4c80b28cf9a27c2fd24cf4ecaaca4187115234a';

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
///
/// Copied from [AlarmRingingNotifier].
@ProviderFor(AlarmRingingNotifier)
final alarmRingingNotifierProvider =
    NotifierProvider<AlarmRingingNotifier, AlarmRingingState>.internal(
      AlarmRingingNotifier.new,
      name: r'alarmRingingNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$alarmRingingNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AlarmRingingNotifier = Notifier<AlarmRingingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
