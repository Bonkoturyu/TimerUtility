# tasklist.md

短期タスク（直近の作業項目）を管理するファイル。
中長期の Phase 管理は `BACKLOG.md` を参照すること。

本ファイルは「今日〜数日以内に着手するもの」「進行中のもの」のみを扱う。
完了タスクは適宜削除し、肥大化させない。

---

## 凡例

- `[ ]` 未着手
- `[~]` 進行中
- `[x]` 完了（次回更新時に削除候補）
- `[!]` ブロック中（理由を併記）

---

## 進行中

<!-- 現在進行中のタスクをここに記載 -->
- なし

---

## 直近の予定

### ドキュメント整備の仕上げ（Phase 0 完了済み）

- [x] ルート直下の `*.md` を `docs/` および `docs/adr/` へ移動
- [x] `CLAUDE.md` を最低限の制約集に圧縮
- [x] `tasklist.md` を新規作成
- [x] `BACKLOG.md` の Phase 0 チェック項目を更新（ドキュメント整備完了を反映）
- [x] `README.md` を最低限のプロジェクト説明に更新

### Phase 1 完了内容（2026-04-29）

- [x] `flutter create --org com.bonkotu.timer --project-name timer_utility --platforms=android .` 実行
- [x] レイヤー別ディレクトリ構造を作成（`lib/{domain,application,infrastructure,presentation}/`）
- [x] `pubspec.yaml` に Phase 1 依存パッケージ追加（115 依存解決済み）
- [x] `analysis_options.yaml` を厳格化（strict-casts/inference/raw-types、freezed 除外、custom_lint）
- [x] `.github/workflows/ci.yml` を新規作成（format / analyze / test ジョブ）
- [x] `lib/main.dart` を ProviderScope + GoRouter の最小構成に書き換え
- [x] `test/widget_test.dart` を新 main.dart に対応するスモークテストに書き換え
- [x] Kotlin パッケージパス差異を `docs/architecture.md` で実態に合わせて修正
- [x] CLAUDE.md のテストポリシーを `flutter_test` 経由に修正（`test` 直接依存はエコシステム制約で断念）
- [x] `flutter analyze` → No issues found
- [x] `flutter test` → All tests passed
- [x] CI が緑になることを確認（push 後の GitHub Actions 実行で確認済み）

### Phase 1 着手準備

- [x] `flutter create` 実行時の org / projectName を確定
  - org: `com.bonkotu.timer`
  - projectName: `timer_utility`
- [x] `pubspec.yaml` で追加する依存パッケージリストを最終確認
  - `freezed` / `freezed_annotation` を追加（Entity の copyWith / sealed class の網羅性検証用途）
  - `intl` は Phase 1 では追加せず、Phase 11（ローカライズ）着手時に `flutter_localizations` とセットで追加
  - `json_serializable` は Drift 永続化のため不要（外部 API 連携が出てきたら再検討）
- [x] Auto 運用ポリシーを CLAUDE.md に明文化
  - 自動実行範囲: コード生成 + テスト実行 + ローカルコミットまで（push は手動）
  - 停止条件: テスト 3 回連続失敗 / 同一ファイル 5 回以上連続編集 / 100 行超の新規生成 / Phase DoD 達成
- [x] `flutter create` の実行環境を確定: HP ProDesk（本マシン）
- [x] Flutter SDK 環境の Warning / NG 解消
  - Android SDK Command-line Tools をインストール
  - `flutter doctor --android-licenses` で全ライセンス承認
  - `flutter config --no-enable-windows-desktop` で Windows desktop 無効化
  - `flutter doctor` で `• No issues found!` を確認

### Auto 運用開始前のユーザー側作業

- [x] GitHub リポジトリ作成済み（`https://github.com/Bonkoturyu/TimerUtility.git`）
- [x] `git remote -v` で push 先 URL 設定済み
- [x] `git ls-remote` で認証確認済み
- [x] Phase 0 ドキュメント push 完了
- [ ] GitHub Settings → Actions → 有効化されていることを確認（Web UI で要確認）
- [x] 上記まで完了したら Auto 起動可能（Actions 確認のみ残）

詳細は `BACKLOG.md` の Phase 1 を参照。

---

## ブロック中

<!-- ブロック要因と解消条件をここに記載 -->
- なし

---

## メモ

- タスクの粒度: 1 タスク = 30 分〜半日程度を目安
- 1 日以上かかるタスクは `BACKLOG.md` の Phase に格上げを検討

---

最終更新日: 2026-04-29
