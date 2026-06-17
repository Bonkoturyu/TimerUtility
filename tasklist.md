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

### Phase 11.9 サブ PR γ

Play Store 提出準備を進行中。

- [x] Privacy Policy の GitHub Pages 公開（Source = `main` / `/docs`、PR #96 / #97 で `docs/index.md` 追加 + Jekyll/Liquid build error 修正済。登録用 URL: `https://bonkoturyu.github.io/TimerUtility/privacy-policy`）
- Play Store listing と Data Safety 申告の確定
- [x] Pixel 6a スクリーンショット 7 シナリオ（ja、1080×2400、`design/screenshots/phone/ja/` に配置）
- [x] `android/key.properties.template` 追加
- [x] release signing を `android/key.properties` 経由に配線
- [x] version bump (`1.0.0+2`)
- [ ] upload keystore 実体生成 + `android/key.properties` 作成
- [ ] 署名付き AAB ビルド

### 直近マージ済み (実態反映、2026-06-15 同期)

- [x] **Phase 11.9 サブ PR β 実機確認** — Pixel 6a / Android 16 で
  launcher icon、Themed Icon (monochrome)、splash cold / warm、
  light / dark、OS 表示名 `TimerUtility` を確認し、すべて OK。
  併せて Timer / Alarm の POST_NOTIFICATIONS 初回ダイアログ、1 分タイマー鳴動、
  Lock 画面 FSI、二重音なしも確認済み。
- [x] **Phase 11.9 サブ PR β 本体** — **PR #91 main マージ済 (2026-06-14、squash `954eea2`)**。
  `design/icon/` に 1024 px 原画、
  adaptive foreground / background / monochrome、splash logo、Play Store
  512 px icon を配置し、Android 各密度の launcher / themed icon /
  light・dark splash リソースを生成。`design/store/feature-graphic-1024x500.png`
  も追加。PixAI / Hoshino v2 のクレジットをアプリ内ライセンスと
  `THIRD_PARTY_NOTICES.md` に反映。`flutter analyze`、`flutter test`
  (673 passed / 1 skipped)、debug APK build、翻訳文書チェック成功。
  実機表示確認は未完のため上記「進行中」に分離。
- [x] **Phase 11.9 サブ PR β 事前準備** — `phase-11.9-beta-prep` /
  **PR #77 main マージ済 (2026-05-29、squash `0a0509d`)**。素材非依存の β 準備:
  strings.xml 5 言語 + Manifest `app_name` 配線 (T4 相当) + §G アイコン仕様の公式裏取り
  確定 + §A 版数再確認。Gemini の Play 角丸「20%」指摘は公式逐語「30%」(2 箇所明記) で
  却下。詳細は [docs/phase-11.9-prep-notes.md](docs/phase-11.9-prep-notes.md) §G / §A
- [x] **Phase 11.9 サブ PR α** — `phase-11.9-alpha` / **PR #72 main マージ済 (2026-05-28)**。
  T0 applicationId rename (`com.bonkotu.timer.timer_utility` → `io.github.bonkoturyu.timer_utility`)、
  I.1 MethodChannel rename、alarm_ringing_screen.dart ハードコード解消、live docs 5 ファイル追従。
  Pixel 6a 8 シナリオすべて OK。詳細は [docs/dev-log.md](docs/dev-log.md)
  「Phase 11.9 サブ PR α」セクション
- [x] **Issue #74 fix — Lock 画面表示中の FSI 二重音** — `fix/issue-74-fsi-cold-launch-double-sound` /
  **PR #75 main マージ済 (2026-05-29、squash `dcac842`)**、issue #74 クローズ。
  判定軸を「Lock 画面表示中か」(KeyguardManager) に補正し unlock 500ms / Lock 1800ms 分岐。
  Pixel 6a 4 シナリオ OK (シナリオ 4 は ×3 連続単音化)。詳細は
  [docs/dev-log.md](docs/dev-log.md) 「Issue #74 fix — Lock 画面表示中の FSI 二重音」セクション

---

## Follow-up タスク

