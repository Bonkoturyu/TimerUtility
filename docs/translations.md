# 翻訳一覧（ARB キー × ja / en）

このドキュメントは `lib/l10n/app_ja.arb` と `lib/l10n/app_en.arb` の対訳を 1 ファイルに俯瞰するためのレビュー用ミラーです。
**コードから参照されるソース・オブ・トゥルースは ARB ファイル**であり、本書はあくまで人間レビュー用の見やすいビューに過ぎません。

更新ルール:

- ARB を編集したら本書も同期する（CI の `dart run tool/check_translations_doc.dart` で
  ja / en ARB と本書のキー集合 diff を自動検証している。ローカルでも同コマンドで確認可能）
- プレースホルダ表記（`{count}`, `{minutes}` 等）はそのまま記載する
- ICU plural 構文（`{count, plural, ...}`）は `ja` / `en` で形式が異なるので注釈欄に明記する
- 既存翻訳の文言調整は ARB 側を直し、本書を同じ commit で更新する
- **zh / zh_Hant / ko の翻訳は本書には載せず、ARB ファイル
  ([lib/l10n/app_zh.arb](../lib/l10n/app_zh.arb) /
  [lib/l10n/app_zh_Hant.arb](../lib/l10n/app_zh_Hant.arb) /
  [lib/l10n/app_ko.arb](../lib/l10n/app_ko.arb)) を直接参照する**。
  5 列ミラー化は横幅が肥大化してレビュー性が下がるため不採用 (A-3 / 2026-05-16)。
  ja / en 列は引き続き本書で対訳一覧として保守する。
- **同期状態**: Phase 11 close out PR (2026-05-16) で ARB との一括同期を完了。
  Phase 9.5 以降に追加された clock 系 / 通知 channel 系 / `presetSheetManageButton` /
  permission severity / 言語切替 / 診断ログの計 33 キーをすべて収録。以後 ARB を変更したら
  本書も同じ commit で同期する (上記「更新ルール」参照)。

最終更新日: 2026-07-30（端末内音声認識による鳴動停止の表示文言を
5 言語へ追加。ARB 199 → 209 キー）

---

## アプリ全体 / ホーム

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `appTitle` | TimerUtility | TimerUtility | アプリ名（固有名詞） |
| `homeOpenStopwatch` | ストップウォッチ | Stopwatch | Phase 11: HomeScreen PageView の前後タブヒント (`PageNavigationHint`) |
| `homeOpenTimer` | タイマー | Timer | 同上 |
| `homeOpenAlarm` | アラーム | Alarm | 同上 |
| `homeOpenClock` | 世界時計 | World Clock | 同上 |

## ストップウォッチ

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `stopwatchAppBarTitle` | ストップウォッチ | Stopwatch | AppBar |
| `stopwatchStart` | 開始 | Start | アクションボタン |
| `stopwatchPause` | 一時停止 | Pause | アクションボタン |
| `stopwatchResume` | 再開 | Resume | アクションボタン |
| `stopwatchLap` | ラップ | Lap | アクションボタン |
| `stopwatchReset` | リセット | Reset | アクションボタン |
| `stopwatchNoLaps` | ラップ未記録 | No laps recorded | 空表示 |
| `stopwatchLapLabel` | ラップ {index} | Lap {index} | リスト行ラベル（{index} = int） |
| `stopwatchSplit` | 区間 {time} | Split {time} | リスト行（{time} = HH:MM:SS） |
| `stopwatchTotal` | 合計 {time} | Total {time} | リスト行（{time} = HH:MM:SS） |

## タイマー一覧画面

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `timerListAppBarTitle` | タイマー | Timers | AppBar |
| `timerListAddFab` | タイマーを追加 | Add Timer | FloatingActionButton |
| `timerListEmptyHint` | タイマーがありません。\n右下の「＋」ボタンから追加できます。 | No timers yet.\nTap + at the bottom-right to add one. | 空表示ヒント |
| `timerListLimitReached` | 上限 {count} 件に達しています | {count, plural, =1{Limit reached: 1 item} other{Limit reached: {count} items}} | SnackBar（ja は plural 不使用、en は ICU plural、preset/timer/alarm の 3 画面で共用するため `items` で汎用化） |

