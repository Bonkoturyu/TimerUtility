# Domain Model

本プロジェクトのドメインモデル（Entity / ValueObject / 状態遷移 / ドメインルール）を定義する。
Claude Code は新規 Entity 追加・既存 Entity 変更時に必ず本ドキュメントを更新すること。

---

## 全体像

```
┌─────────────────────────────────────────────────┐
│  Stopwatch Aggregate                            │
│  ・StopwatchState (sealed)                      │
│  ・LapRecord (ValueObject)                      │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Timer Aggregate                                │
│  ・TimerEntity                                  │
│  ・TimerStatus (enum)                           │
│  ・TimerCollection (集約ルート相当)              │
│  ・SnoozeState (ValueObject)                    │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Preset Aggregate                               │
│  ・Preset                                       │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Alarm Aggregate（Phase 9.5 予定）              │
│  ・AlarmEntity                                  │
│  ・AlarmRepeat (sealed ValueObject)             │
│  ・AlarmService                                 │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Clock Aggregate（Phase 10.5 で実装済み）       │
│  ・ClockLocation                                │
│  ・ClockCollection (集約ルート相当)             │
│  ・ClockTime (ValueObject)                      │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Shared ValueObjects                            │
│  ・AlarmSound                                   │
│  ・TimerId / PresetId / AlarmId /               │
│    ClockLocationId / NotificationId             │
└─────────────────────────────────────────────────┘
```

---

## Stopwatch Aggregate

### StopwatchState（sealed class）

ストップウォッチの状態を sealed class で表現する。`freezed` または Dart 3+ の sealed class を使用。

```
sealed class StopwatchState
├── StopwatchIdle              // 未開始
├── StopwatchRunning            // 計測中
│   ├── startedAt: DateTime    // 開始絶対時刻
│   ├── accumulatedBefore: Duration  // ポーズ前までの累積
│   └── laps: List<LapRecord>
├── StopwatchPaused             // 一時停止中
│   ├── pausedAt: DateTime
│   ├── accumulated: Duration  // 一時停止時点での総経過時間
│   └── laps: List<LapRecord>
```

### 経過時間の計算

`StopwatchRunning` 状態における現在の経過時間:

```
elapsed = accumulatedBefore + (now - startedAt)
```

`StopwatchPaused` 状態:

```
elapsed = accumulated
```

### LapRecord（ValueObject）

```
LapRecord {
  index: int            // 1-indexed
  splitTime: Duration   // 前回 Lap からの差分
  totalTime: Duration   // 開始からの累計
  recordedAt: DateTime  // 絶対時刻
}
```

不変条件:
- `index >= 1`
- `splitTime >= Duration.zero`
- `totalTime >= splitTime`

### 状態遷移

```
StopwatchIdle
   │ start()
   ▼
StopwatchRunning ──────lap()────▶ StopwatchRunning (laps 追加)
   │                                    ▲
   │ pause()                            │
   ▼                                    │
StopwatchPaused ────resume()────────────┘
   │
   │ reset()
   ▼
StopwatchIdle
```

不正な遷移は `StateError` を throw:
- `StopwatchIdle.pause()` → `StateError`
- `StopwatchIdle.lap()` → `StateError`
- `StopwatchPaused.lap()` → `StateError`

---

## Timer Aggregate

### TimerEntity

```
TimerEntity {
  id: TimerId                        // UUID v4（Phase 3 では String）
  notificationId: int                // OS 通知用 int ID（Phase 4 で追加）
  label: String                      // ユーザー指定（空可、空時は表示時にデフォルト名）
  duration: Duration                 // 設定された時間
  endAt: DateTime?                   // 絶対時刻（running 時のみ非 null）
  status: TimerStatus
  pausedRemaining: Duration?         // paused 時の残り時間退避
  alarmSound: AlarmSound             // 鳴動時の音源（Phase 5 で追加予定）
  snooze: SnoozeState                // スヌーズ履歴（Phase 7 で追加予定）
  createdAt: DateTime
}
```

Phase 別フィールド追加履歴:

| フィールド | 追加 Phase | 備考 |
|---|---|---|
| `id, label, duration, endAt, status, pausedRemaining, createdAt` | Phase 3 | 単体タイマーの基本構造 |
| `notificationId` | Phase 4 | `NotificationIdGenerator` で createIdle 時に発番、不変 |
| `alarmSound` | Phase 5（予定） | `AlarmSoundCatalog` の ID を保持 |
| `snooze` | Phase 7（予定） | `SnoozeState` ValueObject |

