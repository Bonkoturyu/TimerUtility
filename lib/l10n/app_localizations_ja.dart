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
  String get permissionBannerActionAllow => '許可する';

  @override
  String get permissionBannerActionOpenSettings => '設定を開く';

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
  String get presetSheetTitle => 'プリセットから選択';

  @override
  String get presetSheetCustomButton => 'カスタム時間で作成';

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
  String get licenseGroupBundledSounds => '同梱音源';

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
}
