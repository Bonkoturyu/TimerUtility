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
- [ ] 実機で「タイマー終了 → カスタム音再生 → Stop で止まる」を確認（Auto 範囲外）

**DoD**:
- タイマー終了時にカスタム音が鳴る
- 停止ボタンで音が止まる
- Widget Test で停止/スヌーズボタンの操作を検証

**依存**: Phase 4 完了
**参照**: `docs/assets-spec.md`

---

## Phase 6: フルスクリーン Intent 対応（最難関）

- [x] AndroidManifest に `USE_FULL_SCREEN_INTENT` / `USE_EXACT_ALARM` 追加 + MainActivity に `showOnLockScreen` / `turnScreenOn` 属性追加（Phase 6a）
- [x] flutter_local_notifications でフルスクリーン Intent 通知設定（importance/priority max、visibility public、playSound false）（Phase 6a）
- [x] 権限取得フロー実装。USE_FULL_SCREEN_INTENT は permission_handler でカバーされないため自前 MethodChannel `com.bonkotu.timer/permission` を導入し、状態確認 → 設定画面誘導まで実装（Phase 6b）
- [x] フォールバック実装（adapter で `canUseFullScreenIntent() == false` 時に `fullScreenIntent` フラグを落としてヘッドアップ通知化）（Phase 6c）
- [ ] アプリが終了状態 / バックグラウンド / フォアグラウンドの 3 パターンで実機確認（Phase 6c の実機作業、ユーザー側）
- [ ] Native → Flutter のイベント送信仕様確定（`docs/platform-channels.md` 更新）

**DoD**:
- ロック画面上にアラーム画面が表示される（権限あり時）
- 権限なし時はヘッドアップ通知で代替動作
- 3 パターンの実機確認結果を `docs/` にメモ

**依存**: Phase 5 完了
**参照**: `docs/android-constraints.md`, `docs/platform-channels.md`, `docs/permissions.md`

---

## Phase 7: スヌーズ機能

- [ ] `domain/timer/snooze_calculator.dart` 実装 + Unit Test
- [ ] `TimerService` にスヌーズメソッド追加 + Unit Test
- [ ] `NotificationScheduler` のキャンセル + 再予約フロー
- [ ] AlarmRingingScreen にスヌーズボタン動作実装
- [ ] スヌーズ時間プリセット（3 分 / 5 分 / 10 分）UI

**DoD**:
- スヌーズで指定時間後に再度アラームが鳴る
- スヌーズ可能回数の上限ロジック（任意、要件確認）
- Unit Test カバレッジ維持

**依存**: Phase 6 完了
**参照**: `docs/domain-model.md`

---

## Phase 8: 複数タイマー管理 + Drift 永続化

- [ ] Drift スキーマ定義（`infrastructure/database/app_database.dart`）
- [ ] `domain/ports/timer_repository.dart`
- [ ] `infrastructure/database/drift_timer_repository.dart` 実装 + Unit Test（in-memory DB）
- [ ] `domain/timer/timer_collection.dart`（複数管理ロジック）+ Unit Test
- [ ] `application/timer_collection_notifier.dart` + Unit Test
- [ ] 同時稼働上限のドメインルール実装
- [ ] `presentation/screens/timer_list_screen.dart` 実装 + Widget Test
- [ ] 各タイマーの個別操作 UI（カード形式）

**DoD**:
- 複数タイマーを同時に稼働できる
- アプリ再起動後にタイマー状態が復元される
- 各タイマーの通知が独立して発火する
- Unit Test カバレッジ維持

**依存**: Phase 7 完了
**参照**: `docs/domain-model.md`, `docs/adr/0002-use-drift.md`

---

## Phase 9: プリセット機能

- [ ] `domain/timer/preset.dart`（Entity）
- [ ] `domain/ports/preset_repository.dart`
- [ ] `infrastructure/database/drift_preset_repository.dart` 実装 + Unit Test
- [ ] `application/preset_notifier.dart` + Unit Test
- [ ] `presentation/screens/preset_manage_screen.dart` 実装 + Widget Test
- [ ] タイマー作成画面でプリセット選択 UI

**DoD**:
- プリセットの追加・編集・削除ができる
- プリセットからワンタップでタイマー作成可能
- Unit Test カバレッジ維持

**依存**: Phase 8 完了
**参照**: `docs/domain-model.md`

---

## Phase 10: 端末再起動後の復元

- [ ] `RECEIVE_BOOT_COMPLETED` 権限追加（要ユーザー確認）
- [ ] Native 側 BootReceiver 実装（Kotlin）
- [ ] BootReceiver から Flutter 側のタイマー復元処理を起動
- [ ] 復元時のタイマー状態判定ロジック（既に時刻過ぎているタイマーの扱い）+ Unit Test
- [ ] 実機での再起動テスト

**DoD**:
- 端末再起動後にアクティブだったタイマーが復元される
- 再起動中に時刻を過ぎたタイマーは適切に処理される（即発火 or completed 扱い、要件確認）

**依存**: Phase 9 完了
**参照**: `docs/android-constraints.md`, `docs/platform-channels.md`

---

## Phase 11（任意）: 仕上げ

- [ ] アプリアイコン・スプラッシュ
- [ ] 設定画面（音源選択、デフォルトスヌーズ時間など）
- [ ] ダークモード対応
- [ ] ローカライズ（日本語 / 英語）
- [ ] Play Store 提出準備（プライバシーポリシー、スクリーンショット）

**DoD**: 公開可能な品質に到達
**依存**: Phase 10 完了

---

## Phase 12（任意）: iOS 版実装（Android 版完成後に着手）

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
| 6 | コード完了（実機 3 パターン確認待ち） | 6a/6b/6c 実装済み、126 テストパス（2026-04-30） |
| 7 | 未着手 | |
| 8 | 未着手 | |
| 9 | 未着手 | |
| 10 | 未着手 | |
| 11 | 未着手 | 任意 |
| 12 | 未着手 | 任意 / iOS 版（Android 版完成後） |

---

最終更新日: 2026-04-30（Phase 6 コード完了を反映、実機 3 パターン確認はユーザー側で残置）
