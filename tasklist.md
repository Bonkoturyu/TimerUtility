# tasklist.md

短期タスク（直近の作業項目）を管理するファイル。
中長期の Phase 管理は `BACKLOG.md` を参照すること。

本ファイルは「今日〜数日以内に着手するもの」「進行中のもの」のみを扱う。
完了タスクの詳細ログは [docs/dev-log.md](docs/dev-log.md) に集約する。

---

## 凡例

- `[ ]` 未着手
- `[~]` 進行中
- `[x]` 完了（次回更新時に削除候補）
- `[!]` ブロック中（理由を併記）

---

## 進行中

なし。

---

## Follow-up タスク（未着手）

### F-7. `AndroidManifest.xml` の `uses-permission` 整形統一 (PR #20 持ち越し)

**経緯**: PR #20 Copilot レビュー (comment id 3213290903) で
[`android/app/src/main/AndroidManifest.xml` line 2](android/app/src/main/AndroidManifest.xml#L2)
の `<uses-permission ... />` の `/>` 前にスペースが無く、line 3-9 (`" />`) と
書式が不一致との指摘あり。cosmetic で機能影響はゼロだが、`AndroidManifest.xml`
は CLAUDE.md「編集時にユーザー確認が必要なファイル」のため、レビュー fix の
スコープでは触らず、次回 Native (Kotlin / Manifest) 編集 PR にまとめる方針で
却下リプライ済。

**修正内容** (TODO):

- [ ] line 2 の `ACCESS_COARSE_LOCATION` を他行と同じ `..." />` 書式に揃える
- [ ] (この機会に) Manifest 全体の `/>` 前空白を一括スキャンし、揺れがあれば
  まとめて統一する

**トリガ**: 次に Native 側 (Kotlin / Manifest 権限追加 / receiver 追加 等) の
編集が発生する PR で着手。単独 PR は切らない。

**優先度**: 低 (差分ノイズ低減目的、機能影響なし)。

---

## ブロック中

<!-- ブロック要因と解消条件をここに記載 -->
- なし

---

## メモ

- タスクの粒度: 1 タスク = 30 分〜半日程度を目安
- 1 日以上かかるタスクは `BACKLOG.md` の Phase に格上げを検討
- 完了タスクの詳細ログ（Phase 1〜11 / 各種 Follow-up）は [docs/dev-log.md](docs/dev-log.md) を参照

---

最終更新日: 2026-05-16（F-10 (PermissionBanner 縦サイズ縮小 / バナー全体タップ可能化 + TalkBack Semantics 維持) 完了 — PR #56 main マージ済、Pixel 6a 実機 TalkBack ON/OFF 両検証 OK。実装は 4 commit に分割 (初版 + TalkBack「ラベルなし テキスト4」修正 + 兄弟 Text 合流修正 + PR レビュー反映) で、Semantics 三点セット (`container: true` + `excludeSemantics: true` + `InkWell.excludeFromSemantics: true`) を確立。F-10 closeout PR で旧 `permissionBannerActionAllow` / `permissionBannerActionOpenSettings` キーも削除。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-15（Phase D (Diagnostic Logging) 完了 — D-1 (PR #49) / D-2 (PR #52) / D-3 (PR #51) すべて main マージ済、Pixel 6a 4 シナリオ実機検証 (ファイル生成 / PII 排除 / トグル永続化 / Share Sheet) すべて OK）

過去の更新: 2026-05-15（Phase 11 言語切替 + F-9 Pixel 6a 実機検証完了 — PR #45 / #43 の合計 5 シナリオ (A-1〜A-4 / B) すべて OK。F-8 PermissionBanner 文中改行はスクショで再現確認、状態据置）

過去の更新: 2026-05-14（Phase 11 言語手動切替 UI 完了 — 設定画面に「言語」項目を追加、`UserPreferenceKeys.localeTag` 永続化 + `SettingsState.localeOverride: Locale?` で MaterialApp.locale を駆動。`null` 選択時は F-9 の localeResolutionCallback に委譲。Public 版は ja / en、experimental ビルドで zh / zh-Hant / ko も追加表示。Notifier 6 件 + Widget 4 件のテストを追加、合計 577 テスト緑 (1 skipped)）

過去の更新: 2026-05-14（F-9 完了 - localeResolutionCallback 追加で未対応 locale が en にフォールバックするよう修正、unit test 9 シナリオ追加、PR #43）

過去の更新: 2026-05-13（Phase 11 CVD banner labels の Pixel 6a 実機検証で発見した課題を follow-up 2 件として記録: F-8 本文折り返し品質 (cosmetic、CVD 識別性に影響なし) + F-9 未対応 locale のフォールバック先を ja → en に変更 (Phase 8.5 由来の既存仕様、繁体中文ユーザに英訳が当たるよう修正提案)）

過去の更新: 2026-05-13（Phase 11 CVD banner labels 完了 — 設定画面サブタスク「色覚多様性 (CVD) 対応モード」を方針 (a) 冗長表示で全ユーザ適用として完結 (PR #39)。詳細は `docs/dev-log.md` 「Phase 11 CVD banner labels (2026-05-13)」参照）

過去の更新: 2026-05-13（Phase 6 完全クローズ — `docs/platform-channels.md` を実装ベースに整列、4 ch 採用見送り確定 + `clearShowWhenLocked` 後付け文書化）

過去の更新: 2026-05-12（完了タスクログを `docs/dev-log.md` に移管、1505 行 → 約 60 行に整理）
