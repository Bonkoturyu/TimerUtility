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
| `notificationSchedulerProvider` | function | `NotificationScheduler` | keepAlive | 通知予約 Adapter（Phase 8 で `show()` 即時通知 API 追加） |
| `alarmSoundPlayerProvider` | function | `AlarmSoundPlayer` | keepAlive | 音再生 Adapter |
| `timerRepositoryProvider` | function | `TimerRepository` | keepAlive | Timer 永続化（Phase 8 で実装、main.dart で DriftTimerRepository を override） |
| `presetRepositoryProvider` | function | `PresetRepository` | keepAlive | Preset 永続化 |
| `alarmRepositoryProvider` | function | `AlarmRepository` | keepAlive | Alarm 永続化（Phase 9.5） |
| `clockLocationRepositoryProvider` | function | `ClockLocationRepository` | keepAlive | 世界時計の永続化（Phase 10.5 で実装済み） |
| `locationDetectorProvider` | function | `LocationDetector` | keepAlive | GPS → IANA TZ ID 解決（Phase 10.5 で実装済み、失敗時 FlutterTimezone fallback） |
| `timezoneResolverProvider` | function | `TimezoneResolver` | keepAlive | IANA TZ → wall clock 変換（Phase 10.5 で実装済み、`TzDatabaseTimezoneResolver`、TZ DB は 1 度だけ load） |
| `permissionManagerProvider` | function | `PermissionManager` | keepAlive | 権限管理 |
| `loggerProvider` | function | `Logger` | keepAlive | ロガー |
| `notificationIdGeneratorProvider` | function | `NotificationIdGenerator` | keepAlive | OS 通知 ID 生成 |
| `userPreferencesProvider` | function | `UserPreferences` | keepAlive | `shared_preferences` の薄ラッパ。`getBool` / `setBool` / `getInt` / `setInt` / `remove` を提供 (Phase 11 で `getInt` / `setInt` を追加し `lastHomePageIndex` を扱えるよう拡張) |

### Domain Service 層

ドメインサービスは Provider 経由で取得。`Clock` を注入された状態で提供。

| Provider | 種別 | 提供型 | 責務 |
|---|---|---|---|
| `stopwatchServiceProvider` | function | `StopwatchService` | StopwatchService インスタンス |
| `timerServiceProvider` | function | `TimerService` | TimerService インスタンス（Phase 8 で `application/timer_service_provider.dart` に分離） |
| `snoozeCalculatorProvider` | function | `SnoozeCalculator` | スヌーズ計算 |
| `durationFormatterProvider` | function | `DurationFormatter` | 表示フォーマット |
| `alarmSoundCatalogProvider` | function | `AlarmSoundCatalog` | 音源カタログ |
| `alarmServiceProvider` | function | `AlarmService` | 指定時刻アラームの次回発火計算（Phase 9.5） |

### Application 層（Notifier）

| Provider | 種別 | 状態型 | スコープ | 責務 |
|---|---|---|---|---|
| `stopwatchNotifierProvider` | Notifier | `StopwatchState` | keepAlive | ストップウォッチ状態管理、Lifecycle 監視 |
| `timerCollectionNotifierProvider` | Notifier | `TimerCollection` | keepAlive | 複数タイマー管理（CRUD / 起動時 DB 復元 / 過去到達タイマーの completed 化 + show() 通知 / 200 ms ticker による ringing 検知）。Phase 8 で実装済み、family 案は廃止し本 Notifier に統合 |
| `alarmRingingNotifierProvider` | Notifier | `AlarmRingingState` | keepAlive | 鳴動中タイマーの管理、音再生制御 |
| `presetNotifierProvider` | Notifier | `List<Preset>` | keepAlive | プリセット CRUD |
| `permissionNotifierProvider` | Notifier | `PermissionState` | keepAlive | 各権限の取得状態 |
| `alarmCollectionNotifierProvider` | Notifier | `List<AlarmEntity>` | keepAlive | 指定時刻アラーム CRUD・ON/OFF 切替・予約管理（Phase 9.5） |
| `clockCollectionNotifierProvider` | Notifier | `List<ClockLocation>` | keepAlive | 世界時計の CRUD・並べ替え・初回起動時の現在地登録（Phase 10.5 で実装済み） |

### Presentation 層（UI 補助）

| Provider | 種別 | 提供型 | スコープ | 責務 |
|---|---|---|---|---|
| `currentTimeStreamProvider` | StreamProvider | `DateTime` | autoDispose | UI 更新用の時刻 Stream。Phase 10.5 で実装済み（世界時計向けは 1 秒周期、ストップウォッチ / タイマー向けは 100ms 周期版を別途検討） |
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

### TimerCollectionNotifier（Phase 8 で実装済み）

