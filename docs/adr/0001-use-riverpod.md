# ADR 0001: 状態管理に Riverpod を採用する

- 状態: Accepted
- 日付: 2026-04-29
- 関連: `docs/state-management.md`

---

## Context（背景・制約）

本プロジェクトは Flutter で実装するストップウォッチ + タイマーアプリ。以下の要件がある:

- **複数タイマーの同時稼働** — 集約状態と個別状態の両方を扱う必要
- **テスト自動化重視** — Notifier 層を含めて高いテストカバレッジを目指す
- **時間制御を伴うロジック** — `Clock` 注入や `fake_async` でのテストが書きやすい状態管理が望ましい
- **Auto 運用前提** — Claude Code が定型コードを生成しやすい構造である必要
- **アプリライフサイクル監視** — paused / resumed で状態を再計算する必要

開発者は C/C++/C# 5 年以上の経験を持ち、アーキテクチャ的な明快さと Separation of Concerns を重視する。

---

## Decision（決定事項）

状態管理ライブラリとして **Riverpod**（`flutter_riverpod` + `riverpod_annotation` + `riverpod_generator`）を採用する。

### 採用構成

- `flutter_riverpod` ^2.5.x
- `riverpod_annotation` ^2.3.x
- `riverpod_generator`（dev、コード生成）
- `riverpod_lint`（dev、規約違反検出）
- `custom_lint`（dev、riverpod_lint の動作基盤）

### 主要パターン

- 状態を持たない依存提供は `@riverpod` 関数形式
- 状態遷移を持つロジックは `@riverpod` クラス形式（Notifier）
- 引数で分岐する場合は family
- インフラ系は `keepAlive: true`、画面固有は autoDispose

詳細は `docs/state-management.md` 参照。

---

## Consequences（結果・トレードオフ）

### 利点

- **テスト容易性**: `ProviderContainer` で完全に隔離されたテストが可能。override で依存を差し替え、`Clock` や `NotificationScheduler` の Fake 注入が容易
- **コード生成による定型化**: `@riverpod` アノテーションでボイラープレートが減り、Claude Code が安定した形式でコードを生成できる
- **依存追跡の自動化**: `ref.watch` による依存関係が明示的、リアクティブな再計算が自動
- **family による複数インスタンス対応**: `timerNotifierProvider(TimerId)` で複数タイマーを自然に扱える
- **AsyncValue**: 非同期状態（DB 読み込み等）を扱いやすい
- **エコシステム**: 現在の Flutter コミュニティでデファクト、情報量が豊富
- **lint サポート**: `riverpod_lint` が規約違反を検出してくれる（Auto 運用で重要）

### 欠点・トレードオフ

- **学習コスト**: provider / family / autoDispose / keepAlive の使い分けに慣れが必要
- **コード生成の依存**: `build_runner` を CI / 開発時に走らせる必要
- **Provider の粒度判断**: 細かく分割するか集約するかの判断が設計者に委ねられる（→ `state-management.md` でルール化）
- **BuildContext 依存の処理**: SnackBar 表示や Navigator 操作は Widget 側のリスナで対応する必要

### 緩和策

- 学習コスト → `docs/state-management.md` で具体例を列挙、Auto 運用時の参照文書とする
- コード生成 → CI で `dart run build_runner build` を必ず実行、`*.g.dart` を gitignore して常に最新化
- 粒度判断 → `state-management.md` で Provider 一覧を表形式で管理、新規追加時に必ず追記

---

## Alternatives Considered（検討した代替案）

### Bloc（flutter_bloc）

- 利点: Event / State の分離が明示的、`bloc_test` が強力
- 欠点: ボイラープレート多い、Event クラスの定義が冗長、ストップウォッチ規模では過剰
- 却下理由: 本プロジェクトの規模では Riverpod の方が記述量が少なく済む。テスト容易性は同等

### Provider（旧来の provider パッケージ）

- 利点: シンプル、学習コスト低
- 欠点: family 相当の機能が弱い、複数タイマー管理に向かない、コミュニティが Riverpod に移行中
- 却下理由: family の不在が複数タイマー要件と合わない、将来性も Riverpod に劣る

### GetX

- 利点: 多機能（Routing / DI / 状態管理 / 国際化等を一括提供）
- 欠点: 規約が独特で他のライブラリと衝突しやすい、テスト容易性に難あり、コミュニティで賛否両論
- 却下理由: アーキテクチャ的明快さを重視する本プロジェクトと方向性が合わない

### 自前 ChangeNotifier + InheritedWidget

- 利点: 外部ライブラリ依存ゼロ
- 欠点: family 相当を自作する必要、テストヘルパも自作、Auto 運用に必要な定型がない
- 却下理由: Auto 運用前提で「ライブラリの規約に乗る」ことの価値が大きい

### Signals (signals.dart)

- 利点: 細粒度のリアクティビティ、最近注目されている
- 欠点: Flutter コミュニティでまだ少数派、テストパターンや事例が少ない
- 却下理由: Auto 運用での参考事例の豊富さで Riverpod に劣る

---

## 関連ドキュメント

- `docs/state-management.md`: Provider 設計の詳細
- `docs/testing-strategy.md`: Provider のテスト方法
- `docs/architecture.md`: Application 層の位置づけ
