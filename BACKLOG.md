# BACKLOG.md

本プロジェクトの Phase 別タスク管理ファイル。Claude Code は作業着手前に必ず本ファイルを参照し、
対象 Phase / タスクの位置と前提条件を確認すること。

- **完了 Phase の実装詳細・実機検証ログ**: [docs/dev-log.md](docs/dev-log.md) を参照
- **短期タスク (直近の作業項目)**: [tasklist.md](tasklist.md) を参照
- 本ファイルは Phase ヘッダ + DoD + 進捗サマリ、および進行中 / 未着手 Phase の詳細のみを保持する

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

## Phase 0: ドキュメント整備 — 完了 (2026-04-29)

CLAUDE.md / BACKLOG.md / tasklist.md / `docs/` 配下の architecture / domain-model /
state-management / testing-strategy / android-constraints / platform-channels /
permissions / assets-spec / ADR 0001〜0004 を整備。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**参照**: `CLAUDE.md`

---

## Phase 1: プロジェクト雛形 + CI セットアップ — 完了 (2026-04-29)

`flutter create` でプロジェクト生成、Riverpod / Drift / freezed 等の依存追加、
`analysis_options.yaml` 厳格化、GitHub Actions CI、`ProviderScope + go_router`
の最小 `main.dart`。`flutter analyze` / `flutter test` / CI すべて緑。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 0 完了
**参照**: `docs/architecture.md`

---

## Phase 2: ストップウォッチ機能（ロジック + UI） — 完了 (2026-04-29)

`StopwatchService` (Pure Dart + Clock 注入)、`StopwatchNotifier`、`StopwatchScreen` +
`LapList` を実装。Start / Pause / Resume / Reset / Lap が正しく動作、47 テストパス、
domain 層カバレッジ 100%。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 1 完了
**参照**: `docs/domain-model.md`, `docs/state-management.md`, `docs/testing-strategy.md`

---

## Phase 3: タイマー機能（単体、アラーム鳴動なし） — 完了 (2026-04-29)

`TimerService` (Clock + idGenerator 注入) + `TimerNotifier` + `TimerScreen` 実装、
カウントダウン → 0 到達で `ringing` 遷移。93 テストパス、domain 層カバレッジ 100%。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 2 完了
**参照**: `docs/domain-model.md`, `docs/state-management.md`

---

## Phase 4: 通知スケジューリング基盤 — 完了 (2026-04-29)

`NotificationScheduler` port + `FlutterLocalNotificationAdapter` 実装、
`PermissionManager` port、AndroidManifest 権限追加、TimerNotifier から
schedule / cancel 呼び出し、Pixel 6a で通知 + バイブ確認済。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 3 完了
**参照**: `docs/android-constraints.md`, `docs/permissions.md`,
`docs/adr/0003-fullscreen-intent-strategy.md`

---

## Phase 5: カスタム音源再生 + AlarmRingingScreen — 完了 (2026-04-30)

`AlarmSoundCatalog` (default / gentle / urgent)、`AudioplayersAdapter` (ReleaseMode.loop)、
`AlarmRingingNotifier`、`AlarmRingingScreen`、通知 payload 経由の Deep Link。
120 テストパス。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 4 完了
**参照**: `docs/assets-spec.md`

---

## Phase 6: フルスクリーン Intent 対応 — 完了 (2026-04-30, docs 完全クローズ 2026-05-13)

USE_FULL_SCREEN_INTENT / USE_EXACT_ALARM + MainActivity `showOnLockScreen` /
`turnScreenOn` + runtime `setShowWhenLocked`、自前 MethodChannel
`com.bonkotu.timer/permission`、`canUseFullScreenIntent` フォールバック、
cold-launch deep link。Pixel 6a で 3 パターン全 OK、126 テストパス。
docs 整理 (4 ch 採用見送り確定 + `clearShowWhenLocked` 後付け文書化) で完全クローズ。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 5 完了
**参照**: `docs/android-constraints.md`, `docs/platform-channels.md`, `docs/permissions.md`

---