不変条件:
- `duration > Duration.zero`
- `duration <= Duration(hours: 99)`（UI 表示制約）
- `status == running` のとき `endAt != null`
- `status != running` のとき `endAt == null`
- `label.length <= 50`
- `notificationId >= 0 && notificationId <= 0x7FFFFFFF`（Phase 4 以降）

### NotificationIdGenerator（Phase 4 で追加）

ドメイン層に配置（`domain/timer/notification_id_generator.dart`）。
TimerId（String）から OS 通知の int ID を決定的に導出する。

```
class NotificationIdGenerator {
  int idFor(String timerId) => timerId.hashCode & 0x7FFFFFFF;
}
```

理由:

- `flutter_local_notifications` は通知 ID を `int` で要求するが、
  ドメインの `TimerId` は UUID v4 ベースの String。両者を橋渡しする。
- `& 0x7FFFFFFF` で 31bit 正整数に丸め、Android 通知 ID の上限内に収める。
- 決定的なので、再起動後も同じ TimerId に対して同じ通知 ID を再構築できる。
- 同一 TimerId が衝突するのは TimerId 自体が衝突した場合のみ（UUID v4 の確率的一意性に依拠）。

### TimerStatus（enum）

```
enum TimerStatus {
  idle,        // 未開始（作成直後）
  running,     // カウントダウン中
  paused,      // 一時停止中
  ringing,     // アラーム鳴動中
  completed,   // 停止済み（鳴動後の停止）
  cancelled,   // キャンセル済み
}
```

### 残り時間の計算

`running` 状態:

```
remaining = endAt - now
if (remaining <= Duration.zero) → ringing 状態へ遷移
```

`paused` 状態:

```
remaining = pausedRemaining  // pause 時に保存
```

その他の状態:

```
remaining = Duration.zero
```

### SnoozeState（ValueObject）

```
SnoozeState {
  count: int               // スヌーズ実行回数（0 始まり）
  lastSnoozedAt: DateTime?
  totalSnoozeDuration: Duration  // 累積スヌーズ時間
}
```

不変条件:
- `count >= 0`
- `count <= maxSnoozeCount`（デフォルト 5、要件で調整）

### 状態遷移

```
            create()
              │
              ▼
TimerIdle ──start()──▶ TimerRunning ──(時刻到達)──▶ TimerRinging
              ▲             │  ▲                         │
              │             │  │                         │
              │      pause()│  │resume()             stop()
              │             ▼  │                         │
              │         TimerPaused                      │
              │             │                            ▼
              │             │                       TimerCompleted
              │             │                            │
              │             │      snooze(N)             │
              │             │  ◀────────────────────────┘
              │      cancel()│
              └────────────┘
                            ▼
                     TimerCancelled
```

不正な遷移:
- `idle.pause()` → `StateError`
- `completed.start()` → `StateError`（再利用したい場合は新規作成）
- `cancelled.<any>()` → `StateError`

### TimerCollection（集約ルート、Phase 8 で実装済み）

複数タイマーを管理する純値型の集約ルート（Pure Dart）。
`lib/domain/timer/timer_collection.dart`

責務:

- タイマーの追加 / 更新 / 削除 / 取得
- 同時稼働数の制約管理（status 区別なくサイズ上限）
- 全タイマーのスナップショット提供（変更操作はすべて新しい
  `TimerCollection` を返す）

ドメインルール:

- 全エントリ数の上限: **10 本**（`maxSize` 定数）
- 上限超過時は `MaxTimerCountExceededException` を throw
- 未知の id への `update` / `remove` は `TimerNotFoundException`
- `add` で既存 id を渡したら暗黙的に `update` 動作（Notifier の DB 復元
  ループ簡略化のため）

メソッド:

```
TimerCollection {
  TimerCollection.empty()
  TimerCollection.fromList(List<TimerEntity>)

  size: int
  isEmpty: bool
  isFull: bool                       // size >= maxSize
  all: List<TimerEntity>             // unmodifiable view
  runningCount: int                  // status == running の数

  findById(String): TimerEntity?
  add(TimerEntity): TimerCollection      // throws MaxTimerCountExceeded
  update(TimerEntity): TimerCollection   // throws TimerNotFound
  remove(String): TimerCollection        // throws TimerNotFound
}
```

### TimerEntity の永続化マッピング（Phase 8、Drift `Timers` テーブル）

`infrastructure/database/app_database.dart` の `Timers` テーブルおよび
`infrastructure/database/mappers/timer_mapper.dart` で双方向変換する。

