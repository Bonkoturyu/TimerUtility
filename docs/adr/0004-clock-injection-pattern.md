# ADR 0004: 時刻取得は Clock 抽象を経由する

- 状態: Accepted
- 日付: 2026-04-29
- 関連: `docs/architecture.md`, `docs/testing-strategy.md`, `docs/state-management.md`

---

## Context（背景・制約）

本プロジェクトは時刻に強く依存するアプリ:

- ストップウォッチの経過時間計算
- タイマーの終了時刻 / 残り時間計算
- アプリ復帰時の状態再計算
- スヌーズ時の新時刻計算
- Lap 記録の時刻保存

これらすべてで `DateTime.now()` 相当の現在時刻取得が必要となる。

加えて以下の要件・嗜好がある:

- **テスト自動化重視** — 時刻に依存するロジックを 100% 自動テスト可能にしたい
- **実時間 sleep を禁止** — テストで `Future.delayed(Duration(seconds: 5))` のような実時間待機をしない
- **fake_async との併用** — `Timer.periodic` 等を含むコードのテストで仮想時間を使う

`DateTime.now()` を直接呼ぶコードは:
- テスト時に時刻を制御できない（テストごとに毎回 1ms 違う値が返る）
- 「N 秒後」を再現するのに実時間 sleep が必要になる
- 結果としてテストが遅く / flaky になる

---

## Decision（決定事項）

すべての時刻取得を **`Clock` 抽象**経由で行う。

### 採用ライブラリ

- `package:clock`（Dart Team 公式メンテ）

### 主要パターン

#### 1. ドメイン層: コンストラクタ注入

```
class StopwatchService {
  final Clock _clock;
  StopwatchService({required Clock clock}) : _clock = clock;

  StopwatchRunning start() {
    return StopwatchRunning(startedAt: _clock.now(), ...);
  }
}
```

#### 2. Application 層: Riverpod 経由で注入

```
@Riverpod(keepAlive: true)
Clock clock(ClockRef ref) => const Clock();

@Riverpod(keepAlive: true)
StopwatchService stopwatchService(StopwatchServiceRef ref) {
  return StopwatchService(clock: ref.watch(clockProvider));
}
```

#### 3. テスト時: `withClock` または override

```
// Domain Unit Test
test('start から 5 秒後の elapsed が 5 秒', () {
  final fixed = DateTime(2026, 1, 1, 12, 0, 0);
  withClock(Clock.fixed(fixed), () {
    final service = StopwatchService(clock: clock);
    final running = service.start();
    withClock(Clock.fixed(fixed.add(Duration(seconds: 5))), () {
      expect(service.elapsed(running), Duration(seconds: 5));
    });
  });
});

// Notifier Test
final container = ProviderContainer(overrides: [
  clockProvider.overrideWithValue(Clock.fixed(DateTime(2026, 1, 1))),
]);
```

### 禁止事項（CLAUDE.md にも明記）

- ❌ `DateTime.now()` の直接呼び出し（必ず `clock.now()` 経由）
- ❌ `Stopwatch`（dart:core）の直接利用
- ❌ `Clock` を介さない時刻計算

---

## Consequences（結果・トレードオフ）

### 利点

- **完全な時刻制御**: テストで「2026 年 1 月 1 日 12 時 0 分」を再現可能
- **高速なテスト**: 実時間待機不要、すべてのテストが秒単位で完了
- **flaky テストの撲滅**: 時刻のブレによる稀な失敗が起きない
- **fake_async との相性**: `fake_async` で仮想時間を使うとき、`Clock` も自動的に追従
- **一元化**: 時刻取得が 1 箇所に集約され、将来「サーバー時刻と同期」等の拡張も容易
- **lint で違反検出可能**: `analysis_options.yaml` で `DateTime.now()` 直接利用を警告化できる

### 欠点・トレードオフ

- **コード量がわずかに増える**: コンストラクタに `Clock` 引数が増える
- **規約の徹底が必要**: 規約違反コードが書かれると意味がない（→ lint と CLAUDE.md で防止）
- **学習コスト**: package:clock の `withClock()` パターンに慣れが必要

### 緩和策

- コード量増 → Riverpod の Provider 化により、Notifier 等での記述は最小限
- 規約徹底 → CLAUDE.md の絶対遵守事項に明記、custom_lint で機械検出
- 学習コスト → `docs/testing-strategy.md` にサンプルコード掲載

---

## Alternatives Considered（検討した代替案）

### `DateTime.now()` 直接利用 + テスト時のみ抽象化

- 利点: コード量が最小
- 欠点: 抽象化されている箇所と直接呼び出しが混在、規約違反が起きやすい
- 却下理由: Auto 運用で Claude Code が無自覚に `DateTime.now()` を書く可能性。一貫性が崩れる

### 自前の `TimeProvider` インターフェース

- 利点: 外部依存ゼロ
- 欠点: `package:clock` のエコシステム（`Clock.fixed`、`withClock` 等）を再発明する必要
- 却下理由: 車輪の再発明、`package:clock` は Dart Team 公式メンテで信頼できる

### `Stopwatch`（dart:core）の利用

- 利点: 経過時間の計測に特化、シンプル
- 欠点:
  - 内部状態を持つため immutable な状態管理と相性が悪い
  - テスト時に「5 秒経過した状態」を作り出すのが困難
  - 端末スリープ中の挙動が `monotonic clock` の実装に依存
- 却下理由: 本プロジェクトは「絶対時刻を保存して差分計算」方式（端末スリープ中も正確）。`Stopwatch` の monotonic 性質は不要、むしろ阻害になる

### `Clockwork` / `time_machine` 等の他ライブラリ

- 利点: より高機能（タイムゾーン処理等）
- 欠点: 過剰な機能、`package:clock` で十分
- 却下理由: シンプルさを重視、必要な機能は `package:clock` で完結

---

## 関連する設計上の選択

### 絶対時刻ベースの状態保持

`Clock` 注入とセットで、**経過時間の管理は絶対時刻（DateTime）で行う**方針を採る:

- ストップウォッチの開始時刻 (`startedAt: DateTime`)
- タイマーの終了時刻 (`endAt: DateTime`)
- Lap の記録時刻 (`recordedAt: DateTime`)

理由:
- 端末スリープ中もシステム時計は止まらないため、絶対時刻ベースなら正確
- `Stopwatch` のような monotonic clock は実装依存で挙動が変わる
- DB に保存して再起動後に復元するときも、絶対時刻なら扱いやすい

### 表示更新と状態管理の分離

- ドメイン状態は離散イベント（start, pause, ringing 化）でしか変わらない
- UI 表示は `Stream.periodic` で 100ms ごとに `clock.now()` から計算
- これにより、ドメイン状態のテストは時刻スナップショット 1 点で完結する

---

## 関連ドキュメント

- `docs/architecture.md`: ドメイン層の制約
- `docs/state-management.md`: clockProvider の定義
- `docs/testing-strategy.md`: withClock / fake_async の使用例
- `docs/domain-model.md`: 絶対時刻ベースの状態設計
