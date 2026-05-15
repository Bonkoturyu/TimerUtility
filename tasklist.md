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

### F-8. `PermissionBanner` の本文折り返し品質改善 (PR #39 実機検証で発見)

**経緯**: PR #39 (Phase 11 CVD banner labels、2026-05-13 main マージ) の
Pixel 6a 実機検証で、`[重要]` バナーの本文が「許可する」ボタンの
幅を避けて折り返すため、文の途中で改行が発生することを確認:

```text
タイマーが終了したときに通知が表    [許可する]
示されません。
```

[`lib/presentation/widgets/permission_banners.dart`](lib/presentation/widgets/permission_banners.dart)
の `_PermissionBanner.build` が `Row(Icon → Column(title + description)
→ TextButton)` 構造で、`Expanded` の本文がボタン幅を確保した残りで
折り返すため。**PR #39 以前から存在する既存挙動**で、CVD 改修
スコープでは触っていない。機能影響なし、視覚品質のみの課題。

**修正内容** (TODO):

- [ ] 本文を縦並び (`Column(title + description + ActionRow)`) に再構成し、
  「許可する」/「設定を開く」ボタンを下段独立配置にする案を検討
- [ ] あるいは Wrap 化 (title + button を 1 行 → 溢れたら折り返し) も検討
- [ ] 画面サイズ分岐 (タブレット / 横画面では現状 Row が自然)
- [ ] Widget Test を追加: 長文タイトルでも文中改行が起きないことを assert

**トリガ**: PermissionBanner の他の UI 改修 PR でまとめる、または
「本文表示品質」テーマで単独 PR を切る。実機検証で UX 影響が
許容できないとユーザ判断された場合は単独 PR に格上げ。

**優先度**: 低 (cosmetic、CVD 識別性自体は損なわれていない、機能影響なし)。
本文折り返しがあっても重大度ラベル `[重要]` / `[補助]` は先頭にあるため
読み始めは保たれている。

**再現確認**: 2026-05-15 PR #45 実機検証時に同現象を再スクショ取得済み。
状態に変化なし、実装案は本タスクの「修正内容 (TODO)」のまま。

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

最終更新日: 2026-05-15（Phase 11 言語切替 + F-9 Pixel 6a 実機検証完了 — PR #45 / #43 の合計 5 シナリオ (A-1〜A-4 / B) すべて OK。F-8 PermissionBanner 文中改行はスクショで再現確認、状態据置。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-14（Phase 11 言語手動切替 UI 完了 — 設定画面に「言語」項目を追加、`UserPreferenceKeys.localeTag` 永続化 + `SettingsState.localeOverride: Locale?` で MaterialApp.locale を駆動。`null` 選択時は F-9 の localeResolutionCallback に委譲。Public 版は ja / en、experimental ビルドで zh / zh-Hant / ko も追加表示。Notifier 6 件 + Widget 4 件のテストを追加、合計 577 テスト緑 (1 skipped)）

過去の更新: 2026-05-14（F-9 完了 - localeResolutionCallback 追加で未対応 locale が en にフォールバックするよう修正、unit test 9 シナリオ追加、PR #43）

過去の更新: 2026-05-13（Phase 11 CVD banner labels の Pixel 6a 実機検証で発見した課題を follow-up 2 件として記録: F-8 本文折り返し品質 (cosmetic、CVD 識別性に影響なし) + F-9 未対応 locale のフォールバック先を ja → en に変更 (Phase 8.5 由来の既存仕様、繁体中文ユーザに英訳が当たるよう修正提案)）

過去の更新: 2026-05-13（Phase 11 CVD banner labels 完了 — 設定画面サブタスク「色覚多様性 (CVD) 対応モード」を方針 (a) 冗長表示で全ユーザ適用として完結 (PR #39)。詳細は `docs/dev-log.md` 「Phase 11 CVD banner labels (2026-05-13)」参照）

過去の更新: 2026-05-13（Phase 6 完全クローズ — `docs/platform-channels.md` を実装ベースに整列、4 ch 採用見送り確定 + `clearShowWhenLocked` 後付け文書化）

過去の更新: 2026-05-12（完了タスクログを `docs/dev-log.md` に移管、1505 行 → 約 60 行に整理）