| ドメインフィールド | 列名 | 型 | 備考 |
| --- | --- | --- | --- |
| `id` | `id` | `TEXT` (PK) | UUID v4 |
| `notificationId` | `notificationId` | `INTEGER` | 31bit 非負 |
| `label` | `label` | `TEXT` | <= 50 文字 |
| `duration` | `durationMs` | `INTEGER` | ミリ秒 |
| `endAt` | `endAtUtcMs` | `INTEGER?` | UTC epoch ms |
| `pausedRemaining` | `pausedRemainingMs` | `INTEGER?` | ミリ秒 |
| `status` | `status` | `TEXT` | `TimerStatus.name` |
| `soundId` | `soundId` | `TEXT?` | カタログ id |
| `createdAt` | `createdAtUtcMs` | `INTEGER` | UTC epoch ms |

エンコーディング方針:

- `DateTime` は UTC epoch ms に正規化（DST やロケール変更で値が動かない
  ように）
- `Duration` は ms（Drift に専用列なし）
- `TimerStatus` は `name` 文字列（enum 値の追加に対し前方互換）
- 未知の status 文字列は `TimerStatus.cancelled` にフォールバック
  （将来 enum を増やしたとき既存 DB を壊さない）

---

## Preset Aggregate

### Preset

```
Preset {
  id: PresetId
  label: String              // ユーザー指定（必須、空不可）
  duration: Duration
  alarmSound: AlarmSound
  displayOrder: int          // ユーザー定義のソート順
  createdAt: DateTime
}
```

不変条件:
- `label.length >= 1 && label.length <= 50`
- `duration > Duration.zero`
- `duration <= Duration(hours: 99)`
- `displayOrder >= 0`

### ドメインルール

- プリセット最大数: **30 件**（UI が破綻しない範囲）
- 同一 label のプリセットは作成可能（重複制約なし）

---

## Alarm Aggregate（Phase 9.5 予定）

「指定時刻に鳴らす目覚まし系アラーム」を表す。Timer Aggregate とは別 Aggregate。
分離理由は `docs/adr/0005-alarm-vs-timer-separation.md` 参照。

### AlarmEntity

```
AlarmEntity {
  id: AlarmId
  notificationId: int                  // NotificationIdGenerator 経由（Timer と共通実装）
  label: String                        // 空可、空時はデフォルト名表示
  targetTime: TimeOfDay                // 時:分（秒は持たない）
  repeat: AlarmRepeat                  // once or weekly(Set<DayOfWeek>)
  soundId: String?                     // null なら AlarmSoundCatalog.defaultSound
  snoozeMinutes: int                   // 5 / 10 / 15 のいずれか
  enabled: bool                        // ON/OFF トグル
  createdAt: DateTime
}
```

不変条件:

- `label.length <= 50`
- `snoozeMinutes ∈ {5, 10, 15}`
- `notificationId >= 0 && notificationId <= 0x7FFFFFFF`
- `repeat == AlarmRepeat.weekly` のとき、`days` は 1 件以上 7 件以下

### AlarmRepeat（sealed ValueObject）

```
sealed class AlarmRepeat
├── AlarmRepeatOnce                   // 単発（次の TargetTime 1 回のみ）
└── AlarmRepeatWeekly                 // 曜日指定の繰り返し
    └── days: Set<DayOfWeek>          // monday..sunday
```

`DayOfWeek` は domain/alarm/day_of_week.dart で定義（Pure Dart enum、`DateTime.weekday` と互換マッピング）。

### AlarmService

`Clock` を注入されたドメインサービス。副作用なし。

```
AlarmService {
  /// 次回発火する絶対時刻を計算する。
  /// - once: 今日の targetTime が未来なら今日、過ぎていれば明日
  /// - weekly: now 以降で、曜日が days に含まれる最も近い日 + targetTime
  DateTime nextFireAt(AlarmEntity alarm);

  /// 鳴動 → 停止後の状態更新。
  /// - once → enabled = false
  /// - weekly → enabled は維持（次回 nextFireAt で次の曜日へ自動進行）
  AlarmEntity advanceAfterFire(AlarmEntity alarm);

  /// スヌーズボタン押下時の再鳴動絶対時刻。now + snoozeMinutes。
  DateTime snoozeUntil(AlarmEntity alarm);
}
```

### 状態モデル

Alarm は Timer と違い「永続的な ON/OFF」が中心で、揮発状態（ringing/snoozing）は AlarmRingingNotifier が一時的に管理する。