- [x] **新規 install 直後の POST_NOTIFICATIONS 初回ダイアログ非表示問題**
  (Phase 11.9 α 実機検証で発見)。Timer 追加開始時と enabled な Alarm 保存時に
  `PermissionNotifier.ensureNotificationPermissionForScheduling()` を通し、
  `unknown` なら refresh 後、`unknown` / `denied` なら `requestNotification()` を呼ぶ。
  拒否時も作成は止めず、既存 PermissionBanner で劣化状態を表示する。
  対象テストは `flutter test test/application/permission_notifier_test.dart
  test/presentation/screens/alarm_edit_screen_test.dart
  test/presentation/screens/home/timer_list_page_test.dart` で成功。
  Pixel 6a 実機でも新規 install 後の Timer 追加時 / Alarm 保存時に
  OS 許可ダイアログが出ることを確認済み。

> `docs/translations.md` 一括同期は Phase 11 close out PR (2026-05-16) で完了。
> CI 自動 diff チェックも `tool/check_translations_doc.dart` で実装済 (2026-05-16)。

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

最終更新日: 2026-06-17（Pixel 6a スクリーンショット 7 シナリオを `design/screenshots/phone/ja/` に格納。γ は Play Console 実画面での listing / Data Safety 確定、upload keystore、署名付き AAB 検証が残り）

過去の更新: 2026-06-15（PR #91 の実態へ同期。Phase 11.9 β はアイコン・
スプラッシュ生成とストア用 icon / Feature Graphic まで完了し、Pixel 6a
実機表示確認のみ残る状態。次の着手単位をサブ PR γ に更新）

過去の更新: 2026-05-29（β 素材非依存準備の PR #77 マージ後同期 — branch `docs/sync-plan-after-77`。Phase 11.9 サブ PR β の素材非依存タスク (strings.xml 5 言語 + Manifest `android:label` → `@string/app_name` 配線 [T4 相当] + §G アイコン仕様公式裏取り確定 + §A 版数再確認) を PR #77 で main マージ (squash `0a0509d`)。本同期で tasklist「次の着手単位: サブ PR β」を実態反映: ゴール方針「素材を入れたら β がほぼ完了する状態」をユーザ合意として明記し、完了済み (素材非依存) と素材投入後の残タスクを分離。pubspec.yaml への launcher_icons / native_splash 設定ブロックは素材非依存で front-load 可能な旨を注記。「直近マージ済み」に #77 エントリ追加。Gemini code-assist の Play 角丸「20%」指摘は公式ページ逐語「Radius will be equivalent to 30% of icon size.」(Attributes Shape 行 + Corner radius セクションの 2 箇所) で却下済。doc-only、`flutter analyze` / `flutter test` 不要）

過去の更新: 2026-05-29（計画ファイルを実態に同期 — branch `docs/sync-plan-files-after-72-75`。`tasklist.md` / `BACKLOG.md` が 2026-05-27 で停止し、PR #72・#75 を「main merge 待ち」と誤記したままだったため実態反映。`gh pr list` で両者マージ済を確認 (#72 Phase 11.9 サブ PR α 2026-05-28、#75 Issue #74 fix 2026-05-29 squash `dcac842`)。`tasklist.md` の「進行中」2 件を「直近マージ済み」へ移動、次の着手単位 = Phase 11.9 サブ PR β を明記、Follow-up に POST_NOTIFICATIONS 初回ダイアログ非表示問題を追加。`BACKLOG.md` 進捗サマリ表 Phase 11.9 行を「α・#74 fix マージ済 → 次 β」に更新。`docs/dev-log.md` #75 セクション末尾の「main 反映待ち」を「マージ完了」に更新。doc-only、`flutter analyze` / `flutter test` 不要。作業ツリーの 15 生成ファイル modified 表示は LF→CRLF eol 差のみで内容差分ゼロ、コミット対象外）

過去の更新: 2026-05-27（Phase 11.9 サブ PR α 実装完了 — branch `phase-11.9-alpha` (ベース `phase-11.8-close-out`) で T0 applicationId rename (`com.bonkotu.timer.timer_utility` → `io.github.bonkoturyu.timer_utility`) + I.1 MethodChannel rename (`com.bonkotu.timer/permission` → `io.github.bonkoturyu.timer_utility/permission`) + alarm_ringing_screen.dart ハードコード解消 (`PermissionChannel.channelName` 定数参照) + live docs 5 ファイル追従 (README / architecture / android-constraints / permissions / platform-channels) を atomic に切替。`AndroidManifest.xml` は触らず (`.MainActivity` 相対参照 + `${applicationName}` プレースホルダ + flutter_local_notifications の third-party receiver は変更不要、事前検討メモ §B.1 で確認済)。`flutter analyze --fatal-infos` 0 issues / `flutter test` 642 passed (1 skipped) / `dart run tool/check_translations_doc.dart` ARB 171 / Doc 171 aligned、grep `com\.bonkotu\.timer` で live files 残存 0 (履歴 docs のみ、§B.4 据置対象)。PR 作成済。残: **Pixel 6a 実機検証** (`adb uninstall com.bonkotu.timer.timer_utility` → `flutter run` → Phase 6 FSI 3 パターン + Phase 8.5 アラーム単音化回帰) はユーザ実施。検証 OK → main マージはユーザ判断。次の着手単位: Phase 11.9 サブ PR β (アイコン素材 + flutter_launcher_icons + flutter_native_splash + strings.xml 5 言語 + Pixel 6a 4 パターン確認)。詳細は [dev-log](docs/dev-log.md) 「Phase 11.9 サブ PR α — applicationId + MethodChannel rename (2026-05-27)」セクション）

