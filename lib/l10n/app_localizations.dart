import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'TimerUtility'**
  String get appTitle;

  /// No description provided for @homeOpenStopwatch.
  ///
  /// In ja, this message translates to:
  /// **'ストップウォッチ'**
  String get homeOpenStopwatch;

  /// No description provided for @homeOpenTimer.
  ///
  /// In ja, this message translates to:
  /// **'タイマー'**
  String get homeOpenTimer;

  /// No description provided for @homeOpenAlarm.
  ///
  /// In ja, this message translates to:
  /// **'アラーム'**
  String get homeOpenAlarm;

  /// No description provided for @homeOpenClock.
  ///
  /// In ja, this message translates to:
  /// **'世界時計'**
  String get homeOpenClock;

  /// No description provided for @stopwatchAppBarTitle.
  ///
  /// In ja, this message translates to:
  /// **'ストップウォッチ'**
  String get stopwatchAppBarTitle;

  /// No description provided for @stopwatchStart.
  ///
  /// In ja, this message translates to:
  /// **'開始'**
  String get stopwatchStart;

  /// No description provided for @stopwatchPause.
  ///
  /// In ja, this message translates to:
  /// **'一時停止'**
  String get stopwatchPause;

  /// No description provided for @stopwatchResume.
  ///
  /// In ja, this message translates to:
  /// **'再開'**
  String get stopwatchResume;

  /// No description provided for @stopwatchLap.
  ///
  /// In ja, this message translates to:
  /// **'ラップ'**
  String get stopwatchLap;

  /// No description provided for @stopwatchReset.
  ///
  /// In ja, this message translates to:
  /// **'リセット'**
  String get stopwatchReset;

  /// No description provided for @stopwatchNoLaps.
  ///
  /// In ja, this message translates to:
  /// **'ラップ未記録'**
  String get stopwatchNoLaps;

  /// No description provided for @stopwatchLapLabel.
  ///
  /// In ja, this message translates to:
  /// **'ラップ {index}'**
  String stopwatchLapLabel(int index);

  /// No description provided for @stopwatchSplit.
  ///
  /// In ja, this message translates to:
  /// **'区間 {time}'**
  String stopwatchSplit(String time);

  /// No description provided for @stopwatchTotal.
  ///
  /// In ja, this message translates to:
  /// **'合計 {time}'**
  String stopwatchTotal(String time);

  /// No description provided for @timerListAppBarTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイマー'**
  String get timerListAppBarTitle;

  /// No description provided for @timerListAddFab.
  ///
  /// In ja, this message translates to:
  /// **'タイマーを追加'**
  String get timerListAddFab;

  /// No description provided for @timerListEmptyHint.
  ///
  /// In ja, this message translates to:
  /// **'タイマーがありません。\n右下の「＋」ボタンから追加できます。'**
  String get timerListEmptyHint;

  /// No description provided for @timerListLimitReached.
  ///
  /// In ja, this message translates to:
  /// **'上限 {count} 件に達しています'**
  String timerListLimitReached(int count);

  /// No description provided for @timerCardTimesUp.
  ///
  /// In ja, this message translates to:
  /// **'終了！'**
  String get timerCardTimesUp;

  /// No description provided for @timerCardActionStart.
  ///
  /// In ja, this message translates to:
  /// **'開始'**
  String get timerCardActionStart;

  /// No description provided for @timerCardActionPause.
  ///
  /// In ja, this message translates to:
  /// **'一時停止'**
  String get timerCardActionPause;

  /// No description provided for @timerCardActionResume.
  ///
  /// In ja, this message translates to:
  /// **'再開'**
  String get timerCardActionResume;

  /// No description provided for @timerCardActionDismiss.
  ///
  /// In ja, this message translates to:
  /// **'解除'**
  String get timerCardActionDismiss;

  /// No description provided for @timerCardActionReset.
  ///
  /// In ja, this message translates to:
  /// **'リセット'**
  String get timerCardActionReset;

  /// No description provided for @timerCardActionDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get timerCardActionDelete;

  /// No description provided for @timerStatusIdle.
  ///
  /// In ja, this message translates to:
  /// **'待機'**
  String get timerStatusIdle;

  /// No description provided for @timerStatusRunning.
  ///
  /// In ja, this message translates to:
  /// **'進行中'**
  String get timerStatusRunning;

  /// No description provided for @timerStatusPaused.
  ///
  /// In ja, this message translates to:
  /// **'一時停止'**
  String get timerStatusPaused;

  /// No description provided for @timerStatusRinging.
  ///
  /// In ja, this message translates to:
  /// **'鳴動中'**
  String get timerStatusRinging;

  /// No description provided for @timerStatusCompleted.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get timerStatusCompleted;

  /// No description provided for @timerStatusCancelled.
  ///
  /// In ja, this message translates to:
  /// **'取消'**
  String get timerStatusCancelled;

  /// No description provided for @alarmListAppBarTitle.
  ///
  /// In ja, this message translates to:
  /// **'アラーム'**
  String get alarmListAppBarTitle;

  /// No description provided for @alarmListAddFab.
  ///
  /// In ja, this message translates to:
  /// **'アラームを追加'**
  String get alarmListAddFab;

  /// No description provided for @alarmListEmptyHint.
  ///
  /// In ja, this message translates to:
  /// **'アラームがありません。\n右下の「＋」ボタンから追加できます。'**
  String get alarmListEmptyHint;

  /// No description provided for @alarmListRepeatEveryday.
  ///
  /// In ja, this message translates to:
  /// **'毎日'**
  String get alarmListRepeatEveryday;

  /// No description provided for @alarmAppBarTitle.
  ///
  /// In ja, this message translates to:
  /// **'アラーム'**
  String get alarmAppBarTitle;

  /// No description provided for @alarmTimesUp.
  ///
  /// In ja, this message translates to:
  /// **'時間です！'**
  String get alarmTimesUp;

  /// No description provided for @alarmStop.
  ///
  /// In ja, this message translates to:
  /// **'停止'**
  String get alarmStop;

  /// No description provided for @alarmSnooze.
  ///
  /// In ja, this message translates to:
  /// **'スヌーズ'**
  String get alarmSnooze;

  /// No description provided for @alarmSnoozePickerTitle.
  ///
  /// In ja, this message translates to:
  /// **'スヌーズ時間を選択'**
  String get alarmSnoozePickerTitle;

  /// No description provided for @alarmSnoozeMinutes.
  ///
  /// In ja, this message translates to:
  /// **'{minutes} 分'**
  String alarmSnoozeMinutes(int minutes);

  /// No description provided for @alarmSnoozeCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get alarmSnoozeCancel;

  /// No description provided for @durationPickerTitle.
  ///
  /// In ja, this message translates to:
  /// **'カスタム時間を選択'**
  String get durationPickerTitle;

  /// No description provided for @durationPickerHours.
  ///
  /// In ja, this message translates to:
  /// **'時'**
  String get durationPickerHours;

  /// No description provided for @durationPickerMinutes.
  ///
  /// In ja, this message translates to:
  /// **'分'**
  String get durationPickerMinutes;

  /// No description provided for @durationPickerSeconds.
  ///
  /// In ja, this message translates to:
  /// **'秒'**
  String get durationPickerSeconds;

  /// No description provided for @durationPickerCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get durationPickerCancel;

  /// No description provided for @durationPickerConfirm.
  ///
  /// In ja, this message translates to:
  /// **'決定'**
  String get durationPickerConfirm;

  /// No description provided for @permissionBannerNotificationsTitle.
  ///
  /// In ja, this message translates to:
  /// **'通知が無効です'**
  String get permissionBannerNotificationsTitle;

  /// No description provided for @permissionBannerNotificationsDescription.
  ///
  /// In ja, this message translates to:
  /// **'タイマーが終了したときに通知が表示されません。'**
  String get permissionBannerNotificationsDescription;

  /// No description provided for @permissionBannerExactAlarmTitle.
  ///
  /// In ja, this message translates to:
  /// **'正確なアラームが無効です'**
  String get permissionBannerExactAlarmTitle;

  /// No description provided for @permissionBannerExactAlarmDescription.
  ///
  /// In ja, this message translates to:
  /// **'省電力モード時にアラームが数分遅れる場合があります。'**
  String get permissionBannerExactAlarmDescription;

  /// No description provided for @permissionBannerFullScreenIntentTitle.
  ///
  /// In ja, this message translates to:
  /// **'ロック画面でのアラームが無効です'**
  String get permissionBannerFullScreenIntentTitle;

  /// No description provided for @permissionBannerFullScreenIntentDescription.
  ///
  /// In ja, this message translates to:
  /// **'権限がない場合は通知バナーで代わりにお知らせします。'**
  String get permissionBannerFullScreenIntentDescription;

  /// No description provided for @permissionBannerActionAllow.
  ///
  /// In ja, this message translates to:
  /// **'許可する'**
  String get permissionBannerActionAllow;

  /// No description provided for @permissionBannerActionOpenSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定を開く'**
  String get permissionBannerActionOpenSettings;

  /// No description provided for @alarmSoundDefault.
  ///
  /// In ja, this message translates to:
  /// **'デフォルト'**
  String get alarmSoundDefault;

  /// No description provided for @alarmSoundGentle.
  ///
  /// In ja, this message translates to:
  /// **'やさしい'**
  String get alarmSoundGentle;

  /// No description provided for @alarmSoundWarning.
  ///
  /// In ja, this message translates to:
  /// **'警告'**
  String get alarmSoundWarning;

  /// No description provided for @notificationTimerEndedTitle.
  ///
  /// In ja, this message translates to:
  /// **'タイマー'**
  String get notificationTimerEndedTitle;

  /// No description provided for @notificationTimerEndedBody.
  ///
  /// In ja, this message translates to:
  /// **'時間になりました。'**
  String get notificationTimerEndedBody;

  /// No description provided for @notificationTimerCompletedBackgroundBody.
  ///
  /// In ja, this message translates to:
  /// **'アプリのバックグラウンド中にタイマーが終了しました。'**
  String get notificationTimerCompletedBackgroundBody;

  /// No description provided for @notificationAlarmRingingTitle.
  ///
  /// In ja, this message translates to:
  /// **'アラーム'**
  String get notificationAlarmRingingTitle;

  /// No description provided for @notificationAlarmRingingBody.
  ///
  /// In ja, this message translates to:
  /// **'アラームの時刻になりました。'**
  String get notificationAlarmRingingBody;

  /// No description provided for @presetSheetTitle.
  ///
  /// In ja, this message translates to:
  /// **'プリセットから選択'**
  String get presetSheetTitle;

  /// No description provided for @presetSheetCustomButton.
  ///
  /// In ja, this message translates to:
  /// **'カスタム時間で作成'**
  String get presetSheetCustomButton;

  /// No description provided for @presetSheetManageButton.
  ///
  /// In ja, this message translates to:
  /// **'プリセットを管理...'**
  String get presetSheetManageButton;

  /// No description provided for @presetManageAppBarTitle.
  ///
  /// In ja, this message translates to:
  /// **'プリセット管理'**
  String get presetManageAppBarTitle;

  /// No description provided for @presetManageMenuOverflow.
  ///
  /// In ja, this message translates to:
  /// **'プリセット管理'**
  String get presetManageMenuOverflow;

  /// No description provided for @presetManageEmptyHint.
  ///
  /// In ja, this message translates to:
  /// **'プリセットがありません。\n+ ボタンから追加するか、テンプレートから差し替えてください。'**
  String get presetManageEmptyHint;

  /// No description provided for @presetManageReplaceTemplate.
  ///
  /// In ja, this message translates to:
  /// **'テンプレートから差し替え'**
  String get presetManageReplaceTemplate;

  /// No description provided for @presetEditTitleNew.
  ///
  /// In ja, this message translates to:
  /// **'プリセットを追加'**
  String get presetEditTitleNew;

  /// No description provided for @presetEditTitleEdit.
  ///
  /// In ja, this message translates to:
  /// **'プリセットを編集'**
  String get presetEditTitleEdit;

  /// No description provided for @presetEditLabelHint.
  ///
  /// In ja, this message translates to:
  /// **'ラベル（任意）'**
  String get presetEditLabelHint;

  /// No description provided for @presetEditDurationLabel.
  ///
  /// In ja, this message translates to:
  /// **'時間'**
  String get presetEditDurationLabel;

  /// No description provided for @presetEditSoundLabel.
  ///
  /// In ja, this message translates to:
  /// **'音源'**
  String get presetEditSoundLabel;

  /// No description provided for @presetEditCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get presetEditCancel;

  /// No description provided for @presetEditSave.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get presetEditSave;

  /// No description provided for @presetDeleteConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'このプリセットを削除しますか？'**
  String get presetDeleteConfirmTitle;

  /// No description provided for @presetDeleteConfirmDontAsk.
  ///
  /// In ja, this message translates to:
  /// **'次から確認しない'**
  String get presetDeleteConfirmDontAsk;

  /// No description provided for @presetDeleteConfirmDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get presetDeleteConfirmDelete;

  /// No description provided for @presetDeleteConfirmCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get presetDeleteConfirmCancel;

  /// No description provided for @presetTemplateReplaceTitle.
  ///
  /// In ja, this message translates to:
  /// **'テンプレートから差し替え'**
  String get presetTemplateReplaceTitle;

  /// No description provided for @presetTemplateReplaceProfileGeneral.
  ///
  /// In ja, this message translates to:
  /// **'一般用'**
  String get presetTemplateReplaceProfileGeneral;

  /// No description provided for @presetTemplateReplaceProfileCooking.
  ///
  /// In ja, this message translates to:
  /// **'料理向け'**
  String get presetTemplateReplaceProfileCooking;

  /// No description provided for @presetTemplateReplaceProfilePomodoro.
  ///
  /// In ja, this message translates to:
  /// **'Pomodoro'**
  String get presetTemplateReplaceProfilePomodoro;

  /// No description provided for @presetTemplateReplaceMode.
  ///
  /// In ja, this message translates to:
  /// **'既存のプリセットがあります。どうしますか？'**
  String get presetTemplateReplaceMode;

  /// No description provided for @presetTemplateReplaceModeOverwrite.
  ///
  /// In ja, this message translates to:
  /// **'上書き'**
  String get presetTemplateReplaceModeOverwrite;

  /// No description provided for @presetTemplateReplaceModeAppend.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get presetTemplateReplaceModeAppend;

  /// No description provided for @presetTemplateReplaceModeCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get presetTemplateReplaceModeCancel;

  /// No description provided for @presetTemplateReplaceLimitWarning.
  ///
  /// In ja, this message translates to:
  /// **'{discarded, plural, =0{} other{プリセット件数の上限を超えたため、{discarded} 件が追加されませんでした}}'**
  String presetTemplateReplaceLimitWarning(int discarded);

  /// No description provided for @presetLabelSeconds.
  ///
  /// In ja, this message translates to:
  /// **'{count}秒'**
  String presetLabelSeconds(int count);

  /// No description provided for @presetLabelMinutes.
  ///
  /// In ja, this message translates to:
  /// **'{count}分'**
  String presetLabelMinutes(int count);

  /// No description provided for @presetLabelHours.
  ///
  /// In ja, this message translates to:
  /// **'{count}時間'**
  String presetLabelHours(int count);

  /// No description provided for @timerCardSoundChange.
  ///
  /// In ja, this message translates to:
  /// **'音源を変更'**
  String get timerCardSoundChange;

  /// No description provided for @timerSoundSheetTitle.
  ///
  /// In ja, this message translates to:
  /// **'音源を選択'**
  String get timerSoundSheetTitle;

  /// No description provided for @licenseMenuOverflow.
  ///
  /// In ja, this message translates to:
  /// **'ライセンス'**
  String get licenseMenuOverflow;

  /// No description provided for @licenseGroupBundledSounds.
  ///
  /// In ja, this message translates to:
  /// **'同梱音源'**
  String get licenseGroupBundledSounds;

  /// No description provided for @licenseGroupSoftware.
  ///
  /// In ja, this message translates to:
  /// **'ソフトウェアライセンス'**
  String get licenseGroupSoftware;

  /// No description provided for @alarmEditTitleNew.
  ///
  /// In ja, this message translates to:
  /// **'アラームを追加'**
  String get alarmEditTitleNew;

  /// No description provided for @alarmEditTitleEdit.
  ///
  /// In ja, this message translates to:
  /// **'アラームを編集'**
  String get alarmEditTitleEdit;

  /// No description provided for @alarmEditEnabledLabel.
  ///
  /// In ja, this message translates to:
  /// **'有効'**
  String get alarmEditEnabledLabel;

  /// No description provided for @alarmEditTimeLabel.
  ///
  /// In ja, this message translates to:
  /// **'時刻'**
  String get alarmEditTimeLabel;

  /// No description provided for @alarmEditRepeatLabel.
  ///
  /// In ja, this message translates to:
  /// **'繰り返し'**
  String get alarmEditRepeatLabel;

  /// No description provided for @alarmEditRepeatOnce.
  ///
  /// In ja, this message translates to:
  /// **'単発'**
  String get alarmEditRepeatOnce;

  /// No description provided for @alarmEditRepeatWeekly.
  ///
  /// In ja, this message translates to:
  /// **'曜日指定'**
  String get alarmEditRepeatWeekly;

  /// No description provided for @alarmEditWeekdaysLabel.
  ///
  /// In ja, this message translates to:
  /// **'鳴らす曜日'**
  String get alarmEditWeekdaysLabel;

  /// No description provided for @alarmEditLabelHint.
  ///
  /// In ja, this message translates to:
  /// **'ラベル（任意）'**
  String get alarmEditLabelHint;

  /// No description provided for @alarmEditSoundLabel.
  ///
  /// In ja, this message translates to:
  /// **'音源'**
  String get alarmEditSoundLabel;

  /// No description provided for @alarmEditSnoozeLabel.
  ///
  /// In ja, this message translates to:
  /// **'スヌーズ'**
  String get alarmEditSnoozeLabel;

  /// No description provided for @alarmEditSnoozeMinutes.
  ///
  /// In ja, this message translates to:
  /// **'{count}分'**
  String alarmEditSnoozeMinutes(int count);

  /// No description provided for @alarmEditCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get alarmEditCancel;

  /// No description provided for @alarmEditSave.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get alarmEditSave;

  /// No description provided for @alarmEditDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get alarmEditDelete;

  /// No description provided for @alarmEditValidationWeekdaysEmpty.
  ///
  /// In ja, this message translates to:
  /// **'曜日を1つ以上選択してください'**
  String get alarmEditValidationWeekdaysEmpty;

  /// No description provided for @alarmEditLoading.
  ///
  /// In ja, this message translates to:
  /// **'アラームを読み込み中…'**
  String get alarmEditLoading;

  /// No description provided for @alarmEditNotFound.
  ///
  /// In ja, this message translates to:
  /// **'対象のアラームが見つかりませんでした'**
  String get alarmEditNotFound;

  /// No description provided for @alarmDeleteConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'このアラームを削除しますか？'**
  String get alarmDeleteConfirmTitle;

  /// No description provided for @alarmDeleteConfirmDontAsk.
  ///
  /// In ja, this message translates to:
  /// **'次から確認しない'**
  String get alarmDeleteConfirmDontAsk;

  /// No description provided for @alarmDeleteConfirmCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get alarmDeleteConfirmCancel;

  /// No description provided for @alarmDeleteConfirmDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get alarmDeleteConfirmDelete;

  /// No description provided for @weekdayMon.
  ///
  /// In ja, this message translates to:
  /// **'月'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In ja, this message translates to:
  /// **'火'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In ja, this message translates to:
  /// **'水'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In ja, this message translates to:
  /// **'木'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In ja, this message translates to:
  /// **'金'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In ja, this message translates to:
  /// **'土'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In ja, this message translates to:
  /// **'日'**
  String get weekdaySun;

  /// No description provided for @clockAppBarTitle.
  ///
  /// In ja, this message translates to:
  /// **'世界時計'**
  String get clockAppBarTitle;

  /// No description provided for @clockListAddFab.
  ///
  /// In ja, this message translates to:
  /// **'時計を追加'**
  String get clockListAddFab;

  /// No description provided for @clockDesignSegmentAnalog.
  ///
  /// In ja, this message translates to:
  /// **'アナログ'**
  String get clockDesignSegmentAnalog;

  /// No description provided for @clockDesignSegmentDigital.
  ///
  /// In ja, this message translates to:
  /// **'デジタル'**
  String get clockDesignSegmentDigital;

  /// No description provided for @clockDesignSegmentCompact.
  ///
  /// In ja, this message translates to:
  /// **'コンパクト'**
  String get clockDesignSegmentCompact;

  /// No description provided for @clockEntryEditAppBarTitle.
  ///
  /// In ja, this message translates to:
  /// **'時計を追加・編集'**
  String get clockEntryEditAppBarTitle;

  /// No description provided for @clockEntryEditSectionPinned.
  ///
  /// In ja, this message translates to:
  /// **'登録済み ({count}/{max})'**
  String clockEntryEditSectionPinned(int count, int max);

  /// No description provided for @clockEntryEditSectionAvailable.
  ///
  /// In ja, this message translates to:
  /// **'追加できる都市'**
  String get clockEntryEditSectionAvailable;

  /// No description provided for @clockEntryEditLimitReached.
  ///
  /// In ja, this message translates to:
  /// **'上限 {count} 件に達しています。削除してから追加してください'**
  String clockEntryEditLimitReached(int count);

  /// No description provided for @clockEntryEditCatalogEmpty.
  ///
  /// In ja, this message translates to:
  /// **'すべての都市が登録済みです'**
  String get clockEntryEditCatalogEmpty;

  /// No description provided for @clockEmptyHint.
  ///
  /// In ja, this message translates to:
  /// **'時計が登録されていません。\n右下の「＋」ボタンから追加できます。'**
  String get clockEmptyHint;

  /// No description provided for @homeMenuSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get homeMenuSettings;

  /// No description provided for @settingsAppBarTitle.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settingsAppBarTitle;

  /// No description provided for @settingsSectionDisplay.
  ///
  /// In ja, this message translates to:
  /// **'表示'**
  String get settingsSectionDisplay;

  /// No description provided for @settingsSectionDefaults.
  ///
  /// In ja, this message translates to:
  /// **'デフォルト'**
  String get settingsSectionDefaults;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In ja, this message translates to:
  /// **'情報'**
  String get settingsSectionAbout;

  /// No description provided for @settingsThemeLabel.
  ///
  /// In ja, this message translates to:
  /// **'テーマ'**
  String get settingsThemeLabel;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ja, this message translates to:
  /// **'システム'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ja, this message translates to:
  /// **'ライト'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ja, this message translates to:
  /// **'ダーク'**
  String get settingsThemeDark;

  /// No description provided for @settingsDefaultSnoozeLabel.
  ///
  /// In ja, this message translates to:
  /// **'スヌーズ分'**
  String get settingsDefaultSnoozeLabel;

  /// No description provided for @settingsDefaultSnoozeOption.
  ///
  /// In ja, this message translates to:
  /// **'{minutes} 分'**
  String settingsDefaultSnoozeOption(int minutes);

  /// No description provided for @settingsDefaultAlarmSoundLabel.
  ///
  /// In ja, this message translates to:
  /// **'アラーム音源'**
  String get settingsDefaultAlarmSoundLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
