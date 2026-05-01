import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/alarm_ringing_notifier.dart';
import '../../application/timer_notifier.dart';
import '../../domain/timer/alarm_sound.dart';
import '../../domain/timer/alarm_sound_catalog.dart';
import '../../domain/timer/snooze_calculator.dart';

/// Native channel used to release the keyguard-override state set by
/// Android when this screen was launched via FullScreenIntent. Reuses
/// the existing permission channel rather than spinning up a second
/// channel just for one method.
const MethodChannel _permissionChannel = MethodChannel(
  'com.bonkotu.timer/permission',
);

/// Phase 5 ringing screen. Shown when a timer reaches `ringing` (either
/// via foreground tick or via tapping the OS notification). Lets the
/// user dismiss the alarm or request a snooze.
///
/// Snooze in Phase 5 is a flag only — actual rescheduling lands in
/// Phase 7 with `SnoozeCalculator`.
///
/// `initState` self-bootstraps `AlarmRingingNotifier.start` whenever the
/// notifier is still idle on entry. This covers the FSI / cold-start
/// paths where `TimerNotifier._onTick` either hasn't fired yet (background
/// → resume race) or never will (cold launch with no in-memory timer
/// state). Without this fallback the user lands on the ringing screen
/// after the bundled-sound notification gets cancelled, leaving them in
/// silence.
class AlarmRingingScreen extends ConsumerStatefulWidget {
  const AlarmRingingScreen({super.key});

  @override
  ConsumerState<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends ConsumerState<AlarmRingingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapRingingIfNeeded();
    });
  }

  /// Ensures audio is playing once we're on this screen. The foreground
  /// tick path may already have called `start`; in that case the notifier
  /// is idempotent and returns early.
  void _bootstrapRingingIfNeeded() {
    final ringing = ref.read(alarmRingingNotifierProvider);
    if (ringing.isPlaying) return;

    final entity = ref.read(timerNotifierProvider);
    final String timerId = entity?.id ?? 'unknown';
    final AlarmSound sound =
        (entity?.soundId == null
            ? null
            : AlarmSoundCatalog.findById(entity!.soundId!)) ??
        AlarmSoundCatalog.defaultSound;
    // Cold start may have lost the entity, so we have no notification id
    // to cancel. -1 is harmless: cancel on a non-existent id is a no-op
    // on Android, and the OS notification has typically already been
    // dismissed by the time we reach here on the cold-launch path.
    final int notificationId = entity?.notificationId ?? -1;

    ref
        .read(alarmRingingNotifierProvider.notifier)
        .start(timerId: timerId, sound: sound, notificationId: notificationId);
  }

  @override
  Widget build(BuildContext context) {
    final ringing = ref.read(alarmRingingNotifierProvider.notifier);
    final timer = ref.read(timerNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Alarm')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                "Time's up!",
                key: Key('alarm_ringing_title'),
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FilledButton(
                    key: const Key('alarm_stop_button'),
                    onPressed: () async {
                      await ringing.stop();
                      // Drop the timer entity so TimerScreen returns to the
                      // setup view rather than staying in "Time's up" state.
                      timer.clear();
                      if (!context.mounted) return;
                      _leaveAlarmScreen(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text('Stop', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('alarm_snooze_button'),
                    onPressed: () => _onSnoozeTap(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text('Snooze', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show the 3 / 5 / 10-minute snooze chooser, then arm the timer for
  /// re-fire. Stops the audioplayers loop synchronously so the user gets
  /// silence between dismiss and re-fire; AlarmRingingNotifier.start will
  /// be called again automatically by AlarmRingingScreen's self-bootstrap
  /// when the rescheduled notification fires.
  Future<void> _onSnoozeTap(BuildContext context) async {
    final int? minutes = await showModalBottomSheet<int>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'スヌーズ時間を選択',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              for (final int m in SnoozeCalculator.allowedMinutes) ...<Widget>[
                FilledButton(
                  key: Key('alarm_snooze_choice_${m}m'),
                  onPressed: () => Navigator.of(sheetContext).pop(m),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('$m 分', style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                key: const Key('alarm_snooze_cancel'),
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('キャンセル'),
              ),
            ],
          ),
        ),
      ),
    );

    if (minutes == null) return;
    if (!context.mounted) return;

    ref.read(timerNotifierProvider.notifier).snooze(minutes);
    _leaveAlarmScreen(context);
  }

  /// Leaves the alarm screen back to the timer setup view.
  ///
  /// We always `go('/timer')` rather than `pop()`-ing, even when there is
  /// a back stack: warm-launch from the notification can cause both
  /// `TimerScreen`'s ringing-listener (which `push`-es) and `main()`'s
  /// notification tap callback (which `go`-es) to fire, leaving two
  /// AlarmRingingScreen frames stacked. Popping only one of them would
  /// strand the user on a stale "Time's up" screen — so we replace the
  /// whole stack to guarantee the user lands on the preset chooser in
  /// one tap regardless of how they got here.
  ///
  /// Also releases the keyguard-override window flags that Android leaves
  /// set when the Activity was launched via FullScreenIntent. Without
  /// this, the recents (■) navigation button stays suppressed for the
  /// rest of the process lifetime.
  void _leaveAlarmScreen(BuildContext context) {
    // Fire-and-forget; missing-plugin / platform errors are non-fatal
    // (the worst outcome is the recents button stays hidden, which the
    // user can recover from by relaunching the app).
    _permissionChannel
        .invokeMethod<void>('clearShowWhenLocked')
        .catchError((_) {});
    context.go('/timer');
  }
}
