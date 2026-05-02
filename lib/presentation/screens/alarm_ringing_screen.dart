import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/alarm_ringing_notifier.dart';
import '../../application/timer_collection_notifier.dart';
import '../../domain/timer/alarm_sound.dart';
import '../../domain/timer/alarm_sound_catalog.dart';
import '../../domain/timer/snooze_calculator.dart';
import '../../domain/timer/timer_entity.dart';
import '../../l10n/app_localizations.dart';

/// Native channel used to release the keyguard-override state set by
/// Android when this screen was launched via FullScreenIntent. Reuses
/// the existing permission channel rather than spinning up a second
/// channel just for one method.
const MethodChannel _permissionChannel = MethodChannel(
  'com.bonkotu.timer/permission',
);

/// Phase 8 ringing screen. Reads the currently ringing timer from
/// [TimerCollectionNotifier]. If multiple timers ring concurrently we
/// service the first one in collection order — Stop / Snooze still
/// only act on that single entry, so a second ringing timer surfaces
/// once the user dismisses this one.
///
/// `initState` self-bootstraps `AlarmRingingNotifier.start` whenever
/// the notifier is still idle on entry, covering the FSI / cold-start
/// paths where the foreground tick path either hasn't fired or doesn't
/// know which timer fired (cold launch with no in-memory state). When
/// no ringing timer is found in the collection, we still bootstrap
/// audio with a synthetic 'unknown' id so the user is never met with
/// silence on this screen.
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

  void _bootstrapRingingIfNeeded() {
    final ringing = ref.read(alarmRingingNotifierProvider);
    if (ringing.isPlaying) return;

    final TimerEntity? entity = ref
        .read(timerCollectionNotifierProvider.notifier)
        .findRinging();
    final String timerId = entity?.id ?? 'unknown';
    final AlarmSound sound =
        (entity?.soundId == null
            ? null
            : AlarmSoundCatalog.findById(entity!.soundId!)) ??
        AlarmSoundCatalog.defaultSound;
    // Cold start may have lost the entity, so we have no notification id
    // to cancel. -1 is harmless: cancel on a non-existent id is a no-op
    // on Android.
    final int notificationId = entity?.notificationId ?? -1;

    ref
        .read(alarmRingingNotifierProvider.notifier)
        .start(timerId: timerId, sound: sound, notificationId: notificationId);
  }

  @override
  Widget build(BuildContext context) {
    final ringingNotifier = ref.read(alarmRingingNotifierProvider.notifier);
    final collection = ref.read(timerCollectionNotifierProvider.notifier);
    final AppLocalizations l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.alarmAppBarTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                l.alarmTimesUp,
                key: const Key('alarm_ringing_title'),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FilledButton(
                    key: const Key('alarm_stop_button'),
                    onPressed: () async {
                      await ringingNotifier.stop();
                      // Cancel the ringing timer (if any) so the list
                      // moves it to `cancelled` and the OS notification
                      // is taken down.
                      final TimerEntity? ringing = collection.findRinging();
                      if (ringing != null) {
                        collection.cancel(ringing.id);
                      }
                      if (!context.mounted) return;
                      _leaveAlarmScreen(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text(
                        l.alarmStop,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('alarm_snooze_button'),
                    onPressed: () => _onSnoozeTap(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text(
                        l.alarmSnooze,
                        style: const TextStyle(fontSize: 18),
                      ),
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

  Future<void> _onSnoozeTap(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final int? minutes = await showModalBottomSheet<int>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l.alarmSnoozePickerTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final int m in SnoozeCalculator.allowedMinutes) ...<Widget>[
                FilledButton(
                  key: Key('alarm_snooze_choice_${m}m'),
                  onPressed: () => Navigator.of(sheetContext).pop(m),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l.alarmSnoozeMinutes(m),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                key: const Key('alarm_snooze_cancel'),
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(l.alarmSnoozeCancel),
              ),
            ],
          ),
        ),
      ),
    );

    if (minutes == null) return;
    if (!context.mounted) return;

    final collection = ref.read(timerCollectionNotifierProvider.notifier);
    final TimerEntity? ringing = collection.findRinging();
    if (ringing == null) return;
    await ref.read(alarmRingingNotifierProvider.notifier).stop();
    collection.snooze(ringing.id, minutes);
    if (!context.mounted) return;
    _leaveAlarmScreen(context);
  }

  /// Leaves the alarm screen back to the timer list view.
  ///
  /// We always `go('/timer')` rather than `pop()`-ing for the same
  /// reason as Phase 5: warm-launch from notification can stack two
  /// frames (TimerListScreen ringing listener + main()'s tap callback),
  /// and we want a single source of truth for "after Stop you land on
  /// the list view".
  void _leaveAlarmScreen(BuildContext context) {
    _permissionChannel
        .invokeMethod<void>('clearShowWhenLocked')
        .catchError((_) {});
    context.go('/timer');
  }
}
