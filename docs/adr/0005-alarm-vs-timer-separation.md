# ADR 0005: 指定時刻アラームを Timer Aggregate と分離する

- 状態: Accepted
- 日付: 2026-05-01
- 関連: `docs/domain-model.md`, `docs/state-management.md`, `BACKLOG.md` (Phase 9.5)

---

## Context（背景・制約）

Phase 9.5 として「指定時刻アラーム機能（曜日繰り返し + スヌーズ）」を追加する。
要件:

- 「毎週月〜金の 7:30 に鳴らす」「明日 6:00 に 1 回だけ鳴らす」のような目覚まし用途
- ON/OFF トグルで予約 / キャンセル
- スヌーズ（5/10/15 分後に再鳴動）
- 端末再起動後も予約が復元される（Phase 10 と連携）

ここで設計上の選択肢が 2 つある:

1. **既存 `TimerEntity` を拡張** して「指定時刻起動モード」を追加
2. **新規 `AlarmEntity` を別 Aggregate として定義** し、Timer と分離

両者は「指定時刻に通知を発火する」という点で似ているが、概念モデル・状態モデル・操作モデルが大きく異なる。

---

## Decision（決定事項）

**新規 `Alarm Aggregate` を `Timer Aggregate` と分離して実装する**。

`lib/domain/alarm/` を新設し、以下を配置:

```
lib/domain/
├── timer/         (既存)
│   ├── timer_entity.dart
│   ├── timer_service.dart
│   └── ...
└── alarm/         (Phase 9.5 新設)
    ├── alarm_entity.dart
    ├── alarm_repeat.dart
    ├── alarm_service.dart
    └── exceptions.dart
```

Repository / Notifier / Screen / Drift テーブルもすべて分離する。

ただし以下は **共有 / 流用** する:

- `domain/timer/notification_id_generator.dart`（OS 通知 ID 生成ロジック）
- `domain/timer/alarm_sound.dart`、`alarm_sound_catalog.dart`（音源定義）
- `domain/ports/notification_scheduler.dart`、`alarm_sound_player.dart`（OS 連携 Port）
- `application/alarm_ringing_notifier.dart` および `presentation/screens/alarm_ringing_screen.dart`
  （鳴動 UI は Timer / Alarm 両用化、起動元は payload prefix `timer:` / `alarm:` で識別）

---

## Consequences（結果・トレードオフ）

### 利点

- **概念モデルの違いをそのまま型に反映できる**:
  - Timer は「相対時間 (Duration) を測るもの」、Alarm は「絶対時刻 (TimeOfDay + 曜日) に鳴るもの」
  - Timer の `endAt: DateTime?` と Alarm の `targetTime: TimeOfDay` は意味が違う
  - 混在させると `if (alarm.targetTime != null) ... else if (timer.duration != null) ...` の分岐地獄になる
- **状態遷移が独立する**:
  - Timer: `idle → running → paused → ringing → completed/cancelled`（単発、揮発状態あり）
  - Alarm: `enabled ⇄ disabled` + 鳴動時の一時的な ringing/snoozing（永続状態が中心）
  - 同じ enum や状態機械に押し込めない
- **永続化スキーマが自然**:
  - Drift で `timers` テーブルと `alarms` テーブルを分離、Mapper も別
  - `repeat: AlarmRepeat` / `enabled: bool` のような Alarm 固有列を Timer 側に持ち込まない
- **テストが書きやすい**:
  - `AlarmService.nextFireAt` のような曜日ロジックを Timer と分離してテスト可能
- **将来の機能拡張が独立する**:
  - 例: アラーム固有の「徐々に音量を上げる」機能を Alarm 側だけに足せる
  - Timer 固有の「複数同時稼働」上限を Alarm に波及させない

### 欠点・トレードオフ

- **コード量が増える**: Entity / Service / Repository / Notifier / Screen を 1 セット追加
- **共有部分の重複可能性**: 「指定時刻 → OS 通知予約」のフロー自体は似ているため、薄い共通化を検討する余地あり
  - 緩和策: 共通化は `NotificationScheduler` Port のレベルで完結している。Service レベルの共通基底クラスは作らない（YAGNI）
