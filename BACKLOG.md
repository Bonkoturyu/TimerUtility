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
**参照**: [CLAUDE.md](CLAUDE.md)

---

## Phase 1: プロジェクト雛形 + CI セットアップ — 完了 (2026-04-29)

`flutter create` でプロジェクト生成、Riverpod / Drift / freezed 等の依存追加、
`analysis_options.yaml` 厳格化、GitHub Actions CI、`ProviderScope + go_router`
の最小 `main.dart`。`flutter analyze` / `flutter test` / CI すべて緑。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 0 完了
**参照**: [docs/architecture.md](docs/architecture.md)

---

## Phase 2: ストップウォッチ機能（ロジック + UI） — 完了 (2026-04-29)

`StopwatchService` (Pure Dart + Clock 注入)、`StopwatchNotifier`、`StopwatchScreen` +
`LapList` を実装。Start / Pause / Resume / Reset / Lap が正しく動作、47 テストパス、
domain 層カバレッジ 100%。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 1 完了
**参照**: [docs/domain-model.md](docs/domain-model.md), [docs/state-management.md](docs/state-management.md), [docs/testing-strategy.md](docs/testing-strategy.md)

---

## Phase 3: タイマー機能（単体、アラーム鳴動なし） — 完了 (2026-04-29)

`TimerService` (Clock + idGenerator 注入) + `TimerNotifier` + `TimerScreen` 実装、
カウントダウン → 0 到達で `ringing` 遷移。93 テストパス、domain 層カバレッジ 100%。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 2 完了
**参照**: [docs/domain-model.md](docs/domain-model.md), [docs/state-management.md](docs/state-management.md)

---

## Phase 4: 通知スケジューリング基盤 — 完了 (2026-04-29)

`NotificationScheduler` port + `FlutterLocalNotificationAdapter` 実装、
`PermissionManager` port、AndroidManifest 権限追加、TimerNotifier から
schedule / cancel 呼び出し、Pixel 6a で通知 + バイブ確認済。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 3 完了
**参照**: [docs/android-constraints.md](docs/android-constraints.md), [docs/permissions.md](docs/permissions.md),
[docs/adr/0003-fullscreen-intent-strategy.md](docs/adr/0003-fullscreen-intent-strategy.md)

---

## Phase 5: カスタム音源再生 + AlarmRingingScreen — 完了 (2026-04-30)

`AlarmSoundCatalog` (default / gentle / urgent)、`AudioplayersAdapter` (ReleaseMode.loop)、
`AlarmRingingNotifier`、`AlarmRingingScreen`、通知 payload 経由の Deep Link。
120 テストパス。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 4 完了
**参照**: [docs/assets-spec.md](docs/assets-spec.md)

---

## Phase 6: フルスクリーン Intent 対応 — 完了 (2026-04-30, docs 完全クローズ 2026-05-13)

USE_FULL_SCREEN_INTENT / USE_EXACT_ALARM + MainActivity `showOnLockScreen` /
`turnScreenOn` + runtime `setShowWhenLocked`、自前 MethodChannel
`com.bonkotu.timer/permission`、`canUseFullScreenIntent` フォールバック、
cold-launch deep link。Pixel 6a で 3 パターン全 OK、126 テストパス。
docs 整理 (4 ch 採用見送り確定 + `clearShowWhenLocked` 後付け文書化) で完全クローズ。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 5 完了
**参照**: [docs/android-constraints.md](docs/android-constraints.md), [docs/platform-channels.md](docs/platform-channels.md), [docs/permissions.md](docs/permissions.md)

---

## Phase 7: スヌーズ機能 + カスタム時間タイマー UI — 完了 (2026-05-01)

`SnoozeCalculator` + `TimerService.snooze`、AlarmRingingScreen にスヌーズボタン (3/5/10 分)、
`DurationPicker` (時 / 分 / 秒ホイール、上限 99 時間)、カスタム時間プリセット。
162 テストパス、Pixel 6a 動作確認済。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 6 完了
**参照**: [docs/domain-model.md](docs/domain-model.md)

---

## Phase 8: 複数タイマー管理 + Drift 永続化 — 完了 (2026-05-02)

