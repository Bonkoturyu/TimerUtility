# State Management

本プロジェクトの Riverpod Provider 設計を定義する。
Claude Code は新規 Provider 追加時に必ず本ドキュメントを更新すること。

---

## 採用ライブラリ

- `flutter_riverpod` ^2.5.x
- `riverpod_annotation` ^2.3.x
- `riverpod_generator`（dev）
- `riverpod_lint`（dev）
- `custom_lint`（dev）

採用理由は `docs/adr/0001-use-riverpod.md` 参照。

---

## 基本方針

### Provider の生成

- **コード生成（`@riverpod`）を基本**とする
- 手書き Provider は package:clock の wrapper 等、シンプルな依存提供のみに限定

### 種別の使い分け

| 種別 | 用途 | 例 |
|---|---|---|
| `@riverpod`（関数形式） | 単純な依存提供、計算結果 | `clockProvider`, `durationFormatterProvider` |
| `@riverpod` クラス（Notifier 形式） | 状態を持つロジック | `stopwatchNotifierProvider` |
| `@Riverpod(keepAlive: true)` | アプリ生存期間中保持 | `appDatabaseProvider`, `clockProvider` |
| family | 引数で分岐 | `timerProvider(TimerId)` |

### スコープ

- `keepAlive: true`: インフラ系 / 全画面共有が必要なもの
- デフォルト（autoDispose）: 画面固有の状態

---

## Provider 一覧

### Infrastructure 層

| Provider | 種別 | 提供型 | スコープ | 責務 |
|---|---|---|---|---|
| `clockProvider` | function | `Clock` | keepAlive | 時刻取得の抽象化（テスト時に override） |
| `appDatabaseProvider` | function | `AppDatabase` | keepAlive | Drift DB インスタンス |
| `notificationSchedulerProvider` | function | `NotificationScheduler` | keepAlive | 通知予約 Adapter |
| `alarmSoundPlayerProvider` | function | `AlarmSoundPlayer` | keepAlive | 音再生 Adapter |
| `timerRepositoryProvider` | function | `TimerRepository` | keepAlive | Timer 永続化 |
| `presetRepositoryProvider` | function | `PresetRepository` | keepAlive | Preset 永続化 |
| `alarmRepositoryProvider` | function | `AlarmRepository` | keepAlive | Alarm 永続化（Phase 9.5） |
| `clockLocationRepositoryProvider` | function | `ClockLocationRepository` | keepAlive | 世界時計の永続化（Phase 10.5） |
| `locationDetectorProvider` | function | `LocationDetector` | keepAlive | GPS → IANA TZ ID 解決（Phase 10.5、失敗時 FlutterTimezone fallback） |
| `permissionManagerProvider` | function | `PermissionManager` | keepAlive | 権限管理 |
| `loggerProvider` | function | `Logger` | keepAlive | ロガー |
| `notificationIdGeneratorProvider` | function | `NotificationIdGenerator` | keepAlive | OS 通知 ID 生成 |

### Domain Service 層

ドメインサービスは Provider 経由で取得。`Clock` を注入された状態で提供。

| Provider | 種別 | 提供型 | 責務 |
|---|---|---|---|
| `stopwatchServiceProvider` | function | `StopwatchService` | StopwatchService インスタンス |
| `timerServiceProvider` | function | `TimerService` | TimerService インスタンス |
| `snoozeCalculatorProvider` | function | `SnoozeCalculator` | スヌーズ計算 |
| `durationFormatterProvider` | function | `DurationFormatter` | 表示フォーマット |
| `alarmSoundCatalogProvider` | function | `AlarmSoundCatalog` | 音源カタログ |
| `alarmServiceProvider` | function | `AlarmService` | 指定時刻アラームの次回発火計算（Phase 9.5） |

### Application 層（Notifier）

| Provider | 種別 | 状態型 | スコープ | 責務 |
|---|---|---|---|---|
| `stopwatchNotifierProvider` | Notifier | `StopwatchState` | keepAlive | ストップウォッチ状態管理、Lifecycle 監視 |
| `timerCollectionNotifierProvider` | Notifier | `TimerCollectionState` | keepAlive | 複数タイマー管理、起動時 DB 復元 |
| `timerNotifierProvider(TimerId)` | Notifier.family | `TimerEntity` | autoDispose | 個別タイマーの操作 |
| `alarmRingingNotifierProvider` | Notifier | `AlarmRingingState` | keepAlive | 鳴動中タイマーの管理、音再生制御 |
| `presetNotifierProvider` | Notifier | `List<Preset>` | keepAlive | プリセット CRUD |
| `permissionNotifierProvider` | Notifier | `PermissionState` | keepAlive | 各権限の取得状態 |
| `alarmCollectionNotifierProvider` | Notifier | `List<AlarmEntity>` | keepAlive | 指定時刻アラーム CRUD・ON/OFF 切替・予約管理（Phase 9.5） |
| `clockCollectionNotifierProvider` | Notifier | `List<ClockLocation>` | keepAlive | 世界時計の CRUD・並べ替え・初回起動時の現在地登録（Phase 10.5） |

