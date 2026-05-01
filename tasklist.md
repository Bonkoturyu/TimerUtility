# tasklist.md

短期タスク（直近の作業項目）を管理するファイル。
中長期の Phase 管理は `BACKLOG.md` を参照すること。

本ファイルは「今日〜数日以内に着手するもの」「進行中のもの」のみを扱う。
完了タスクは適宜削除し、肥大化させない。

---

## 凡例

- `[ ]` 未着手
- `[~]` 進行中
- `[x]` 完了（次回更新時に削除候補）
- `[!]` ブロック中（理由を併記）

---

## 進行中

<!-- 現在進行中のタスクをここに記載 -->
- なし（Phase 7 スヌーズ機能本体まで完了、2026-05-01）

---

## 直近の予定

### Phase 7「スヌーズ機能本体」完了内容（2026-05-01）

- [x] `lib/domain/timer/snooze_calculator.dart` 新規（Pure Dart、Clock 注入、3/5/10 分プリセット限定 + ArgumentError、Set 定数 `allowedMinutes`）
- [x] `test/domain/timer/snooze_calculator_test.dart` 新規（8 シナリオ: 3/5/10 分の正常 + 日付跨ぎ + プリセット外 3 種 + allowedMinutes 検証）
- [x] `lib/domain/timer/timer_service.dart` に `snooze(entity, snoozeMinutes)` 追加（ringing → running、endAt = now + N 分、duration 不変）
- [x] `test/domain/timer/timer_service_test.dart` にスヌーズ 9 シナリオ追加
- [x] `lib/application/timer_notifier.dart` に `snooze(int)` 追加（state 更新 + ticker 再開 + NotificationScheduler.schedule + AlarmRingingNotifier.stop で audioplayers 停止）
- [x] `test/application/timer_notifier_test.dart` にスヌーズ 3 シナリオ追加（5 分 re-arm + scheduler verify + StateError）
- [x] `lib/presentation/screens/alarm_ringing_screen.dart` のスヌーズボタンをモーダル + 3/5/10 分選択 + `TimerNotifier.snooze` 呼び出しに置き換え（snooze_calculator import）
- [x] `test/presentation/screens/alarm_ringing_screen_test.dart` 旧スヌーズテストを 3 つの新シナリオに置き換え（チョイスシート表示 / 5 分選択で running + 画面遷移 / キャンセルで現状維持）。`_SeededTimerNotifier` で ringing 状態をシード、`super.build()` で _ticker dispose を継承
- [x] flutter analyze: No issues found
- [x] flutter test: 162 / 162 passed（既存 140 + 新規 22）
- [x] dart format 整形済み
- [ ] 実機検証: ringing → snooze 5 分 → 5 分後に再鳴動 + 通知音 + AlarmRingingScreen 自動表示（Auto 範囲外）

### カスタム時間タイマー UI 完了内容（2026-05-01）

- [x] `lib/presentation/widgets/duration_picker.dart` 新規（CupertinoPicker × 3 のホイール、確定/キャンセル）
- [x] `test/presentation/widgets/duration_picker_test.dart` 新規（7 シナリオ: 初期値表示 / 0:00:00 disabled / positive enabled / 99:00:00 確定 OK + 戻り値検証 / 99h+1s で disabled / Cancel で null pop / drag で値変化）
- [x] `lib/presentation/screens/timer_screen.dart` 編集: プリセット行末尾に「カスタム」FilledButton.tonal を追加 → `showModalBottomSheet<Duration>` 経由で DurationPicker 表示 → 確定値で `TimerNotifier.create` 呼び出し
- [x] `test/presentation/screens/timer_screen_test.dart` 編集: setup mode に 3 シナリオ追加（カスタムボタン表示 / モーダル表示 / 確定で active 遷移）+ 1 シナリオ（キャンセルで setup 維持）
- [x] flutter analyze: No issues found
- [x] flutter test: 136 / 136 passed（既存 126 + 新規 10）
- [x] dart format で整形済み
- [ ] 実機で「カスタム時間（例: 1h 30m）→ Start → カウントダウン → 鳴動」の動作確認（Auto 範囲外）

