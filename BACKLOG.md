# BACKLOG.md

本プロジェクトの Phase 別タスク管理ファイル。Claude Code は作業着手前に必ず本ファイルを参照し、
対象 Phase / タスクの位置と前提条件を確認すること。

---

## 凡例

- `[ ]` 未着手
- `[~]` 進行中
- `[x]` 完了
- `[!]` ブロック中（理由を併記）

各タスクには以下が含まれる:
- **DoD**: Definition of Done（完了条件）
- **依存**: 前提となる Phase / タスク
- **参照**: 関連ドキュメント

---

## Phase 0: ドキュメント整備（最優先）

Auto 運用の土台。本 Phase が完了するまで Phase 1 以降に着手しない。

- [x] `CLAUDE.md` 作成
- [x] `BACKLOG.md` 作成
- [x] `tasklist.md` 作成（短期タスク管理）
- [x] `docs/architecture.md` 作成
- [x] `docs/domain-model.md` 作成
- [x] `docs/state-management.md` 作成
- [x] `docs/testing-strategy.md` 作成
- [x] `docs/android-constraints.md` 作成
- [x] `docs/platform-channels.md` 作成
- [x] `docs/permissions.md` 作成
- [x] `docs/assets-spec.md` 作成
- [x] `docs/adr/0001-use-riverpod.md` 作成
- [x] `docs/adr/0002-use-drift.md` 作成
- [x] `docs/adr/0003-fullscreen-intent-strategy.md` 作成
- [x] `docs/adr/0004-clock-injection-pattern.md` 作成
- [x] `CLAUDE.md` を最低限の制約集に圧縮（詳細は `docs/` へ集約）
- [x] `README.md` を最低限のプロジェクト説明に整備

**DoD**: 上記すべて作成済み、相互リンクが正しく機能している。
**依存**: なし
**参照**: `CLAUDE.md`

---

## Phase 1: プロジェクト雛形 + CI セットアップ

- [x] `flutter create` でプロジェクト生成（org=com.bonkotu.timer / projectName=timer_utility / Android 専用）
- [x] ディレクトリ構造を `CLAUDE.md` の規約通りに整備（`lib/{domain,application,infrastructure,presentation}/`、`test/`、`integration_test/`）
- [x] `pubspec.yaml` に依存追加: `flutter_riverpod`, `riverpod_annotation`, `go_router`, `clock`, `drift`, `drift_flutter`, `flutter_local_notifications`, `audioplayers`, `permission_handler`, `uuid`, `logger`, `freezed_annotation`
- [x] dev_dependencies: `riverpod_generator`, `build_runner`, `drift_dev`, `mocktail`, `fake_async`, `custom_lint`, `riverpod_lint`, `freezed`
  - 注: `test` 直接依存はエコシステム制約（flutter_test の matcher/test_api ピン留め）により断念。`flutter_test` 経由で `package:test` API を使用。詳細は CLAUDE.md テストポリシー参照
- [x] `analysis_options.yaml` 設定（strict-casts/inference/raw-types、freezed 除外、custom_lint プラグイン有効化、追加 lint ルール）
  - レイヤー間 import 制限は Phase 1 では入れず、CLAUDE.md 規約 + レビューで担保