過去の更新: 2026-05-27（Phase 11.8 完全クローズ — T10 (GitHub Settings → Visibility = Public + Description + Topics 設定) を本日ユーザ実施で完了し Phase 11.8 を完全クローズ。branch `phase-11.8-close-out` で `docs/dev-log.md` / `docs/oss-and-play-release-plan.md` / BACKLOG.md / tasklist.md の 4 ファイルに完了記録を反映。T10 実施結果: `gh repo view --json` で Visibility=PUBLIC、Description=「Multi-timer / alarm / world-clock for Android 16. Reference implementation of Flutter Clean Architecture + Android alarm constraints handling.」、Topics 9 件 (`alarm` / `android` / `claude-code` / `clean-architecture` / `dart` / `drift` / `flutter` / `riverpod` / `timer`)。`gh api .../community/profile` で `health_percentage: 100`、シークレットウィンドウで Public URL 表示確認済 (ユーザ実施)。Phase 11.8 進行中エントリを削除、Phase 11.9 エントリを「サブ PR α 着手準備完了」状態に更新。次の着手単位: Phase 11.9 サブ PR α (T0 applicationId 変更 + MethodChannel rename + live docs 追従)。詳細は [dev-log](docs/dev-log.md) 「Phase 11.8 完全クローズ — T10 (Public 化) 完了 (2026-05-27)」セクション）

