# ADR 0002: 永続化に Drift を採用する

- 状態: Accepted
- 日付: 2026-04-29
- 関連: `docs/architecture.md`, `docs/domain-model.md`

---

## Context（背景・制約）

本プロジェクトは以下の永続化ニーズを持つ:

- **複数 TimerEntity の保存** — 同時稼働 10 本まで、状態 / 終了時刻 / ラベル等を保存
- **Preset の保存** — 最大 30 件、表示順あり
- **端末再起動後の復元** — `BOOT_COMPLETED` 後に全タイマーを読み出して再予約
- **クエリ要件** — status による絞り込み、displayOrder ソート
- **トランザクション** — 複数タイマーの一括更新

加えて以下の制約・嗜好がある:

- **テスト自動化重視** — DB 層も in-memory でユニットテスト可能であることが必須
- **型安全** — C# の Entity Framework のような型安全クエリビルダを好む
- **ドメイン層との分離** — ドメイン Entity とテーブル定義を分離可能

---

## Decision（決定事項）

永続化ライブラリとして **Drift** を採用する。

### 採用構成

- `drift` ^2.x
- `drift_flutter` ^x.x（Flutter 環境向けの sqlite 接続ヘルパ）
- `drift_dev`（dev、コード生成）
- `sqlite3_flutter_libs`（ネイティブ sqlite バンドル、必要に応じて）

### 主要パターン

- テーブル定義は Dart クラスで宣言（`@DriftDatabase` アノテーション）
- ドメイン Entity と DB レコードは Mapper で変換、両者を分離
- テスト時は `NativeDatabase.memory()` で in-memory DB を使用
- Repository は `domain/ports/` に抽象、`infrastructure/database/` に実装

詳細は `docs/architecture.md` のディレクトリ構造、`docs/domain-model.md` の永続化マッピング参照。

---

## Consequences（結果・トレードオフ）

### 利点

- **型安全クエリ**: SELECT / WHERE / ORDER BY が型チェック済みのコードで書ける。タイポやスキーマ変更時のミスを compile time に検出
- **in-memory テスト**: `NativeDatabase.memory()` で完全自動テスト可能。Repository の振る舞いを高速に検証
- **マイグレーション**: スキーマ変更時のマイグレーション機構が標準提供
- **トランザクション**: `db.transaction()` で複数操作の atomic 化が容易
- **コード生成**: `*.g.dart` の自動生成でボイラープレート削減
- **ストリーム**: クエリ結果を `Stream` で監視可能（リアクティブな UI 更新）
- **アクティブメンテナンス**: 開発が継続的、Flutter コミュニティで広く使用されている
- **C# / EF Core 経験者に親和的**: クエリビルダの感覚が似ている

### 欠点・トレードオフ

- **コード生成の依存**: `build_runner` を CI / 開発時に走らせる必要（Riverpod と同じ）
- **生成コードの量**: テーブル数に応じて `*.g.dart` が肥大化
- **ドメイン Entity との二重管理**: テーブル定義と Entity を別管理、Mapper が必要
- **学習コスト**: Drift 独自 DSL（Companion 等）の理解が必要

### 緩和策

- 二重管理 → Mapper クラスを `infrastructure/database/mappers/` に集約、規約化
- 学習コスト → `docs/architecture.md` でディレクトリ構造を確定、定型を Auto 運用で生成可能に

---

## Alternatives Considered（検討した代替案）

### sqflite（生 SQL）

- 利点: 軽量、依存少
- 欠点: 型安全でない、SQL 文字列のタイポリスク、マイグレーション機構が貧弱
- 却下理由: テスト容易性と型安全性で Drift に劣る。複数テーブル + マイグレーションを考えると Drift の優位性が大きい

### Hive

- 利点: 高速、シンプル、NoSQL 風
- 欠点: 複雑なクエリに弱い（filter は全件走査）、メンテナンス状況に懸念がある時期があった
- 却下理由: 複数タイマーを status で絞り込む等のクエリ要件に対し、SQL ベースの Drift の方が適切