### Presentation 層（UI 補助）

| Provider | 種別 | 提供型 | スコープ | 責務 |
|---|---|---|---|---|
| `currentTimeStreamProvider` | StreamProvider | `DateTime` | autoDispose | UI 更新用の時刻 Stream。Phase 10.5 で実装（世界時計向けは 1 秒周期、ストップウォッチ / タイマー向けは 100ms 周期版を別途検討） |
| `stopwatchTickProvider` | StreamProvider | `Duration` | autoDispose | ストップウォッチ表示更新用 |
| `timerTickProvider(TimerId)` | StreamProvider.family | `Duration` | autoDispose | 各タイマー残り時間表示更新用 |

---

## Notifier の責務範囲

### StopwatchNotifier

```
責務:
- StopwatchService への操作委譲（start/pause/resume/lap/reset）
- AppLifecycleListener の購読
  - paused → 表示更新を停止（Stream を pause）
  - resumed → Clock から最新時刻取得して状態再計算
- 状態の永続化は不要（ストップウォッチは揮発で OK）

非責務:
- 経過時間の計算ロジック（StopwatchService に委譲）
- Lap 配列の操作（StopwatchService に委譲）
```

### TimerCollectionNotifier

```
責務:
- アプリ起動時の DB からの復元
- TimerEntity の追加 / 削除 / 取得
- TimerCollection ドメイン集約への委譲
- 同時稼働上限の検証
- DB への永続化（変更時に Repository 経由）

非責務:
- 個別タイマーの状態遷移（TimerNotifier に委譲）
- 通知予約の直接実行（TimerNotifier 経由）
```

### TimerNotifier (family)

```
責務:
- 個別タイマーの状態遷移
- TimerService への操作委譲
- NotificationScheduler への予約 / キャンセル
- 状態変更時に TimerCollectionNotifier に通知（DB 更新トリガ）

非責務:
- 複数タイマー間の調整（TimerCollectionNotifier の責務）
- 音再生（AlarmRingingNotifier の責務）
```

### AlarmRingingNotifier

```
責務:
- 鳴動中エントリのリスト管理（Timer / Alarm 両用、複数同時鳴動対応）
- AlarmSoundPlayer による音再生制御
- ringing 起動時に「自分が引き継ぐ通知」を NotificationScheduler.cancel
  で停止する（OS Channel の bundled sound と audioplayers の二重再生
  を避けるため。詳細経緯は docs/android-constraints.md の Phase 6 後
  フォロー再発防止メモ）
- start は isPlaying 検査で idempotent（複数経路から呼ばれても OK）
- Native からの「アラーム発火」イベント受信（payload prefix で起動元判別）
- 停止 / スヌーズ操作の受付

非責務:
- 通知のスケジュール / cancelAll などの全体ライフサイクル
  （NotificationScheduler / TimerNotifier / AlarmCollectionNotifier の責務）
- タイマー状態の更新（TimerNotifier に委譲）
- 指定時刻アラームの enabled / 次回発火状態の更新（AlarmCollectionNotifier に委譲）
```

`start` は AlarmRingingScreen の self-bootstrap (initState の post-frame
callback) と TimerScreen ringing listener 経由 push の両方から呼ばれ得る
が、isPlaying ガードで二重起動しない設計。AlarmRingingScreen 起動を
唯一の cancel + play トリガーにすることで、前面 / 背景 (FSI) /
コールドスタートのいずれの経路でも「画面が出てから音が切り替わる」順序
が保証され、AlarmManager の通知発火を阻害しない。

Phase 9.5 以降は payload prefix `timer:` / `alarm:` で起動元を識別し、停止 / スヌーズ操作を
それぞれ `TimerNotifier` / `AlarmCollectionNotifier` に振り分ける。
詳細は `docs/adr/0005-alarm-vs-timer-separation.md` 参照。

### ClockCollectionNotifier（Phase 10.5）

```
責務:
- アプリ起動時の DB からの全 ClockLocation 読み込み
- 初回起動時 (DB が空) に LocationDetector.detectTimezoneId() を呼び
  「現在地」エントリを 1 件追加 (isCurrentLocation: true)
- ClockLocation の追加 / 削除 / 並べ替え (上限 6 件、ClockCollection 集約に委譲)
- 変更時に ClockLocationRepository 経由で永続化

非責務:
- 現在時刻の Stream 提供 (currentTimeStreamProvider に委譲)
- 各 TZ の壁時計時刻計算 (ClockTime ValueObject に委譲、Widget 側で呼ぶ)
- GPS 取得そのもの (LocationDetector port に委譲)
```

