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
  String get homeOpenStopwatch => 'Stopwatch';

  @override
  String get homeOpenTimer => 'Timer';

  @override
  String get homeOpenAlarm => 'Alarm';

  @override
  String get homeOpenClock => 'World Clock';

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
      'No timers yet.\nTap + at the bottom-right to add one.';

  @override
  String timerListLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Limit reached: $count items',
      one: 'Limit reached: 1 item',
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
  String get alarmListAppBarTitle => 'Alarms';

  @override
  String get alarmListAddFab => 'Add Alarm';

  @override
  String get alarmListEmptyHint =>
      'No alarms yet.\nTap + at the bottom-right to add one.';

  @override
  String get alarmListRepeatEveryday => 'Every day';

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
  String get alarmSoundWarning => 'Warning';

  @override
  String get notificationTimerEndedTitle => 'Timer';

  @override
  String get notificationTimerEndedBody => 'Time is up.';

  @override
  String get notificationTimerCompletedBackgroundBody =>
      'Timer ended while the app was in the background.';

  @override
  String get notificationAlarmRingingTitle => 'Alarm';

  @override
  String get notificationAlarmRingingBody => 'It\'s time for your alarm.';

  @override
  String get presetSheetTitle => 'Choose preset';

  @override
  String get presetSheetCustomButton => 'Create with custom time';

  @override
  String get presetSheetManageButton => 'Manage presets...';

  @override
  String get presetManageAppBarTitle => 'Manage presets';

  @override
  String get presetManageMenuOverflow => 'Manage presets';

  @override
  String get presetManageEmptyHint =>
      'No presets yet.\nTap + to add one or replace from a template.';

  @override
  String get presetManageReplaceTemplate => 'Replace from template';

  @override
  String get presetEditTitleNew => 'Add preset';

  @override
  String get presetEditTitleEdit => 'Edit preset';

  @override
  String get presetEditLabelHint => 'Label (optional)';

  @override
  String get presetEditDurationLabel => 'Duration';

  @override
  String get presetEditSoundLabel => 'Sound';

  @override
  String get presetEditCancel => 'Cancel';

  @override
  String get presetEditSave => 'Save';

  @override
  String get presetDeleteConfirmTitle => 'Delete this preset?';

  @override
  String get presetDeleteConfirmDontAsk => 'Don\'t ask again';

  @override
  String get presetDeleteConfirmDelete => 'Delete';

  @override
  String get presetDeleteConfirmCancel => 'Cancel';

  @override
  String get presetTemplateReplaceTitle => 'Replace from template';

  @override
  String get presetTemplateReplaceProfileGeneral => 'General';

  @override
  String get presetTemplateReplaceProfileCooking => 'Cooking';

  @override
  String get presetTemplateReplaceProfilePomodoro => 'Pomodoro';

  @override
  String get presetTemplateReplaceMode =>
      'You already have presets. What would you like to do?';

  @override
  String get presetTemplateReplaceModeOverwrite => 'Overwrite';

  @override
  String get presetTemplateReplaceModeAppend => 'Append';

  @override
  String get presetTemplateReplaceModeCancel => 'Cancel';

  @override
  String presetTemplateReplaceLimitWarning(int discarded) {
    String _temp0 = intl.Intl.pluralLogic(
      discarded,
      locale: localeName,
      other: '$discarded presets were skipped because the limit was reached',
      one: '1 preset was skipped because the limit was reached',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String presetLabelSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String presetLabelMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String presetLabelHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get timerCardSoundChange => 'Change sound';

  @override
  String get timerSoundSheetTitle => 'Choose sound';

  @override
  String get licenseMenuOverflow => 'Licenses';

  @override
  String get licenseGroupBundledSounds => 'Bundled sounds';

  @override
  String get licenseGroupSoftware => 'Software licenses';

  @override
  String get alarmEditTitleNew => 'Add alarm';

  @override
  String get alarmEditTitleEdit => 'Edit alarm';

  @override
  String get alarmEditEnabledLabel => 'Enabled';

  @override
  String get alarmEditTimeLabel => 'Time';

  @override
  String get alarmEditRepeatLabel => 'Repeat';

  @override
  String get alarmEditRepeatOnce => 'Once';

  @override
  String get alarmEditRepeatWeekly => 'Weekly';

  @override
  String get alarmEditWeekdaysLabel => 'Days';

  @override
  String get alarmEditLabelHint => 'Label (optional)';

  @override
  String get alarmEditSoundLabel => 'Sound';

  @override
  String get alarmEditSnoozeLabel => 'Snooze';

  @override
  String alarmEditSnoozeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get alarmEditCancel => 'Cancel';

  @override
  String get alarmEditSave => 'Save';

  @override
  String get alarmEditDelete => 'Delete';

  @override
  String get alarmEditValidationWeekdaysEmpty => 'Select at least one day';

  @override
  String get alarmEditLoading => 'Loading alarm…';

  @override
  String get alarmEditNotFound => 'The alarm could not be found';

  @override
  String get alarmDeleteConfirmTitle => 'Delete this alarm?';

  @override
  String get alarmDeleteConfirmDontAsk => 'Don\'t ask again';

  @override
  String get alarmDeleteConfirmCancel => 'Cancel';

  @override
  String get alarmDeleteConfirmDelete => 'Delete';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get clockAppBarTitle => 'World Clock';

  @override
  String get clockListAddFab => 'Add clock';

  @override
  String get clockDesignSegmentAnalog => 'Analog';

  @override
  String get clockDesignSegmentDigital => 'Digital';

  @override
  String get clockDesignSegmentCompact => 'Compact';

  @override
  String get clockEntryEditAppBarTitle => 'Add or edit clocks';

  @override
  String clockEntryEditSectionPinned(int count, int max) {
    return 'Pinned ($count/$max)';
  }

  @override
  String get clockEntryEditSectionAvailable => 'Available cities';

  @override
  String clockEntryEditLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Maximum of $count cities reached. Remove one to add another.',
      one: 'Maximum of 1 city reached. Remove it to add another.',
    );
    return '$_temp0';
  }

  @override
  String get clockEntryEditCatalogEmpty =>
      'All available cities are already pinned';

  @override
  String get clockEmptyHint =>
      'No clocks yet.\nTap + at the bottom-right to add one.';

  @override
  String get homeMenuSettings => 'Settings';

  @override
  String get settingsAppBarTitle => 'Settings';

  @override
  String get settingsSectionDisplay => 'Display';

  @override
  String get settingsSectionDefaults => 'Defaults';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsDefaultSnoozeLabel => 'Snooze minutes';

  @override
  String settingsDefaultSnoozeOption(int minutes) {
    return '$minutes min';
  }

  @override
  String get settingsDefaultAlarmSoundLabel => 'Alarm sound';
}