過去の更新: 2026-05-27（Phase 11.8 T8.5 / T8.6 omit 決定 — branch `phase-11.8-t10-unblock` で計画文書更新。2026-05-16 に `privacy@github.com` 宛で送信した個人情報削除申請が 11 日経過しても auto-ack / ticket / bounce すべてゼロで処理されている形跡なし。並行して orphan commit `f2e46e3` の `docs/opus-startup-prompt.md` 旧版を `gh api .../contents/...?ref=f2e46e3` で実物確認 → 露出内容は技術スキル列挙 (C/C++/C# 等) + Web/VR/3D ツール列挙 + 自宅 PC 構成 (Ryzen + マルチ GPU + OLLAMA 構成) + 使用 SaaS (Claude Code / Copilot / Gemini 等) のみで典型 PII (氏名 / 連絡先 / 住所 / financial / credentials / API キー / 写真) ゼロ。GitHub アカウント `@Bonkoturyu` プロフィール程度の独自性、悪用可能性低と評価。ユーザー判断で T8.5 / T8.6 omit + T10 (Public 化) を T8.6 非依存に変更し進行解除。`docs/oss-and-play-release-plan.md` Phase 11.8 セクションのタスク表 / DoD / 検証を打消し線付きで撤回、memory `feedback_filter_branch_github_cache.md` に「コスト・ベネフィット例外」セクション追記 (Privacy team 長期無反応 + 典型 PII ゼロのとき omit する判定手順)。残: **T10 (GitHub Settings → Visibility = Public + Description / Topics 設定)** はユーザ作業 (不可逆)。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-17（Phase 11.9 事前検討 §I キックオフ判断 4 件確定 — branch `phase-11.9-prep` の PR #68 に追加 commit。推奨案 A を全件採用: (1) MethodChannel 名 (`com.bonkotu.timer/permission` → `io.github.bonkoturyu.timer_utility/permission`) を T0 同 PR で移行 + alarm_ringing_screen.dart のハードコード解消、(2) アイコン素材は monochrome layer も含む 3 層セットで T1 から作成、(3) アプリ名は全 5 言語 `TimerUtility` 統一、(4) サブ PR α/β/γ 3 分割で進行。`phase-11.9-prep-notes.md` §I を「残論点」→「確定事項」に書き換え + BACKLOG.md / tasklist.md 追従。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-17（Phase 11.9 事前検討 4 件 (A 依存版数 / B applicationId 影響範囲 grep / C 5 言語アプリ名 / G アイコン仕様) + 実アーティファクト 4 件 (privacy-policy ja/en、play-store-listing、release-signing) を branch `phase-11.9-prep` で先行作成。Phase 11.8 T8.5 GitHub Privacy team 申請返信待ち期間の活用。Phase 11.9 着手前にユーザ判断必要な残論点 4 件 (MethodChannel 名移行を T0 と同 PR にするか / monochrome layer 必須化対応 / アプリ名ローカライズ統一案で良いか / サブ PR α/β/γ 分割案) を `docs/phase-11.9-prep-notes.md` §I に集約。`dart format` / `flutter analyze` / ARB diff チェックすべて緑、doc-only のため `flutter test` は CI 任せ。Phase 11.8 残: **T8.5 返信待ち (2026-05-17 時点で `gh api .../contents/docs/opus-startup-prompt.md?ref=f2e46e3` は 200 OK 継続、cache 削除未処理)** → T8.6 → T10。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-16（Phase 11.8 OSS 公開準備の T1〜T9 着手 — branch `phase-11.8-oss-prep` で実装。計画書 [docs/oss-and-play-release-plan.md](docs/oss-and-play-release-plan.md) (PR #66 承認済) の Claude 単独実行可能タスクを一括着手: README 再構成 (Build & Run / Architecture / fork ガイド / "What's special" 日本語+英語) / `THIRD_PARTY_NOTICES.md` 新規 / `CONTRIBUTING.md` 新規 / `CODE_OF_CONDUCT.md` 新規 (Contributor Covenant 2.1) / `.github/ISSUE_TEMPLATE/{bug_report,feature_request}.md` + `PULL_REQUEST_TEMPLATE.md` 新規 / `pubspec.yaml` に `homepage` / `repository` / `issue_tracker` 追加 / 秘密情報 grep + commit author 全件確認 (hit 0、author は GitHub 提供 noreply 1 件のみ) / BACKLOG.md + tasklist.md + docs/dev-log.md 反映。`dart format` (254 ファイル、変更 0) / `flutter analyze --fatal-infos` / `flutter test` (642 緑 / 1 skipped) / `dart run tool/check_translations_doc.dart` (ARB 171 / Doc 171 一致) すべて緑。残: **T8.5 (GitHub Privacy team `privacy@github.com` メール直送、orphan commit `f2e46e3` 経由の `docs/opus-startup-prompt.md` 旧版 cache 削除申請、本人がリポジトリから自身の個人情報を削除するケースのため [Privacy contact form](https://github.com/contact/privacy) → `Other` 経由)** + T8.6 (404 確認) + T10 (GitHub Public 化) はユーザ作業のため本セッション外。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-16（Phase 11 close out — `docs/translations.md` 一括同期完了。tasklist.md の Follow-up エントリをクローズ。ARB と translations.md のキー集合を `Compare-Object` で確認 (ARB 171 / Doc 171 / 差分なし)。冒頭「既知の差分」段落と末尾の旧 zh/ko 列ロードマップ記述 (5 列ミラー不採用方針と矛盾) を整合化。33 キーを既存 4 セクション拡張 + 新規 2 セクション (「世界時計 (Phase 10.5)」「通知 channel (Phase 11 A-2)」) に振り分け。Phase 11 残作業は「アプリアイコン・スプラッシュ」「Play Store 提出準備」の 2 件のみ。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-16（A-3 (中韓 ARB 本格翻訳) 完了 — PR #61 main マージ済、Pixel 6a 実機検証完了。Phase 11 ローカライズ残作業はこれで全件クローズ、残るは Phase 11 全体の「アプリアイコン・スプラッシュ」「Play Store 提出準備」のみ。Copilot レビュー 2 ラウンドで重要 bug 2 件発見・修正 (i. zh_Hant の `Locale('zh', 'Hant')` countryCode 形式が gen-l10n の `scriptCode` 期待値と不整合で繁体字が Simplified にフォールバックする bug、`Locale.fromSubtags` に修正、ii. flag 依存テストが実質未検証だった点を `@visibleForTesting debugExperimentalSupportedLocales` で flag 非依存に書き直し)。実機検証で韓国語空表示 wrap (`다.` 単独行漏れ) と中文 SnackBar `一个星期` 曖昧性も追加発見・修正。642 テスト緑 (1 skipped)。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-16（A-3 — 中国語簡体字 / 繁体字 / 韓国語の ARB 本格翻訳本体。`app_zh.arb` / `app_zh_Hant.arb` / `app_ko.arb` を新規作成 (各 172 翻訳キー、ja / en と完全同一キー集合)。`flutter gen-l10n` で `AppLocalizationsZh` / `AppLocalizationsZhHant` / `AppLocalizationsKo` 生成。zh / zh_Hant / ko は CLDR plural rule で `other` のみ。`docs/translations.md` は ja / en 2 列維持 + 3 言語は ARB 直接参照運用へ切替 (方針 a)）

過去の更新: 2026-05-16（A-2 (通知 channel 名 i18n) + F-7 (Manifest 整形) 完了 — PR #59 main マージ済、Pixel 6a 5 シナリオ実機検証完了。`NotificationStrings` を `lib/domain/notifications/` に移動 (依存方向修正) + `NotificationScheduler.updateChannelNames` port 追加で、locale 切替時に同 id `createNotificationChannel` 再呼び出しにより OS 設定画面の channel 名が即時追従。F-7 は `AndroidManifest.xml` line 2 整形 (PR #20 持ち越し) を同梱。641 テスト緑 (1 skipped)。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-16（F-10 (PermissionBanner 縦サイズ縮小 / バナー全体タップ可能化 + TalkBack Semantics 維持) 完了 — PR #56 main マージ済、Pixel 6a 実機 TalkBack ON/OFF 両検証 OK。実装は 4 commit に分割 (初版 + TalkBack「ラベルなし テキスト4」修正 + 兄弟 Text 合流修正 + PR レビュー反映) で、Semantics 三点セット (`container: true` + `excludeSemantics: true` + `InkWell.excludeFromSemantics: true`) を確立。F-10 closeout PR で旧 `permissionBannerActionAllow` / `permissionBannerActionOpenSettings` キーも削除。詳細は [dev-log](docs/dev-log.md)）

過去の更新: 2026-05-15（Phase D (Diagnostic Logging) 完了 — D-1 (PR #49) / D-2 (PR #52) / D-3 (PR #51) すべて main マージ済、Pixel 6a 4 シナリオ実機検証 (ファイル生成 / PII 排除 / トグル永続化 / Share Sheet) すべて OK）

過去の更新: 2026-05-15（Phase 11 言語切替 + F-9 Pixel 6a 実機検証完了 — PR #45 / #43 の合計 5 シナリオ (A-1〜A-4 / B) すべて OK。F-8 PermissionBanner 文中改行はスクショで再現確認、状態据置）

過去の更新: 2026-05-14（Phase 11 言語手動切替 UI 完了 — 設定画面に「言語」項目を追加、`UserPreferenceKeys.localeTag` 永続化 + `SettingsState.localeOverride: Locale?` で MaterialApp.locale を駆動。`null` 選択時は F-9 の localeResolutionCallback に委譲。Public 版は ja / en、experimental ビルドで zh / zh-Hant / ko も追加表示。Notifier 6 件 + Widget 4 件のテストを追加、合計 577 テスト緑 (1 skipped)）

過去の更新: 2026-05-14（F-9 完了 - localeResolutionCallback 追加で未対応 locale が en にフォールバックするよう修正、unit test 9 シナリオ追加、PR #43）

過去の更新: 2026-05-13（Phase 11 CVD banner labels の Pixel 6a 実機検証で発見した課題を follow-up 2 件として記録: F-8 本文折り返し品質 (cosmetic、CVD 識別性に影響なし) + F-9 未対応 locale のフォールバック先を ja → en に変更 (Phase 8.5 由来の既存仕様、繁体中文ユーザに英訳が当たるよう修正提案)）

過去の更新: 2026-05-13（Phase 11 CVD banner labels 完了 — 設定画面サブタスク「色覚多様性 (CVD) 対応モード」を方針 (a) 冗長表示で全ユーザ適用として完結 (PR #39)。詳細は `docs/dev-log.md` 「Phase 11 CVD banner labels (2026-05-13)」参照）

過去の更新: 2026-05-13（Phase 6 完全クローズ — `docs/platform-channels.md` を実装ベースに整列、4 ch 採用見送り確定 + `clearShowWhenLocked` 後付け文書化）

過去の更新: 2026-05-12（完了タスクログを `docs/dev-log.md` に移管、1505 行 → 約 60 行に整理）