GPS 失敗 (権限拒否 / オフライン / 逆ジオコ失敗) 時は LocationDetector の
adapter 内で FlutterTimezone.getLocalTimezone() に fallback するため、
Notifier 側はこの分岐を意識しない。

### AlarmCollectionNotifier（Phase 9.5）

```
責務:
- アプリ起動時の DB からの全アラーム読み込み
- AlarmEntity の CRUD（add / update / delete）
- enabled トグルの切替
- enabled 化 / 編集時に AlarmService.nextFireAt → NotificationScheduler.schedule
- disabled 化 / 削除時に NotificationScheduler.cancel
- 鳴動 → 停止イベント受信時に AlarmService.advanceAfterFire → 次回 schedule + 永続化
- 鳴動 → スヌーズイベント受信時に AlarmService.snoozeUntil → schedule（既存 notificationId）
- 端末再起動後の全 enabled アラーム再予約（Phase 10 BootReceiver から呼び出し）

非責務:
- 鳴動 UI の制御（AlarmRingingNotifier に委譲）
- 音再生（AlarmRingingNotifier 経由 AlarmSoundPlayer）
- 次回発火時刻計算ロジック（AlarmService に委譲）
```

### PresetNotifier

```
責務:
- プリセット CRUD
- PresetRepository 経由で永続化
- 表示順管理

非責務:
- プリセット選択時のタイマー作成（TimerCollectionNotifier の責務）
```

### PermissionNotifier

```
責務:
- 各権限（POST_NOTIFICATIONS, USE_FULL_SCREEN_INTENT, SCHEDULE_EXACT_ALARM）の状態管理
- 権限要求トリガ
- 拒否時のフォールバック判定

非責務:
- 権限要求 UI の表示（Presentation 層の責務）
```

---

## Provider 間の依存関係

```
[Notifier 層]
   stopwatchNotifierProvider
       │
       ├─ ref.watch(clockProvider)
       └─ ref.watch(stopwatchServiceProvider)

   timerCollectionNotifierProvider
       │
       ├─ ref.watch(clockProvider)
       ├─ ref.watch(timerRepositoryProvider)
       └─ ref.watch(notificationIdGeneratorProvider)

   timerNotifierProvider(id)
       │
       ├─ ref.watch(clockProvider)
       ├─ ref.watch(timerServiceProvider)
       ├─ ref.watch(notificationSchedulerProvider)
       ├─ ref.watch(timerCollectionNotifierProvider.notifier)
       └─ ref.watch(snoozeCalculatorProvider)

   alarmRingingNotifierProvider
       │
       ├─ ref.watch(alarmSoundPlayerProvider)
       ├─ ref.watch(timerCollectionNotifierProvider.notifier)
       └─ ref.watch(alarmCollectionNotifierProvider.notifier)   // Phase 9.5

   alarmCollectionNotifierProvider                              // Phase 9.5
       │
       ├─ ref.watch(clockProvider)
       ├─ ref.watch(alarmServiceProvider)
       ├─ ref.watch(alarmRepositoryProvider)
       ├─ ref.watch(notificationSchedulerProvider)
       └─ ref.watch(notificationIdGeneratorProvider)

   clockCollectionNotifierProvider                              // Phase 10.5
       │
       ├─ ref.watch(clockLocationRepositoryProvider)
       └─ ref.watch(locationDetectorProvider)   // 初回起動時のみ呼ぶ
```

---

## ライフサイクル監視

`AppLifecycleListener`（Flutter 3.13+）を使用。
購読場所は **必要な Notifier のみ**。

| Notifier | 監視する状態 | アクション |
|---|---|---|
| `StopwatchNotifier` | paused / resumed | 表示 Stream の停止 / 再開、resume 時に時刻再計算 |
| `TimerCollectionNotifier` | resumed | 全タイマーの残り時間再計算、過ぎたタイマーは ringing 化 |
| `AlarmRingingNotifier` | resumed | 鳴動中エントリの状態同期 |
| `AlarmCollectionNotifier` | resumed | 全 enabled アラームの次回発火時刻を再計算（端末時刻変更検知も兼ねる、Phase 9.5） |
| `ClockCollectionNotifier` | (監視なし) | 時刻表示は currentTimeStreamProvider が autoDispose で画面表示中のみ active のため、Notifier 側で lifecycle 監視は不要（Phase 10.5） |

実装パターン:

```
Notifier の build() 内で AppLifecycleListener を生成し、
ref.onDispose で破棄する。
```

---

## ref.watch / ref.read の使い分け