### Isar

- 利点: 高速、型安全、リアクティブクエリ
- 欠点: 開発が停滞気味（v3 以降の動きが鈍い）、コミュニティの懸念が高まっている
- 却下理由: 長期運用を考えると不安。現時点の安定性で Drift の方が信頼できる

### ObjectBox

- 利点: 高速、リアクティブ
- 欠点: 商用ライセンスとの境界が複雑、コミュニティが小さめ
- 却下理由: ライセンスの将来不透明性、Flutter コミュニティでのデファクト性が低い

### SharedPreferences

- 利点: 最もシンプル、Flutter 標準
- 欠点: key-value のみ、複数レコード管理に不向き、JSON シリアライズで対処は可能だがクエリ不可
- 却下理由: 複数タイマー + プリセットの管理にはデータ構造として不適切。プリセット **だけ** なら使えるが、タイマーで Drift が必要なら統一した方が良い

### Floor

- 利点: Room（Android）に近い API、アノテーションベース
- 欠点: 開発が停滞気味、Drift より機能が少ない
- 却下理由: Drift の上位互換に近く、選ぶ理由がない

---

## 関連ドキュメント

- `docs/architecture.md`: Repository の配置と依存方向
- `docs/domain-model.md`: Entity と DB スキーマのマッピング
- `docs/testing-strategy.md`: in-memory DB でのテスト方法

---

## Phase 8 Implementation Note (2026-05-01)

初版スキーマは `Timers` テーブル 1 つのみ。`schemaVersion = 1`。

- **テーブル定義**: `lib/infrastructure/database/app_database.dart`
  （`@DriftDatabase(tables: [Timers])`）
- **Mapper**: `lib/infrastructure/database/mappers/timer_mapper.dart`
  （`TimerEntity` ⇔ `TimerRow` / `TimersCompanion` の双方向変換）
- **Repository 実装**: `lib/infrastructure/database/drift_timer_repository.dart`
  （`upsert` は `insertOnConflictUpdate`、`findById` は `getSingleOrNull`）
- **本番接続**: `main()` で `AppDatabase()` (`drift_flutter` の `driftDatabase(name: 'timer_utility')`)
  を生成、`DriftTimerRepository(database)` でラップして
  `timerRepositoryProvider.overrideWithValue(...)`
- **テスト接続**: `AppDatabase.forTesting(NativeDatabase.memory())` で
  in-memory SQLite を起動。Mapper / Repository / TimerCollectionNotifier
  の Unit Test に使用
- **エンコーディング**:
  - `DateTime` → `INTEGER` (UTC epoch ms)。DST / ロケール変更で値が動かない
  - `Duration` → `INTEGER` (ms)
  - `TimerStatus` → `TEXT` (`enum.name`)。enum 値追加に対し前方互換、
    未知の name は `cancelled` フォールバック
- **スキーマ Bump の履歴と方針**: 当初 Phase 8 では timers のみ (v1) だったが、
  以下の通り追加 / リネームを重ねている。`schemaVersion` を bump し
  `MigrationStrategy.onUpgrade` の `if (from < N)` ブロックを足す方針:
  - v1 → v2 (Phase 9): `presets` テーブル追加 + default preset 6 件 seed
  - v2 → v3 (Phase 9.5): `alarms` テーブル追加
  - v3 → v4 (Phase 10.5): `clock_locations` テーブル追加 (seed なし)
  - v4 → v5 (Phase 11): `clock_locations` → `clock_entries` リネーム。
    `INSERT INTO clock_entries SELECT * FROM clock_locations` + `DROP TABLE` の
    new-table 方式 (カラム名据置で 1:1 コピー可)。専用 migration テスト
    `test/infrastructure/database/migration_v4_to_v5_test.dart` で
    Happy path / 空テーブル / bool 保存の 3 ケースを検証。