## タイマーカード

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `timerCardTimesUp` | 終了！ | Time's up! | カード内テキスト |
| `timerCardActionStart` | 開始 | Start | プライマリボタン |
| `timerCardActionPause` | 一時停止 | Pause | プライマリボタン |
| `timerCardActionResume` | 再開 | Resume | プライマリボタン |
| `timerCardActionDismiss` | 解除 | Dismiss | プライマリボタン（鳴動中） |
| `timerCardActionReset` | リセット | Reset | プライマリボタン（完了/取消） |
| `timerCardActionDelete` | 削除 | Delete | カード削除 |
| `timerCardSoundChange` | 音源を変更 | Change sound | 音源ボタンの tooltip |
| `timerIntervalNotificationLabel` | 定間隔通知 | Interval notifications | タイマーカードの切替項目 |
| `timerIntervalNotificationDescription` | 計測を続けながら、設定時間ごとに短く音を鳴らします。 | Keep measuring and play a short sound at each set interval. | 定間隔通知の説明 |
| `timerIntervalNotificationEnabledTooltip` | 定間隔通知：有効 | Interval notifications: on | ONアイコンのtooltip / Semantics |
| `timerIntervalNotificationDisabledTooltip` | 定間隔通知：無効 | Interval notifications: off | OFFアイコンのtooltip / Semantics |
| `commonClose` | 閉じる | Close | Bottom Sheet共通の閉じる操作 |

## タイマーステータス

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `timerStatusIdle` | 待機 | idle | カード右上 Chip |
| `timerStatusRunning` | 進行中 | running | カード右上 Chip |
| `timerStatusPaused` | 一時停止 | paused | カード右上 Chip |
| `timerStatusRinging` | 鳴動中 | ringing | カード右上 Chip |
| `timerStatusCompleted` | 完了 | completed | カード右上 Chip |
| `timerStatusCancelled` | 取消 | cancelled | カード右上 Chip |

## アラーム鳴動画面

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `alarmAppBarTitle` | アラーム | Alarm | AppBar |
| `alarmTimesUp` | 時間です！ | Time's up! | 大見出し |
| `alarmStop` | 停止 | Stop | プライマリ |
| `alarmVoiceStopListening` | 音声停止を待機中（「停止」と話してください） | Listening for “Stop” | 端末内音声認識の待機状態 |
| `alarmVoiceStopModelDownloadRequired` | この言語の端末内音声モデルが必要です | An on-device speech model is required for this language | モデル未取得状態 |
| `alarmVoiceStopModelDownloadPending` | 端末内音声モデルを準備しています | Preparing the on-device speech model | モデル取得待ち状態 |
| `alarmVoiceStopLanguageUnsupported` | この言語は端末内音声認識に対応していません | This language is not supported for on-device speech recognition | 言語非対応状態 |
| `alarmVoiceStopUnavailable` | 端末内の音声停止を利用できません | On-device voice stop is unavailable | 認識不可／権限エラー状態 |
| `alarmSnooze` | スヌーズ | Snooze | セカンダリ |
| `alarmSnoozePickerTitle` | スヌーズ時間を選択 | Choose snooze duration | bottom sheet タイトル |
| `alarmSnoozeMinutes` | {minutes} 分 | {% raw %}{minutes, plural, =1{1 minute} other{{minutes} minutes}}{% endraw %} | bottom sheet オプション（ja は固定形式） |
| `alarmSnoozeCancel` | キャンセル | Cancel | bottom sheet ボタン |

## アラーム一覧画面（Phase 9.5）

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `alarmListAppBarTitle` | アラーム | Alarms | AppBar |
| `alarmListAddFab` | アラームを追加 | Add Alarm | FloatingActionButton |
| `alarmListEmptyHint` | アラームがありません。\n右下の「＋」ボタンから追加できます。 | No alarms yet.\nTap + at the bottom-right to add one. | 空表示ヒント |
| `alarmListRepeatEveryday` | 毎日 | Every day | 全曜日選択時のサブタイトル省略表示 |