- [x] `.github/workflows/ci.yml` 作成（`flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, `flutter test`）
- [x] `lib/main.dart` を最小構成（ProviderScope + go_router）に書き換え
- [x] 動作確認（`flutter analyze`: No issues found / `flutter test`: All tests passed）

**DoD**: `flutter analyze` がエラー 0、`flutter test` がパス（テストは雛形のみで OK）、CI が緑になる。
**依存**: Phase 0 完了
**参照**: `docs/architecture.md`

---

## Phase 2: ストップウォッチ機能（ロジック + UI）

- [x] `application/clock_provider.dart` 配置（ADR 0004 に従い application 層に配置。Pure Dart 制約を保つため）
- [x] `domain/shared/duration_formatter.dart` 実装 + Unit Test（Pure Dart クラス。Provider 化は application 層で）
- [x] `domain/stopwatch/stopwatch_state.dart`（freezed sealed class で Idle/Running/Paused + LapRecord を定義）
- [x] `domain/stopwatch/stopwatch_service.dart` 実装 + Unit Test
  - 状態遷移: idle → running → paused → idle
  - Lap 記録ロジック
  - `Clock` 注入による時間制御
- [x] `application/stopwatch_notifier.dart`（Riverpod Notifier）+ Unit Test
- [x] `presentation/screens/stopwatch_screen.dart` 実装 + Widget Test（Timer は ConsumerStatefulWidget の dispose で確実に cancel）
- [x] `presentation/widgets/lap_list.dart` 実装 + Widget Test
- [x] go_router にルート登録（`/stopwatch` と HomeScreen からの導線）

**DoD**:
- ストップウォッチが Start/Pause/Resume/Reset/Lap で正しく動く
- Unit Test カバレッジ: domain 層 90%以上
- Widget Test: 主要操作 3 シナリオ以上
- アプリを裏に回しても復帰時に正しい時刻表示（ライフサイクル対応）

**依存**: Phase 1 完了
**参照**: `docs/domain-model.md`, `docs/state-management.md`, `docs/testing-strategy.md`

---

## Phase 3: タイマー機能（単体、アラーム鳴動なし）

通知 / 音再生は未対応。カウントダウン表示と状態遷移のみ。

- [x] `domain/timer/timer_status.dart`（enum: idle, running, paused, ringing, completed, cancelled）
- [x] `domain/timer/timer_entity.dart`（id, label, duration, endAt, pausedRemaining, status, createdAt。notificationId/alarmSound/snooze は Phase 4/5/7 で追加予定）
- [x] `domain/timer/timer_service.dart` 実装 + Unit Test
  - `Clock` 注入（idGenerator も差し替え可能）
  - createIdle / start / pause / resume / cancel / tick / reset / remaining
  - Start 時に endAt 計算、ArgumentError による作成時バリデーション、不正遷移は StateError
- [x] `application/timer_notifier.dart` + Unit Test（fake_async 使用、200ms 周期 Timer.periodic で endAt 到達検知）
- [x] `presentation/screens/timer_screen.dart` 実装 + Widget Test
  - 単一タイマーの作成（Duration プリセット）・カウントダウン表示・キャンセル
  - ConsumerStatefulWidget の dispose で Timer.cancel

**DoD**:
- 単一タイマーで Start → カウントダウン → 0 到達で `ringing` 状態に遷移
- 通知や音は **まだ鳴らない**（次 Phase で対応）
- Unit Test カバレッジ: domain 層 90%以上

**依存**: Phase 2 完了
**参照**: `docs/domain-model.md`, `docs/state-management.md`

---

## Phase 4: 通知スケジューリング基盤

- [x] `docs/permissions.md` の権限取得フロー実装
- [x] `domain/ports/notification_scheduler.dart`（インターフェース定義）
- [x] `infrastructure/notification/flutter_local_notification_adapter.dart` 実装
- [x] `domain/timer/notification_id_generator.dart` 実装 + Unit Test（domain 層配置）
- [x] `domain/ports/permission_manager.dart`（インターフェース定義）
- [x] `infrastructure/permission/permission_handler_adapter.dart` 実装
- [x] `application/permission_notifier.dart`（権限状態管理）+ Unit Test
- [x] AndroidManifest.xml に必要権限を追加（POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / WAKE_LOCK / VIBRATE）
- [x] build.gradle.kts に minSdk=26 と coreLibraryDesugaring を追加
- [x] 通知チャンネル初期化処理（main.dart で `Adapter.initialize()` 実行）
- [x] TimerNotifier から start/resume 時に schedule、pause/cancel/reset 時に cancel を呼び出し
- [x] TimerScreen に権限拒否時のバナー UI 実装（Widget Test 3 シナリオ）
- [x] Adapter のモック差し替えで TimerNotifier の予約呼び出しを Unit Test
- [x] 実機 (Pixel 6a / Android 16) での通知発火 + バイブレーション動作確認

**DoD**:
- タイマー終了時に通知が表示される
- 権限拒否時のフォールバック UX が実装済み
- 通知 ID の重複が発生しない設計（Unit Test 検証）

**依存**: Phase 3 完了
**参照**: `docs/android-constraints.md`, `docs/permissions.md`, `docs/adr/0003-fullscreen-intent-strategy.md`

---

## Phase 5: カスタム音源再生 + AlarmRingingScreen

- [x] 音源を `assets/sounds/` に配置（仕様は `docs/assets-spec.md`）
- [x] `domain/timer/alarm_sound.dart`（freezed ValueObject）
- [x] `domain/timer/alarm_sound_catalog.dart`（同梱音源 default/gentle/urgent + Unit Test）
- [x] `domain/timer/timer_entity.dart` に `String? soundId` 追加
- [x] `domain/ports/alarm_sound_player.dart`（インターフェース）
- [x] `infrastructure/audio/audioplayers_adapter.dart`（ReleaseMode.loop）
- [x] `application/alarm_sound_player_provider.dart`
- [x] `application/alarm_ringing_notifier.dart`（freezed State + start / stop / snoozeRequested）+ Unit Test
- [x] `application/timer_notifier.dart` で ringing 遷移時に AlarmRingingNotifier.start を発火
- [x] `presentation/screens/alarm_ringing_screen.dart` + Widget Test 3 シナリオ（停止ボタン / スヌーズボタン）
- [x] go_router で `/alarm-ringing` ルート追加
- [x] 通知タップ → `/alarm-ringing` 遷移の Deep Link（`onDidReceiveNotificationResponse` + payload 経由）
- [x] 実機で「タイマー終了 → カスタム音再生 → Stop で止まる」を確認（Phase 6 実機検証 2026-04-30 のパターン 1〜3 + Phase 8 検証 6 で実質カバー済）

**DoD**:
- タイマー終了時にカスタム音が鳴る
- 停止ボタンで音が止まる
- Widget Test で停止/スヌーズボタンの操作を検証

**依存**: Phase 4 完了
**参照**: `docs/assets-spec.md`

---

## Phase 6: フルスクリーン Intent 対応（最難関）

- [x] AndroidManifest に `USE_FULL_SCREEN_INTENT` / `USE_EXACT_ALARM` 追加 + MainActivity に `showOnLockScreen` / `turnScreenOn` 属性追加（Phase 6a）+ MainActivity.onCreate で `setShowWhenLocked` / `setTurnScreenOn` runtime 呼び出し（実機検証フォロー）
- [x] flutter_local_notifications でフルスクリーン Intent 通知設定（importance/priority max、visibility public、sound: バンドル音源、AudioAttributesUsage.alarm）
- [x] 権限取得フロー実装。USE_FULL_SCREEN_INTENT は permission_handler でカバーされないため自前 MethodChannel `com.bonkotu.timer/permission` を導入し、状態確認 → 設定画面誘導まで実装（Phase 6b）
- [x] フォールバック実装（adapter で `canUseFullScreenIntent() == false` 時に `fullScreenIntent` フラグを落としてヘッドアップ通知化）（Phase 6c）
- [x] アプリが終了状態 / バックグラウンド / フォアグラウンドの 3 パターンで実機確認（Pixel 6a / Android 16、2026-04-30）
- [x] コールドスタート deep link（`getNotificationAppLaunchDetails()`）と warm-launch 時の二重スタック対策
- [ ] Native → Flutter のイベント送信仕様確定（`docs/platform-channels.md` 更新）— 残課題（次 Phase で必要になったら）

**DoD**:
- [x] ロック画面上にアラーム画面が表示される（権限あり時）
- [x] 権限なし時はヘッドアップ通知で代替動作
- [x] 3 パターンの実機確認結果を `docs/android-constraints.md` の検証チェックリストと「Phase 6 実機検証で見つかって修正した問題」セクションに記録

**依存**: Phase 5 完了
**参照**: `docs/android-constraints.md`, `docs/platform-channels.md`, `docs/permissions.md`

---

## Phase 7: スヌーズ機能 + カスタム時間タイマー UI

- [ ] `domain/timer/snooze_calculator.dart` 実装 + Unit Test
- [ ] `TimerService` にスヌーズメソッド追加 + Unit Test
- [ ] `NotificationScheduler` のキャンセル + 再予約フロー
- [ ] AlarmRingingScreen にスヌーズボタン動作実装
- [ ] スヌーズ時間プリセット（3 分 / 5 分 / 10 分）UI
- [ ] `presentation/widgets/duration_picker.dart` 新規実装 + Widget Test（時 / 分 / 秒のホイール選択、上限 99 時間）
- [ ] TimerScreen のプリセットチップに「カスタム」エントリ追加 → DurationPicker をモーダル表示 → `TimerNotifier.create` 呼び出し + Widget Test

**DoD**:
- スヌーズで指定時間後に再度アラームが鳴る
- スヌーズ可能回数の上限ロジック（任意、要件確認）
- TimerScreen から任意秒数（時 / 分 / 秒）のタイマーを作成できる
- DurationPicker は `duration > 0` かつ `<= Duration(hours: 99)` をバリデーション
- Unit Test カバレッジ維持

**依存**: Phase 6 完了
**参照**: `docs/domain-model.md`

**補足**: カスタム時間タイマー UI は本来 Phase 3（単体タイマー）の補完だが、ドメインは既に対応済み（[TimerEntity](lib/domain/timer/timer_entity.dart) は任意 Duration を受け付け）で UI のみの追加なので Phase 7 に組み込む。スヌーズ機能と並行して着手可能。

---

## Phase 8: 複数タイマー管理 + Drift 永続化

- [x] Drift スキーマ定義（`infrastructure/database/app_database.dart`）
- [x] `domain/ports/timer_repository.dart`
- [x] `infrastructure/database/drift_timer_repository.dart` 実装 + Unit Test（in-memory DB）
- [x] `infrastructure/database/mappers/timer_mapper.dart` 実装 + Unit Test
- [x] `domain/timer/timer_collection.dart`（複数管理ロジック）+ Unit Test
- [x] `domain/timer/exceptions.dart`（`MaxTimerCountExceededException` / `TimerNotFoundException`）
- [x] `application/timer_collection_notifier.dart` + Unit Test（起動時 DB 復元 + 過去到達タイマーの completed 化 + 通知 1 回）
- [x] `application/timer_service_provider.dart`（旧 timer_notifier.dart から分離）
- [x] `application/timer_repository_provider.dart`（main.dart で override）
- [x] 同時稼働上限のドメインルール実装（**10 本固定**）
- [x] `domain/ports/notification_scheduler.dart` に `show()` 追加（復元時の即時通知用）
- [x] `infrastructure/notification/flutter_local_notification_adapter.dart` に `show()` 実装
- [x] `presentation/screens/timer_list_screen.dart` 実装 + Widget Test 5 シナリオ
- [x] 各タイマーの個別操作 UI（カード形式: ラベル / 残り時間 / 状態バッジ / Start/Pause/Resume/Cancel/Reset/Delete）
- [x] AlarmRingingScreen を Collection 参照に書き換え（`findRinging` ベース）
- [x] `lib/main.dart` で AppDatabase + DriftTimerRepository を配線、`/timer` を TimerListScreen に置換
- [x] **削除**: `application/timer_notifier.dart` / `presentation/screens/timer_screen.dart`（単一タイマー画面の廃止）
- [x] 実機検証 (Pixel 6a / Android 16、2026-05-02): 6 シナリオすべて想定通り
  - 検証 1: 複数タイマー (3 本) 同時稼働 / 通知 ID 衝突なし
  - 検証 2: アプリ強制終了 → 再起動で idle / running / paused が状態保持で復元
  - 検証 3: 過去到達 running が completed + 無音ヘッドアップ通知 1 回 (修正後)
  - 検証 4: 上限 10 本到達後の FAB タップで SnackBar (修正後)
  - 検証 5: 各カードの Start/Pause/Resume/Delete/Reset と Stop 経由 cancelled が独立に作用
  - 検証 6: 通知タップ → AlarmRingingScreen → Stop で該当タイマーが cancelled

**DoD**:

- [x] 複数タイマーを同時に稼働できる（最大 10 本）
- [x] アプリ再起動後にタイマー状態が復元される（`endAt < now` の running は completed + `show()` 通知 1 回）
- [x] 各タイマーの通知が独立して発火する（NotificationIdGenerator が衝突しないこと検証済み）
- [x] Unit Test カバレッジ維持（180 件パス、TimerCollection / Mapper / Repository / Notifier すべて Unit Test 完備）

**依存**: Phase 7 完了
**参照**: `docs/domain-model.md`, `docs/adr/0002-use-drift.md`

### Phase 8 着手時の確定事項（2026-05-01）

- 同時稼働上限: **10 本**（`TimerCollection.maxSize`）
- `/timer` ルート: 一覧画面に置換、単一画面 (`TimerScreen`) は廃止
- Provider 構造: `timerNotifierProvider`（単一）廃止、`timerCollectionNotifierProvider` に統一
  （docs/state-management.md の `timerNotifierProvider(TimerId)` family 案も廃止）
- 復元時の過去タイマー: `completed` 扱い + `NotificationScheduler.show()` で 1 度だけ通知
  （AlarmRingingScreen は起動しない、音も鳴らさない、アプリ再起動 / 端末再起動とも同じロジック）

---

## Phase 9: プリセット機能

### Domain 層

- [x] `domain/timer/preset.dart`（Entity, freezed: id / label / duration / soundId / createdAt）
- [x] `domain/timer/preset_collection.dart`（集約ルート、最大 10 件、`add` / `update` / `remove`）
- [x] `domain/timer/preset_service.dart`（バリデーション + Clock + idGenerator 注入、sentinel ベースの soundId クリア対応）
- [x] `domain/timer/preset_templates.dart`（Pure Dart 定数、3 プロファイル: general / cooking / pomodoro 各 6 件）
- [x] `domain/timer/preset_exceptions.dart`（`MaxPresetCountExceededException` / `PresetNotFoundException`）
- [x] `domain/ports/preset_repository.dart`（findAll / findById / upsert / delete / replaceAll）
- [x] `domain/ports/user_preferences.dart`（`getBool` / `setBool` / `remove` + `UserPreferenceKeys`）

### Infrastructure 層

- [x] `infrastructure/database/app_database.dart` schemaVersion 1 → 2、Presets テーブル追加 + `MigrationStrategy`（onCreate / onUpgrade で general profile を atomic seed）
- [x] `infrastructure/database/mappers/preset_mapper.dart`（epoch-ms UTC エンコード）
- [x] `infrastructure/database/drift_preset_repository.dart`（`replaceAll` は transaction 内で delete + batch insert）
- [x] `infrastructure/preferences/shared_preferences_user_preferences.dart`（async create() + テスト用ファクトリ）

### Application 層

- [x] `application/preset_repository_provider.dart` / `application/user_preferences_provider.dart`（main.dart で override）
- [x] `application/preset_collection_notifier.dart`（keepAlive、build / restore / create / update / delete / `replaceFromTemplate(profileId, mode: overwrite | append)` + `ReplaceTemplateResult`）
- [x] `application/timer_collection_notifier.dart` に `changeSound(id, soundId)` 追加（status / endAt 保持）

### Presentation 層

- [x] `lib/l10n/app_*.arb` に約 27 キー追加（プリセット関連 + ICU plural ラベル + 音源 sheet）
- [x] `presentation/widgets/preset_label_formatter.dart`（duration → 表示文字列、ラベル併記時のサブタイトル用）
- [x] `presentation/widgets/preset_select_sheet.dart`（FAB → 2x3 GridView + カスタム時間ボタン、空時は custom ボタンのみ）
- [x] `presentation/widgets/preset_edit_sheet.dart`（label / duration wheels / sound dropdown / 保存）
- [x] `presentation/widgets/preset_delete_confirm_dialog.dart`（「次から確認しない」チェック）
- [x] `presentation/widgets/sound_select_sheet.dart`（ListTile ベース、AlarmSoundCatalog.all から動的）
- [x] `presentation/widgets/duration_picker.dart` に DurationPickerWheels を再利用可能 widget として抽出
- [x] `presentation/screens/preset_manage_screen.dart`（カード一覧 + ♪ / Edit / Delete IconButton + AppBar overflow → テンプレート差し替えフロー）
- [x] `presentation/screens/timer_list_screen.dart` 編集（FAB → preset sheet → custom 経路、カードに sound IconButton + ラベル併記、AppBar overflow → /presets）
- [x] `lib/main.dart`（DriftPresetRepository / SharedPreferencesUserPreferences 配線、`/presets` ルート追加）

### テスト

- [x] domain Unit Test 38 件（PresetCollection 12 / PresetService 17 / PresetTemplates 9）
- [x] infrastructure Unit Test 25 件（PresetMapper 7 / DriftPresetRepository 10 / SharedPreferencesUserPreferences 8）
- [x] application Unit Test 11 件（PresetCollectionNotifier、deterministic id sequence + restore 検証）
- [x] presentation Widget Test 21 件（preset_label_formatter 12 / preset_select_sheet 4 / preset_manage_screen 5）
- [x] Phase 8 Widget Test 4 件を Phase 9 配線に追従（preset sheet 経由 / sound 変更）
- [x] flutter analyze: No issues found
- [x] flutter test: **275 / 275 passed**

### 実機検証 (Pixel 6a / Android 16、2026-05-02)

10 シナリオすべて OK:

1. 初回起動 → TimerListScreen 空 + AppBar overflow に「プリセット管理」表示
2. FAB → プリセット sheet → チップ → タイマー作成
3. FAB → プリセット sheet → カスタム時間 → DurationPicker → タイマー作成
4. タイマーカードの ♪ → SoundSelectSheet → 選択反映
5. プリセット管理画面 → FAB → 新規追加
6. プリセット編集（label / duration / sound）
7. 削除確認ダイアログ「次から確認しない」チェック → 削除
8. 別プリセット削除 → ダイアログ省略で即削除
9. テンプレート置換 overwrite（料理 → 6 件 gentle）
10. テンプレート置換 append（5 件 + Pomodoro 6 → 1 件 discarded SnackBar、計 10 件）

### 実機検証フィードバック反映

- [x] テンプレート差し替えダイアログ: 追加 = FilledButton（プライマリ）、上書き = error 色 TextButton に強調入れ替え（誤タップ事故防止）
- [x] プリセット管理リストの下端 padding 96 → 128 dp（FAB と最下カード Delete ボタンの干渉解消）
- [x] 各プリセットカードに ♪ IconButton を追加（TimerCard と同位置、右上 Chip は表示専用で残す）
- [x] 音源 Chip を `IgnorePointer` で囲んで Material ink 起因の AppBar チラつきを抑制
- [x] プリセット管理カード: ラベル指定時、サブタイトルに `formatPresetDurationOnly` で時間併記
- [x] タイマー一覧カード: `entity.label` 非空時、duration の上に小さくラベル表示

### 仕様変更ログ

- [x] DurationPicker 内に音源 dropdown を統合する当初プランは取り下げ。CupertinoPicker と Dropdown が同一モーダル内で hit-test 干渉を起こしたため、カスタム時間作成時はカタログ既定音 → カードの ♪ ボタンで後から変更、という UX に変更（実機でこちらの方が直感的との確認済）
- [x] soundId `'urgent'` → `'warning'` にリネーム（i18n キー / soundId / アセットファイル名 / Pomodoro テンプレート / テスト すべて統一、pre-release 段階のため互換性配慮なし）

### docs

- [x] `docs/translations.md` 新規（ARB 全キー × ja / en の対訳ミラー、人間レビュー用）
- [x] `docs/assets-spec.md` / `docs/oss-publishing-notes.md` / `assets/sounds/LICENSES.md` を `alarm_warning.mp3` に追従

**DoD**:

- [x] プリセットの追加・編集・削除ができる
- [x] プリセットからワンタップでタイマー作成可能
- [x] テンプレートからの差し替え（overwrite / append）が動作、append は上限超過分を SnackBar で告知
- [x] 上限 10 件のドメインルール
- [x] Unit + Widget Test 計 275 件パス、Pixel 6a 10 シナリオ実機 OK

**依存**: Phase 8 完了
**参照**: `docs/domain-model.md`, `docs/translations.md`, `docs/adr/0002-use-drift.md`

---

## Phase 9.5: 指定時刻アラーム機能（曜日繰り返し + スヌーズ）

「明日 7:30 に鳴らす」「毎週月〜金の 6:00」のような目覚まし用途のアラーム機能。
Timer Aggregate とは別 Aggregate として実装する。
分離理由は `docs/adr/0005-alarm-vs-timer-separation.md` 参照。

### Domain 層

- [x] `domain/alarm/day_of_week.dart`（enum、`DateTime.weekday` と互換マッピング）
- [x] `domain/alarm/alarm_repeat.dart`（sealed class: `AlarmRepeatOnce` / `AlarmRepeatWeekly(Set<DayOfWeek>)`）+ Unit Test
- [x] `domain/alarm/alarm_entity.dart`（freezed、`docs/domain-model.md` の AlarmEntity 定義に従う）
- [x] `domain/alarm/time_of_day_value.dart`（Pure Dart 版 TimeOfDay、material 非依存）
- [x] `domain/alarm/alarm_service.dart` 実装 + Unit Test
  - `nextFireAt` / `advanceAfterFire` / `snoozeUntil` の 3 メソッド
  - `Clock` 注入、副作用なし
  - 曜日跨ぎ、日付跨ぎ、夏時間相当のエッジケースをカバー
- [x] `domain/alarm/exceptions.dart`（`AlarmNotFoundException` / `MaxAlarmCountExceededException` / `InvalidAlarmRepeatException` / `InvalidSnoozeMinutesException`）
- [x] `domain/ports/alarm_repository.dart`（`upsert` / `delete` / `findById` / `findAll`）

### Infrastructure 層

- [x] `infrastructure/database/app_database.dart` に `alarms` テーブル追加（Drift スキーマ migration）
- [x] `infrastructure/database/drift_alarm_repository.dart` 実装 + Unit Test（in-memory DB）
- [x] `infrastructure/database/mappers/alarm_mapper.dart`（AlarmEntity ⇔ AlarmsCompanion、`repeatKind` + `repeatDaysBitmask` 専用列で永続化）

### Application 層

- [x] `application/alarm_repository_provider.dart`
- [x] `application/alarm_service_provider.dart`
- [x] `application/alarm_collection_notifier.dart` 実装 + Unit Test
  - State: `List<AlarmEntity>`
  - `load` / `create` / `update` / `toggle(AlarmId)` / `delete(AlarmId)` / `onFiredStop` / `onFiredSnooze`
  - enabled 化 / 編集時 → `AlarmService.nextFireAt` → `NotificationScheduler.schedule`（payload: `alarm:<id>`）
  - disabled 化 / 削除時 → `NotificationScheduler.cancel`
  - 鳴動 → 停止イベントで `advanceAfterFire` + 永続化 + 次回 schedule
  - 鳴動 → スヌーズイベントで `snoozeUntil` + schedule
- [x] `application/alarm_ringing_notifier.dart` を Timer / Alarm 両用化（`AlarmSource` enum 追加）
  - payload prefix `timer:` / `alarm:` で起動元判別
  - 既存テストは regression（Timer 由来パスは挙動不変）
- [x] `lib/main.dart` の `onDidReceiveNotificationResponse` を payload prefix 対応に拡張（warm / cold launch 両 path で queryParameters 経由で AlarmRingingScreen に渡す）

### Presentation 層

- [x] `presentation/screens/alarm_list_screen.dart` 実装 + Widget Test 7 件
  - アラーム一覧（時刻 / 曜日 / ラベル / ON-OFF Switch、時刻昇順）
  - カードタップで `/alarms/edit/:id` 遷移
  - FAB で `/alarms/edit` (新規作成)
  - 削除導線は AlarmEditScreen 側に集約（誤タップ事故防止）
- [x] `presentation/screens/alarm_edit_screen.dart` 実装 + Widget Test
  - TimePicker / SegmentedButton (Once/Weekly) + WeekdaySelector / ラベル TextField / 音源選択 / スヌーズ分 SegmentedButton (5/10/15)
  - 削除ボタン（既存アラーム時のみ、確認ダイアログ + 「次から確認しない」サポート）
- [x] `presentation/widgets/weekday_selector.dart`（FilterChip 7 個の multi-select）+ Widget Test
- [x] `presentation/widgets/alarm_delete_confirm_dialog.dart` + Widget Test
- [x] go_router に `/alarms` / `/alarms/edit` / `/alarms/edit/:id` ルート追加
- [x] HomeScreen に Stopwatch / Timer / Alarm の 3 本柱導線を追加

### docs 更新

- [x] `docs/architecture.md` のディレクトリ構造図に `lib/domain/alarm/` 等を追記
- [x] `docs/translations.md` に Phase 9.5 関連 ARB キーを反映
- [ ] `docs/domain-model.md` は Phase 9.5 設計時点の定義とほぼ一致のため追記不要

### 実機検証

- [x] Pixel 6a / Android 16 で以下の 4 シナリオを確認（2026-05-04 完了、PR #11 / #13 内で発覚した 5 件のバグを fix 済）:
  1. 単発アラームを 1 分後にセット → 鳴動 → 停止 → enabled が false になる
  2. 単発アラームを 1 分後にセット → 鳴動 → スヌーズ → 5 分後再鳴動
  3. weekly アラーム（明日のみ）を翌日同時刻にセット → 鳴動 → 停止 → enabled 維持、次回発火は次の該当曜日
  4. アプリ強制終了 → アラーム時刻到達 → フルスクリーン Intent 発火

**DoD**:

- 単発 / 曜日指定の両モードでアラーム作成・編集・削除ができる
- ON/OFF トグルで予約 / キャンセルが正しく行われる
- スヌーズで指定分後に再鳴動する
- 曜日指定アラームは停止後も自動で次回曜日に進む
- Unit Test カバレッジ: domain 層 90% 以上、AlarmCollectionNotifier 80% 以上
- Pixel 6a 実機で 4 シナリオすべて成功

**依存**: Phase 9 完了（Drift 基盤と PresetRepository 実装パターンを利用）。
Phase 10 BootReceiver は Alarm 再予約も含めて実装する（Phase 10 の依存タスクとしてリンク）。
**参照**: `docs/domain-model.md`, `docs/state-management.md`, `docs/adr/0005-alarm-vs-timer-separation.md`, `docs/adr/0003-fullscreen-intent-strategy.md`

---

## Phase 10: 端末再起動後の復元（Timer + Alarm）

採用方針: 純 Flutter (Native BootReceiver は新設しない)。
flutter_local_notifications の ScheduledNotificationBootReceiver と
アプリ起動時の `_restoreFromRepository` / `_loadFromRepository` で
covered。詳細は `docs/android-constraints.md` 起動時復元セクション。

- [x] `RECEIVE_BOOT_COMPLETED` 権限追加 (Phase 1 で既に宣言済)
- [x] `flutter_local_notifications` の ScheduledNotificationBootReceiver
      で boot 後の保留通知が再登録される (パッケージ標準動作)
- [x] Timer の起動時状態復元 (Phase 8 で完了、過去到達は completed + show)
- [x] Alarm の起動時状態復元: enabled な alarm を AlarmService.nextFireAt
      で再 schedule (Phase 9.5 で完了)
- [x] Alarm 過去到達 once-mode の取り扱い: enabled=false に落として
      show 通知 1 回 (Phase 10、AlarmCollectionNotifier._loadFromRepository
      に `_isPastDueOnce` ヘルパで判定追加)
- [x] 実機検証: Pixel 6a / Android 16 で 4 シナリオ確認 (2026-05-09 完了)
  1. [x] 5 分後 timer 設定 → 端末再起動 → 4 分後に通知発火 (OK、1 巡目)
  2. [x] 翌朝の once-mode alarm 設定 → 端末再起動 → 翌朝定刻に発火
        (1 巡目 NG → manifest `exported="true"` 修正後の 2 巡目で OK)
  3. [x] 過去到達 once-mode alarm を擬似的に作成 → 起動後 enabled=false +
        show 通知 1 回 (Settings → Force stop → 日時進行 → launcher 起動の
        2 巡目手順で OK。アプリ起動前は通知ゼロ、cold-start 時に heads-up
        1 回、AlarmRingingScreen への自動遷移なし、通知タップで遷移、
        Stop 後にカード OFF を確認)
  4. [x] weekly alarm (明日の曜日のみ) を再起動跨ぎで翌日定刻に発火 (OK、1 巡目)

**DoD**:

- 端末再起動後にアクティブだったタイマーが復元される
- 端末再起動後に enabled なアラームが再予約される
- 再起動中に時刻を過ぎた timer は completed 扱い + show 通知
- 再起動中に時刻を過ぎた once-mode alarm は enabled=false に落ちる
- 再起動中に時刻を過ぎた weekly alarm は次回曜日に進む

**依存**: Phase 9.5 完了
**参照**: `docs/android-constraints.md` 起動時復元セクション

---

## Phase 10.5: 世界時計 (World Clock)

タイマー / アラームと並列の独立タブ「時計」機能。最大 6 都市の現在時刻を 1 画面で
見渡せ、3 種類のデザインを `PageView` の横スワイプで切り替えられる。初回起動時のみ
GPS で現在地のタイムゾーンを取得し、それ以降は端末タイムゾーン (FlutterTimezone)
を使用する。

ホーム画面ウィジェット (Android App Widget) 化は本 Phase スコープ外（将来 Phase）。

### Domain 層

- [x] `domain/clock/clock_location.dart`（freezed Entity: id / displayName / timezoneId / isCurrentLocation / displayOrder / createdAt）
- [x] `domain/clock/clock_collection.dart`（集約ルート、最大 6 件のドメインルール、add / update / remove / reorder。`isCurrentLocation` 一意性を集約で保証、`reorder` は 0..N-1 で displayOrder 再採番）
- [x] `domain/clock/clock_time.dart`（ValueObject `ClockTime { now, timezoneId }` + abstract `TimezoneResolver` を同居。timezone パッケージの実装は Infrastructure 層 adapter で wire）
- [x] `domain/clock/exceptions.dart`（`MaxClockLocationCountExceededException` / `ClockLocationNotFoundException` / `InvalidTimezoneIdException`）
- [x] `domain/ports/clock_location_repository.dart`（preset 流儀: `findAll` / `findById` / `upsert` / `delete` / `replaceAll`）
- [x] `domain/ports/location_detector.dart`（`Future<String> detectTimezoneId()` 抽象、GPS → 国コード → 代表 TZ。失敗時は実装側で fallback）

### Infrastructure 層

- [ ] `infrastructure/database/app_database.dart` に `clock_locations` テーブル追加（Drift schema migration）
- [ ] `infrastructure/database/drift_clock_location_repository.dart` 実装 + Unit Test（in-memory DB）
- [ ] `infrastructure/database/mappers/clock_location_mapper.dart`（ClockLocation ⇔ ClockLocationsCompanion）
- [ ] `infrastructure/location/location_detector_adapter.dart`
  - `geolocator` で coarse location 取得 → `geocoding` で逆ジオコーディング → 国コード + administrative_area_1 → 代表 TZ マップで解決
  - 失敗時 (権限拒否 / オフライン / 逆ジオコ失敗) は `FlutterTimezone.getLocalTimezone()` にフォールバック
- [ ] `infrastructure/clock/timezone_catalog.dart`
  - プリセット主要都市 20-30 件（東京 / NY / LA / シカゴ / デンバー / ロンドン / パリ / ベルリン / モスクワ / ドバイ / 上海 / シンガポール / シドニー / オークランド / ホノルル / バンクーバー / メキシコシティ / サンパウロ 等）
  - 国コード → 代表 TZ マップ（US はデフォルト LA、CA / AU 等の複数 TZ 国もデフォルト 1 件）

### Application 層

- [ ] `application/clock_location_repository_provider.dart`
- [ ] `application/location_detector_provider.dart`
- [ ] `application/clock_collection_notifier.dart` 実装 + Unit Test
  - State: `List<ClockLocation>`
  - `load` / `addPreset(timezoneId, displayName)` / `remove(id)` / `reorder(oldIndex, newIndex)`
  - 起動時 DB 復元
  - 初回起動時（DB 空）に `LocationDetector.detectTimezoneId()` → 「現在地」として登録
- [ ] `application/clock_tick/current_time_stream_provider.dart` 実装（既存 `docs/state-management.md` で定義済み、ここで実装）
  - 1 秒周期 `Stream.periodic` + `Clock` 経由で `DateTime` を流す
  - autoDispose、画面表示中のみ active

### Presentation 層

- [ ] `presentation/widgets/analog_clock_widget.dart` + Widget Test
  - `CustomPainter` で時針 / 分針 / 秒針描画、引数で `DateTime` と `Size` を受け取る
- [ ] `presentation/widgets/digital_clock_widget.dart` + Widget Test
  - `HH:mm:ss` + 都市名 + UTC オフセット表示
- [ ] `presentation/widgets/clock_design_a.dart` / `clock_design_b.dart` / `clock_design_c.dart`
  - 3 種類のデザインバリエーション。Grid 内で `ClockLocation` × `DateTime` を描画
- [ ] `presentation/screens/clock_screen.dart` + Widget Test
  - `PageView` でデザイン A/B/C 切替（横スワイプ + ドットインジケーター）
  - 各ページに最大 6 個の時計を 2x3 Grid 表示
  - FAB / Edit ボタンで `/clock/locations` へ
- [ ] `presentation/screens/clock_location_picker_screen.dart` + Widget Test
  - プリセット都市から追加選択（上限 6 個に達したら disable）
  - 並べ替え（`ReorderableListView`）+ 削除
- [ ] `lib/main.dart` の `go_router` に `/clock` / `/clock/locations` ルート追加
- [ ] `HomeScreen` に「Open Clock」ボタンを追加（Stopwatch / Timer / Clock の 3 本柱、または BottomNavigationBar 化検討）

### Manifest / pubspec（要ユーザー確認）

- [ ] `pubspec.yaml` に `geolocator: ^14.x` / `geocoding: ^4.x` 追加
- [ ] `android/app/src/main/AndroidManifest.xml` に `ACCESS_COARSE_LOCATION` 追加
- [ ] `docs/permissions.md` に位置情報権限フローを追記（取得タイミング: 初回起動時の現在地検出時のみ、拒否時は FlutterTimezone fallback）

### docs 更新

- [ ] `docs/architecture.md` のディレクトリ構造図に `lib/domain/clock/`, `infrastructure/location/`, `infrastructure/clock/` を追記
- [ ] `docs/domain-model.md` に Clock Aggregate（ClockLocation / ClockCollection / ClockTime）を追加
- [ ] `docs/state-management.md` に `clockCollectionNotifierProvider` 等を追加、`currentTimeStreamProvider` を実装済みに更新

### 実機検証（Pixel 6a / Android 16）

- [ ] 初回起動 → 位置情報許可 → 「現在地」時計が自動追加される
- [ ] 位置情報拒否 → 端末タイムゾーン（例: Asia/Tokyo）で「現在地」が登録される
- [ ] 地域追加（LA / NY / London 等）→ Grid に表示、秒単位で更新
- [ ] PageView スワイプでデザイン A/B/C 切替
- [ ] アプリ強制終了 → 再起動 → 時計リストが復元される（Drift）
- [ ] 並べ替え / 削除動作

**DoD**:

- 1 画面で最大 6 都市の現在時刻が秒単位で更新される
- 初回起動時に GPS で現在地を 1 度だけ取得、以降は端末 TZ
- アナログ / デジタル両表示、3 デザイン切替が動作
- Unit Test カバレッジ: domain 層 90% 以上、ClockCollectionNotifier 80% 以上
- Widget Test: 主要 5 シナリオ以上（デザイン切替 / 地域追加 / 削除 / 並替 / 上限 6 件 disable）

**依存**: Phase 10 完了（Drift 基盤と起動時復元パターンを利用）。pubspec.yaml /
AndroidManifest 編集はユーザー確認必須。
**参照**: `docs/state-management.md`（currentTimeStreamProvider）, `docs/domain-model.md`,
`docs/permissions.md`, `docs/adr/0004-clock-injection-pattern.md`

---

## Phase 11（任意）: 仕上げ

- [ ] アプリアイコン・スプラッシュ
- [ ] 設定画面（音源選択、デフォルトスヌーズ時間など）
- [x] ライセンス表示画面（2026-05-02、Phase 11 先行小タスクとして実装）
      `LicenseRegistry.addLicense` で `assets/sounds/LICENSES.md` を 1 行 1 段落
      の `LicenseEntry` として登録、`LicensesScreen` (2 セクション ExpansionTile：
      同梱音源 / ソフトウェアライセンス) で表示。導線は HomeScreen AppBar
      overflow メニューの「ライセンス」エントリ。設定画面が出来たらメニューは
      設定画面側に移設する想定
- [ ] ダークモード対応
- [~] ローカライズ（日本語 / 英語、内部対応で中国語簡体字 / 繁体字 / 韓国語）
  - Phase 8.5 で土台 (flutter_localizations + gen-l10n + ARB) を導入済 (2026-05-02):
    日英 ARB 完備、`--dart-define=ENABLE_EXPERIMENTAL_LOCALES=true` で
    zh / zh-Hant / ko を有効化可能。
  - 通知本文 i18n も対応済 (2026-05-03、PR #5): `NotificationStringsNotifier`
    と `WidgetsBindingObserver.didChangeLocales` で OS の locale 切替に追従、
    走行中タイマーは `rescheduleAllRunning()` で再 schedule。
  - Phase 11 残: 実翻訳 + 中韓 ARB 追加 + 通知 channel 名 (現在は固定文字列)
    の i18n + 設定画面での手動切替 UI
- [ ] Play Store 提出準備（プライバシーポリシー、スクリーンショット）

**DoD**: 公開可能な品質に到達
**依存**: Phase 10 / Phase 10.5 完了

---

## Phase 12（任意）: iOS 版実装（Android 版完成後に着手）

### 事前タスク（Phase 12 着手前にまとめて実施、2026-05-02 ユーザ判断で持ち越し）

iOS 版開始時または Play Store 公開前のタイミングで、以下の依存メジャーバンプを
別ブランチでまとめて検証する。Phase 9 完了時点 (2026-05-02) では現状で
特に困っていないため Phase 11 までは現行版を維持する方針:

- [ ] `freezed` / `freezed_annotation` 2.x → 3.x（codegen 全件再生成、copyWith
  semantics 確認）
- [ ] `flutter_riverpod` / `riverpod_annotation` / `riverpod_generator` /
  `riverpod_lint` 2.x → 3.x / 4.x（AsyncNotifier の build セマンティクス、
  `.notifier` 生成形、`.invalidate()` スコープの breaking。全 Notifier の
  挙動を Widget Test + 実機で再検証）
- [ ] `flutter_local_notifications` 19.x → 21.x（Phase 8.5 follow-up で
  チューニングした「Channel v6 + cancel→500ms→play」が FLN 21 でも単音化
  する確認、6 シナリオ実機検証）
- [ ] 上記に紐づいて自動的に unlock される `drift` / `drift_dev` /
  `drift_flutter` / `timezone` / `build_runner` の最新化
- [ ] `go_router` 14.x → 17.x（3 メジャー分 / ルート登録 API 確認）
- [ ] `permission_handler_android` の継続バージョン追従（Android compileSdk
  要求の追従）

### iOS 化本体

- [ ] `flutter create --platforms=ios .` で iOS プロジェクト生成
- [ ] iOS シミュレータでビルド確認（既存 adapter がクロスプラットフォーム対応パッケージを使っているため、ビルドは通る可能性あり）
- [ ] iOS 用 infrastructure adapter のスケルトン作成
  - `lib/infrastructure/notification/ios/cupertino_notification_adapter.dart`
  - `lib/infrastructure/permission/ios/permission_handler_adapter.dart`
  - `lib/infrastructure/audio/` は audioplayers がクロスプラットフォームのためそのままで良い可能性
- [ ] Riverpod Provider で `defaultTargetPlatform` による分岐
- [ ] iOS の制約に合わせた要件再定義（exact alarm / フルスクリーン Intent 不可への対応方針決定）
- [ ] iOS 用 Info.plist 設定（通知権限 NSUserNotificationsUsageDescription、バックグラウンドモード等）
- [ ] iOS シミュレータ / 実機での動作確認

**DoD（確定方針反映）**:

- iOS シミュレータでアプリが起動・基本操作できる
- iOS で扱える範囲のタイマー機能が動作（**OS 標準通知レベル、±1 分精度許容、ロック画面占有なし**）
- Android 固有機能（FullScreenIntent / exact alarm 等）は iOS 版では実装対象外
- 既存 Android 版の動作・テストに影響を与えない

**依存**: Phase 11 完了
**参照**: 着手時に iOS の通知制約を再調査し、`docs/architecture.md` の「iOS 対応方針」を更新

---

## 進捗サマリ

| Phase | 状態 | 備考 |
|---|---|---|
| 0 | 完了 | ドキュメント整備完了（2026-04-29） |
| 1 | 完了 | DoD 完全達成（flutter analyze / test / CI すべて緑、2026-04-29） |
| 2 | 完了（CI 緑化待ち） | ローカル DoD 達成、domain カバレッジ 100%、47 テストパス（2026-04-29） |
| 3 | 完了（CI 緑化待ち） | ローカル DoD 達成、domain カバレッジ 100%、93 テストパス（2026-04-29） |
| 4 | 完了（CI 緑化待ち） | ローカル DoD 達成、Pixel 6a 実機通知 + バイブ確認済み（2026-04-29） |
| 5 | 完了（実機音再生確認待ち） | ローカル DoD 達成、120 テストパス（2026-04-30） |
| 6 | 完了 | 6a/6b/6c 実装 + 実機 3 パターン全部 OK（Pixel 6a / Android 16、2026-04-30）、126 テストパス |
| 7 | 完了（実機検証済み） | スヌーズ + カスタム時間タイマー UI 完了（2026-05-01）、162 テストパス、Pixel 6a 動作確認済 |
| 8 | 完了（実機検証済み） | 複数タイマー (上限 10) + Drift 永続化 + 起動時復元 (過去到達は completed + show 通知)、180 テストパス、Pixel 6a で 6 シナリオ検証済（2026-05-02） |
| 8.5 | 完了（土台のみ、本番翻訳は Phase 11） | ローカライズ土台 (flutter_localizations + gen-l10n + 日英 ARB)。中国語簡体字 / 繁体字 / 韓国語は `--dart-define=ENABLE_EXPERIMENTAL_LOCALES=true` で内部対応可能（2026-05-02、180 テストパス） |
| 8.5 follow-up | 完了 | アラーム再鳴動時の二重音修正 (Channel `timer_alarm_v6` + `start()` で cancel→500ms→play 順序、2026-05-02、Pixel 6a で 6 シナリオ単音化確認済) |
| 9 | 完了（実機検証済み） | プリセット機能 + テンプレート差し替え + ♪ ボタン + ラベル併記、275 テストパス、Pixel 6a で 10 シナリオ + フィードバック 6 件反映済（2026-05-02） |
| 9.5 | 完了（実機検証済み） | 指定時刻アラーム機能。Domain〜Presentation 全レイヤー実装 + AlarmListScreen + go_router 配線 + HomeScreen 3 本柱導線、Pixel 6a / Android 16 で 4 シナリオ検証済（PR #11 / #13 で発覚 5 件 fix 込み、2026-05-04） |
| 10 | 完了（実機検証済み） | Timer + Alarm の起動時復元 + past-due once-mode 取り下げ。Pixel 6a / Android 16 で 4 シナリオ確認済 (2026-05-09)。1 巡目で `ScheduledNotificationBootReceiver` の Android 12+ exported 要件不備が発覚 → manifest fix → 2 巡目で全シナリオ OK。392 テストパス |
| 10.5 | 未着手 | 世界時計（最大 6 都市、3 デザイン PageView 切替、初回 GPS 取得）。Phase 10 完了後 |
| 11 | 未着手 | 任意 |
| 12 | 未着手 | 任意 / iOS 版（Android 版完成後） |

---

最終更新日: 2026-05-09（Phase 10 完了。Pixel 6a / Android 16 で 4 シナリオ実機検証済、`ScheduledNotificationBootReceiver` の `exported="true"` 修正と past-due 検知の二段構えで再起動跨ぎ + 過去到達 once の両方を救済）