## Phase 7: スヌーズ機能 + カスタム時間タイマー UI — 完了 (2026-05-01)

`SnoozeCalculator` + `TimerService.snooze`、AlarmRingingScreen にスヌーズボタン (3/5/10 分)、
`DurationPicker` (時 / 分 / 秒ホイール、上限 99 時間)、カスタム時間プリセット。
162 テストパス、Pixel 6a 動作確認済。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 6 完了
**参照**: `docs/domain-model.md`

---

## Phase 8: 複数タイマー管理 + Drift 永続化 — 完了 (2026-05-02)

Drift スキーマ + `TimerRepository` + `TimerCollection` (上限 10 本) +
`TimerCollectionNotifier` + `TimerListScreen`、起動時 DB 復元 (過去到達は completed +
無音 show 通知 1 回)。Pixel 6a で 6 シナリオすべて OK、180 テストパス。
旧 `timer_notifier.dart` / `timer_screen.dart` は削除。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 7 完了
**参照**: `docs/domain-model.md`, `docs/adr/0002-use-drift.md`

---

## Phase 9: プリセット機能 — 完了 (2026-05-02)

`Preset` / `PresetCollection` / `PresetService` / `PresetTemplates` (general /
cooking / pomodoro 各 6 件)、Drift schemaVersion 1 → 2 + atomic seed、
`SharedPreferencesUserPreferences`、PresetSelectSheet / EditSheet /
SoundSelectSheet / PresetManageScreen、テンプレート差し替え (overwrite/append、
append は上限超過分を SnackBar 告知)、♪ ボタンによる音源変更、ラベル併記。
275 テストパス、Pixel 6a で 10 シナリオ + フィードバック 6 件反映済。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 8 完了
**参照**: `docs/domain-model.md`, `docs/translations.md`, `docs/adr/0002-use-drift.md`

---

## Phase 9.5: 指定時刻アラーム機能（曜日繰り返し + スヌーズ） — 完了 (2026-05-04)

別 Aggregate (`AlarmEntity` / `AlarmRepeat` / `AlarmService` / `AlarmCollection`)、
Drift `alarms` テーブル、AlarmRingingNotifier の Timer / Alarm 両用化 (payload
prefix `timer:` / `alarm:`)、AlarmListScreen / AlarmEditScreen / WeekdaySelector、
go_router `/alarms` 配線、HomeScreen 3 本柱導線。PR #11 / #13 で発覚した
5 件のバグ fix 込みで Pixel 6a 4 シナリオ OK。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 9 完了 (Drift 基盤と PresetRepository 実装パターンを利用)
**参照**: `docs/domain-model.md`, `docs/state-management.md`,
`docs/adr/0005-alarm-vs-timer-separation.md`, `docs/adr/0003-fullscreen-intent-strategy.md`

---

## Phase 10: 端末再起動後の復元（Timer + Alarm） — 完了 (2026-05-09)

採用方針は純 Flutter (Native BootReceiver 新設なし)。`ScheduledNotificationBootReceiver` +
アプリ起動時の `_restoreFromRepository` / `_loadFromRepository` でカバー。Alarm 過去到達
once-mode は enabled=false + show 通知 1 回。Pixel 6a 4 シナリオ確認済 (1 巡目で
manifest `exported="true"` 不備が発覚 → 2 巡目で全 OK)、392 テストパス。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 9.5 完了
**参照**: `docs/android-constraints.md` 起動時復元セクション

---

## Phase 10.5: 世界時計 (World Clock) — 完了 (2026-05-10)

