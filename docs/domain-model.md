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
│  Shared ValueObjects                            │
│  ・AlarmSound                                   │
│  ・TimerId / PresetId / NotificationId          │
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
  id: TimerId                        // UUID v4
  notificationId: NotificationId     // OS 通知用 int ID
  label: String                      // ユーザー指定（空可、空時は表示時にデフォルト名）
  duration: Duration                 // 設定された時間
  endAt: DateTime?                   // 絶対時刻（running 時のみ非 null）
  status: TimerStatus
  alarmSound: AlarmSound             // 鳴動時の音源
  snooze: SnoozeState                // スヌーズ履歴
  createdAt: DateTime
}
```

不変条件:
- `duration > Duration.zero`
- `duration <= Duration(hours: 99)`（UI 表示制約）
- `status == running` のとき `endAt != null`
- `status != running` のとき `endAt == null`
- `label.length <= 50`

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

### TimerCollection（集約ルート）

複数タイマーを管理する集約。

責務:
- タイマーの追加 / 削除 / 取得
- 同時稼働数の制約管理
- 全タイマーの状態スナップショット提供

ドメインルール:
- 同時稼働（`running` + `paused` + `ringing`）の上限: **10 本**
- 上限超過時は `MaxTimerCountExceededException` を throw
- `completed` / `cancelled` はカウント外

メソッド:

```
TimerCollection {
  add(TimerEntity)
  remove(TimerId)
  get(TimerId): TimerEntity?
  activeCount(): int             // running + paused + ringing
  ringingTimers(): List<TimerEntity>
  snapshotAt(DateTime now): List<TimerSnapshot>  // 残り時間を含む表示用
}
```

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

Mapper クラスを `infrastructure/database/mappers/` に配置。
ドメイン層は永続化形式を知らない。

---

## 関連ドキュメント

- `docs/architecture.md`: レイヤー構造
- `docs/state-management.md`: ドメインを Riverpod でどう公開するか
- `docs/testing-strategy.md`: ドメインのテスト方針

---

最終更新日: 2026-04-29