## アラーム編集画面（Phase 9.5）

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `alarmEditTitleNew` | アラームを追加 | Add alarm | AppBar (新規モード) |
| `alarmEditTitleEdit` | アラームを編集 | Edit alarm | AppBar (編集モード) |
| `alarmEditEnabledLabel` | 有効 | Enabled | AppBar 右の Switch ラベル |
| `alarmEditTimeLabel` | 時刻 | Time | セクション見出し |
| `alarmEditRepeatLabel` | 繰り返し | Repeat | セクション見出し |
| `alarmEditRepeatOnce` | 単発 | Once | SegmentedButton ラベル |
| `alarmEditRepeatWeekly` | 曜日指定 | Weekly | SegmentedButton ラベル |
| `alarmEditWeekdaysLabel` | 鳴らす曜日 | Days | セクション見出し |
| `alarmEditLabelHint` | ラベル（任意） | Label (optional) | TextField placeholder |
| `alarmEditSoundLabel` | 音源 | Sound | セクション見出し |
| `alarmEditSnoozeLabel` | スヌーズ | Snooze | セクション見出し |
| `alarmEditSnoozeMinutes` | {count}分 | {% raw %}{count, plural, =1{1 minute} other{{count} minutes}}{% endraw %} | SegmentedButton (5/10/15) |
| `alarmEditCancel` | キャンセル | Cancel | アクション |
| `alarmEditSave` | 保存 | Save | AppBar 保存ボタン tooltip |
| `alarmEditDelete` | 削除 | Delete | AppBar 削除ボタン tooltip |
| `alarmEditValidationWeekdaysEmpty` | 曜日を1つ以上選択してください | Select at least one day | 保存時バリデーション SnackBar |
| `alarmEditLoading` | アラームを読み込み中… | Loading alarm… | 編集モード初期化中の placeholder |
| `alarmEditNotFound` | 対象のアラームが見つかりませんでした | The alarm could not be found | 編集対象未発見時の SnackBar |

## アラーム削除確認ダイアログ（Phase 9.5）

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `alarmDeleteConfirmTitle` | このアラームを削除しますか？ | Delete this alarm? | dialog タイトル |
| `alarmDeleteConfirmDontAsk` | 次から確認しない | Don't ask again | チェックボックスラベル |
| `alarmDeleteConfirmCancel` | キャンセル | Cancel | dialog アクション |
| `alarmDeleteConfirmDelete` | 削除 | Delete | dialog 削除アクション |

## 曜日略称

`WeekdaySelector` (Phase 9.5) で各 `FilterChip` のラベルとして使用。一覧画面の繰り返し
サブタイトルでも結合表示で再利用する。

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `weekdayMon` | 月 | Mon | 月曜 |
| `weekdayTue` | 火 | Tue | 火曜 |
| `weekdayWed` | 水 | Wed | 水曜 |
| `weekdayThu` | 木 | Thu | 木曜 |
| `weekdayFri` | 金 | Fri | 金曜 |
| `weekdaySat` | 土 | Sat | 土曜 |
| `weekdaySun` | 日 | Sun | 日曜 |

## 世界時計（Phase 10.5）

`ClockScreen` (`/clock` ルート、ホームの `ClockPage` から開く) /
`ClockEntryEditScreen` (`/clock/edit`) / `TimezoneCatalog` 由来。最大 6 都市の
現在時刻を 3 デザイン (Analog / Digital / Compact) で表示する HomeScreen の
4 番目のタブ。

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `clockAppBarTitle` | 世界時計 | World Clock | AppBar |
| `clockListAddFab` | 時計を追加 | Add clock | FloatingActionButton |
| `clockDesignSegmentAnalog` | アナログ | Analog | デザイン切替 SegmentedButton |
| `clockDesignSegmentDigital` | デジタル | Digital | デザイン切替 SegmentedButton |
| `clockDesignSegmentCompact` | コンパクト | Compact | デザイン切替 SegmentedButton |
| `clockEntryEditAppBarTitle` | 時計を追加・編集 | Add or edit clocks | 編集画面 AppBar |
| `clockEntryEditSectionPinned` | 登録済み ({count}/{max}) | Pinned ({count}/{max}) | 登録済みセクション見出し ({count}/{max} = int) |
| `clockEntryEditSectionAvailable` | 追加できる都市 | Available cities | 追加可能セクション見出し |
| `clockEntryEditLimitReached` | 上限 {count} 件に達しています。削除してから追加してください | {count, plural, =1{Maximum of 1 city reached. Remove it to add another.} other{Maximum of {count} cities reached. Remove one to add another.}} | 上限到達時の SnackBar（ja は plural 不使用、en は ICU plural） |
| `clockEntryEditCatalogEmpty` | すべての都市が登録済みです | All available cities are already pinned | 追加可能セクションが空の表示 |
| `clockEmptyHint` | 時計が登録されていません。\n右下の「＋」ボタンから追加できます。 | No clocks yet.\nTap + at the bottom-right to add one. | 空表示ヒント |

