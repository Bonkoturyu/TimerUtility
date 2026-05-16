// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'TimerUtility';

  @override
  String get homeOpenStopwatch => '秒表';

  @override
  String get homeOpenTimer => '定时器';

  @override
  String get homeOpenAlarm => '闹钟';

  @override
  String get homeOpenClock => '世界时钟';

  @override
  String get stopwatchAppBarTitle => '秒表';

  @override
  String get stopwatchStart => '开始';

  @override
  String get stopwatchPause => '暂停';

  @override
  String get stopwatchResume => '继续';

  @override
  String get stopwatchLap => '计圈';

  @override
  String get stopwatchReset => '重置';

  @override
  String get stopwatchNoLaps => '尚无计圈记录';

  @override
  String stopwatchLapLabel(int index) {
    return '第 $index 圈';
  }

  @override
  String stopwatchSplit(String time) {
    return '区间 $time';
  }

  @override
  String stopwatchTotal(String time) {
    return '总计 $time';
  }

  @override
  String get timerListAppBarTitle => '定时器';

  @override
  String get timerListAddFab => '添加定时器';

  @override
  String get timerListEmptyHint => '暂无定时器。\n点击右下角的“+”按钮添加。';

  @override
  String timerListLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已达到上限 $count 个',
    );
    return '$_temp0';
  }

  @override
  String get timerCardTimesUp => '时间到！';

  @override
  String get timerCardActionStart => '开始';

  @override
  String get timerCardActionPause => '暂停';

  @override
  String get timerCardActionResume => '继续';

  @override
  String get timerCardActionDismiss => '解除';

  @override
  String get timerCardActionReset => '重置';

  @override
  String get timerCardActionDelete => '删除';

  @override
  String get timerStatusIdle => '待机';

  @override
  String get timerStatusRunning => '进行中';

  @override
  String get timerStatusPaused => '已暂停';

  @override
  String get timerStatusRinging => '响铃中';

  @override
  String get timerStatusCompleted => '已完成';

  @override
  String get timerStatusCancelled => '已取消';

  @override
  String get alarmListAppBarTitle => '闹钟';

  @override
  String get alarmListAddFab => '添加闹钟';

  @override
  String get alarmListEmptyHint => '暂无闹钟。\n点击右下角的“+”按钮添加。';

  @override
  String get alarmListRepeatEveryday => '每天';

  @override
  String get alarmAppBarTitle => '闹钟';

  @override
  String get alarmTimesUp => '时间到！';

  @override
  String get alarmStop => '停止';

  @override
  String get alarmSnooze => '稍后提醒';

  @override
  String get alarmSnoozePickerTitle => '选择稍后提醒时长';

  @override
  String alarmSnoozeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分钟',
    );
    return '$_temp0';
  }

  @override
  String get alarmSnoozeCancel => '取消';

  @override
  String get durationPickerTitle => '选择自定义时长';

  @override
  String get durationPickerHours => '时';

  @override
  String get durationPickerMinutes => '分';

  @override
  String get durationPickerSeconds => '秒';

  @override
  String get durationPickerCancel => '取消';

  @override
  String get durationPickerConfirm => '确定';

  @override
  String get permissionBannerNotificationsTitle => '通知已停用';

  @override
  String get permissionBannerNotificationsDescription => '定时器结束时将不会显示通知。';

  @override
  String get permissionBannerExactAlarmTitle => '精确闹钟已停用';

  @override
  String get permissionBannerExactAlarmDescription => '省电模式下闹钟可能会延迟数分钟响起。';

  @override
  String get permissionBannerFullScreenIntentTitle => '锁屏闹钟已停用';

  @override
  String get permissionBannerFullScreenIntentDescription =>
      '未授予此权限时，闹钟将改为以悬浮通知的形式提示。';

  @override
  String get permissionBannerHintTapToAllow => '点击此处即可更改权限。';

  @override
  String get permissionBannerHintTapToOpenSettings => '点击此处即可打开设置。';

  @override
  String get permissionBannerSeverityCritical => '[重要]';

  @override
  String get permissionBannerSeverityRecommended => '[推荐]';

  @override
  String get permissionBannerSeveritySupplementary => '[辅助]';

  @override
  String get alarmSoundDefault => '默认';

  @override
  String get alarmSoundGentle => '轻柔';

  @override
  String get alarmSoundWarning => '警示';

  @override
  String get notificationTimerEndedTitle => '定时器';

  @override
  String get notificationTimerEndedBody => '时间到。';

  @override
  String get notificationTimerCompletedBackgroundBody => '应用在后台运行时定时器已结束。';

  @override
  String get notificationAlarmRingingTitle => '闹钟';

  @override
  String get notificationAlarmRingingBody => '闹钟时间到。';

  @override
  String get notificationTimerAlarmChannelName => '定时器闹钟';

  @override
  String get notificationTimerAlarmChannelDescription => '定时器结束时的闹钟通知';

  @override
  String get notificationTimerCompletedChannelName => '定时器完成（后台）';

  @override
  String get notificationTimerCompletedChannelDescription => '应用在后台时定时器结束的无声通知';

  @override
  String get presetSheetTitle => '从预设中选择';

  @override
  String get presetSheetCustomButton => '使用自定义时长创建';

  @override
  String get presetSheetManageButton => '管理预设...';

  @override
  String get presetManageAppBarTitle => '预设管理';

  @override
  String get presetManageMenuOverflow => '预设管理';

  @override
  String get presetManageEmptyHint => '暂无预设。\n点击 + 按钮添加，或从模板中替换。';

  @override
  String get presetManageReplaceTemplate => '从模板替换';

  @override
  String get presetEditTitleNew => '添加预设';

  @override
  String get presetEditTitleEdit => '编辑预设';

  @override
  String get presetEditLabelHint => '标签（可选）';

  @override
  String get presetEditDurationLabel => '时长';

  @override
  String get presetEditSoundLabel => '音源';

  @override
  String get presetEditCancel => '取消';

  @override
  String get presetEditSave => '保存';

  @override
  String get presetDeleteConfirmTitle => '确定删除此预设吗？';

  @override
  String get presetDeleteConfirmDontAsk => '下次不再询问';

  @override
  String get presetDeleteConfirmDelete => '删除';

  @override
  String get presetDeleteConfirmCancel => '取消';

  @override
  String get presetTemplateReplaceTitle => '从模板替换';

  @override
  String get presetTemplateReplaceProfileGeneral => '通用';

  @override
  String get presetTemplateReplaceProfileCooking => '烹饪';

  @override
  String get presetTemplateReplaceProfilePomodoro => '番茄钟';

  @override
  String get presetTemplateReplaceMode => '已存在预设，要如何处理？';

  @override
  String get presetTemplateReplaceModeOverwrite => '覆盖';

  @override
  String get presetTemplateReplaceModeAppend => '追加';

  @override
  String get presetTemplateReplaceModeCancel => '取消';

  @override
  String presetTemplateReplaceLimitWarning(int discarded) {
    String _temp0 = intl.Intl.pluralLogic(
      discarded,
      locale: localeName,
      other: '因超过预设数量上限，有 $discarded 项未被添加',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String presetLabelSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒',
    );
    return '$_temp0';
  }

  @override
  String presetLabelMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟',
    );
    return '$_temp0';
  }

  @override
  String presetLabelHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时',
    );
    return '$_temp0';
  }

  @override
  String get timerCardSoundChange => '更改音源';

  @override
  String get timerSoundSheetTitle => '选择音源';

  @override
  String get licenseMenuOverflow => '许可证';

  @override
  String get licenseGroupBundledSounds => '随附音源';

  @override
  String get licenseGroupSoftware => '软件许可证';

  @override
  String get alarmEditTitleNew => '添加闹钟';

  @override
  String get alarmEditTitleEdit => '编辑闹钟';

  @override
  String get alarmEditEnabledLabel => '启用';

  @override
  String get alarmEditTimeLabel => '时间';

  @override
  String get alarmEditRepeatLabel => '重复';

  @override
  String get alarmEditRepeatOnce => '单次';

  @override
  String get alarmEditRepeatWeekly => '按星期';

  @override
  String get alarmEditWeekdaysLabel => '响铃日';

  @override
  String get alarmEditLabelHint => '标签（可选）';

  @override
  String get alarmEditSoundLabel => '音源';

  @override
  String get alarmEditSnoozeLabel => '稍后提醒';

  @override
  String alarmEditSnoozeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟',
    );
    return '$_temp0';
  }

  @override
  String get alarmEditCancel => '取消';

  @override
  String get alarmEditSave => '保存';

  @override
  String get alarmEditDelete => '删除';

  @override
  String get alarmEditValidationWeekdaysEmpty => '请至少选择一个星期';

  @override
  String get alarmEditLoading => '正在加载闹钟…';

  @override
  String get alarmEditNotFound => '未找到对应的闹钟';

  @override
  String get alarmDeleteConfirmTitle => '确定删除此闹钟吗？';

  @override
  String get alarmDeleteConfirmDontAsk => '下次不再询问';

  @override
  String get alarmDeleteConfirmCancel => '取消';

  @override
  String get alarmDeleteConfirmDelete => '删除';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get weekdaySun => '日';

  @override
  String get clockAppBarTitle => '世界时钟';

  @override
  String get clockListAddFab => '添加时钟';

  @override
  String get clockDesignSegmentAnalog => '指针';

  @override
  String get clockDesignSegmentDigital => '数字';

  @override
  String get clockDesignSegmentCompact => '紧凑';

  @override
  String get clockEntryEditAppBarTitle => '添加/编辑时钟';

  @override
  String clockEntryEditSectionPinned(int count, int max) {
    return '已添加（$count/$max）';
  }

  @override
  String get clockEntryEditSectionAvailable => '可添加的城市';

  @override
  String clockEntryEditLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已达到上限 $count 个，请先删除后再添加',
    );
    return '$_temp0';
  }

  @override
  String get clockEntryEditCatalogEmpty => '所有城市都已添加';

  @override
  String get clockEmptyHint => '尚未添加时钟。\n点击右下角的“+”按钮添加。';

  @override
  String get homeMenuSettings => '设置';

  @override
  String get settingsAppBarTitle => '设置';

  @override
  String get settingsSectionDisplay => '显示';

  @override
  String get settingsSectionDefaults => '默认值';

  @override
  String get settingsSectionAbout => '关于';

  @override
  String get settingsThemeLabel => '主题';

  @override
  String get settingsThemeSystem => '系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsDefaultSnoozeLabel => '稍后提醒分钟';

  @override
  String settingsDefaultSnoozeOption(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get settingsDefaultAlarmSoundLabel => '闹钟音源';

  @override
  String get settingsLanguageLabel => '语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsLanguageDialogTitle => '选择语言';

  @override
  String get settingsSectionDiagnostics => '诊断日志';

  @override
  String get settingsDiagnosticLogToggle => '启用诊断日志';

  @override
  String get settingsDiagnosticLogToggleDescription =>
      '将定时器操作、权限变更、通知触发与异常记录到设备本地文件。不会记录个人信息（标签/位置）。';

  @override
  String get settingsDiagnosticShareLogs => '共享日志';

  @override
  String get settingsDiagnosticShareLogsSubject => 'TimerUtility 诊断日志';

  @override
  String get settingsDiagnosticShareLogsDescription =>
      '将已保存的日志打包为 zip 并打开共享菜单。';

  @override
  String get settingsDiagnosticShareLogsInProgress => '正在准备日志…';

  @override
  String get settingsDiagnosticShareLogsSuccess => '已打开共享菜单';

  @override
  String settingsDiagnosticShareLogsError(String message) {
    return '共享日志失败：$message';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'TimerUtility';

  @override
  String get homeOpenStopwatch => '碼錶';

  @override
  String get homeOpenTimer => '計時器';

  @override
  String get homeOpenAlarm => '鬧鐘';

  @override
  String get homeOpenClock => '世界時鐘';

  @override
  String get stopwatchAppBarTitle => '碼錶';

  @override
  String get stopwatchStart => '開始';

  @override
  String get stopwatchPause => '暫停';

  @override
  String get stopwatchResume => '繼續';

  @override
  String get stopwatchLap => '計圈';

  @override
  String get stopwatchReset => '重設';

  @override
  String get stopwatchNoLaps => '尚無計圈紀錄';

  @override
  String stopwatchLapLabel(int index) {
    return '第 $index 圈';
  }

  @override
  String stopwatchSplit(String time) {
    return '區間 $time';
  }

  @override
  String stopwatchTotal(String time) {
    return '總計 $time';
  }

  @override
  String get timerListAppBarTitle => '計時器';

  @override
  String get timerListAddFab => '新增計時器';

  @override
  String get timerListEmptyHint => '目前沒有計時器。\n點選右下角的「+」按鈕即可新增。';

  @override
  String timerListLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已達上限 $count 個',
    );
    return '$_temp0';
  }

  @override
  String get timerCardTimesUp => '時間到！';

  @override
  String get timerCardActionStart => '開始';

  @override
  String get timerCardActionPause => '暫停';

  @override
  String get timerCardActionResume => '繼續';

  @override
  String get timerCardActionDismiss => '解除';

  @override
  String get timerCardActionReset => '重設';

  @override
  String get timerCardActionDelete => '刪除';

  @override
  String get timerStatusIdle => '待機';

  @override
  String get timerStatusRunning => '進行中';

  @override
  String get timerStatusPaused => '已暫停';

  @override
  String get timerStatusRinging => '響鈴中';

  @override
  String get timerStatusCompleted => '已完成';

  @override
  String get timerStatusCancelled => '已取消';

  @override
  String get alarmListAppBarTitle => '鬧鐘';

  @override
  String get alarmListAddFab => '新增鬧鐘';

  @override
  String get alarmListEmptyHint => '目前沒有鬧鐘。\n點選右下角的「+」按鈕即可新增。';

  @override
  String get alarmListRepeatEveryday => '每天';

  @override
  String get alarmAppBarTitle => '鬧鐘';

  @override
  String get alarmTimesUp => '時間到！';

  @override
  String get alarmStop => '停止';

  @override
  String get alarmSnooze => '貪睡';

  @override
  String get alarmSnoozePickerTitle => '選擇貪睡時間';

  @override
  String alarmSnoozeMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分鐘',
    );
    return '$_temp0';
  }

  @override
  String get alarmSnoozeCancel => '取消';

  @override
  String get durationPickerTitle => '選擇自訂時間';

  @override
  String get durationPickerHours => '時';

  @override
  String get durationPickerMinutes => '分';

  @override
  String get durationPickerSeconds => '秒';

  @override
  String get durationPickerCancel => '取消';

  @override
  String get durationPickerConfirm => '確定';

  @override
  String get permissionBannerNotificationsTitle => '通知已停用';

  @override
  String get permissionBannerNotificationsDescription => '計時器結束時將不會顯示通知。';

  @override
  String get permissionBannerExactAlarmTitle => '精確鬧鐘已停用';

  @override
  String get permissionBannerExactAlarmDescription => '在省電模式下，鬧鐘可能會延遲數分鐘才響起。';

  @override
  String get permissionBannerFullScreenIntentTitle => '鎖定畫面鬧鐘已停用';

  @override
  String get permissionBannerFullScreenIntentDescription =>
      '未授予此權限時，鬧鐘將改以橫幅通知顯示。';

  @override
  String get permissionBannerHintTapToAllow => '點選任意處即可變更權限。';

  @override
  String get permissionBannerHintTapToOpenSettings => '點選任意處即可開啟設定。';

  @override
  String get permissionBannerSeverityCritical => '[重要]';

  @override
  String get permissionBannerSeverityRecommended => '[建議]';

  @override
  String get permissionBannerSeveritySupplementary => '[輔助]';

  @override
  String get alarmSoundDefault => '預設';

  @override
  String get alarmSoundGentle => '輕柔';

  @override
  String get alarmSoundWarning => '警示';

  @override
  String get notificationTimerEndedTitle => '計時器';

  @override
  String get notificationTimerEndedBody => '時間到了。';

  @override
  String get notificationTimerCompletedBackgroundBody => '應用程式在背景執行時，計時器已結束。';

  @override
  String get notificationAlarmRingingTitle => '鬧鐘';

  @override
  String get notificationAlarmRingingBody => '鬧鐘時間到了。';

  @override
  String get notificationTimerAlarmChannelName => '計時器鬧鐘';

  @override
  String get notificationTimerAlarmChannelDescription => '計時器結束時的鬧鐘通知';

  @override
  String get notificationTimerCompletedChannelName => '計時器完成（背景）';

  @override
  String get notificationTimerCompletedChannelDescription =>
      '應用程式在背景時計時器結束的無聲通知';

  @override
  String get presetSheetTitle => '從預設中選擇';

  @override
  String get presetSheetCustomButton => '以自訂時間建立';

  @override
  String get presetSheetManageButton => '管理預設...';

  @override
  String get presetManageAppBarTitle => '預設管理';

  @override
  String get presetManageMenuOverflow => '預設管理';

  @override
  String get presetManageEmptyHint => '目前沒有預設。\n點選 + 按鈕新增，或從範本中替換。';

  @override
  String get presetManageReplaceTemplate => '從範本替換';

  @override
  String get presetEditTitleNew => '新增預設';

  @override
  String get presetEditTitleEdit => '編輯預設';

  @override
  String get presetEditLabelHint => '標籤（選填）';

  @override
  String get presetEditDurationLabel => '時間';

  @override
  String get presetEditSoundLabel => '音效';

  @override
  String get presetEditCancel => '取消';

  @override
  String get presetEditSave => '儲存';

  @override
  String get presetDeleteConfirmTitle => '要刪除此預設嗎？';

  @override
  String get presetDeleteConfirmDontAsk => '下次不再詢問';

  @override
  String get presetDeleteConfirmDelete => '刪除';

  @override
  String get presetDeleteConfirmCancel => '取消';

  @override
  String get presetTemplateReplaceTitle => '從範本替換';

  @override
  String get presetTemplateReplaceProfileGeneral => '一般';

  @override
  String get presetTemplateReplaceProfileCooking => '烹飪';

  @override
  String get presetTemplateReplaceProfilePomodoro => '番茄鐘';

  @override
  String get presetTemplateReplaceMode => '已有預設，要如何處理？';

  @override
  String get presetTemplateReplaceModeOverwrite => '覆寫';

  @override
  String get presetTemplateReplaceModeAppend => '附加';

  @override
  String get presetTemplateReplaceModeCancel => '取消';

  @override
  String presetTemplateReplaceLimitWarning(int discarded) {
    String _temp0 = intl.Intl.pluralLogic(
      discarded,
      locale: localeName,
      other: '因超過預設數量上限，有 $discarded 項未被加入',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String presetLabelSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒',
    );
    return '$_temp0';
  }

  @override
  String presetLabelMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分鐘',
    );
    return '$_temp0';
  }

  @override
  String presetLabelHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小時',
    );
    return '$_temp0';
  }

  @override
  String get timerCardSoundChange => '變更音效';

  @override
  String get timerSoundSheetTitle => '選擇音效';

  @override
  String get licenseMenuOverflow => '授權';

  @override
  String get licenseGroupBundledSounds => '內建音效';

  @override
  String get licenseGroupSoftware => '軟體授權';

  @override
  String get alarmEditTitleNew => '新增鬧鐘';

  @override
  String get alarmEditTitleEdit => '編輯鬧鐘';

  @override
  String get alarmEditEnabledLabel => '啟用';

  @override
  String get alarmEditTimeLabel => '時間';

  @override
  String get alarmEditRepeatLabel => '重複';

  @override
  String get alarmEditRepeatOnce => '單次';

  @override
  String get alarmEditRepeatWeekly => '每週';

  @override
  String get alarmEditWeekdaysLabel => '響鈴日';

  @override
  String get alarmEditLabelHint => '標籤（選填）';

  @override
  String get alarmEditSoundLabel => '音效';

  @override
  String get alarmEditSnoozeLabel => '貪睡';

  @override
  String alarmEditSnoozeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分鐘',
    );
    return '$_temp0';
  }

  @override
  String get alarmEditCancel => '取消';

  @override
  String get alarmEditSave => '儲存';

  @override
  String get alarmEditDelete => '刪除';

  @override
  String get alarmEditValidationWeekdaysEmpty => '請至少選擇一個星期';

  @override
  String get alarmEditLoading => '正在載入鬧鐘…';

  @override
  String get alarmEditNotFound => '找不到對應的鬧鐘';

  @override
  String get alarmDeleteConfirmTitle => '要刪除此鬧鐘嗎？';

  @override
  String get alarmDeleteConfirmDontAsk => '下次不再詢問';

  @override
  String get alarmDeleteConfirmCancel => '取消';

  @override
  String get alarmDeleteConfirmDelete => '刪除';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get weekdaySun => '日';

  @override
  String get clockAppBarTitle => '世界時鐘';

  @override
  String get clockListAddFab => '新增時鐘';

  @override
  String get clockDesignSegmentAnalog => '指針';

  @override
  String get clockDesignSegmentDigital => '數位';

  @override
  String get clockDesignSegmentCompact => '精簡';

  @override
  String get clockEntryEditAppBarTitle => '新增/編輯時鐘';

  @override
  String clockEntryEditSectionPinned(int count, int max) {
    return '已新增（$count/$max）';
  }

  @override
  String get clockEntryEditSectionAvailable => '可新增的城市';

  @override
  String clockEntryEditLimitReached(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已達上限 $count 個，請先刪除後再新增',
    );
    return '$_temp0';
  }

  @override
  String get clockEntryEditCatalogEmpty => '所有城市皆已新增';

  @override
  String get clockEmptyHint => '目前沒有時鐘。\n點選右下角的「+」按鈕即可新增。';

  @override
  String get homeMenuSettings => '設定';

  @override
  String get settingsAppBarTitle => '設定';

  @override
  String get settingsSectionDisplay => '顯示';

  @override
  String get settingsSectionDefaults => '預設值';

  @override
  String get settingsSectionAbout => '關於';

  @override
  String get settingsThemeLabel => '主題';

  @override
  String get settingsThemeSystem => '系統';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsDefaultSnoozeLabel => '貪睡分鐘';

  @override
  String settingsDefaultSnoozeOption(int minutes) {
    return '$minutes 分鐘';
  }

  @override
  String get settingsDefaultAlarmSoundLabel => '鬧鐘音效';

  @override
  String get settingsLanguageLabel => '語言';

  @override
  String get settingsLanguageSystem => '跟隨系統';

  @override
  String get settingsLanguageDialogTitle => '選擇語言';

  @override
  String get settingsSectionDiagnostics => '診斷紀錄';

  @override
  String get settingsDiagnosticLogToggle => '啟用診斷紀錄';

  @override
  String get settingsDiagnosticLogToggleDescription =>
      '將計時器操作、權限變更、通知觸發與例外狀況記錄到裝置內檔案。不會記錄個人資訊（標籤/位置）。';

  @override
  String get settingsDiagnosticShareLogs => '分享紀錄';

  @override
  String get settingsDiagnosticShareLogsSubject => 'TimerUtility 診斷紀錄';

  @override
  String get settingsDiagnosticShareLogsDescription =>
      '將已儲存的紀錄打包為 zip 並開啟分享選單。';

  @override
  String get settingsDiagnosticShareLogsInProgress => '正在準備紀錄…';

  @override
  String get settingsDiagnosticShareLogsSuccess => '已開啟分享選單';

  @override
  String settingsDiagnosticShareLogsError(String message) {
    return '分享紀錄失敗：$message';
  }
}