Phase 3 までの単一 `TimerNotifier` を廃止し、複数タイマーの単一情報源
として再設計したもの。State は `TimerCollection`。

```
責務:
- アプリ起動時の DB からの復元 (Repository.findAll)
- 復元時、`endAt < now` の running を completed に書き換えて永続化し、
  NotificationScheduler.show() で「Timer ended while away」通知を
  各 timerId につき 1 回だけ表示
- TimerEntity の create / update / delete (TimerCollection / TimerService
  経由)
- 個別タイマーの状態遷移 (start / pause / resume / cancel / reset / snooze)
- 200 ms ticker による全 running の進行と ringing 遷移検知
  (`runningCount == 0` で自動停止 / 必要時に再起動)
- NotificationScheduler への schedule / cancel (state 変更ごとに連動)
- 同時稼働上限 (10 本) の検証
- 各操作後に Repository.upsert / delete でフルライト

非責務:
- 通知の即時表示そのもの (NotificationScheduler の責務)
- 音再生 (AlarmRingingNotifier の責務)
- 過去到達タイマーへの AlarmRingingScreen 起動 (Phase 8 設計上、復元時は
  音も画面も出さず通知 1 回のみ)
```

**廃止**: `timerNotifierProvider(TimerId)` family は Phase 8 で廃止。
個別タイマー操作はすべて `TimerCollectionNotifier` のメソッドに統合した。
複数 Notifier が同じ TimerEntity を二重に書く競合や、family エントリの
ライフサイクル管理オーバーヘッドを避けるため。

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

### ClockCollectionNotifier（Phase 10.5 で実装済み）

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

   timerCollectionNotifierProvider                              // Phase 8
       │
       ├─ ref.read(clockProvider)
       ├─ ref.read(timerServiceProvider)
       ├─ ref.read(timerRepositoryProvider)
       ├─ ref.read(notificationSchedulerProvider)
       └─ ref.read(permissionNotifierProvider)   // exact alarm 判定

   alarmRingingNotifierProvider
       │
       ├─ ref.read(alarmSoundPlayerProvider)
       ├─ ref.read(notificationSchedulerProvider)   // bundled sound cancel
       ├─ ref.read(timerCollectionNotifierProvider.notifier)
       └─ ref.read(alarmCollectionNotifierProvider.notifier)   // Phase 9.5

   alarmCollectionNotifierProvider                              // Phase 9.5
       │
       ├─ ref.watch(clockProvider)
       ├─ ref.watch(alarmServiceProvider)
       ├─ ref.watch(alarmRepositoryProvider)
       ├─ ref.watch(notificationSchedulerProvider)
       └─ ref.watch(notificationIdGeneratorProvider)

   clockCollectionNotifierProvider                              // Phase 10.5 で実装済み
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
| `ClockCollectionNotifier` | (監視なし) | 時刻表示は currentTimeStreamProvider が autoDispose で画面表示中のみ active のため、Notifier 側で lifecycle 監視は不要（Phase 10.5 で実装済み） |

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
依存: timerCollectionNotifierProvider, currentTimeStreamProvider
出力: Duration（100ms 精度）
```

Phase 8 では本 Provider は導入せず、`TimerListScreen` 側で
`Timer.periodic(200ms)` + `setState` により表示更新している
(`TimerCollectionNotifier` 側の ticker と独立)。後続 Phase で本 Provider
を導入する場合は `timerCollectionNotifierProvider` 経由で TimerEntity
を取得する設計とする。

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
├── timer_service_provider.dart      // Phase 8: TimerService Provider 分離
├── timer_service_provider.g.dart
├── timer_repository_provider.dart   // Phase 8: main.dart で override
├── timer_repository_provider.g.dart
├── timer_collection_notifier.dart   // Phase 8: 旧 timer_notifier.dart 廃止
├── timer_collection_notifier.g.dart
├── alarm_ringing_notifier.dart
├── alarm_ringing_notifier.g.dart
├── preset_notifier.dart
├── preset_notifier.g.dart
├── permission_notifier.dart
├── permission_notifier.g.dart
├── alarm_collection_notifier.dart      // Phase 9.5
├── alarm_collection_notifier.g.dart
├── clock_collection_notifier.dart      // Phase 10.5 で実装済み
├── clock_collection_notifier.g.dart
├── location_detector_provider.dart     // Phase 10.5 で実装済み
├── clock_location_repository_provider.dart  // Phase 10.5 で実装済み
├── timezone_resolver_provider.dart     // Phase 10.5 で実装済み
├── clock_tick/                         // Phase 10.5 で実装済み
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

最終更新日: 2026-05-01（Phase 8 完了反映: timerCollectionNotifierProvider に統合、family 案廃止、timerServiceProvider / timerRepositoryProvider 配線を明記）
