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

### F-10. `PermissionBanner` 縦サイズ縮小 (バナー全体タップ可能化 + TalkBack 維持) (PR #47 実機検証で発見)

**経緯**: PR #47 (F-8 文中改行解消、2026-05-15 main マージ) の Pixel 6a 実機検証で、
縦並び化により本来の文中改行は解消されたが、TextButton (`[許可する]`) が
description 下段に独立配置された結果、バナー全体の縦サイズが約 48dp 増加して
「だいぶでかい」とユーザ判断。ユーザ提案で **バナー全体をタップ可能化し
TextButton を削除する** 方針が確定 (2026-05-15)。

**スクショ**: 2026-05-15 Pixel 6a 実機 (debug ビルド)。`[重要] 通知が無効です`
バナーが画面上部の約 1/4 を占有。文中改行は解消済みだが、空白行 +
ボタン領域で縦が冗長。

**修正内容** (TODO):

- [ ] `_PermissionBanner` ルートを `InkWell` (or `Material(... + InkWell)`) で
      ラップし、`onTap: onAction` でバナー全体をタップ可能化
- [ ] `TextButton` (および `Align(centerRight)` ラッパ) を削除
- [ ] description 末尾に「タップで権限を変更できます。」相当の案内を追加
      (ARB 編集)。`actionLabel` が `permissionBannerActionAllow` /
      `permissionBannerActionOpenSettings` で分岐する点との文言整合を
      取ること (例: denied → 「タップで権限を変更できます」、
      permanentlyDenied → 「タップで設定を開けます」のような分岐 ARB を新設)
- [ ] **TalkBack 維持**: `Semantics(button: true, onTap: onAction, label: ...)`
      で button role を明示的に保持。`InkWell` の自動 semantics に任せず、
      明示的に指定して読み上げを保証する。`Icon` / accent 帯は
      `ExcludeSemantics` で読み上げから除外
- [ ] 既存タップ動作テスト 2 件 (`許可する` / `設定を開く` を `find.text(...)`
      で取得 → タップ) を、各バナーの既存 Key (`banner_post_notifications` /
      `banner_exact_alarm` / `banner_full_screen_intent`) を使って
      `find.byKey(const Key('banner_*'))` で対象を一意特定し、`tester.tap()`
      で発火させる形に書き換え。`find.byType(InkWell)` は同時 3 バナー表示で
      Ambiguous lookup になるため使わない
- [ ] F-8 で追加した「TextButton.top >= description.bottom」 assert は
      TextButton ごと削除されるため、テスト自体を削除 (F-10 で「ボタンが無い」状態に変わる)
- [ ] 新規テスト追加: `tester.getSemantics(find.byKey(...))` で
      `SemanticsFlag.isButton` が立っていること、`SemanticsAction.tap` が
      ある ことを assert
- [ ] 実機検証 (Pixel 6a / Android 16, TalkBack ON / OFF 両方):
  - TalkBack OFF: バナータップで権限ダイアログ / 設定画面が開く
  - TalkBack ON: 「\[重要\] 通知が無効です。タイマーが終了したときに通知が
    表示されません。タップで権限を変更できます。 ボタン」 と読まれる
  - バナー全体の縦サイズが PR #47 比で縮小していること

**トリガ**: 単独 PR。F-10 として実装する。

**優先度**: 中 (UX 影響あり、F-8 解消後の副次課題)。

**スコープ外** (触らない):

- accent 幅ロジック (8 / 5 / 3 pt)、severity / fontWeight、配色
- 重大度ラベル (`[重要]` / `[推奨]` / `[補助]`) の表示位置・文言
- 他バナー (CVD バナー等) のレイアウト

**親 Plan / Auto 指示文**: 別途作成予定 (本タスク着手時に
`f-10-permissionbanner-fullbanner-tap-*.md` 相当のファイル名で、ユーザ環境の
Plans 保存場所に用意)。リポジトリ管理外のため絶対パスはここに記載しない。

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

最終更新日: 2026-05-15（Phase D (Diagnostic Logging) 完了 — D-1 (PR #49) / D-2 (PR #52) / D-3 (PR #51) すべて main マージ済、Pixel 6a 4 シナリオ実機検証 (ファイル生成 / PII 排除 / トグル永続化 / Share Sheet) すべて OK。F-10 (PermissionBanner 縦サイズ縮小) は別件で未着手のまま据置。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-15（Phase 11 言語切替 + F-9 Pixel 6a 実機検証完了 — PR #45 / #43 の合計 5 シナリオ (A-1〜A-4 / B) すべて OK。F-8 PermissionBanner 文中改行はスクショで再現確認、状態据置）

過去の更新: 2026-05-14（Phase 11 言語手動切替 UI 完了 — 設定画面に「言語」項目を追加、`UserPreferenceKeys.localeTag` 永続化 + `SettingsState.localeOverride: Locale?` で MaterialApp.locale を駆動。`null` 選択時は F-9 の localeResolutionCallback に委譲。Public 版は ja / en、experimental ビルドで zh / zh-Hant / ko も追加表示。Notifier 6 件 + Widget 4 件のテストを追加、合計 577 テスト緑 (1 skipped)）

過去の更新: 2026-05-14（F-9 完了 - localeResolutionCallback 追加で未対応 locale が en にフォールバックするよう修正、unit test 9 シナリオ追加、PR #43）

過去の更新: 2026-05-13（Phase 11 CVD banner labels の Pixel 6a 実機検証で発見した課題を follow-up 2 件として記録: F-8 本文折り返し品質 (cosmetic、CVD 識別性に影響なし) + F-9 未対応 locale のフォールバック先を ja → en に変更 (Phase 8.5 由来の既存仕様、繁体中文ユーザに英訳が当たるよう修正提案)）

過去の更新: 2026-05-13（Phase 11 CVD banner labels 完了 — 設定画面サブタスク「色覚多様性 (CVD) 対応モード」を方針 (a) 冗長表示で全ユーザ適用として完結 (PR #39)。詳細は `docs/dev-log.md` 「Phase 11 CVD banner labels (2026-05-13)」参照）

過去の更新: 2026-05-13（Phase 6 完全クローズ — `docs/platform-channels.md` を実装ベースに整列、4 ch 採用見送り確定 + `clearShowWhenLocked` 後付け文書化）

過去の更新: 2026-05-12（完了タスクログを `docs/dev-log.md` に移管、1505 行 → 約 60 行に整理）
