// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'TimerUtility';

  @override
  String get homeOpenStopwatch => 'ストップウォッチ';

  @override
  String get homeOpenTimer => 'タイマー';

  @override
  String get homeOpenAlarm => 'アラーム';

  @override
  String get homeOpenClock => '世界時計';

  @override
  String get stopwatchAppBarTitle => 'ストップウォッチ';

  @override
  String get stopwatchStart => '開始';

  @override
  String get stopwatchPause => '一時停止';

  @override
  String get stopwatchResume => '再開';

  @override
  String get stopwatchLap => 'ラップ';

  @override
  String get stopwatchReset => 'リセット';

  @override
  String get stopwatchNoLaps => 'ラップ未記録';

  @override
  String stopwatchLapLabel(int index) {
    return 'ラップ $index';
  }

  @override
  String stopwatchSplit(String time) {
    return '区間 $time';
  }

  @override
  String stopwatchTotal(String time) {
    return '合計 $time';
  }

  @override
  String get timerListAppBarTitle => 'タイマー';

  @override
  String get timerListAddFab => 'タイマーを追加';

  @override
  String get timerListEmptyHint => 'タイマーがありません。\n右下の「＋」ボタンから追加できます。';

  @override
  String timerListLimitReached(int count) {
    return '上限 $count 件に達しています';
  }

  @override
  String get timerCardTimesUp => '終了！';

  @override
  String get timerCardActionStart => '開始';

  @override
  String get timerCardActionPause => '一時停止';

  @override
  String get timerCardActionResume => '再開';

  @override
  String get timerCardActionDismiss => '解除';

  @override
  String get timerCardActionReset => 'リセット';

  @override
  String get timerCardActionDelete => '削除';

  @override
  String get timerStatusIdle => '待機';

  @override
  String get timerStatusRunning => '進行中';

  @override
  String get timerStatusPaused => '一時停止';

  @override
  String get timerStatusRinging => '鳴動中';

  @override
  String get timerStatusCompleted => '完了';

  @override
  String get timerStatusCancelled => '取消';

  @override
  String get alarmListAppBarTitle => 'アラーム';

  @override
  String get alarmListAddFab => 'アラームを追加';

  @override
  String get alarmListEmptyHint => 'アラームがありません。\n右下の「＋」ボタンから追加できます。';

  @override
  String get alarmListRepeatEveryday => '毎日';

  @override
  String get alarmAppBarTitle => 'アラーム';

  @override
  String get alarmTimesUp => '時間です！';

  @override
  String get alarmStop => '停止';

  @override
  String get alarmVoiceStopListening => '音声停止を待機中（「停止」と話してください）';

  @override
  String get alarmVoiceStopModelDownloadRequired => 'この言語の端末内音声モデルが必要です';

  @override
  String get alarmVoiceStopModelDownloadPending => '端末内音声モデルを準備しています';

  @override
  String get alarmVoiceStopLanguageUnsupported => 'この言語は端末内音声認識に対応していません';

  @override
  String get alarmVoiceStopUnavailable => '端末内の音声停止を利用できません';

  @override
  String get alarmSnooze => 'スヌーズ';

  @override
  String get alarmSnoozePickerTitle => 'スヌーズ時間を選択';

  @override
  String alarmSnoozeMinutes(int minutes) {
    return '$minutes 分';
  }

  @override
  String get alarmSnoozeCancel => 'キャンセル';

  @override
  String get durationPickerTitle => 'カスタム時間を選択';

  @override
  String get durationPickerHours => '時';

  @override
  String get durationPickerMinutes => '分';

  @override
  String get durationPickerSeconds => '秒';

  @override
  String get durationPickerCancel => 'キャンセル';

  @override
  String get durationPickerConfirm => '決定';

  @override
  String get permissionBannerNotificationsTitle => '通知が無効です';

  @override
  String get permissionBannerNotificationsDescription =>
      'タイマーが終了したときに通知が表示されません。';

  @override
  String get permissionBannerExactAlarmTitle => '正確なアラームが無効です';

  @override
  String get permissionBannerExactAlarmDescription =>
      '省電力モード時にアラームが数分遅れる場合があります。';

  @override
  String get permissionBannerFullScreenIntentTitle => 'ロック画面でのアラームが無効です';

  @override
  String get permissionBannerFullScreenIntentDescription =>
      '権限がない場合は通知バナーで代わりにお知らせします。';

  @override
  String get permissionBannerHintTapToAllow => 'タップで権限を変更できます。';

  @override
  String get permissionBannerHintTapToOpenSettings => 'タップで設定を開けます。';

  @override
  String get permissionBannerSeverityCritical => '[重要]';

  @override
  String get permissionBannerSeverityRecommended => '[推奨]';

  @override
  String get permissionBannerSeveritySupplementary => '[補助]';

  @override
  String get alarmSoundDefault => 'デフォルト';

  @override
  String get alarmSoundGentle => 'やさしい';

  @override
  String get alarmSoundWarning => '警告';

  @override
  String get notificationTimerEndedTitle => 'タイマー';

  @override
  String get notificationTimerEndedBody => '時間になりました。';

  @override
  String get notificationTimerCompletedBackgroundBody =>
      'アプリのバックグラウンド中にタイマーが終了しました。';

  @override
  String get notificationAlarmRingingTitle => 'アラーム';

  @override
  String get notificationAlarmRingingBody => 'アラームの時刻になりました。';

  @override
  String get notificationTimerAlarmChannelName => 'タイマーアラーム';

  @override
  String get notificationTimerAlarmChannelDescription => 'タイマー終了時のアラーム通知';

  @override
  String get notificationTimerCompletedChannelName => 'タイマー完了（バックグラウンド）';

  @override
  String get notificationTimerCompletedChannelDescription =>
      'バックグラウンド中にタイマーが終了したことを知らせる無音通知';

  @override
  String get presetSheetTitle => 'プリセットから選択';

  @override
  String get presetSheetCustomButton => 'カスタム時間で作成';

  @override
  String get presetSheetManageButton => 'プリセットを管理...';

  @override
  String get presetManageAppBarTitle => 'プリセット管理';

  @override
  String get presetManageMenuOverflow => 'プリセット管理';

  @override
  String get presetManageEmptyHint =>
      'プリセットがありません。\n+ ボタンから追加するか、テンプレートから差し替えてください。';

  @override
  String get presetManageReplaceTemplate => 'テンプレートから差し替え';

  @override
  String get presetEditTitleNew => 'プリセットを追加';

  @override
  String get presetEditTitleEdit => 'プリセットを編集';

  @override
  String get presetEditLabelHint => 'ラベル（任意）';

  @override
  String get presetEditDurationLabel => '時間';

  @override
  String get presetEditSoundLabel => '音源';

  @override
  String get presetEditCancel => 'キャンセル';

  @override
  String get presetEditSave => '保存';

  @override
  String get presetDeleteConfirmTitle => 'このプリセットを削除しますか？';

  @override
  String get presetDeleteConfirmDontAsk => '次から確認しない';

  @override
  String get presetDeleteConfirmDelete => '削除';

  @override
  String get presetDeleteConfirmCancel => 'キャンセル';

  @override
  String get presetTemplateReplaceTitle => 'テンプレートから差し替え';

  @override
  String get presetTemplateReplaceProfileGeneral => '一般用';

  @override
  String get presetTemplateReplaceProfileCooking => '料理向け';

  @override
  String get presetTemplateReplaceProfilePomodoro => 'Pomodoro';

  @override
  String get presetTemplateReplaceMode => '既存のプリセットがあります。どうしますか？';

  @override
  String get presetTemplateReplaceModeOverwrite => '上書き';

  @override
  String get presetTemplateReplaceModeAppend => '追加';

  @override
  String get presetTemplateReplaceModeCancel => 'キャンセル';

  @override
  String presetTemplateReplaceLimitWarning(int discarded) {
    String _temp0 = intl.Intl.pluralLogic(
      discarded,
      locale: localeName,
      other: 'プリセット件数の上限を超えたため、$discarded 件が追加されませんでした',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String presetLabelSeconds(int count) {
    return '$count秒';
  }

  @override
  String presetLabelMinutes(int count) {
    return '$count分';
  }

  @override
  String presetLabelHours(int count) {
    return '$count時間';
  }

  @override
  String get timerCardSoundChange => '音源を変更';

  @override
  String get timerSoundSheetTitle => '音源を選択';

  @override
  String get licenseMenuOverflow => 'ライセンス';

  @override
  String get licenseGroupBundledAssets => '同梱アセット';

  @override
  String get licenseGroupSoftware => 'ソフトウェアライセンス';

  @override
  String get alarmEditTitleNew => 'アラームを追加';

  @override
  String get alarmEditTitleEdit => 'アラームを編集';

  @override
  String get alarmEditEnabledLabel => '有効';

  @override
  String get alarmEditTimeLabel => '時刻';

  @override
  String get alarmEditRepeatLabel => '繰り返し';

  @override
  String get alarmEditRepeatOnce => '単発';

  @override
  String get alarmEditRepeatWeekly => '曜日指定';

  @override
  String get alarmEditWeekdaysLabel => '鳴らす曜日';

  @override
  String get alarmEditLabelHint => 'ラベル（任意）';

  @override
  String get alarmEditSoundLabel => '音源';

  @override
  String get alarmEditSnoozeLabel => 'スヌーズ';

  @override
  String alarmEditSnoozeMinutes(int count) {
    return '$count分';
  }

  @override
  String get alarmEditCancel => 'キャンセル';

  @override
  String get alarmEditSave => '保存';

  @override
  String get alarmEditDelete => '削除';

  @override
  String get alarmEditValidationWeekdaysEmpty => '曜日を1つ以上選択してください';

  @override
  String get alarmEditLoading => 'アラームを読み込み中…';

  @override
  String get alarmEditNotFound => '対象のアラームが見つかりませんでした';

  @override
  String get alarmDeleteConfirmTitle => 'このアラームを削除しますか？';

  @override
  String get alarmDeleteConfirmDontAsk => '次から確認しない';

  @override
  String get alarmDeleteConfirmCancel => 'キャンセル';

  @override
  String get alarmDeleteConfirmDelete => '削除';

  @override
  String get weekdayMon => '月';

  @override
  String get weekdayTue => '火';

  @override
  String get weekdayWed => '水';

  @override
  String get weekdayThu => '木';

  @override
  String get weekdayFri => '金';

  @override
  String get weekdaySat => '土';

  @override
  String get weekdaySun => '日';

  @override
  String get clockAppBarTitle => '世界時計';

  @override
  String get clockListAddFab => '時計を追加';

  @override
  String get clockDesignSegmentAnalog => 'アナログ';

  @override
  String get clockDesignSegmentDigital => 'デジタル';

  @override
  String get clockDesignSegmentCompact => 'コンパクト';

  @override
  String get clockEntryEditAppBarTitle => '時計を追加・編集';

  @override
  String clockEntryEditSectionPinned(int count, int max) {
    return '登録済み ($count/$max)';
  }

  @override
  String get clockEntryEditSectionAvailable => '追加できる都市';

  @override
  String clockEntryEditLimitReached(int count) {
    return '上限 $count 件に達しています。削除してから追加してください';
  }

  @override
  String get clockEntryEditCatalogEmpty => 'すべての都市が登録済みです';

  @override
  String get clockEmptyHint => '時計が登録されていません。\n右下の「＋」ボタンから追加できます。';

  @override
  String get homeMenuSettings => '設定';

  @override
  String get settingsAppBarTitle => '設定';

  @override
  String get settingsSectionDisplay => '表示';

  @override
  String get settingsSectionAlarmSound => 'アラーム音';

  @override
  String get settingsSectionDefaults => 'デフォルト';

  @override
  String get settingsSectionVoiceControl => '音声操作';

  @override
  String get settingsSectionAbout => '情報';

  @override
  String get settingsVersionLabel => 'バージョン';

  @override
  String get settingsThemeLabel => 'テーマ';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsDefaultSnoozeLabel => 'スヌーズ分';

  @override
  String settingsDefaultSnoozeOption(int minutes) {
    return '$minutes 分';
  }

  @override
  String get settingsDefaultAlarmSoundLabel => 'アラーム音源';

  @override
  String get settingsAlarmVolumeLabel => 'アプリ内の音量';

  @override
  String settingsAlarmVolumeValue(int percent) {
    return '$percent%';
  }

  @override
  String get settingsLanguageLabel => '言語';

  @override
  String get settingsLanguageSystem => 'システムに合わせる';

  @override
  String get settingsLanguageDialogTitle => '言語を選択';

  @override
  String get settingsVoiceStopLabel => '音声で停止';

  @override
  String get settingsVoiceStopDescription => '鳴動中だけ端末内で音声を認識します。音声は保存・送信されません。';

  @override
  String get settingsVoiceStopEnabledDescription =>
      '「停止」と話すとタイマーまたはアラームを停止します。';

  @override
  String get settingsVoiceStopChecking => '端末内音声認識を確認しています…';

  @override
  String get settingsVoiceStopModelDownloadRequired =>
      'この言語の端末内音声モデルが必要です。有効にすると取得を開始します。';

  @override
  String get settingsVoiceStopModelDownloadPending =>
      '端末内音声モデルを準備しています。完了後に利用できます。';

  @override
  String get settingsVoiceStopModelDownloadStarted =>
      '端末内音声モデルの取得を開始しました。完了後に利用できます。';

  @override
  String get settingsVoiceStopLanguageUnsupported => 'この言語は端末内音声認識に対応していません。';

  @override
  String get settingsVoiceStopUnavailable => 'この端末では端末内音声認識を利用できません。';

  @override
  String get settingsVoiceStopPermissionDenied => '音声停止にはマイク権限が必要です。';

  @override
  String get settingsOpenAppSettings => '設定を開く';

  @override
  String get importedSoundManageTitle => '取り込み音源';

  @override
  String get importedSoundManageDescription => '端末から追加した音源を管理します';

  @override
  String get importedSoundAdd => '端末から追加';

  @override
  String get importedSoundEmpty => '取り込み音源はありません。\n右下のボタンから追加できます。';

  @override
  String get importedSoundLoadError => '取り込み音源を読み込めませんでした';

  @override
  String importedSoundAdded(String name) {
    return '$name を追加しました';
  }

  @override
  String get importedSoundImportError => '音源を追加できませんでした';

  @override
  String importedSoundDuplicate(String name) {
    return '$name は追加済みです。既存の音源を選択しました。';
  }

  @override
  String get importedSoundPreview => '試聴';

  @override
  String get importedSoundPreviewError => '音源を再生できませんでした';

  @override
  String get importedSoundRename => '名前を変更';

  @override
  String get importedSoundRenameTitle => '音源の名前を変更';

  @override
  String get importedSoundNameLabel => '名前';

  @override
  String get importedSoundNameRequired => '名前を入力してください';

  @override
  String get importedSoundRenameError => '名前を変更できませんでした';

  @override
  String get importedSoundDelete => '削除';

  @override
  String get importedSoundDeleteTitle => 'この音源を削除しますか？';

  @override
  String get importedSoundDeleteDescription =>
      '使用中のタイマー、アラーム、プリセット、既定音源はデフォルト音へ変更されます。';

  @override
  String get importedSoundDeleted => '音源を削除しました';

  @override
  String get importedSoundDeleteError => '音源を削除できませんでした';

  @override
  String get importedSoundSave => '保存';

  @override
  String get importedSoundCancel => 'キャンセル';

  @override
  String get settingsSectionDiagnostics => '診断ログ';

  @override
  String get settingsDiagnosticLogToggle => '診断ログを有効化';

  @override
  String get settingsDiagnosticLogToggleDescription =>
      'タイマー操作・権限変更・通知発火・例外を端末内ファイルに記録します。個人情報 (ラベル / 位置情報) は記録されません。';

  @override
  String get timerIntervalNotificationLabel => '定間隔通知';

  @override
  String get timerIntervalNotificationDescription =>
      '計測を続けながら、設定時間ごとに短く音を鳴らします。';

  @override
  String get timerIntervalNotificationEnabledTooltip => '定間隔通知：有効';

  @override
  String get timerIntervalNotificationDisabledTooltip => '定間隔通知：無効';

  @override
  String get commonClose => '閉じる';

  @override
  String get settingsDiagnosticShareLogs => 'ログを共有';

  @override
  String get settingsDiagnosticShareLogsSubject => 'TimerUtility 診断ログ';

  @override
  String get settingsDiagnosticShareLogsDescription =>
      '保存済みログを zip にまとめて共有メニューを開きます。';

  @override
  String get settingsDiagnosticShareLogsInProgress => 'ログを準備しています…';

  @override
  String get settingsDiagnosticShareLogsSuccess => '共有メニューを開きました';

  @override
  String settingsDiagnosticShareLogsError(String message) {
    return 'ログの共有に失敗しました: $message';
  }
}