Drift スキーマ + `TimerRepository` + `TimerCollection` (上限 10 本) +
`TimerCollectionNotifier` + `TimerListScreen`、起動時 DB 復元 (過去到達は completed +
無音 show 通知 1 回)。Pixel 6a で 6 シナリオすべて OK、180 テストパス。
旧 `timer_notifier.dart` / `timer_screen.dart` は削除。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 7 完了
**参照**: [docs/domain-model.md](docs/domain-model.md), [docs/adr/0002-use-drift.md](docs/adr/0002-use-drift.md)

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
**参照**: [docs/domain-model.md](docs/domain-model.md), [docs/translations.md](docs/translations.md), [docs/adr/0002-use-drift.md](docs/adr/0002-use-drift.md)

---

## Phase 9.5: 指定時刻アラーム機能（曜日繰り返し + スヌーズ） — 完了 (2026-05-04)

別 Aggregate (`AlarmEntity` / `AlarmRepeat` / `AlarmService` / `AlarmCollection`)、
Drift `alarms` テーブル、AlarmRingingNotifier の Timer / Alarm 両用化 (payload
prefix `timer:` / `alarm:`)、AlarmListScreen / AlarmEditScreen / WeekdaySelector、
go_router `/alarms` 配線、HomeScreen 3 本柱導線。PR #11 / #13 で発覚した
5 件のバグ fix 込みで Pixel 6a 4 シナリオ OK。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 9 完了 (Drift 基盤と PresetRepository 実装パターンを利用)
**参照**: [docs/domain-model.md](docs/domain-model.md), [docs/state-management.md](docs/state-management.md),
[docs/adr/0005-alarm-vs-timer-separation.md](docs/adr/0005-alarm-vs-timer-separation.md), [docs/adr/0003-fullscreen-intent-strategy.md](docs/adr/0003-fullscreen-intent-strategy.md)

---

## Phase 10: 端末再起動後の復元（Timer + Alarm） — 完了 (2026-05-09)

採用方針は純 Flutter (Native BootReceiver 新設なし)。`ScheduledNotificationBootReceiver` +
アプリ起動時の `_restoreFromRepository` / `_loadFromRepository` でカバー。Alarm 過去到達
once-mode は enabled=false + show 通知 1 回。Pixel 6a 4 シナリオ確認済 (1 巡目で
manifest `exported="true"` 不備が発覚 → 2 巡目で全 OK)、392 テストパス。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 9.5 完了
**参照**: [docs/android-constraints.md](docs/android-constraints.md) 起動時復元セクション

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
**参照**: [docs/state-management.md](docs/state-management.md), [docs/domain-model.md](docs/domain-model.md),
[docs/permissions.md](docs/permissions.md), [docs/adr/0004-clock-injection-pattern.md](docs/adr/0004-clock-injection-pattern.md)

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