### Phase 6 実機検証結果（2026-04-30、Pixel 6a / Android 16）

- [x] パターン 1（前面）: AlarmRingingScreen 遷移 + カスタム音再生 + Stop 動作
- [x] パターン 2（背景）: ロック画面上に AlarmRingingScreen + バンドル音源再生 + Stop 1 回で setup mode
- [x] パターン 3（強制終了）: コールドスタート deep link + バンドル音源がアラーム音量で再生 + Stop で setup mode
- [x] 権限なし時のヘッドアップ通知フォールバック（adapter の動的判定で動作）
- [x] 設定画面誘導の往復動作

検証中に発見した問題と修正は docs/android-constraints.md の「Phase 6 実機検証で
見つかって修正した問題（再発防止メモ）」に集約。

### Phase 6c 完了内容（2026-04-30）

- [x] FlutterLocalNotificationAdapter に PermissionChannel を注入
- [x] schedule 内で `canUseFullScreenIntent()` を毎回検査し、false 時は `fullScreenIntent: false` でヘッドアップ通知化
- [x] `MissingPluginException` / `PlatformException` 時は安全側（false）にフォールバック
- [x] docs/permissions.md / docs/architecture.md / docs/android-constraints.md を Phase 6 完了範囲で更新
- [x] 実機検証フォロー修正:
  - MainActivity.onCreate で `setShowWhenLocked(true)` / `setTurnScreenOn(true)` のランタイム呼び出し
  - main() の通知タップ callback と TimerScreen の ringing listener に重複ガード、`_leaveAlarmScreen` は `context.go('/timer')` で全置換
  - コールドスタート deep link（`getNotificationAppLaunchDetails()` で `initialLocation` 切替）
  - TimerNotifier.clear() で notification cancel
  - `assets/sounds/alarm_default.mp3` を `android/app/src/main/res/raw/` にもコピー、Channel に `RawResourceAndroidNotificationSound` + `AudioAttributesUsage.alarm` を明示。Channel id を v4 までバンプ（旧 id は init 時に削除）
- [x] flutter analyze: No issues found
- [x] flutter test: 126 / 126 passed

### Phase 6b 完了内容（2026-04-30）

- [x] `domain/ports/permission_manager.dart` に `checkFullScreenIntent` / `openFullScreenIntentSettings` 追加
- [x] `lib/infrastructure/platform/permission_channel.dart` 新規（`com.bonkotu.timer/permission` Channel ラッパ）
- [x] `lib/infrastructure/permission/permission_handler_adapter.dart` を const 解除し PermissionChannel 注入対応
- [x] Native `MainActivity.kt`: `com.bonkotu.timer/permission` Channel ハンドラ登録、`canUseFullScreenIntent()` (API 34+) と `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` Intent 発行を実装。古い API では true 返却 + アプリ詳細画面フォールバック
- [x] `application/permission_notifier.dart`: `PermissionState` に `fullScreenIntent` 追加（freezed 再生成）、`openFullScreenIntentSettings` メソッド追加、`refresh` で 3 軸読み込み
- [x] `presentation/screens/timer_screen.dart`: FSI 拒否時のバナー追加（'banner_full_screen_intent'）
- [x] `test/infrastructure/platform/permission_channel_test.dart` 新規 + 4 テスト
- [x] `test/application/permission_notifier_test.dart` を 3 軸対応 + FSI delegate テスト追加
- [x] `test/presentation/screens/timer_screen_test.dart` に FSI バナー Widget テスト追加 + 既存 banner テストを 3 軸対応
- [x] flutter analyze: No issues found
- [x] flutter test: 126 / 126 passed

### Phase 6a 完了内容（2026-04-30）

- [x] AndroidManifest に `USE_EXACT_ALARM` / `USE_FULL_SCREEN_INTENT` 追加
- [x] `<activity>` に `android:showOnLockScreen="true"` / `android:turnScreenOn="true"` 追加
- [x] FlutterLocalNotificationAdapter:
  - 通知 Channel の `importance: high` → `max`、`playSound: false` 追加
  - `AndroidNotificationDetails` を `importance: max` / `priority: max` / `fullScreenIntent: true` /
    `visibility: NotificationVisibility.public` / `playSound: false` に更新