```
AlarmEntity.enabled = true
   │ targetTime 到達
   ▼
[OS 通知発火 + AlarmRingingScreen 表示]
   │
   ├─ 停止 → AlarmService.advanceAfterFire
   │           ├─ once   → enabled = false （永続化）
   │           └─ weekly → enabled = true、次回 nextFireAt を schedule（永続化）
   │
   └─ スヌーズ → AlarmService.snoozeUntil
                  → NotificationScheduler.schedule（既存 notificationId で再予約）
```

### Alarm 集約ルール

- アラーム最大数: **50 件**（UI が破綻しない範囲）
- 同一 targetTime / repeat のアラーム重複は許容（ユーザー判断）
- weekly アラームの `days` が空集合になる遷移は許可しない（バリデーションで弾く）

---

## Clock Aggregate（Phase 10.5 で実装済み）

「世界時計」機能のドメイン。1 画面で最大 6 都市の現在時刻を見渡す用途。
タイマー / アラームとは独立したタブとして提供される。

### ClockLocation

```
ClockLocation {
  id: ClockLocationId           // UUID
  displayName: String           // 例: "東京", "Los Angeles"
  timezoneId: String            // IANA TZ ID, 例: "Asia/Tokyo", "America/Los_Angeles"
  isCurrentLocation: bool       // 初回起動時の GPS 由来なら true、ユーザー追加なら false
  displayOrder: int             // 1〜6（並び順）
  createdAt: DateTime
}
```

不変条件:

- `displayName.length >= 1 && displayName.length <= 30`
- `timezoneId` は IANA Time Zone Database に存在する ID（`tz.getLocation(id)` で解決可能）
- `displayOrder >= 0 && displayOrder <= 5`
- `isCurrentLocation = true` のエントリは ClockCollection 全体で 0 件 or 1 件

### ClockCollection（集約ルート）

複数の世界時計を管理する集約。

責務:

- ClockLocation の追加 / 削除 / 並べ替え
- 上限制約の検証
- 現在地エントリの一意性保証

ドメインルール:

- 同時表示の上限: **6 件**（UI が破綻しない範囲）
- 上限超過時は `MaxClockLocationCountExceededException` を throw
- 同一 `timezoneId` のエントリ重複は許容（ユーザー判断、表示名は別にできる）

メソッド:

```
ClockCollection {
  add(ClockLocation)
  remove(ClockLocationId)
  reorder(int oldIndex, int newIndex)
  get(ClockLocationId): ClockLocation?
  count(): int
  currentLocation(): ClockLocation?  // isCurrentLocation = true のものを返す
}
```

### ClockTime（ValueObject）

ある絶対時刻を特定タイムゾーンの壁時計時刻に変換する純粋計算。

```
ClockTime {
  static DateTime computeAt(DateTime now, String timezoneId)
}
```

実装は `tz.TZDateTime.from(now, tz.getLocation(timezoneId))` ベース。
副作用なし、`Clock` 注入不要（now を引数で受ける純関数）。

不正な timezoneId は `InvalidTimezoneIdException` を throw（`tz.getLocation` の `LocationNotFoundException` をラップ）。

### Presentation 層からの参照（Phase 10.5）

- `ClockScreen` (`lib/presentation/screens/clock_screen.dart`):
  `clockCollectionNotifierProvider.select((c) => c.locations)` と
  `currentTimeStreamProvider` を watch、3 デザイン widget
  (`ClockDesignA/B/C`) に `locations` / `now` を props 注入する。
- `ClockEntryEditScreen` (`lib/presentation/screens/clock_entry_edit_screen.dart`):
  `TimezoneCatalog.presets` から都市を add、`ClockCollectionNotifier`
  経由で `ClockCollection` 集約に対する mutation
  (add / remove / reorder) を行う。

---

## Shared ValueObjects

### AlarmSound

```
AlarmSound {
  id: String              // 音源カタログ上の一意 ID
  displayName: String     // UI 表示名
  assetPath: String       // assets/sounds/xxx.mp3
}
```

具体的な音源は `AlarmSoundCatalog`（domain/timer/alarm_sound_catalog.dart）に列挙。
詳細は `docs/assets-spec.md` 参照。

### TimerId / PresetId / NotificationId

型安全のため、`String` / `int` の単純な extension type または専用クラスで包む。

```
extension type TimerId(String value) {
  factory TimerId.generate() => TimerId(Uuid().v4());
}

extension type PresetId(String value) {
  factory PresetId.generate() => PresetId(Uuid().v4());
}

extension type AlarmId(String value) {
  factory AlarmId.generate() => AlarmId(Uuid().v4());
}

extension type ClockLocationId(String value) {
  factory ClockLocationId.generate() => ClockLocationId(Uuid().v4());
}

extension type NotificationId(int value) {
  // 32bit int の範囲、生成は NotificationIdGenerator 経由
}
```