- [~] アプリアイコン・スプラッシュ (Phase 11.9 β、PR #91 main マージ済):
  素材作成・Android リソース生成・Play Store 用 icon / Feature Graphic は完了。
  Pixel 6a で launcher / themed icon / light・dark splash の実機確認が残る。
- [x] ローカライズ残作業 (2026-05-16): 配下 3 項目すべて完了。Phase 11
  全体としては「アプリアイコン・スプラッシュ」「Play Store 提出準備」が残作業
  - [x] 中国語簡体字 / 繁体字 / 韓国語の本格翻訳 (A-3 / 2026-05-16, PR #61):
    [lib/l10n/app_zh.arb](lib/l10n/app_zh.arb) /
    [lib/l10n/app_zh_Hant.arb](lib/l10n/app_zh_Hant.arb) /
    [lib/l10n/app_ko.arb](lib/l10n/app_ko.arb) を新規作成 (各 172 翻訳キー、
    ja / en と完全同一キー集合)。`flutter gen-l10n` で
    `AppLocalizationsZh` / `AppLocalizationsZhHant` / `AppLocalizationsKo`
    を生成、`flutter analyze` / `flutter test` (642 緑 / 1 skip) /
    `flutter build apk --debug --dart-define=ENABLE_EXPERIMENTAL_LOCALES=true`
    すべて成功。zh / zh_Hant / ko は CLDR plural rule で `other` のみ。
    Copilot レビューで重要 bug 2 件修正: (i) `lib/main.dart` の
    `_experimentalSupportedLocales` を `Locale.fromSubtags(scriptCode: 'Hant')`
    に修正 (countryCode 形式だと繁体字選択が Simplified にフォールバックする
    バグ)、(ii) flag 依存テストが実質未検証だった点を
    `@visibleForTesting debugExperimentalSupportedLocales` で flag 非依存化。
    Pixel 6a 実機検証で韓国語空表示 wrap (`다.` 単独行漏れ → imperative
    `추가하세요` に短縮) と中文 SnackBar `一个星期` 曖昧性 (→ `一天` に修正)
    も追加発見・対応。[docs/translations.md](docs/translations.md) は
    ja / en 2 列維持 + 3 言語は ARB 直接参照に運用切替 (5 列ミラー不採用、
    `homeOpen*` / `*EmptyHint` の stale 行は同期、残りは Phase 11 close out
    PR で一括同期予定)。詳細は [dev-log](docs/dev-log.md)
  - [x] 通知 channel 名の i18n (2026-05-16, PR #59): `NotificationStrings` を
    `lib/domain/notifications/` に移動 (`infrastructure → application` 依存方向
    違反を回避) + `NotificationScheduler.updateChannelNames(NotificationStrings)`
    port メソッド追加 + adapter で `_recreateChannels()` ヘルパに分離。locale
    切替リスナーから `unawaited(scheduler.updateChannelNames(strings))` を呼び
    出すと、同 id `createNotificationChannel` 再呼び出しで OS 設定画面の
    channel 名/説明が即時追従 (importance/sound/vibration は Android 仕様で
    保護され不変)。F-7 (Manifest line 2 整形、PR #20 持ち越し) も同梱。
    mocktail ベースの adapter unit test 3 件追加で 641 テスト緑。Pixel 6a
    5 シナリオ実機検証 OK。詳細は [dev-log](docs/dev-log.md)
  - [x] 設定画面での言語手動切替 UI (2026-05-14): `UserPreferenceKeys.localeTag`
    に BCP-47 タグを永続化し、`SettingsState.localeOverride: Locale?` で
    保持。`null` は「システムに合わせる」(F-9 の localeResolutionCallback
    に委譲)、明示選択時は MaterialApp.locale に渡す。`ref.listen` で手動
    切替時も通知文言を即時更新。Public 版は ja / en の 2 言語、experimental
    フラグ true でビルドした場合のみ zh / zh-Hant / ko も選択肢に出る。
    18 + 9 件のテストを追加、577 テスト緑 (1 skipped)。Pixel 6a 5 シナリオ
    OK (2026-05-15、詳細は [dev-log](docs/dev-log.md))
- [ ] Play Store 提出準備（プライバシーポリシー、スクリーンショット）

**DoD**: 公開可能な品質に到達
**依存**: Phase 10 / Phase 10.5 完了

---

## Phase D（任意 / 観測機構）: Diagnostic Logging — 完了 (2026-05-15)

ベータテスター / 開発者向けに「アプリの動作ログを zip にまとめて OS Share Sheet で
送れる」観測機構を 3 PR で実装。Domain (PII セーフな sealed class) → Application
(`DiagnosticLogger` + isEnabled ゲート + `DiagnosticExportController`) →
Infrastructure (`FileDiagnosticSinkAdapter` JSON Lines + `DiagnosticLogRotator`
retention 14 日 / 累計 50 MB / 1 ファイル 1 MB で分割 + `ZipDiagnosticLogExporterAdapter` +
`share_plus`) → Presentation (SettingsScreen に診断ログトグル + 共有 tile) の 4 層構成。

- D-1 (PR #49): Domain + Application、Sink は In-Memory のみ
- D-2 (PR #52、当初 #50 が D-1 マージで auto-close したため再作成): File-backed sink +
  ローテーション + `LocationDetectorAdapter` 配線 + `main.dart` 全域 error 経路を
  isEnabled ゲート経由に書き換え
- D-3 (PR #51): zip + Share Sheet + Settings UI 配線

Pixel 6a / Android 16 で 4 シナリオ (ファイル生成 / PII 排除 / トグル永続化 /
Share Sheet) すべて OK。

**DoD**: 達成 (詳細は [docs/dev-log.md](docs/dev-log.md))
**依存**: Phase 11 言語切替完了 (実機検証時の不具合観測手段として位置付け)
**参照**: [docs/dev-log.md](docs/dev-log.md) 「Phase D (Diagnostic Logging) 完了」セクション

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
**参照**: 着手時に iOS の通知制約を再調査し、[docs/architecture.md](docs/architecture.md) の「iOS 対応方針」を更新

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
| 11 (その他) | 進行中 | 設定画面 4 項目 (PR #36) + CVD 冗長表示 (PR #39) + 言語手動切替 UI (2026-05-14) + 通知 channel 名 i18n (PR #59、2026-05-16) + F-7 Manifest 整形 (PR #59) + A-3 中韓 ARB 本格翻訳 (zh / zh_Hant / ko、2026-05-16) 完了。アプリアイコン / Splash は PR #91 で生成済、実機表示確認待ち。残: Play Store 提出準備 (Phase 11.9 / 11.10、計画書 [docs/oss-and-play-release-plan.md](docs/oss-and-play-release-plan.md) PR #66 承認済) |
| 11.8 (OSS 公開) | 完了 (2026-05-27) | T1〜T9 PR #67 main マージ (2026-05-16)、T8.5/T8.6 は 2026-05-27 omit (Privacy team 11 日無反応 + 典型 PII ゼロ確認)、T10 (Public 化) 2026-05-27 ユーザ実施完了。Visibility=PUBLIC、Description 設定済、Topics 9 件設定済、Community Standards 100% (`gh api .../community/profile`)、シークレットウィンドウ Public URL 表示確認済 |
| 11.9 (Play 提出準備) | β 実装マージ済、実機確認待ち / γ 未着手 | サブ PR α (**PR #72 main マージ済 2026-05-28**) で applicationId / MethodChannel 移行、Issue #74 fix (**PR #75 main マージ済 2026-05-29**) で Lock 画面 FSI 二重音を解消。β 事前準備 (**PR #77 main マージ済 2026-05-29**) 後、β 本体 **PR #91 main マージ済 (2026-06-14、squash `954eea2`)**: 3 層 adaptive icon、monochrome themed icon、light / dark splash、Play Store 512 px icon、Feature Graphic を作成・生成。PixAI / Hoshino v2 クレジットもアプリ内と notice に反映。`flutter analyze` / `flutter test` (673 passed / 1 skipped) / debug APK build / 翻訳文書チェック成功。残: Pixel 6a の launcher / themed icon / splash 実機確認、γ (Privacy Policy Pages 公開 + listing + screenshots + signing + aab)。既知 follow-up: 新規 install 直後 POST_NOTIFICATIONS 初回ダイアログ + Banner 不表示。 |
| D (Diagnostic Logging) | 完了 | D-1 (PR #49) / D-2 (PR #52) / D-3 (PR #51) すべて main マージ済、Pixel 6a 4 シナリオ OK (2026-05-15) |
| 12 | 未着手 | 任意 / iOS 版（Android 版完成後） |

---

最終更新日: 2026-06-15（PR #91 マージ後の実態へ同期。Phase 11.9 β は
アイコン / Splash の素材作成・Android リソース生成・Play Store 512 px icon /
Feature Graphic・PixAI クレジットまで完了。PR 検証は `flutter analyze` /
`flutter test` 673 passed (1 skipped) / debug APK build / 翻訳文書チェック成功。
Pixel 6a 実機表示確認のみ β に残し、次の着手単位を γ に更新）

過去の更新: 2026-05-29（計画ファイルを実態に同期 — branch `docs/sync-plan-files-after-72-75`。BACKLOG.md / tasklist.md が 2026-05-27 で停止し PR #72・#75 を「main merge 待ち」と誤記したままだったため実態反映。`gh pr list` で両者マージ済を確認: #72 (Phase 11.9 サブ PR α) 2026-05-28、#75 (Issue #74 fix) 2026-05-29 squash `dcac842`。進捗サマリ表 Phase 11.9 行を「α・#74 fix マージ済 → 次 β」に更新、tasklist.md の進行中 2 件を直近マージ済みへ移動 + 次の着手単位 = サブ PR β を明記、docs/dev-log.md #75 セクション末尾をマージ完了に更新。doc-only。作業ツリーの 15 生成ファイル modified 表示は LF→CRLF eol 差のみで内容差分ゼロ、コミット対象外）

過去の更新: 2026-05-27（Phase 11.9 サブ PR α 実装完了 — branch `phase-11.9-alpha` (ベース `phase-11.8-close-out`)。T0 applicationId rename (`com.bonkotu.timer.timer_utility` → `io.github.bonkoturyu.timer_utility`) + I.1 MethodChannel rename (`com.bonkotu.timer/permission` → `io.github.bonkoturyu.timer_utility/permission`) + alarm_ringing_screen.dart ハードコード解消 (`PermissionChannel.channelName` 定数参照に refactor) + live docs 5 ファイル追従 (README / architecture / android-constraints / permissions / platform-channels) を atomic に切替。事前検討メモ §I.1 で確定した推奨案 A (MethodChannel 名 T0 同 PR 移行 + ハードコード解消) に従う。AndroidManifest.xml は触らず (§B.1 で `.MainActivity` 相対参照 + `${applicationName}` プレースホルダ + flutter_local_notifications の third-party receiver は変更不要を確認済)。`flutter analyze --fatal-infos` 0 issues / `flutter test` 642 passed (1 skipped) / `dart run tool/check_translations_doc.dart` ARB 171 / Doc 171 aligned、grep `com\.bonkotu\.timer` で live files 残存 0 (履歴 docs のみ、§B.4 据置対象)。PR 作成済。残: **Pixel 6a 実機検証** (`adb uninstall com.bonkotu.timer.timer_utility` → `flutter run` → Phase 6 FSI 3 パターン + Phase 8.5 アラーム単音化回帰) はユーザ実施。検証 OK → main マージはユーザ判断 (memory「git の main 反映は PR ごとに明示許可」)。次の着手単位: Phase 11.9 サブ PR β (アイコン素材 + flutter_launcher_icons + flutter_native_splash + strings.xml 5 言語 + Pixel 6a 4 パターン確認)。詳細は [dev-log](docs/dev-log.md) 「Phase 11.9 サブ PR α — applicationId + MethodChannel rename (2026-05-27)」セクション）

過去の更新: 2026-05-27（Phase 11.8 完全クローズ — T10 (GitHub Settings → Visibility = Public + Description + Topics 設定) を本日ユーザ実施で完了。branch `phase-11.8-close-out` で `docs/dev-log.md` / `docs/oss-and-play-release-plan.md` / BACKLOG.md / tasklist.md の 4 ファイルに完了記録を反映。T10 実施結果: `gh repo view --json` 出力で Visibility=PUBLIC、Description=「Multi-timer / alarm / world-clock for Android 16. Reference implementation of Flutter Clean Architecture + Android alarm constraints handling.」、Topics 9 件 (`alarm` / `android` / `claude-code` / `clean-architecture` / `dart` / `drift` / `flutter` / `riverpod` / `timer`)。`gh api repos/Bonkoturyu/TimerUtility/community/profile` で `health_percentage: 100` 確認 (※ API 上 `issue_template: null` と表示されるが、ディレクトリ形式 `.github/ISSUE_TEMPLATE/{bug_report,feature_request}.md` は別経路で OK 判定されるため health_percentage は 100% に到達)、シークレットウィンドウで Public URL アクセス成功 (ユーザ確認済)。Phase 11.8 全タスク状況: T1〜T9 PR #67 (2026-05-16) main マージ済、T8.5/T8.6 同日午前 omit 決定 (PR #69)、T10 同日 ユーザ実施で完了。doc-only 変更のため `flutter test` / `flutter analyze` は未実行 (PR #67 時点で 642 緑 / 1 skipped 維持)。次の着手単位は Phase 11.9 サブ PR α (T0 applicationId 変更 `com.bonkotu.timer.timer_utility` → `io.github.bonkoturyu.timer_utility` + MethodChannel `com.bonkotu.timer/permission` → `io.github.bonkoturyu.timer_utility/permission` rename + live docs 追従)。詳細は [dev-log](docs/dev-log.md) 「Phase 11.8 完全クローズ — T10 (Public 化) 完了 (2026-05-27)」セクション）

過去の更新: 2026-05-27（Phase 11.8 T8.5 / T8.6 omit 決定 — branch `phase-11.8-t10-unblock`。2026-05-16 に `privacy@github.com` 宛で送信した個人情報削除申請が 11 日経過 (5/16 → 5/27) しても auto-ack / ticket / bounce すべてゼロで処理されている形跡なし。並行して orphan commit `f2e46e3` の `docs/opus-startup-prompt.md` 旧版を `gh api .../contents/...?ref=f2e46e3` で実物確認 → 露出内容は技術スキル列挙 (C/C++/C#、Dart/Flutter、TS/JS、Python、GDScript) + Web/VR/3D ツール列挙 (Next.js、Unity、UE5、SteamVR、OpenVR Skeletal Input、DXGI Desktop Duplication 等) + 自宅 PC 構成 (Ryzen + マルチ GPU + `CUDA_VISIBLE_DEVICES` UUID 指定 + `OLLAMA_HOST=0.0.0.0`) + 使用 SaaS (Ollama / Continue.dev / faster-whisper / PaddleOCR / OPUS-MT / NLLB-200 / Claude Code / Copilot / Gemini Flash) のみで、典型 PII (氏名 / 連絡先 / 住所 / financial / credentials / API キー / 写真) ゼロ。GitHub アカウント `@Bonkoturyu` のプロフィール程度の独自性、悪用可能性低と評価。ユーザー判断で T8.5/T8.6 を omit、T10 (Public 化) を T8.6 非依存に変更し進行解除。`docs/oss-and-play-release-plan.md` Phase 11.8 セクションのタスク表 / DoD / 検証を打消し線付きで撤回、memory `feedback_filter_branch_github_cache.md` に「コスト・ベネフィット例外」セクション追記 (Privacy team 長期無反応 + 典型 PII ゼロのとき omit する判定手順を将来再利用可能化)。残: T10 (GitHub Settings → Visibility = Public + Description / Topics 設定) はユーザ作業 (不可逆)。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-17（Phase 11.9 事前検討 §I キックオフ判断 4 件確定 — branch `phase-11.9-prep` で実装中の PR #68 に追加 commit。ユーザ承認の推奨案 A をすべて採用: (1) MethodChannel 名 `com.bonkotu.timer/permission` → `io.github.bonkoturyu.timer_utility/permission` を T0 と同 PR で移行 + alarm_ringing_screen.dart のハードコード解消、(2) アイコン素材は foreground + background + monochrome layer 3 層セットで T1 から作成 (themed icon 必須化への保険 + Android 13+ UX 改善)、(3) アプリ名は全 5 言語 (ja/en/zh/zh_Hant/ko) で `TimerUtility` 統一 (既存 ARB `appTitle` と整合、ブランド一貫性)、(4) サブ PR 分割は α (T0 + MethodChannel + live docs) / β (T1-T7 アイコン+Splash+strings.xml+Pixel 6a 検証) / γ (T8-T18 privacy-policy GitHub Pages + listing + signing + aab) の 3 PR 案で進行。`phase-11.9-prep-notes.md` §I を「残論点」→「確定事項」に書き換え、tasklist.md / BACKLOG.md も追従。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-17（Phase 11.9 事前検討着手 — branch `phase-11.9-prep` で実装。Phase 11.8 T8.5 GitHub Privacy team 申請 (2026-05-17 ユーザ送信済) の返信待ち期間活用。`docs/phase-11.9-prep-notes.md` 新規 (A 依存版数 / B applicationId 影響範囲 grep / C 5 言語アプリ名統一 / G アイコン仕様要件 + サブ PR α/β/γ 分割案 + 残論点 4 件) + 実アーティファクト草稿 4 件: `docs/privacy-policy.md` / `docs/privacy-policy.en.md` (8 権限利用根拠 + GPS 一時利用 + 診断ログ取扱い、Data Safety 申告と整合) / `docs/play-store-listing.md` (短い説明 80 字 / 長い説明 4000 字 / What's new / Data Safety / Content Rating / 8 権限 Play Console 用説明文 + スクショシナリオ + 連絡先) / `docs/release-signing.md` (keytool / `key.properties` / `build.gradle.kts` 配線 / Play App Signing 加入 / CI 自動署名 / セキュリティ注意)。Native / pubspec.yaml 編集なし。`dart format` (254 ファイル、変更 0) / `flutter analyze --fatal-infos` / `tool/check_translations_doc.dart` (ARB 171 / Doc 171 一致) すべて緑。doc-only のため `flutter test` は CI 任せ (前 PR で 642 緑確認済)。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-16（Phase 11.8 OSS 公開準備の T1〜T9 着手 — branch `phase-11.8-oss-prep` で実装。README 再構成 (Build & Run / Architecture / fork ガイド / "What's special" 4+ EN 段落) / `THIRD_PARTY_NOTICES.md` 新規 / `CONTRIBUTING.md` 新規 / `CODE_OF_CONDUCT.md` 新規 (Contributor Covenant 2.1、Enforcement は `@Bonkoturyu` GitHub Issues 経由) / `.github/ISSUE_TEMPLATE/{bug_report,feature_request}.md` + `PULL_REQUEST_TEMPLATE.md` 新規 / `pubspec.yaml` に `homepage` / `repository` / `issue_tracker` 追加 / 秘密情報 grep + commit author 全件確認 (hit 0、author は GitHub 提供 noreply 1 件のみ)。`flutter analyze --fatal-infos` / `flutter test` (642 緑 / 1 skipped) / `dart run tool/check_translations_doc.dart` (ARB 171 / Doc 171 一致) すべて緑。残: T8.5 (GitHub Privacy team `privacy@github.com` メール申請、orphan commit `f2e46e3` 経由の `docs/opus-startup-prompt.md` 旧版 cache 削除) + T8.6 (404 確認) + T10 (GitHub Public 化) はユーザ作業のため本セッション外。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-16（A-2 (通知 channel 名 i18n) + F-7 (Manifest 整形) 完了 — PR #59 main マージ済、Pixel 6a 5 シナリオ実機検証完了。`NotificationStrings` を `lib/domain/notifications/` に移動 (依存方向修正) + `NotificationScheduler.updateChannelNames` port 追加で、locale 切替時に同 id `createNotificationChannel` 再呼び出しにより OS 設定画面の channel 名が即時追従。F-7 (PR #20 持ち越し Manifest line 2 整形) も同梱。641 テスト緑 (1 skipped)。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-15（Phase D (Diagnostic Logging) 完了 — D-1 (PR #49) / D-2 (PR #52) / D-3 (PR #51) すべて main マージ済、Pixel 6a 4 シナリオ実機検証 (ファイル生成 / PII 排除 / トグル永続化 / Share Sheet) すべて OK。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-14（Phase 11 言語手動切替 UI 完了 — 設定画面に「言語」項目を追加、`localeTag` 永続化 + `SettingsState.localeOverride` で MaterialApp.locale を駆動、577 テスト緑）

過去の更新: 2026-05-14（BACKLOG.md コンパクト化 — 完了 Phase 0〜10.5 の `[x]` チェックリスト・実機検証詳細を [docs/dev-log.md](docs/dev-log.md) に集約し、本ファイルは Phase ヘッダ + 1 行要約 + dev-log リンク + 進捗サマリ + 進行中/未着手 Phase の詳細のみ保持。790 行 → 316 行）

過去の更新: 2026-05-13（Phase 11 CVD banner labels 完了 — `permission_banners.dart` の 3 種バナーに重大度ラベル + FontWeight 段階差 + 左端色帯幅で形状差。558 テストパス (1 skipped)、PR #39）