## DurationPicker

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `durationPickerTitle` | カスタム時間を選択 | Choose custom duration | bottom sheet タイトル |
| `durationPickerHours` | 時 | h | wheel ラベル |
| `durationPickerMinutes` | 分 | m | wheel ラベル |
| `durationPickerSeconds` | 秒 | s | wheel ラベル |
| `durationPickerCancel` | キャンセル | Cancel | アクション |
| `durationPickerConfirm` | 決定 | Confirm | アクション |

## 権限バナー

CVD (色覚多様性) 対応として **方針 (a) 冗長表示** を採用 (Phase 11 / PR #39)。
3 種バナーに重大度ラベル `[重要]` / `[推奨]` / `[補助]` を全ユーザ向けに併記し、
`FontWeight` 段階差と左端色帯幅で形状差も併用することで、配色だけに依存しない
識別性を確保している。

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `permissionBannerNotificationsTitle` | 通知が無効です | Notifications disabled | バナータイトル |
| `permissionBannerNotificationsDescription` | タイマーが終了したときに通知が表示されません。 | Timer-end notifications won't be shown. | バナー説明 |
| `permissionBannerExactAlarmTitle` | 正確なアラームが無効です | Exact alarms disabled | バナータイトル |
| `permissionBannerExactAlarmDescription` | 省電力モード時にアラームが数分遅れる場合があります。 | Alarms may fire several minutes late while the device is in power-saving mode. | バナー説明 |
| `permissionBannerFullScreenIntentTitle` | ロック画面でのアラームが無効です | Lock-screen alarms disabled | バナータイトル |
| `permissionBannerFullScreenIntentDescription` | 権限がない場合は通知バナーで代わりにお知らせします。 | Without this permission, alarms will appear as a heads-up banner instead. | バナー説明 |
| `permissionBannerHintTapToAllow` | タップで権限を変更できます。 | Tap anywhere to change this permission. | バナー下部 hint (denied 時、F-10 で TextButton を廃止して全体タップ可能化に移行) |
| `permissionBannerHintTapToOpenSettings` | タップで設定を開けます。 | Tap anywhere to open settings. | バナー下部 hint (permanentlyDenied / `[補助]` バナー時) |
| `permissionBannerSeverityCritical` | [重要] | [Critical] | CVD 冗長表示の重大度ラベル (Notifications denied 時に併記) |
| `permissionBannerSeverityRecommended` | [推奨] | [Recommended] | CVD 冗長表示の重大度ラベル (ExactAlarm denied 時に併記) |
| `permissionBannerSeveritySupplementary` | [補助] | [Supplementary] | CVD 冗長表示の重大度ラベル (FullScreenIntent denied 時に併記) |

## 音源カタログ表示名

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `alarmSoundDefault` | デフォルト | Default | カタログ表示名 |
| `alarmSoundGentle` | やさしい | Gentle | カタログ表示名 |
| `alarmSoundWarning` | 警告 | Warning | カタログ表示名（soundId='warning'） |
| `alarmSoundCustom1` | カスタム１ | Custom 1 | カタログ表示名（soundId='bhutan'） |
| `alarmSoundCustom2` | カスタム２ | Custom 2 | カタログ表示名（soundId='spain'） |
| `timerSoundSheetTitle` | 音源を選択 | Choose sound | bottom sheet タイトル（タイマー / プリセット共通） |

> 将来 ~10 音源まで増える予定。新規音源を追加するときは `alarmSound<XXX>` 形式で本表に追記する。

## 通知本文

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `notificationTimerEndedTitle` | タイマー | Timer | 通知タイトル |
| `notificationTimerEndedBody` | 時間になりました。 | Time is up. | 通知本文 |
| `notificationTimerCompletedBackgroundBody` | アプリのバックグラウンド中にタイマーが終了しました。 | Timer ended while the app was in the background. | バックグラウンド完了通知 |

## 通知 channel（Phase 11 A-2）

A-2 (PR #59) で i18n 化した OS 設定画面の通知 channel 名 / 説明、および
AlarmEntity 起動時の通知タイトル / 本文。`NotificationStrings` (Pure Dart) を
`lib/domain/notifications/` に配置し、locale 切替リスナーから
`NotificationScheduler.updateChannelNames` を呼び出すと、同 id `createNotificationChannel`
再呼び出しで OS 設定画面の channel 名 / 説明が即時追従する
（importance / sound / vibration は Android 仕様で保護され不変）。

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `notificationAlarmRingingTitle` | アラーム | Alarm | アラーム起動時の通知タイトル (Phase 9.5 由来、A-2 で i18n 化) |
| `notificationAlarmRingingBody` | アラームの時刻になりました。 | It's time for your alarm. | アラーム起動時の通知本文 |
| `notificationTimerAlarmChannelName` | タイマーアラーム | Timer Alarm | OS 設定画面の channel 名 (タイマー / アラーム鳴動用、共通 channel) |
| `notificationTimerAlarmChannelDescription` | タイマー終了時のアラーム通知 | Alarm notification when a timer ends | 同上の channel 説明 |
| `notificationTimerCompletedChannelName` | タイマー完了（バックグラウンド） | Timer Completed (Background) | OS 設定画面の channel 名 (起動時復元時の無音 show 通知用) |
| `notificationTimerCompletedChannelDescription` | バックグラウンド中にタイマーが終了したことを知らせる無音通知 | Silent notification when a timer ends while the app is in the background | 同上の channel 説明 |

## ライセンス画面

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `licenseMenuOverflow` | ライセンス | Licenses | HomeScreen AppBar overflow メニュー項目 |
| `licenseGroupBundledAssets` | 同梱アセット | Bundled assets | LicensesScreen のセクション見出し |
| `licenseGroupSoftware` | ソフトウェアライセンス | Software licenses | LicensesScreen のセクション見出し |

## プリセット選択シート（FAB → bottom sheet）

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `presetSheetTitle` | プリセットから選択 | Choose preset | bottom sheet タイトル |
| `presetSheetCustomButton` | カスタム時間で作成 | Create with custom time | プリセット未使用時のフォールバック |
| `presetSheetManageButton` | プリセットを管理... | Manage presets... | シート末尾のエントリ。プリセット管理画面への導線 (発見性改善 / PR #35) |

## プリセット管理画面

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `presetManageAppBarTitle` | プリセット管理 | Manage presets | AppBar |
| `presetManageMenuOverflow` | プリセット管理 | Manage presets | TimerListScreen overflow メニュー項目 |
| `presetManageEmptyHint` | プリセットがありません。\n+ ボタンから追加するか、テンプレートから差し替えてください。 | No presets yet.\nTap + to add one or replace from a template. | 空表示ヒント |
| `presetManageReplaceTemplate` | テンプレートから差し替え | Replace from template | overflow メニュー項目 |

## プリセット編集シート

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `presetEditTitleNew` | プリセットを追加 | Add preset | bottom sheet タイトル（新規） |
| `presetEditTitleEdit` | プリセットを編集 | Edit preset | bottom sheet タイトル（編集） |
| `presetEditLabelHint` | ラベル（任意） | Label (optional) | TextField hint |
| `presetEditDurationLabel` | 時間 | Duration | フォームセクション見出し |
| `presetEditSoundLabel` | 音源 | Sound | フォームセクション見出し |
| `presetEditCancel` | キャンセル | Cancel | アクション |
| `presetEditSave` | 保存 | Save | アクション |

## プリセット削除確認ダイアログ

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `presetDeleteConfirmTitle` | このプリセットを削除しますか？ | Delete this preset? | ダイアログタイトル |
| `presetDeleteConfirmDontAsk` | 次から確認しない | Don't ask again | チェックボックス |
| `presetDeleteConfirmDelete` | 削除 | Delete | プライマリ（破壊的） |
| `presetDeleteConfirmCancel` | キャンセル | Cancel | キャンセル |

## テンプレート差し替え（Plan Y）

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `presetTemplateReplaceTitle` | テンプレートから差し替え | Replace from template | プロファイル選択 / モード選択ダイアログ共通タイトル |
| `presetTemplateReplaceProfileGeneral` | 一般用 | General | プロファイル名（30s/1m/3m/5m/10m/30m） |
| `presetTemplateReplaceProfileCooking` | 料理向け | Cooking | プロファイル名（gentle 音源） |
| `presetTemplateReplaceProfilePomodoro` | Pomodoro | Pomodoro | プロファイル名（urgent 音源） |
| `presetTemplateReplaceMode` | 既存のプリセットがあります。どうしますか？ | You already have presets. What would you like to do? | モード選択ダイアログ本文 |
| `presetTemplateReplaceModeOverwrite` | 上書き | Overwrite | 破壊的アクション（既存を全削除して置換） |
| `presetTemplateReplaceModeAppend` | 追加 | Append | 既存に追加（プライマリ） |
| `presetTemplateReplaceModeCancel` | キャンセル | Cancel | キャンセル |
| `presetTemplateReplaceLimitWarning` | {discarded, plural, =0{} other{プリセット件数の上限を超えたため、{discarded} 件が追加されませんでした}} | {% raw %}{discarded, plural, =0{} =1{1 preset was skipped because the limit was reached} other{{discarded} presets were skipped because the limit was reached}}{% endraw %} | append 時に上限到達した件数を伝える SnackBar |

## プリセットラベル（duration → 表示文字列）

ラベル未指定の Preset を表示するときに自動生成される表記。`formatPresetDurationOnly`（`lib/presentation/widgets/preset_label_formatter.dart`）から呼ばれる。

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `presetLabelSeconds` | {count}秒 | {% raw %}{count, plural, =1{1 second} other{{count} seconds}}{% endraw %} | 秒のみ（< 1 分） |
| `presetLabelMinutes` | {count}分 | {% raw %}{count, plural, =1{1 minute} other{{count} minutes}}{% endraw %} | 分のみ（< 1 時間 & 秒 = 0） |
| `presetLabelHours` | {count}時間 | {% raw %}{count, plural, =1{1 hour} other{{count} hours}}{% endraw %} | 時のみ（分 = 0 & 秒 = 0） |

> 1h30m / 5m20s のような複合 duration はこの表に当てはまらず、`HH:MM:SS` 形式（`DurationFormatter`）にフォールバックする。

---

## 設定画面（Phase 11）

`SettingsScreen` (`/settings`) のセクション見出しと各 ListTile 用ラベル。
HomeScreen overflow から旧「ライセンス」エントリを削除し、ここに集約する。
`licenseMenuOverflow` (既存キー) はライセンス導線の ListTile と LicensesScreen
AppBar 両方で再利用。

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `homeMenuSettings` | 設定 | Settings | HomeScreen AppBar overflow メニュー項目 |
| `settingsAppBarTitle` | 設定 | Settings | AppBar |
| `settingsSectionDisplay` | 表示 | Display | セクション見出し |
| `settingsSectionDefaults` | デフォルト | Defaults | セクション見出し |
| `settingsSectionAlarmSound` | アプリ音量 | App volume | セクション見出し |
| `settingsSectionVoiceControl` | 音声操作 | Voice control | セクション見出し |
| `settingsSectionAbout` | 情報 | About | セクション見出し |
| `settingsVersionLabel` | バージョン | Version | ListTile title（subtitle の `1.0.0 (2)` は `package_info_plus` 実行時取得のため非翻訳） |
| `settingsThemeLabel` | テーマ | Theme | ListTile title |
| `settingsThemeSystem` | システム | System | SegmentedButton ラベル (ThemeMode.system) |
| `settingsThemeLight` | ライト | Light | SegmentedButton ラベル (ThemeMode.light) |
| `settingsThemeDark` | ダーク | Dark | SegmentedButton ラベル (ThemeMode.dark) |
| `settingsDefaultSnoozeLabel` | スヌーズ分 | Snooze minutes | ListTile title |
| `settingsDefaultSnoozeOption` | {minutes} 分 | {minutes} min | SegmentedButton ラベル (5/10/15) |
| `settingsDefaultAlarmSoundLabel` | アラーム音源 | Alarm sound | ListTile title |
| `settingsAlarmVolumeLabel` | 音量 | Volume | 音量 Slider の ListTile title |
| `settingsAlarmVolumeValue` | {percent}% | {percent}% | 音量 Slider の値表示（10〜100%、5%刻み） |
| `settingsLanguageLabel` | 言語 | Language | ListTile title (言語手動切替) |
| `settingsLanguageSystem` | システムに合わせる | Follow system | 言語選択ダイアログの先頭オプション (`localeOverride = null`、F-9 の `localeResolutionCallback` に委譲) |
| `settingsLanguageDialogTitle` | 言語を選択 | Select language | 言語選択ダイアログタイトル |
| `settingsVoiceStopLabel` | 音声で停止 | Stop by voice | 端末内音声停止トグル title |
| `settingsVoiceStopDescription` | 鳴動中だけ端末内で音声を認識します。音声は保存・送信されません。 | Recognize a voice command on-device only while an alarm is ringing. Audio is never saved or sent. | 無効時 subtitle |
| `settingsVoiceStopEnabledDescription` | 「停止」と話すとタイマーまたはアラームを停止します。 | Say “Stop” to stop the ringing timer or alarm. | 有効時 subtitle |
| `settingsVoiceStopChecking` | 端末内音声認識を確認しています… | Checking on-device speech recognition… | 利用可否確認中 |
| `settingsVoiceStopModelDownloadRequired` | この言語の端末内音声モデルが必要です。有効にすると取得を開始します。 | An on-device speech model is required for this language. Enabling this feature starts the download. | モデル取得前 subtitle |
| `settingsVoiceStopModelDownloadPending` | 端末内音声モデルを準備しています。完了後に利用できます。 | The on-device speech model is being prepared. Voice stop will be available when it finishes. | モデル取得待ち subtitle |
| `settingsVoiceStopModelDownloadStarted` | 端末内音声モデルの取得を開始しました。完了後に利用できます。 | The on-device speech model download has started. Voice stop will be available when it finishes. | モデル取得開始 SnackBar |
| `settingsVoiceStopLanguageUnsupported` | この言語は端末内音声認識に対応していません。 | This language is not supported for on-device speech recognition. | 言語非対応 subtitle |
| `settingsVoiceStopUnavailable` | この端末では端末内音声認識を利用できません。 | On-device speech recognition is unavailable on this device. | 利用不可 subtitle |
| `settingsVoiceStopPermissionDenied` | 音声停止にはマイク権限が必要です。 | Microphone permission is required for voice stop. | 権限拒否 SnackBar |
| `settingsOpenAppSettings` | 設定を開く | Open settings | permanently denied 時の SnackBar action |
| `importedSoundManageTitle` | 取り込み音源 | Imported sounds | 設定画面の管理導線と管理画面 AppBar |
| `importedSoundManageDescription` | 端末から追加した音源を管理します | Manage sounds added from your device | 設定画面の管理導線 subtitle |
| `importedSoundAdd` | 端末から追加 | Add from device | 音源追加ボタン |
| `importedSoundEmpty` | 取り込み音源はありません。<br>右下のボタンから追加できます。 | No imported sounds.<br>Use the button below to add one. | 管理画面の空表示 |
| `importedSoundLoadError` | 取り込み音源を読み込めませんでした | Could not load imported sounds | 一覧読込失敗表示 |
| `importedSoundAdded` | {name} を追加しました | Added {name} | 追加成功 SnackBar (`name` = String) |
| `importedSoundImportError` | 音源を追加できませんでした | Could not add the sound | 追加失敗 SnackBar |
| `importedSoundDuplicate` | {name} は追加済みです。既存の音源を選択しました。 | {name} has already been added. Using the existing sound. | 重複追加時 SnackBar (`name` = String) |
| `importedSoundPreview` | 試聴 | Preview | 試聴ボタン tooltip |
| `importedSoundPreviewError` | 音源を再生できませんでした | Could not play the sound | 試聴失敗 SnackBar |
| `importedSoundRename` | 名前を変更 | Rename | 名前変更ボタン tooltip |
| `importedSoundRenameTitle` | 音源の名前を変更 | Rename sound | 名前変更ダイアログタイトル |
| `importedSoundNameLabel` | 名前 | Name | 名前入力欄ラベル |
| `importedSoundNameRequired` | 名前を入力してください | Enter a name | 空の名前に対する入力エラー |
| `importedSoundRenameError` | 名前を変更できませんでした | Could not rename the sound | 名前変更失敗 SnackBar |
| `importedSoundDelete` | 削除 | Delete | 削除ボタン tooltip |
| `importedSoundDeleteTitle` | この音源を削除しますか？ | Delete this sound? | 削除確認ダイアログタイトル |
| `importedSoundDeleteDescription` | 使用中のタイマー、アラーム、プリセット、既定音源はデフォルト音へ変更されます。 | Timers, alarms, presets, and the default sound using it will change to the default sound. | 削除確認ダイアログ本文 |
| `importedSoundDeleted` | 音源を削除しました | Sound deleted | 削除成功 SnackBar |
| `importedSoundDeleteError` | 音源を削除できませんでした | Could not delete the sound | 削除失敗 SnackBar |
| `importedSoundSave` | 保存 | Save | 名前変更ダイアログの確定ボタン |
| `importedSoundCancel` | キャンセル | Cancel | 名前変更・削除確認の取消ボタン |

> 個別言語のラベル (日本語 / English / 简体中文 / 繁體中文 / 한국어) は ARB
> には個別キーを持たず、`SettingsScreen` 内の const Map `_languageDisplayNames`
> でハードコード保持している (実装は
> [lib/presentation/screens/settings_screen.dart](../lib/presentation/screens/settings_screen.dart)
> L17-23)。各言語名は **そのロケール自身の表記** で出すのが多言語アプリの慣習で、
> 現在の UI ロケールに依存させないため。公開ビルドで 5 件すべて表示される
> (2026-07-28 に `ENABLE_EXPERIMENTAL_LOCALES` フラグを撤廃)。表示順は
> `supportedLocaleTags`
> ([lib/application/settings_notifier.dart](../lib/application/settings_notifier.dart))
> が単一のソース。

### 診断ログ（Phase D）

`SettingsScreen` の「診断ログ」セクション。`DiagnosticLogger` の有効化トグルと
zip + Share Sheet 経由でのログ共有導線。詳細は
[docs/dev-log.md](dev-log.md) 「Phase D (Diagnostic Logging) 完了」セクション参照。

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `settingsSectionDiagnostics` | 診断ログ | Diagnostic logs | セクション見出し |
| `settingsDiagnosticLogToggle` | 診断ログを有効化 | Enable diagnostic logging | トグル ListTile title |
| `settingsDiagnosticLogToggleDescription` | タイマー操作・権限変更・通知発火・例外を端末内ファイルに記録します。個人情報 (ラベル / 位置情報) は記録されません。 | Record timer actions, permission changes, notification fires, and exceptions to on-device files. No personal data (labels / location) is captured. | トグル ListTile subtitle |
| `settingsDiagnosticShareLogs` | ログを共有 | Share logs | 共有 ListTile title |
| `settingsDiagnosticShareLogsSubject` | TimerUtility 診断ログ | TimerUtility diagnostic logs | Share Sheet の subject |
| `settingsDiagnosticShareLogsDescription` | 保存済みログを zip にまとめて共有メニューを開きます。 | Bundle stored logs into a zip and open the share sheet. | 共有 ListTile subtitle |
| `settingsDiagnosticShareLogsInProgress` | ログを準備しています… | Preparing logs… | zip 生成中の SnackBar |
| `settingsDiagnosticShareLogsSuccess` | 共有メニューを開きました | Share sheet opened | 成功時の SnackBar |
| `settingsDiagnosticShareLogsError` | ログの共有に失敗しました: {message} | Failed to share logs: {message} | 失敗時の SnackBar ({message} = String) |

---

## レビュー・更新者向けメモ

- ARB を変更したら `flutter gen-l10n` を実行 → `lib/l10n/app_localizations.dart` 系の生成物が更新される
- 本書の表は「key 単位の対訳が探しやすいこと」を優先しているので、ja / en 両方のセル幅が極端に違っても気にしない
- zh / zh_Hant / ko は本書に載せない (5 列ミラー不採用 / A-3 2026-05-16) — 翻訳本体は ARB ファイルを直接参照する
- 既存翻訳の自然さに違和感を感じたら、まず「該当 key の用途列」を読んで文脈を把握する