- [x] flutter analyze: No issues found
- [x] flutter test: 120 / 120 passed

### Phase 5 完了内容（2026-04-30）

- [x] `assets/sounds/` に default / gentle / urgent の 3 音源を配置 + LICENSES.md
- [x] `pubspec.yaml` の `flutter:` セクションに `assets/sounds/` 登録
- [x] `lib/domain/timer/alarm_sound.dart`（freezed ValueObject、`AlarmSound.create` でバリデーション）
- [x] `lib/domain/timer/alarm_sound_catalog.dart`（all / defaultSound / findById）+ 6 ユニットテスト
- [x] `lib/domain/timer/timer_entity.dart` に `String? soundId` 追加（freezed 再生成）
- [x] `lib/domain/timer/timer_service.dart` の `createIdle` に `soundId` 引数追加
- [x] `lib/domain/ports/alarm_sound_player.dart`（play / stop / isPlaying / dispose）
- [x] `lib/infrastructure/audio/audioplayers_adapter.dart`（`ReleaseMode.loop` + `AssetSource`）
- [x] `lib/application/alarm_sound_player_provider.dart`
- [x] `lib/application/alarm_ringing_notifier.dart`（`AlarmRingingState` freezed + start / stop / snoozeRequested）+ 4 ユニットテスト
- [x] `lib/application/timer_notifier.dart` に ringing 連携: tick で ringing 化を検知して AlarmRingingNotifier.start を発火、cancel/reset で stop を発火
- [x] `lib/presentation/screens/alarm_ringing_screen.dart`（Stop / Snooze ボタン）+ 3 Widget テスト
- [x] `lib/main.dart`: `/alarm-ringing` ルート追加 + `onNotificationTap` callback で payload 経由 deep link
- [x] `lib/presentation/screens/timer_screen.dart`: ringing 遷移時に `context.push('/alarm-ringing')` で自動遷移
- [x] `lib/domain/ports/notification_scheduler.dart` の schedule に `payload` 引数追加（既存テストを更新）
- [x] flutter analyze: No issues found
- [x] flutter test: 120 / 120 passed
- [x] dart format で全体整形済み
- [ ] 実機で 5s タイマー → カスタム音再生 → Stop で止まる動作確認（Auto 範囲外）
- [ ] CI が緑になることを確認（push 後に GitHub Actions で確認）

### Phase 4 完了内容（2026-04-29）

- [x] `lib/domain/timer/notification_id_generator.dart`（Pure Dart、`timerId.hashCode & 0x7FFFFFFF`）+ 4 ユニットテスト
- [x] `lib/domain/ports/notification_scheduler.dart`（schedule / cancel / cancelAll）
- [x] `lib/domain/ports/permission_manager.dart`（DomainPermissionStatus enum + 5 メソッド）
- [x] `lib/domain/timer/timer_entity.dart` 拡張: `notificationId` フィールド追加
- [x] `lib/domain/timer/timer_service.dart` 更新: NotificationIdGenerator 注入で createIdle 時に id を発番
- [x] `lib/infrastructure/notification/flutter_local_notification_adapter.dart`（`zonedSchedule` + AndroidScheduleMode 切替）
- [x] `lib/infrastructure/permission/permission_handler_adapter.dart`
- [x] `lib/application/notification_scheduler_provider.dart`
- [x] `lib/application/permission_notifier.dart`（PermissionState freezed + Notifier）+ 5 ユニットテスト
- [x] `lib/application/timer_notifier.dart` に通知連携: start/resume で schedule、pause/cancel/reset で cancel
- [x] `lib/main.dart` で `WidgetsFlutterBinding.ensureInitialized()` + `Adapter.initialize()`
- [x] `lib/presentation/screens/timer_screen.dart` に権限拒否時バナー（POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM）+ 3 Widget テスト
- [x] AndroidManifest.xml に POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / WAKE_LOCK / VIBRATE 追加
- [x] android/app/build.gradle.kts: minSdk=26、coreLibraryDesugaring 有効化
- [x] pubspec.yaml に `flutter_local_notifications: ^19.0.0` `permission_handler: ^11.3.1` `timezone: ^0.10.1` `flutter_timezone: ^5.0.2` 追加
- [x] adapter で `tz.setLocalLocation` を実行（zonedSchedule の前提条件）
- [x] android/app/build.gradle.kts: desugar_jdk_libs を 2.1.4 へ更新（flutter_local_notifications 19 が要求）
- [x] flutter analyze: No issues found
- [x] flutter test: 106 / 106 passed
- [x] Emulator (Pixel 6a API 33) での権限フロー / バナー UI 動作確認済み
- [x] Emulator で `_plugin.show()` 経由の即時通知が表示できることを確認（チャンネル / 権限 / プラグイン初期化が正常）
- [x] AndroidManifest に `flutter_local_notifications` の `<receiver>` 2 つ + `RECEIVE_BOOT_COMPLETED` 権限を追加（プラグイン README で必須宣言）
- [x] **実機 (Pixel 6a / Android 16) で 5 秒タイマー → 通知発火 + バイブ動作確認**
- [x] docs/domain-model.md（TimerEntity に notificationId、NotificationIdGenerator 章）反映済み
- [x] docs/architecture.md（ports/permission_manager 追加 + ディレクトリ構造の Phase 4/5 実装状況反映）更新（2026-04-30）
- [ ] CI が緑になることを確認（push 後に GitHub Actions で確認）

