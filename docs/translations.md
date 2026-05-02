# 翻訳一覧（ARB キー × ja / en）

このドキュメントは `lib/l10n/app_ja.arb` と `lib/l10n/app_en.arb` の対訳を 1 ファイルに俯瞰するためのレビュー用ミラーです。
**コードから参照されるソース・オブ・トゥルースは ARB ファイル**であり、本書はあくまで人間レビュー用の見やすいビューに過ぎません。

更新ルール:

- ARB を編集したら本書も同期する（CI で diff チェック予定 / 当面は手動）
- プレースホルダ表記（`{count}`, `{minutes}` 等）はそのまま記載する
- ICU plural 構文（`{count, plural, ...}`）は `ja` / `en` で形式が異なるので注釈欄に明記する
- 既存翻訳の文言調整は ARB 側を直し、本書を同じ commit で更新する

最終更新日: 2026-05-02

---

## アプリ全体 / ホーム

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `appTitle` | TimerUtility | TimerUtility | アプリ名（固有名詞） |
| `homeOpenStopwatch` | ストップウォッチを開く | Open Stopwatch | ホームのナビゲーションボタン |
| `homeOpenTimer` | タイマーを開く | Open Timer | ホームのナビゲーションボタン |

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
| `timerListEmptyHint` | タイマーがありません。\n右下の「タイマーを追加」から追加できます。 | No timers yet.\nTap "Add Timer" at the bottom-right to create one. | 空表示ヒント |
| `timerListLimitReached` | 上限 {count} 件に達しています | {count, plural, =1{Limit reached: 1 timer} other{Limit reached: {count} timers}} | SnackBar（ja は plural 不使用、en は ICU plural） |

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

## アラーム画面

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `alarmAppBarTitle` | アラーム | Alarm | AppBar |
| `alarmTimesUp` | 時間です！ | Time's up! | 大見出し |
| `alarmStop` | 停止 | Stop | プライマリ |
| `alarmSnooze` | スヌーズ | Snooze | セカンダリ |
| `alarmSnoozePickerTitle` | スヌーズ時間を選択 | Choose snooze duration | bottom sheet タイトル |
| `alarmSnoozeMinutes` | {minutes} 分 | {minutes, plural, =1{1 minute} other{{minutes} minutes}} | bottom sheet オプション（ja は固定形式） |
| `alarmSnoozeCancel` | キャンセル | Cancel | bottom sheet ボタン |

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
| `permissionBannerActionAllow` | 許可する | Allow | バナー上の許可ボタン |
| `permissionBannerActionOpenSettings` | 設定を開く | Open settings | バナー上の設定ボタン |

## 音源カタログ表示名

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `alarmSoundDefault` | デフォルト | Default | カタログ表示名 |
| `alarmSoundGentle` | やさしい | Gentle | カタログ表示名 |
| `alarmSoundUrgent` | 急ぎ | Urgent | カタログ表示名 |
| `timerSoundSheetTitle` | 音源を選択 | Choose sound | bottom sheet タイトル（タイマー / プリセット共通） |

> 将来 ~10 音源まで増える予定。新規音源を追加するときは `alarmSound<XXX>` 形式で本表に追記する。

## 通知本文

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| `notificationTimerEndedTitle` | タイマー | Timer | 通知タイトル |
| `notificationTimerEndedBody` | 時間になりました。 | Time is up. | 通知本文 |
| `notificationTimerCompletedBackgroundBody` | アプリのバックグラウンド中にタイマーが終了しました。 | Timer ended while the app was in the background. | バックグラウンド完了通知 |

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

## レビュー・更新者向けメモ

- ARB を変更したら `flutter gen-l10n` を実行 → `lib/l10n/app_localizations.dart` 系の生成物が更新される
- 本書の表は「key 単位の対訳が探しやすいこと」を優先しているので、ja / en 両方のセル幅が極端に違っても気にしない
- 中国語 / 韓国語の experimental flag が立った段階で `zh` / `ko` 列を追加する（Phase 8.5 ロードマップ）
- 既存翻訳の自然さに違和感を感じたら、まず「該当 key の用途列」を読んで文脈を把握する