最大 6 都市の現在時刻を 3 デザイン (PageView 切替) で表示。
`ClockEntry` / `ClockCollection` / `TimezoneResolver` / `LocationDetector`、
Drift schemaVersion 3 → 4、`TimezoneCatalog` 25 都市プリセット + `CountryToTimezone`
約 40 ヶ国マップ、初回 GPS で現在地登録 / 拒否時は `FlutterTimezone` fallback。
504 テストパス、Pixel 6a で 8 シナリオ OK (PR #26 / #27 フォロー含む)。
ホーム画面ウィジェット化は将来 Phase。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 10 完了 (Drift 基盤と起動時復元パターンを利用)
**参照**: `docs/state-management.md`, `docs/domain-model.md`,
`docs/permissions.md`, `docs/adr/0004-clock-injection-pattern.md`

---

## Phase 11（任意）: 仕上げ

### 完了済みサブタスク

- [x] **HomeScreen を PageView 化** (2026-05-10): Stopwatch / Timer / Alarm /
  Clock を 4 タブ横 swipe、デフォルト Timer (index 1)、`UserPreferences.lastHomePageIndex`
  で復元。詳細は [dev-log](docs/dev-log.md)
- [x] **ライセンス表示画面** (2026-05-02): `LicenseRegistry.addLicense` で同梱音源 +
  ソフトウェアライセンスを表示。設定画面完成時に導線を設定画面側に移設済
- [x] **ダークモード対応** (2026-05-11): `MaterialApp.darkTheme` を deepPurple seed +
  `Brightness.dark`、ハードコード色を MD3 semantic role に置換。Pixel 6a 7 シナリオ OK。
  詳細は [dev-log](docs/dev-log.md)
- [x] **プリセット管理の発見性改善** (2026-05-12, PR #35): `PresetSelectSheet` 末尾に
  「プリセットを管理...」エントリ追加。Pixel 6a 6 シナリオ OK。
  詳細は [dev-log](docs/dev-log.md)
- [x] **Clock ドメインリネーム** (2026-05-11): `ClockLocation` → `ClockEntry`、
  Drift `clock_locations` → `clock_entries` (schemaVersion 4 → 5 で `INSERT...SELECT`
  migration)。`isCurrentLocation` / `LocationDetector` は GPS 由来として据置。
  詳細は [dev-log](docs/dev-log.md)
- [x] **ClockLocationPicker UI 名称統一** (2026-05-11, PR #29): 表示文言を
  「時計を追加・編集」/「Add or edit clocks」に更新
- [x] **設定画面 4 項目** (2026-05-12, PR #36): テーマ手動切替 (`UserPreferences.themeMode`
  に `int` 永続化) / デフォルトスヌーズ分 / デフォルトアラーム音源 / ライセンス導線移設を
  `SettingsNotifier` で一元管理。Pixel 6a 7 シナリオ OK
- [x] **CVD (色覚多様性) 対応モード** (2026-05-13, PR #39): 方針 (a) 冗長表示を採用。
  `permission_banners.dart` の 3 種バナーに重大度ラベル `[重要]` / `[推奨]` / `[補助]` 併記 +
  `FontWeight` 段階差 + 左端色帯幅で形状差を付与。558 テストパス (1 skipped)。
  実機検証は [dev-log](docs/dev-log.md)

### 残タスク

- [ ] アプリアイコン・スプラッシュ
- [~] ローカライズ残作業
  - 中国語簡体字 / 繁体字 / 韓国語の本格翻訳 (現状 `--dart-define=ENABLE_EXPERIMENTAL_LOCALES=true`
    で内部対応のみ)
  - 通知 channel 名の i18n (現状は固定文字列)
  - 設定画面での言語手動切替 UI
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
| --- | --- | --- |
| 0 | 完了 | ドキュメント整備完了（2026-04-29） |
| 1 | 完了 | DoD 完全達成（flutter analyze / test / CI すべて緑、2026-04-29） |
| 2 | 完了 | ローカル DoD 達成、domain カバレッジ 100%、47 テストパス（2026-04-29） |
| 3 | 完了 | ローカル DoD 達成、domain カバレッジ 100%、93 テストパス（2026-04-29） |
| 4 | 完了 | ローカル DoD 達成、Pixel 6a 実機通知 + バイブ確認済み（2026-04-29） |
| 5 | 完了 | ローカル DoD 達成、120 テストパス（2026-04-30） |
| 6 | 完了 | 6a/6b/6c 実装 + 実機 3 パターン全部 OK（Pixel 6a / Android 16、2026-04-30）、126 テストパス。docs 整理で完全クローズ (2026-05-13、4 ch 採用見送り確定 + `clearShowWhenLocked` 後付け文書化) |
| 7 | 完了 | スヌーズ + カスタム時間タイマー UI 完了（2026-05-01）、162 テストパス、Pixel 6a 動作確認済 |
| 8 | 完了 | 複数タイマー (上限 10) + Drift 永続化 + 起動時復元、180 テストパス、Pixel 6a 6 シナリオ検証済（2026-05-02） |
| 8.5 | 完了（土台のみ、本番翻訳は Phase 11） | ローカライズ土台 (flutter_localizations + gen-l10n + 日英 ARB)。中韓は `--dart-define=ENABLE_EXPERIMENTAL_LOCALES=true` で内部対応可能（2026-05-02、180 テストパス） |
| 8.5 follow-up | 完了 | アラーム再鳴動時の二重音修正 (Channel `timer_alarm_v6` + `start()` で cancel→500ms→play 順序、2026-05-02、Pixel 6a 6 シナリオ単音化確認済) |
| 9 | 完了 | プリセット機能 + テンプレート差し替え + ♪ ボタン + ラベル併記、275 テストパス、Pixel 6a 10 シナリオ + フィードバック 6 件反映済（2026-05-02） |
| 9.5 | 完了 | 指定時刻アラーム機能。全レイヤー実装 + AlarmListScreen + go_router 配線 + HomeScreen 3 本柱導線、Pixel 6a 4 シナリオ検証済（PR #11 / #13 で発覚 5 件 fix 込み、2026-05-04） |
| 10 | 完了 | Timer + Alarm の起動時復元 + past-due once-mode 取り下げ。Pixel 6a 4 シナリオ確認済 (2026-05-09)。1 巡目で `ScheduledNotificationBootReceiver` の Android 12+ exported 要件不備が発覚 → manifest fix → 2 巡目で全 OK。392 テストパス |
| 10.5 | 完了 | 世界時計。全層実装 + main.dart 配線 + l10n + docs 更新。実機検証フィードバック対応 (PageView 循環 / 都市 A-Z / ドット pill 化) は PR #26、システム nav バー回避 (SafeArea bottom) は PR #27 でマージ・実機確認済（2026-05-10、Pixel 6a 6 シナリオ + 上限ガード + ドット nav バー余白すべて OK）、504 テストパス |
| 11 (HomeScreen PageView) | 完了 | HomeScreen を 4 タブ横 PageView 化、518 テストパス、Pixel 6a 実機検証完了 (2026-05-10) |
| 11 (ダークモード) | 完了 | `MaterialApp.darkTheme` deepPurple seed + `Brightness.dark`、permission_banners / analog_clock_widget を MD3 semantic role に置換、527 テストパス、Pixel 6a 7 シナリオ実機検証完了 (2026-05-11) |
| 11 (その他) | 進行中 | 設定画面 4 項目 (テーマ / スヌーズ / アラーム音源 / ライセンス導線、PR #36) + CVD 冗長表示 (PR #39、2026-05-13) 完了。残: アプリアイコン / 言語手動切替 UI / 通知 channel 名 i18n / 中韓 ARB 本格翻訳 / Play Store 提出準備 |
| 12 | 未着手 | 任意 / iOS 版（Android 版完成後） |

---

最終更新日: 2026-05-14（BACKLOG.md コンパクト化 — 完了 Phase 0〜10.5 の `[x]` チェックリスト・実機検証詳細を [docs/dev-log.md](docs/dev-log.md) に集約し、本ファイルは Phase ヘッダ + 1 行要約 + dev-log リンク + 進捗サマリ + 進行中/未着手 Phase の詳細のみ保持。790 行 → 約 280 行）

過去の更新: 2026-05-13（Phase 11 CVD banner labels 完了 — `permission_banners.dart` の 3 種バナーに重大度ラベル + FontWeight 段階差 + 左端色帯幅で形状差。558 テストパス (1 skipped)、PR #39）