### ドキュメント整備の仕上げ（Phase 0 完了済み）

- [x] ルート直下の `*.md` を `docs/` および `docs/adr/` へ移動
- [x] `CLAUDE.md` を最低限の制約集に圧縮
- [x] `tasklist.md` を新規作成
- [x] `BACKLOG.md` の Phase 0 チェック項目を更新（ドキュメント整備完了を反映）
- [x] `README.md` を最低限のプロジェクト説明に更新

### Phase 1 完了内容（2026-04-29）

- [x] `flutter create --org com.bonkotu.timer --project-name timer_utility --platforms=android .` 実行
- [x] レイヤー別ディレクトリ構造を作成（`lib/{domain,application,infrastructure,presentation}/`）
- [x] `pubspec.yaml` に Phase 1 依存パッケージ追加（115 依存解決済み）
- [x] `analysis_options.yaml` を厳格化（strict-casts/inference/raw-types、freezed 除外、custom_lint）
- [x] `.github/workflows/ci.yml` を新規作成（format / analyze / test ジョブ）
- [x] `lib/main.dart` を ProviderScope + GoRouter の最小構成に書き換え
- [x] `test/widget_test.dart` を新 main.dart に対応するスモークテストに書き換え
- [x] Kotlin パッケージパス差異を `docs/architecture.md` で実態に合わせて修正
- [x] CLAUDE.md のテストポリシーを `flutter_test` 経由に修正（`test` 直接依存はエコシステム制約で断念）
- [x] `flutter analyze` → No issues found
- [x] `flutter test` → All tests passed
- [x] CI が緑になることを確認（push 後の GitHub Actions 実行で確認済み）

### Phase 3 完了内容（2026-04-29）

- [x] `lib/domain/timer/timer_status.dart` (enum 6 状態)
- [x] `lib/domain/timer/timer_entity.dart` (freezed クラス、Phase 3 最小フィールド)
- [x] `lib/domain/timer/timer_service.dart` (Clock + idGenerator 注入) + 31 ユニットテスト
- [x] `lib/application/timer_notifier.dart` (`@Riverpod` Notifier、Timer.periodic 200ms) + 10 fake_async テスト
- [x] `lib/presentation/screens/timer_screen.dart` (Setup/Active 2 モード) + 5 Widget テスト
- [x] `lib/main.dart` 更新: `/timer` ルート追加、HomeScreen に導線
- [x] flutter analyze: No issues found
- [x] flutter test: 93 / 93 passed (Phase 2 の 47 + Phase 3 の 46)
- [x] domain 層カバレッジ: timer_service 100%、stopwatch_service 100%、duration_formatter 100%
- [x] バックグラウンド復帰時に endAt 過ぎていれば即 ringing（Notifier テストで検証）
- [ ] CI が緑になることを確認（push 後に GitHub Actions で確認）

