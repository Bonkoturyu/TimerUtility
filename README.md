# TimerUtility

Flutter 製のストップウォッチ + タイマーアプリ。Android 16 (API 36) 主ターゲット。

## 主な機能（予定）

- ストップウォッチ（Lap 記録）
- 複数タイマー同時稼働
- カスタムアラーム音
- ロック画面上のアラーム表示（フルスクリーン Intent）
- 端末再起動後のタイマー復元
- プリセット管理

## 技術スタック

- **言語/フレームワーク**: Flutter (Dart)
- **状態管理**: Riverpod
- **ルーティング**: go_router
- **永続化**: Drift (SQLite)
- **通知**: flutter_local_notifications
- **音声再生**: audioplayers

## ドキュメント

- [CLAUDE.md](CLAUDE.md) — Claude Code 向けの絶対制約集
- [BACKLOG.md](BACKLOG.md) — Phase 別タスク管理
- [tasklist.md](tasklist.md) — 短期タスク管理
- [docs/architecture.md](docs/architecture.md) — レイヤー構造・命名規則・ディレクトリ構造
- [docs/domain-model.md](docs/domain-model.md) — Entity / ValueObject 定義
- [docs/state-management.md](docs/state-management.md) — Riverpod Provider 一覧
- [docs/android-constraints.md](docs/android-constraints.md) — Android 16 制約・FullScreenIntent
- [docs/platform-channels.md](docs/platform-channels.md) — Native ↔ Flutter メッセージ仕様
- [docs/testing-strategy.md](docs/testing-strategy.md) — テスト戦略
- [docs/permissions.md](docs/permissions.md) — 権限取得フロー
- [docs/assets-spec.md](docs/assets-spec.md) — 同梱音源仕様
- [docs/adr/](docs/adr/) — アーキテクチャ意思決定記録（ADR）

## ライセンス

[LICENSE](LICENSE) を参照。
