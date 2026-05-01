import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/alarm_ringing_notifier.dart';
import '../../application/timer_notifier.dart';

/// Phase 5 ringing screen. Shown when a timer reaches `ringing` (either
/// via foreground tick or via tapping the OS notification). Lets the
/// user dismiss the alarm or request a snooze.
///
/// Snooze in Phase 5 is a flag only — actual rescheduling lands in
/// Phase 7 with `SnoozeCalculator`.
class AlarmRingingScreen extends ConsumerWidget {
  const AlarmRingingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alarmRingingNotifierProvider);
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
              const SizedBox(height: 16),
              Text(
                state.currentTimerId == null
                    ? 'No active timer'
                    : 'Timer: ${state.currentTimerId}',
                key: const Key('alarm_ringing_label'),
                style: const TextStyle(fontSize: 16),
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
                    onPressed: () async {
                      await ringing.snoozeRequested();
                      // Phase 5 snooze is intent-only; treat dismissal the
                      // same as Stop until Phase 7 wires up rescheduling.
                      timer.clear();
                      if (!context.mounted) return;
                      _leaveAlarmScreen(context);
                    },
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
  void _leaveAlarmScreen(BuildContext context) {
    context.go('/timer');
  }
}