### Phase 2 完了内容（2026-04-29）

- [x] エコシステム互換性: `dependency_overrides: analyzer_plugin: ^0.13.0` で build_runner を解決
- [x] `lib/domain/shared/duration_formatter.dart` (Pure Dart) + 13 ユニットテスト
- [x] `lib/domain/stopwatch/stopwatch_state.dart` (freezed sealed class: Idle / Running / Paused + LapRecord)
- [x] `lib/domain/stopwatch/stopwatch_service.dart` (Clock 注入、Pure Dart) + 16 ユニットテスト
- [x] `lib/application/clock_provider.dart` (`@Riverpod(keepAlive: true)`)
- [x] `lib/application/stopwatch_notifier.dart` (`@Riverpod` Notifier + stopwatchServiceProvider) + 8 Notifier テスト
- [x] `lib/presentation/widgets/lap_list.dart` + 4 Widget テスト
- [x] `lib/presentation/screens/stopwatch_screen.dart` (ConsumerStatefulWidget + Timer.periodic in dispose) + 4 Widget テスト
- [x] `lib/main.dart` 更新: `/stopwatch` ルート追加、HomeScreen に導線
- [x] BACKLOG / docs/architecture.md の clock_provider 配置場所修正（ADR 0004 整合）
- [x] flutter analyze: No issues found
- [x] flutter test: 47 / 47 passed
- [x] domain 層カバレッジ: stopwatch_service 100%、duration_formatter 100%（DoD 90% を大幅クリア）
- [ ] CI が緑になることを確認（push 後に GitHub Actions で確認）

### Phase 1 着手準備

- [x] `flutter create` 実行時の org / projectName を確定
  - org: `com.bonkotu.timer`
  - projectName: `timer_utility`
- [x] `pubspec.yaml` で追加する依存パッケージリストを最終確認
  - `freezed` / `freezed_annotation` を追加（Entity の copyWith / sealed class の網羅性検証用途）
  - `intl` は Phase 1 では追加せず、Phase 11（ローカライズ）着手時に `flutter_localizations` とセットで追加
  - `json_serializable` は Drift 永続化のため不要（外部 API 連携が出てきたら再検討）
- [x] Auto 運用ポリシーを CLAUDE.md に明文化
  - 自動実行範囲: コード生成 + テスト実行 + ローカルコミットまで（push は手動）
  - 停止条件: テスト 3 回連続失敗 / 同一ファイル 5 回以上連続編集 / 100 行超の新規生成 / Phase DoD 達成
- [x] `flutter create` の実行環境を確定: HP ProDesk（本マシン）
- [x] Flutter SDK 環境の Warning / NG 解消
  - Android SDK Command-line Tools をインストール
  - `flutter doctor --android-licenses` で全ライセンス承認
  - `flutter config --no-enable-windows-desktop` で Windows desktop 無効化
  - `flutter doctor` で `• No issues found!` を確認

### Auto 運用開始前のユーザー側作業

- [x] GitHub リポジトリ作成済み（`https://github.com/Bonkoturyu/TimerUtility.git`）
- [x] `git remote -v` で push 先 URL 設定済み
- [x] `git ls-remote` で認証確認済み
- [x] Phase 0 ドキュメント push 完了
- [ ] GitHub Settings → Actions → 有効化されていることを確認（Web UI で要確認）
- [x] 上記まで完了したら Auto 起動可能（Actions 確認のみ残）

詳細は `BACKLOG.md` の Phase 1 を参照。

---

## ブロック中

<!-- ブロック要因と解消条件をここに記載 -->
- なし

---

## メモ

- タスクの粒度: 1 タスク = 30 分〜半日程度を目安
- 1 日以上かかるタスクは `BACKLOG.md` の Phase に格上げを検討

---

最終更新日: 2026-05-01（Phase 7 スヌーズ機能本体まで完了、162 テストパス）