### Duration の扱い

- Dart 標準の `Duration` を使用
- 表示フォーマットは `DurationFormatter`（domain/shared/）で統一
- 形式: `HH:MM:SS` / `MM:SS.ss`（ストップウォッチ用、100ms 単位）

---

## ドメインサービスの責務

### StopwatchService

- 状態遷移ロジック（start / pause / resume / lap / reset）
- `Clock` を注入され、現在時刻を取得
- 副作用なし（永続化や通知は呼ばない）

### TimerService

- 単一タイマーの状態遷移ロジック
- `Clock` を注入され、endAt 計算と残り時間判定
- 副作用なし

### TimerCollection

- 複数タイマーの集約管理
- 上限制約の検証
- スナップショット生成

### SnoozeCalculator

- スヌーズ時の新 endAt 計算
- スヌーズ可能性判定（上限到達チェック）

### AlarmService

- 指定時刻アラームの次回発火時刻計算（once / weekly）
- 鳴動後の次回状態への遷移
- スヌーズ時の再発火時刻計算
- `Clock` を注入され、副作用なし

### ClockTime

- 絶対時刻 (DateTime) → 特定 IANA TZ の壁時計時刻への変換
- `Clock` 注入不要（now を引数で受ける純関数）
- `tz.TZDateTime.from` ベース、副作用なし

### DurationFormatter

- `Duration` → `String` の変換
- フォーマットバリエーション:
  - `formatHms(Duration)`: `HH:MM:SS`
  - `formatMsCs(Duration)`: `MM:SS.cc`（ストップウォッチ向け、cs = centisecond）
  - `formatRemaining(Duration)`: タイマー残り時間表示

---

## 例外定義

ドメイン層で定義する専用例外:

| 例外クラス | 発生状況 |
|---|---|
| `InvalidTimerStateException` | 不正な状態遷移を試みた |
| `TimerNotFoundException` | 指定 ID のタイマーが存在しない |
| `MaxTimerCountExceededException` | 同時稼働上限を超過 |
| `MaxSnoozeCountExceededException` | スヌーズ上限を超過 |
| `InvalidDurationException` | duration が制約違反 |
| `InvalidLabelException` | label が制約違反 |
| `AlarmNotFoundException` | 指定 ID のアラームが存在しない（Phase 9.5） |
| `MaxAlarmCountExceededException` | アラーム最大数（50）を超過（Phase 9.5） |
| `InvalidAlarmRepeatException` | weekly の `days` が空集合等の制約違反（Phase 9.5） |
| `InvalidSnoozeMinutesException` | `snoozeMinutes` が許可値（5/10/15）外（Phase 9.5） |
| `MaxClockLocationCountExceededException` | 世界時計の同時表示上限（6）を超過（Phase 10.5 で実装済み） |
| `ClockLocationNotFoundException` | 指定 ID の世界時計エントリが存在しない（Phase 10.5 で実装済み） |
| `InvalidTimezoneIdException` | `timezoneId` が IANA TZ DB に存在しない（Phase 10.5 で実装済み） |

すべて `domain/<aggregate>/exceptions.dart` に集約。

---

## 不変条件の実装方針

- Entity / ValueObject のコンストラクタで検証
- `factory` コンストラクタでバリデーション、違反時は専用例外 throw
- `freezed` 使用時も `assert` だけでなく明示的な例外 throw を併用

例:

```
factory TimerEntity.create({
  required Duration duration,
  required String label,
  ...
}) {
  if (duration <= Duration.zero) {
    throw InvalidDurationException('duration must be positive');
  }
  if (label.length > 50) {
    throw InvalidLabelException('label too long');
  }
  ...
}
```

---

## 永続化との対応

ドメイン Entity と Drift スキーマのマッピング:

| Drift Table | Domain Entity |
|---|---|
| `timers` | `TimerEntity` |
| `presets` | `Preset` |
| `alarms` | `AlarmEntity`（Phase 9.5 で追加予定） |
| `clock_locations` | `ClockLocation`（Phase 10.5 で実装済み） |

Mapper クラスを `infrastructure/database/mappers/` に配置。
ドメイン層は永続化形式を知らない。

---

## 関連ドキュメント

- `docs/architecture.md`: レイヤー構造
- `docs/state-management.md`: ドメインを Riverpod でどう公開するか
- `docs/testing-strategy.md`: ドメインのテスト方針

---

最終更新日: 2026-05-01（Phase 8 完了反映: TimerCollection を実装済みに更新 + TimerEntity の Drift 永続化マッピングを追加）
