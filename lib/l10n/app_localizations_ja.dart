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
  String get homeOpenStopwatch => 'ストップウォッチを開く';

  @override
  String get homeOpenTimer => 'タイマーを開く';

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
  String get timerListEmptyHint => 'タイマーがありません。\n右下の「タイマーを追加」から追加できます。';

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
  String get alarmSoundUrgent => '急ぎ';

  @override
  String get notificationTimerEndedTitle => 'タイマー';

  @override
  String get notificationTimerEndedBody => '時間になりました。';

  @override
  String get notificationTimerCompletedBackgroundBody =>
      'アプリのバックグラウンド中にタイマーが終了しました。';
}
