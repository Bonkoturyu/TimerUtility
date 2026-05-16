# 翻訳一覧（ARB キー × ja / en）

このドキュメントは `lib/l10n/app_ja.arb` と `lib/l10n/app_en.arb` の対訳を 1 ファイルに俯瞰するためのレビュー用ミラーです。
**コードから参照されるソース・オブ・トゥルースは ARB ファイル**であり、本書はあくまで人間レビュー用の見やすいビューに過ぎません。

更新ルール:

- ARB を編集したら本書も同期する（CI で diff チェック予定 / 当面は手動）
- プレースホルダ表記（`{count}`, `{minutes}` 等）はそのまま記載する
- ICU plural 構文（`{count, plural, ...}`）は `ja` / `en` で形式が異なるので注釈欄に明記する
- 既存翻訳の文言調整は ARB 側を直し、本書を同じ commit で更新する
- **zh / zh_Hant / ko の翻訳は本書には載せず、ARB ファイル
  ([lib/l10n/app_zh.arb](../lib/l10n/app_zh.arb) /
  [lib/l10n/app_zh_Hant.arb](../lib/l10n/app_zh_Hant.arb) /
  [lib/l10n/app_ko.arb](../lib/l10n/app_ko.arb)) を直接参照する**。
  5 列ミラー化は横幅が肥大化してレビュー性が下がるため不採用 (A-3 / 2026-05-16)。
  ja / en 列は引き続き本書で対訳一覧として保守する。
- **既知の差分**: 本ファイルの ja / en 表は Phase 11 以前の語彙が一部残っており、
  最新の ARB と完全には同期していない。A-3 (2026-05-16) で
  `homeOpen*` / `timerListEmptyHint` / `alarmListEmptyHint` の 3 グループを
  同期したが、Phase 9.5 以降に追加された一部キー (clock 系 / 通知 channel 系 /
  presetSheetManageButton 等) は未収録。Phase 11 close out PR で一括同期予定

最終更新日: 2026-05-16（A-3 — zh / zh_Hant / ko の本格翻訳完了に伴い、3 言語は ARB 直接参照運用へ切替）

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
| `alarmSnooze` | スヌーズ | Snooze | セカンダリ |
| `alarmSnoozePickerTitle` | スヌーズ時間を選択 | Choose snooze duration | bottom sheet タイトル |
| `alarmSnoozeMinutes` | {minutes} 分 | {minutes, plural, =1{1 minute} other{{minutes} minutes}} | bottom sheet オプション（ja は固定形式） |
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
| `alarmEditSnoozeMinutes` | {count}分 | {count, plural, =1{1 minute} other{{count} minutes}} | SegmentedButton (5/10/15) |
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

## 音源カタログ表示名

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `alarmSoundDefault` | デフォルト | Default | カタログ表示名 |
| `alarmSoundGentle` | やさしい | Gentle | カタログ表示名 |
| `alarmSoundWarning` | 警告 | Warning | カタログ表示名（soundId='warning'） |
| `timerSoundSheetTitle` | 音源を選択 | Choose sound | bottom sheet タイトル（タイマー / プリセット共通） |

> 将来 ~10 音源まで増える予定。新規音源を追加するときは `alarmSound<XXX>` 形式で本表に追記する。

## 通知本文

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `notificationTimerEndedTitle` | タイマー | Timer | 通知タイトル |
| `notificationTimerEndedBody` | 時間になりました。 | Time is up. | 通知本文 |
| `notificationTimerCompletedBackgroundBody` | アプリのバックグラウンド中にタイマーが終了しました。 | Timer ended while the app was in the background. | バックグラウンド完了通知 |

## ライセンス画面

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `licenseMenuOverflow` | ライセンス | Licenses | HomeScreen AppBar overflow メニュー項目 |
| `licenseGroupBundledSounds` | 同梱音源 | Bundled sounds | LicensesScreen のセクション見出し |
| `licenseGroupSoftware` | ソフトウェアライセンス | Software licenses | LicensesScreen のセクション見出し |

## プリセット選択シート（FAB → bottom sheet）

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `presetSheetTitle` | プリセットから選択 | Choose preset | bottom sheet タイトル |
| `presetSheetCustomButton` | カスタム時間で作成 | Create with custom time | プリセット未使用時のフォールバック |

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
| `presetTemplateReplaceLimitWarning` | {discarded, plural, =0{} other{プリセット件数の上限を超えたため、{discarded} 件が追加されませんでした}} | {discarded, plural, =0{} =1{1 preset was skipped because the limit was reached} other{{discarded} presets were skipped because the limit was reached}} | append 時に上限到達した件数を伝える SnackBar |

## プリセットラベル（duration → 表示文字列）

ラベル未指定の Preset を表示するときに自動生成される表記。`formatPresetDurationOnly`（`lib/presentation/widgets/preset_label_formatter.dart`）から呼ばれる。

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `presetLabelSeconds` | {count}秒 | {count, plural, =1{1 second} other{{count} seconds}} | 秒のみ（< 1 分） |
| `presetLabelMinutes` | {count}分 | {count, plural, =1{1 minute} other{{count} minutes}} | 分のみ（< 1 時間 & 秒 = 0） |
| `presetLabelHours` | {count}時間 | {count, plural, =1{1 hour} other{{count} hours}} | 時のみ（分 = 0 & 秒 = 0） |

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
| `settingsSectionAbout` | 情報 | About | セクション見出し |
| `settingsThemeLabel` | テーマ | Theme | ListTile title |
| `settingsThemeSystem` | システム | System | SegmentedButton ラベル (ThemeMode.system) |
| `settingsThemeLight` | ライト | Light | SegmentedButton ラベル (ThemeMode.light) |
| `settingsThemeDark` | ダーク | Dark | SegmentedButton ラベル (ThemeMode.dark) |
| `settingsDefaultSnoozeLabel` | スヌーズ分 | Snooze minutes | ListTile title |
| `settingsDefaultSnoozeOption` | {minutes} 分 | {minutes} min | SegmentedButton ラベル (5/10/15) |
| `settingsDefaultAlarmSoundLabel` | アラーム音源 | Alarm sound | ListTile title |

---

## レビュー・更新者向けメモ

- ARB を変更したら `flutter gen-l10n` を実行 → `lib/l10n/app_localizations.dart` 系の生成物が更新される
- 本書の表は「key 単位の対訳が探しやすいこと」を優先しているので、ja / en 両方のセル幅が極端に違っても気にしない
- 中国語 / 韓国語の experimental flag が立った段階で `zh` / `ko` 列を追加する（Phase 8.5 ロードマップ）
- 既存翻訳の自然さに違和感を感じたら、まず「該当 key の用途列」を読んで文脈を把握する
