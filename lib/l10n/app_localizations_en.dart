// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TimerUtility';

  @override
  String get homeOpenStopwatch => 'Open Stopwatch';

  @override
  String get homeOpenTimer => 'Open Timer';

  @override
  String get stopwatchAppBarTitle => 'Stopwatch';

  @override
  String get stopwatchStart => 'Start';

  @override
  String get stopwatchPause => 'Pause';

  @override
  String get stopwatchResume => 'Resume';

  @override
  String get stopwatchLap => 'Lap';

  @override
  String get stopwatchReset => 'Reset';

  @override
  String get stopwatchNoLaps => 'No laps recorded';

  @override
  String stopwatchLapLabel(int index) {
    return 'Lap $index';
  }

  @override
  String stopwatchSplit(String time) {
    return 'Split $time';
  }

  @override
  String stopwatchTotal(String time) {
    return 'Total $time';
  }

  @override
  String get timerListAppBarTitle => 'Timers';

  @override
  String get timerListAddFab => 'Add Timer';

  @override
  String get timerListEmptyHint =>
      'No timers yet.\nTap “Add Timer” at the bottom-right to create one.';

  @override
  String timerListLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Limit reached: $count timers',
      one: 'Limit reached: 1 timer',
    );
    return '$_temp0';
  }

  @override
  String get timerCardTimesUp => 'Time\'s up!';

  @override
  String get timerCardActionStart => 'Start';

  @override
  String get timerCardActionPause => 'Pause';

  @override
  String get timerCardActionResume => 'Resume';

  @override
  String get timerCardActionDismiss => 'Dismiss';

  @override
  String get timerCardActionReset => 'Reset';

  @override
  String get timerCardActionDelete => 'Delete';

  @override
  String get timerStatusIdle => 'idle';

  @override
  String get timerStatusRunning => 'running';

  @override
  String get timerStatusPaused => 'paused';

  @override
  String get timerStatusRinging => 'ringing';

  @override
  String get timerStatusCompleted => 'completed';

  @override
  String get timerStatusCancelled => 'cancelled';

  @override
  String get alarmAppBarTitle => 'Alarm';

  @override
  String get alarmTimesUp => 'Time\'s up!';

  @override
  String get alarmStop => 'Stop';

  @override
  String get alarmSnooze => 'Snooze';

  @override
  String get alarmSnoozePickerTitle => 'Choose snooze duration';

  @override
  String alarmSnoozeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get alarmSnoozeCancel => 'Cancel';

  @override
  String get durationPickerTitle => 'Choose custom duration';

  @override
  String get durationPickerHours => 'h';

  @override
  String get durationPickerMinutes => 'm';

  @override
  String get durationPickerSeconds => 's';

  @override
  String get durationPickerCancel => 'Cancel';

  @override
  String get durationPickerConfirm => 'Confirm';

  @override
  String get permissionBannerNotificationsTitle => 'Notifications disabled';

  @override
  String get permissionBannerNotificationsDescription =>
      'Timer-end notifications won\'t be shown.';

  @override
  String get permissionBannerExactAlarmTitle => 'Exact alarms disabled';

  @override
  String get permissionBannerExactAlarmDescription =>
      'Alarms may fire several minutes late while the device is in power-saving mode.';

  @override
  String get permissionBannerFullScreenIntentTitle =>
      'Lock-screen alarms disabled';

  @override
  String get permissionBannerFullScreenIntentDescription =>
      'Without this permission, alarms will appear as a heads-up banner instead.';

  @override
  String get permissionBannerActionAllow => 'Allow';

  @override
  String get permissionBannerActionOpenSettings => 'Open settings';

  @override
  String get alarmSoundDefault => 'Default';

  @override
  String get alarmSoundGentle => 'Gentle';

  @override
  String get alarmSoundUrgent => 'Urgent';

  @override
  String get notificationTimerEndedTitle => 'Timer';

  @override
  String get notificationTimerEndedBody => 'Time is up.';

  @override
  String get notificationTimerCompletedBackgroundBody =>
      'Timer ended while the app was in the background.';
}
