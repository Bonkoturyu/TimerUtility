// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'TimerUtility';

  @override
  String get homeOpenStopwatch => '스톱워치';

  @override
  String get homeOpenTimer => '타이머';

  @override
  String get homeOpenAlarm => '알람';

  @override
  String get homeOpenClock => '세계 시계';

  @override
  String get stopwatchAppBarTitle => '스톱워치';

  @override
  String get stopwatchStart => '시작';

  @override
  String get stopwatchPause => '일시정지';

  @override
  String get stopwatchResume => '재개';

  @override
  String get stopwatchLap => '랩';

  @override
  String get stopwatchReset => '초기화';

  @override
  String get stopwatchNoLaps => '랩 기록 없음';

  @override
  String stopwatchLapLabel(int index) {
    return '랩 $index';
  }

  @override
  String stopwatchSplit(String time) {
    return '구간 $time';
  }

  @override
  String stopwatchTotal(String time) {
    return '합계 $time';
  }

  @override
  String get timerListAppBarTitle => '타이머';

  @override
  String get timerListAddFab => '타이머 추가';

  @override
  String get timerListEmptyHint => '타이머가 없습니다.\n오른쪽 아래의 “+” 버튼으로 추가하세요.';

  @override
  String timerListLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '최대 $count개에 도달했습니다',
    );
    return '$_temp0';
  }

  @override
  String get timerCardTimesUp => '시간이 됐어요!';

  @override
  String get timerCardActionStart => '시작';

  @override
  String get timerCardActionPause => '일시정지';

  @override
  String get timerCardActionResume => '재개';

  @override
  String get timerCardActionDismiss => '해제';

  @override
  String get timerCardActionReset => '초기화';

  @override
  String get timerCardActionDelete => '삭제';

  @override
  String get timerStatusIdle => '대기';

  @override
  String get timerStatusRunning => '진행 중';

  @override
  String get timerStatusPaused => '일시정지';

  @override
  String get timerStatusRinging => '울리는 중';

  @override
  String get timerStatusCompleted => '완료';

  @override
  String get timerStatusCancelled => '취소됨';

  @override
  String get alarmListAppBarTitle => '알람';

  @override
  String get alarmListAddFab => '알람 추가';

  @override
  String get alarmListEmptyHint => '알람이 없습니다.\n오른쪽 아래의 “+” 버튼으로 추가하세요.';

  @override
  String get alarmListRepeatEveryday => '매일';

  @override
  String get alarmAppBarTitle => '알람';

  @override
  String get alarmTimesUp => '시간이 됐어요!';

  @override
  String get alarmStop => '정지';

  @override
  String get alarmSnooze => '다시 알림';

  @override
  String get alarmSnoozePickerTitle => '다시 알림 시간을 선택';

  @override
  String alarmSnoozeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes분',
    );
    return '$_temp0';
  }

  @override
  String get alarmSnoozeCancel => '취소';

  @override
  String get durationPickerTitle => '사용자 지정 시간 선택';

  @override
  String get durationPickerHours => '시';

  @override
  String get durationPickerMinutes => '분';

  @override
  String get durationPickerSeconds => '초';

  @override
  String get durationPickerCancel => '취소';

  @override
  String get durationPickerConfirm => '확인';

  @override
  String get permissionBannerNotificationsTitle => '알림이 비활성화되어 있습니다';

  @override
  String get permissionBannerNotificationsDescription =>
      '타이머가 종료될 때 알림이 표시되지 않습니다.';

  @override
  String get permissionBannerExactAlarmTitle => '정확한 알람이 비활성화되어 있습니다';

  @override
  String get permissionBannerExactAlarmDescription =>
      '절전 모드에서는 알람이 몇 분 늦게 울릴 수 있습니다.';

  @override
  String get permissionBannerFullScreenIntentTitle => '잠금 화면 알람이 비활성화되어 있습니다';

  @override
  String get permissionBannerFullScreenIntentDescription =>
      '권한이 없으면 알람이 헤드업 알림 배너로 대신 표시됩니다.';

  @override
  String get permissionBannerHintTapToAllow => '탭하면 권한을 변경할 수 있습니다.';

  @override
  String get permissionBannerHintTapToOpenSettings => '탭하면 설정을 열 수 있습니다.';

  @override
  String get permissionBannerSeverityCritical => '[중요]';

  @override
  String get permissionBannerSeverityRecommended => '[권장]';

  @override
  String get permissionBannerSeveritySupplementary => '[보조]';

  @override
  String get alarmSoundDefault => '기본';

  @override
  String get alarmSoundGentle => '부드러움';

  @override
  String get alarmSoundWarning => '경고';

  @override
  String get notificationTimerEndedTitle => '타이머';

  @override
  String get notificationTimerEndedBody => '시간이 되었습니다.';

  @override
  String get notificationTimerCompletedBackgroundBody =>
      '앱이 백그라운드에 있는 동안 타이머가 종료되었습니다.';

  @override
  String get notificationAlarmRingingTitle => '알람';

  @override
  String get notificationAlarmRingingBody => '알람 시간이 되었습니다.';

  @override
  String get notificationTimerAlarmChannelName => '타이머 알람';

  @override
  String get notificationTimerAlarmChannelDescription => '타이머 종료 시의 알람 알림';

  @override
  String get notificationTimerCompletedChannelName => '타이머 완료(백그라운드)';

  @override
  String get notificationTimerCompletedChannelDescription =>
      '백그라운드 중에 타이머가 종료된 것을 알리는 무음 알림';

  @override
  String get presetSheetTitle => '프리셋에서 선택';

  @override
  String get presetSheetCustomButton => '사용자 지정 시간으로 만들기';

  @override
  String get presetSheetManageButton => '프리셋 관리...';

  @override
  String get presetManageAppBarTitle => '프리셋 관리';

  @override
  String get presetManageMenuOverflow => '프리셋 관리';

  @override
  String get presetManageEmptyHint => '프리셋이 없습니다.\n+ 버튼으로 추가하거나 템플릿으로 교체하세요.';

  @override
  String get presetManageReplaceTemplate => '템플릿으로 교체';

  @override
  String get presetEditTitleNew => '프리셋 추가';

  @override
  String get presetEditTitleEdit => '프리셋 편집';

  @override
  String get presetEditLabelHint => '라벨(선택)';

  @override
  String get presetEditDurationLabel => '시간';

  @override
  String get presetEditSoundLabel => '사운드';

  @override
  String get presetEditCancel => '취소';

  @override
  String get presetEditSave => '저장';

  @override
  String get presetDeleteConfirmTitle => '이 프리셋을 삭제할까요?';

  @override
  String get presetDeleteConfirmDontAsk => '다음부터 묻지 않기';

  @override
  String get presetDeleteConfirmDelete => '삭제';

  @override
  String get presetDeleteConfirmCancel => '취소';

  @override
  String get presetTemplateReplaceTitle => '템플릿으로 교체';

  @override
  String get presetTemplateReplaceProfileGeneral => '일반';

  @override
  String get presetTemplateReplaceProfileCooking => '요리용';

  @override
  String get presetTemplateReplaceProfilePomodoro => '뽀모도로';

  @override
  String get presetTemplateReplaceMode => '이미 프리셋이 있습니다. 어떻게 할까요?';

  @override
  String get presetTemplateReplaceModeOverwrite => '덮어쓰기';

  @override
  String get presetTemplateReplaceModeAppend => '추가';

  @override
  String get presetTemplateReplaceModeCancel => '취소';

  @override
  String presetTemplateReplaceLimitWarning(int discarded) {
    String _temp0 = intl.Intl.pluralLogic(
      discarded,
      locale: localeName,
      other: '프리셋 개수 상한을 초과해 $discarded개가 추가되지 않았습니다',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String presetLabelSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count초',
    );
    return '$_temp0';
  }

  @override
  String presetLabelMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분',
    );
    return '$_temp0';
  }

  @override
  String presetLabelHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count시간',
    );
    return '$_temp0';
  }

  @override
  String get timerCardSoundChange => '사운드 변경';

  @override
  String get timerSoundSheetTitle => '사운드 선택';

  @override
  String get licenseMenuOverflow => '라이선스';

  @override
  String get licenseGroupBundledSounds => '내장 사운드';

  @override
  String get licenseGroupSoftware => '소프트웨어 라이선스';

  @override
  String get alarmEditTitleNew => '알람 추가';

  @override
  String get alarmEditTitleEdit => '알람 편집';

  @override
  String get alarmEditEnabledLabel => '사용';

  @override
  String get alarmEditTimeLabel => '시각';

  @override
  String get alarmEditRepeatLabel => '반복';

  @override
  String get alarmEditRepeatOnce => '한 번';

  @override
  String get alarmEditRepeatWeekly => '요일 지정';

  @override
  String get alarmEditWeekdaysLabel => '울리는 요일';

  @override
  String get alarmEditLabelHint => '라벨(선택)';

  @override
  String get alarmEditSoundLabel => '사운드';

  @override
  String get alarmEditSnoozeLabel => '다시 알림';

  @override
  String alarmEditSnoozeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count분',
    );
    return '$_temp0';
  }

  @override
  String get alarmEditCancel => '취소';

  @override
  String get alarmEditSave => '저장';

  @override
  String get alarmEditDelete => '삭제';

  @override
  String get alarmEditValidationWeekdaysEmpty => '요일을 하나 이상 선택하세요';

  @override
  String get alarmEditLoading => '알람을 불러오는 중…';

  @override
  String get alarmEditNotFound => '해당 알람을 찾을 수 없습니다';

  @override
  String get alarmDeleteConfirmTitle => '이 알람을 삭제할까요?';

  @override
  String get alarmDeleteConfirmDontAsk => '다음부터 묻지 않기';

  @override
  String get alarmDeleteConfirmCancel => '취소';

  @override
  String get alarmDeleteConfirmDelete => '삭제';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get weekdaySun => '일';

  @override
  String get clockAppBarTitle => '세계 시계';

  @override
  String get clockListAddFab => '시계 추가';

  @override
  String get clockDesignSegmentAnalog => '아날로그';

  @override
  String get clockDesignSegmentDigital => '디지털';

  @override
  String get clockDesignSegmentCompact => '콤팩트';

  @override
  String get clockEntryEditAppBarTitle => '시계 추가・편집';

  @override
  String clockEntryEditSectionPinned(int count, int max) {
    return '등록됨 ($count/$max)';
  }

  @override
  String get clockEntryEditSectionAvailable => '추가할 수 있는 도시';

  @override
  String clockEntryEditLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '최대 $count개에 도달했습니다. 삭제한 후에 추가하세요',
    );
    return '$_temp0';
  }

  @override
  String get clockEntryEditCatalogEmpty => '모든 도시가 이미 등록되어 있습니다';

  @override
  String get clockEmptyHint => '등록된 시계가 없습니다.\n오른쪽 아래의 “+” 버튼으로 추가하세요.';

  @override
  String get homeMenuSettings => '설정';

  @override
  String get settingsAppBarTitle => '설정';

  @override
  String get settingsSectionDisplay => '표시';

  @override
  String get settingsSectionDefaults => '기본값';

  @override
  String get settingsSectionAbout => '정보';

  @override
  String get settingsThemeLabel => '테마';

  @override
  String get settingsThemeSystem => '시스템';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsDefaultSnoozeLabel => '다시 알림 분';

  @override
  String settingsDefaultSnoozeOption(int minutes) {
    return '$minutes분';
  }

  @override
  String get settingsDefaultAlarmSoundLabel => '알람 사운드';

  @override
  String get settingsLanguageLabel => '언어';

  @override
  String get settingsLanguageSystem => '시스템 설정 따르기';

  @override
  String get settingsLanguageDialogTitle => '언어 선택';

  @override
  String get settingsSectionDiagnostics => '진단 로그';

  @override
  String get settingsDiagnosticLogToggle => '진단 로그 활성화';

  @override
  String get settingsDiagnosticLogToggleDescription =>
      '타이머 조작, 권한 변경, 알림 발생, 예외를 기기 내 파일에 기록합니다. 개인정보(라벨 / 위치)는 기록되지 않습니다.';

  @override
  String get settingsDiagnosticShareLogs => '로그 공유';

  @override
  String get settingsDiagnosticShareLogsSubject => 'TimerUtility 진단 로그';

  @override
  String get settingsDiagnosticShareLogsDescription =>
      '저장된 로그를 zip으로 묶어 공유 메뉴를 엽니다.';

  @override
  String get settingsDiagnosticShareLogsInProgress => '로그를 준비하는 중…';

  @override
  String get settingsDiagnosticShareLogsSuccess => '공유 메뉴를 열었습니다';

  @override
  String settingsDiagnosticShareLogsError(String message) {
    return '로그 공유에 실패했습니다: $message';
  }
}