| 用途 | API | 例 |
|---|---|---|
| 状態の購読（再ビルド対象） | `ref.watch` | UI からの参照、依存先 Provider の変更に追従 |
| 一回限りの読み取り | `ref.read` | ボタンタップ時の操作呼び出し |
| Notifier 自体の取得 | `ref.read(xxxProvider.notifier)` | メソッド呼び出し時 |

**禁止事項**:
- ❌ `build` メソッド以外で `ref.watch` を使用（Notifier の build / Widget の build のみ）
- ❌ Notifier の build で `ref.read` を使用（依存追跡が壊れる）

---

## State 型の設計

### sealed class / freezed の使い分け

- **状態が複数の形を取る場合**: sealed class（StopwatchState など）
- **単一形状で値が変わるだけ**: freezed の単一クラス
- **Entity 自体を State にする場合**: そのまま使用（TimerEntity など）

### immutability

- すべての State は immutable
- 更新は `state = state.copyWith(...)` または新規インスタンス生成
- mutable な field を持たない

---

## 表示更新用 Stream

UI でストップウォッチ / タイマーの表示を更新するための Stream Provider。

### `currentTimeStreamProvider`

```
責務: 100ms 周期で現在時刻を流す
利用: ストップウォッチ画面、タイマー画面
注意: 画面が表示されている間のみ active（autoDispose）
実装: Stream.periodic + Clock 経由
```

### `stopwatchTickProvider`

```
責務: ストップウォッチの表示用経過時間
依存: stopwatchNotifierProvider, currentTimeStreamProvider
出力: Duration（100ms 精度）
```

### `timerTickProvider(TimerId)`

```
責務: 各タイマーの表示用残り時間
依存: timerNotifierProvider(id), currentTimeStreamProvider
出力: Duration（100ms 精度）
```

これらは UI 表示専用で、ドメインの状態には影響しない。
domain/ の状態は離散イベント（start, pause, ringing 化）でしか変わらない。

---

## テスト時の override

### 標準オーバーライド構成

テスト時は `ProviderContainer` で以下を override:

```
ProviderContainer(overrides: [
  clockProvider.overrideWithValue(fixedClock),
  notificationSchedulerProvider.overrideWithValue(fakeScheduler),
  alarmSoundPlayerProvider.overrideWithValue(fakePlayer),
  appDatabaseProvider.overrideWithValue(inMemoryDb),
  timerRepositoryProvider.overrideWithValue(fakeRepository),
])
```

詳細は `docs/testing-strategy.md` 参照。

---

## ディレクトリ配置

```
lib/application/
├── stopwatch_notifier.dart
├── stopwatch_notifier.g.dart        // 自動生成
├── timer_notifier.dart
├── timer_notifier.g.dart
├── timer_collection_notifier.dart
├── timer_collection_notifier.g.dart
├── alarm_ringing_notifier.dart
├── alarm_ringing_notifier.g.dart
├── preset_notifier.dart
├── preset_notifier.g.dart
├── permission_notifier.dart
├── permission_notifier.g.dart
├── alarm_collection_notifier.dart      // Phase 9.5
├── alarm_collection_notifier.g.dart
├── clock_collection_notifier.dart      // Phase 10.5
├── clock_collection_notifier.g.dart
├── location_detector_provider.dart     // Phase 10.5
├── clock_location_repository_provider.dart  // Phase 10.5
├── clock_tick/                         // Phase 10.5
│   └── current_time_stream_provider.dart
├── tick/
│   ├── current_time_stream_provider.dart
│   ├── stopwatch_tick_provider.dart
│   └── timer_tick_provider.dart
└── infrastructure_providers.dart    // インフラ系 Provider 一括定義
```

---

## アンチパターン（やってはいけない）

❌ **Notifier 内で他の Notifier の状態を mutate する**
→ Notifier 同士は ref で参照するが、相手の state を直接書き換えない

❌ **Widget 内で複雑なロジック**
→ 必ず Notifier に委譲

❌ **Provider 内で BuildContext に依存する**
→ Navigator / SnackBar 等は Widget 側のリスナで対応

❌ **autoDispose Provider に重い初期化処理を入れる**
→ keepAlive 化を検討

❌ **family の引数に複雑なオブジェクトを渡す**
→ 値型で hashable なもの（String, int, ID 系）に限定

---

## 関連ドキュメント

- `docs/architecture.md`: レイヤー全体構造
- `docs/domain-model.md`: ドメインモデル詳細
- `docs/testing-strategy.md`: Provider のテスト方法
- `docs/adr/0001-use-riverpod.md`: Riverpod 採用の経緯

---

最終更新日: 2026-05-01（Phase 10.5 世界時計関連 Provider・Notifier 責務・依存図を追加、currentTimeStreamProvider の実装 Phase 明記）