- **AlarmRingingScreen の payload 識別ロジックが必要**:
  - 通知タップ時の payload を `timer:<id>` / `alarm:<id>` でプレフィックス分離
  - main.dart の `onDidReceiveNotificationResponse` に分岐追加
  - 緩和策: prefix 規約は単純で、Notifier 起点なので分岐は 1 箇所

### 制約として受け入れる点

- **「Timer も Alarm も同じ抽象で扱いたい」という未来要件は出ない前提**
  - 出た場合は `RingingTrigger` のようなインターフェース層を後付けで導入可能
  - 現時点では分離のメリットが圧倒的に大きい

---

## Alternatives Considered（検討した代替案）

### A. TimerEntity を拡張して「指定時刻起動モード」を追加

```
TimerEntity {
  ...
  startMode: StartMode           // immediate | scheduledAt(DateTime) | weekly(...)
  repeat: AlarmRepeat?
  enabled: bool                  // Alarm 用、Timer 時は常に true
  ...
}
```

- 利点: クラス数が増えない、通知予約ロジックを共有できる
- 欠点:
  - `enabled` は Alarm 用、`pausedRemaining` は Timer 用、と nullable フィールドが乱立
  - `TimerStatus` enum に `disabled` を足すか、別 enum で `Alarm.enabled` を持つか曖昧
  - 「単発タイマー」と「曜日繰り返しアラーム」を 1 つの `TimerCollection` で管理するのは集約境界が広すぎる
  - Drift の `timers` テーブルが「タイマー兼アラーム」になり、列の意味が不明瞭
- 却下理由: 概念の異なる 2 つを 1 つの Entity に押し込めると、すべての操作で「これは Timer か Alarm か」の分岐が必要になる。型安全が失われる

### B. 完全に共通の `Schedulable` 基底 Entity を導入

- 利点: 通知予約ロジックを 1 箇所に集約
- 欠点: 抽象化のコストが先に発生、現状 Timer / Alarm の 2 種類しかないので過剰
- 却下理由: YAGNI。3 つ目の概念（例: カウントアップ通知 等）が出てきた段階で再検討

### C. Alarm を Phase 11（仕上げ）で対応する

- 利点: コア機能を先に固められる
- 欠点: Drift / BootReceiver と密結合のため、Phase 8 / Phase 10 完了直後がもっとも自然
- 却下理由: Phase 11 まで遅らせる技術的理由がない。Phase 9 と Phase 10 の間（9.5）が依存関係的に最適

---

## 鳴動 UI の共通化方針

`AlarmRingingScreen` と `AlarmRingingNotifier` は Timer / Alarm 両用化する:

- `AlarmRingingState` の `currentTimerId` を `String currentSourceId` にリネームしない（ADR 後方互換のため）
  → 代わりに payload prefix で起動元を識別し、Notifier 内部で分岐
- 通知 payload 規約:
  - Timer 由来: `timer:<TimerId>`
  - Alarm 由来: `alarm:<AlarmId>`
- `main.dart` の `onDidReceiveNotificationResponse` で prefix を見て:
  - `timer:` → 既存ルート（TimerNotifier 経由）
  - `alarm:` → AlarmCollectionNotifier の鳴動ハンドラを起動

「停止」「スヌーズ」ボタンの挙動も payload prefix で分岐:

- Timer: 既存通り `TimerNotifier.cancel` → `completed`
- Alarm: `AlarmService.advanceAfterFire` で次回曜日へ進める or once は `enabled: false` 化 + 永続化 + 次回 schedule

---

## 関連ドキュメント

- `docs/domain-model.md`: Alarm Aggregate 定義（Phase 9.5 で追記）
- `docs/state-management.md`: `alarmCollectionNotifierProvider` 等（Phase 9.5 で追記）
- `docs/adr/0003-fullscreen-intent-strategy.md`: AlarmManager + フルスクリーン Intent 方式（Alarm でもそのまま流用）
- `BACKLOG.md`: Phase 9.5 タスク一覧
