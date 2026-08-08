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
  String get alarmVoiceStopListening => 'Listening for “Stop”';

  @override
  String get alarmVoiceStopModelDownloadRequired =>
      'An on-device speech model is required for this language';

  @override
  String get alarmVoiceStopModelDownloadPending =>
      'Preparing the on-device speech model';

  @override
  String get alarmVoiceStopLanguageUnsupported =>
      'This language is not supported for on-device speech recognition';

  @override
  String get alarmVoiceStopUnavailable => 'On-device voice stop is unavailable';

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
  String get permissionBannerHintTapToAllow =>
      'Tap anywhere to change this permission.';

  @override
  String get permissionBannerHintTapToOpenSettings =>
      'Tap anywhere to open settings.';

  @override
  String get permissionBannerSeverityCritical => '[Critical]';

  @override
  String get permissionBannerSeverityRecommended => '[Recommended]';

  @override
  String get permissionBannerSeveritySupplementary => '[Supplementary]';

  @override
  String get alarmSoundDefault => 'Default';

  @override
  String get alarmSoundGentle => 'Gentle';

  @override
  String get alarmSoundWarning => 'Warning';

  @override
  String get alarmSoundCustom1 => 'Custom 1';

  @override
  String get alarmSoundCustom2 => 'Custom 2';

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
  String get notificationTimerAlarmChannelName => 'Timer Alarm';

  @override
  String get notificationTimerAlarmChannelDescription =>
      'Alarm notification when a timer ends';

  @override
  String get notificationTimerCompletedChannelName =>
      'Timer Completed (Background)';

  @override
  String get notificationTimerCompletedChannelDescription =>
      'Silent notification when a timer ends while the app is in the background';

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
  String get licenseGroupBundledAssets => 'Bundled assets';

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
  String get settingsSectionAlarmSound => 'App volume';

  @override
  String get settingsSectionDefaults => 'Defaults';

  @override
  String get settingsSectionVoiceControl => 'Voice control';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsVersionLabel => 'Version';

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

  @override
  String get settingsAlarmVolumeLabel => 'Volume';

  @override
  String settingsAlarmVolumeValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsLanguageSystem => 'Follow system';

  @override
  String get settingsLanguageDialogTitle => 'Select language';

  @override
  String get settingsVoiceStopLabel => 'Stop by voice';

  @override
  String get settingsVoiceStopDescription =>
      'Recognize a voice command on-device only while an alarm is ringing. Audio is never saved or sent.';

  @override
  String get settingsVoiceStopEnabledDescription =>
      'Say “Stop” to stop the ringing timer or alarm.';

  @override
  String get settingsVoiceStopChecking =>
      'Checking on-device speech recognition…';

  @override
  String get settingsVoiceStopModelDownloadRequired =>
      'An on-device speech model is required for this language. Enabling this feature starts the download.';

  @override
  String get settingsVoiceStopModelDownloadPending =>
      'The on-device speech model is being prepared. Voice stop will be available when it finishes.';

  @override
  String get settingsVoiceStopModelDownloadStarted =>
      'The on-device speech model download has started. Voice stop will be available when it finishes.';

  @override
  String get settingsVoiceStopLanguageUnsupported =>
      'This language is not supported for on-device speech recognition.';

  @override
  String get settingsVoiceStopUnavailable =>
      'On-device speech recognition is unavailable on this device.';

  @override
  String get settingsVoiceStopPermissionDenied =>
      'Microphone permission is required for voice stop.';

  @override
  String get settingsOpenAppSettings => 'Open settings';

  @override
  String get importedSoundManageTitle => 'Imported sounds';

  @override
  String get importedSoundManageDescription =>
      'Manage sounds added from your device';

  @override
  String get importedSoundAdd => 'Add from device';

  @override
  String get importedSoundEmpty =>
      'No imported sounds.\nUse the button below to add one.';

  @override
  String get importedSoundLoadError => 'Could not load imported sounds';

  @override
  String importedSoundAdded(String name) {
    return 'Added $name';
  }

  @override
  String get importedSoundImportError => 'Could not add the sound';

  @override
  String importedSoundDuplicate(String name) {
    return '$name has already been added. Using the existing sound.';
  }

  @override
  String get importedSoundPreview => 'Preview';

  @override
  String get importedSoundPreviewError => 'Could not play the sound';

  @override
  String get importedSoundRename => 'Rename';

  @override
  String get importedSoundRenameTitle => 'Rename sound';

  @override
  String get importedSoundNameLabel => 'Name';

  @override
  String get importedSoundNameRequired => 'Enter a name';

  @override
  String get importedSoundRenameError => 'Could not rename the sound';

  @override
  String get importedSoundDelete => 'Delete';

  @override
  String get importedSoundDeleteTitle => 'Delete this sound?';

  @override
  String get importedSoundDeleteDescription =>
      'Timers, alarms, presets, and the default sound using it will change to the default sound.';

  @override
  String get importedSoundDeleted => 'Sound deleted';

  @override
  String get importedSoundDeleteError => 'Could not delete the sound';

  @override
  String get importedSoundSave => 'Save';

  @override
  String get importedSoundCancel => 'Cancel';

  @override
  String get settingsSectionDiagnostics => 'Diagnostic logs';

  @override
  String get settingsDiagnosticLogToggle => 'Enable diagnostic logging';

  @override
  String get settingsDiagnosticLogToggleDescription =>
      'Record timer actions, permission changes, notification fires, and exceptions to on-device files. No personal data (labels / location) is captured.';

  @override
  String get timerIntervalNotificationLabel => 'Interval notifications';

  @override
  String get timerIntervalNotificationDescription =>
      'Keep measuring and play a short sound at each set interval.';

  @override
  String get timerIntervalNotificationEnabledTooltip =>
      'Interval notifications: on';

  @override
  String get timerIntervalNotificationDisabledTooltip =>
      'Interval notifications: off';

  @override
  String get commonClose => 'Close';

  @override
  String get settingsDiagnosticShareLogs => 'Share logs';

  @override
  String get settingsDiagnosticShareLogsSubject =>
      'TimerUtility diagnostic logs';

  @override
  String get settingsDiagnosticShareLogsDescription =>
      'Bundle stored logs into a zip and open the share sheet.';

  @override
  String get settingsDiagnosticShareLogsInProgress => 'Preparing logs…';

  @override
  String get settingsDiagnosticShareLogsSuccess => 'Share sheet opened';

  @override
  String settingsDiagnosticShareLogsError(String message) {
    return 'Failed to share logs: $message';
  }
}
