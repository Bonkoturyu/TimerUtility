# TimerUtility OSS 公開 → Play Store 提出 実装計画

作成日: 2026-05-16
状態: 承認済 (本計画策定セッション、2026-05-16)
関連: [docs/oss-publishing-notes.md](oss-publishing-notes.md) (公開可否・特許リスク監査) / [BACKLOG.md](../BACKLOG.md) (Phase 11 残タスク) / [tasklist.md](../tasklist.md)

## Context

TimerUtility (Flutter / Android 16 / Pixel 6a 主ターゲット) は Phase 11 の残作業が
「アプリアイコン・スプラッシュの実機表示確認」「Play Store 提出準備」となり、
コア機能・ローカライズ・診断ログ機構はすべて完了済み。アイコン / Splash の
実装とストア用 icon / Feature Graphic は PR #91 で main へマージ済み
(673 テスト成功 / 1 skipped)。

[docs/oss-publishing-notes.md](oss-publishing-notes.md) (2026-05-02) で OSS 公開可・特許リスクなしと監査済。本計画策定セッション (2026-05-16) のリポジトリ実態確認結果:

- ライセンス・秘密情報・commit author email は全クリア
- ネットワーク送信ゼロ、Data Safety 申告は「収集なし / 共有なし」で出せる
- README / community files / アイコン / Splash / keystore / プライバシーポリシー / ストア素材が **未整備**

本計画は **OSS 公開を先行** し、フィードバックを受けながら Play 提出素材を整える 3 段階構造で進める。

## 確定方針 (ユーザ承認済)

| 項目 | 確定値 |
| --- | --- |
| 公開順 | OSS Public 化 → Play 提出 |
| 署名 | 新規 upload keystore + Play App Signing 加入 |
| OSS 公開時のアイコン | デフォルト Flutter ロゴのまま |
| プライバシーポリシー | 同一リポ GitHub Pages (`docs/` 配下) |
| Phase 分割 | 11.8 / 11.9 / 11.10 の 3 段階 |
| applicationId | **`io.github.bonkoturyu.timer_utility`** に変更 (現状 `com.bonkotu.timer.timer_utility`) |
| README "What's special" | 日本語要約 + 英語本文の併記 |
| ProGuard/R8 | Phase 11.10 Production 前までオフ、その後検討 |

---

## Phase 11.8: OSS 公開 — 完了 (2026-05-27)

**目的**: アイコンはデフォルトのまま、GitHub リポジトリを Public 化する。Native / Android 設定には触らない。

**最終結果**: T1〜T9 を PR #67 (2026-05-16) で main マージ、T8.5/T8.6 を 2026-05-27 omit (PR #69 で計画書反映、判断根拠は [docs/dev-log.md](dev-log.md) 「Phase 11.8 T8.5 / T8.6 omit 決定 — Public 化のブロック解除 (2026-05-27)」セクション)、T10 を 2026-05-27 ユーザ実施で完全クローズ。詳細は [docs/dev-log.md](dev-log.md) 「Phase 11.8 完全クローズ — T10 (Public 化) 完了 (2026-05-27)」セクション参照。

### タスク

| # | タスク | 編集対象 | 確認必須 |
| --- | --- | --- | --- |
| T1 | README に「Screenshots プレースホルダ」「Build & Run」「Architecture 概要 + docs リンク」「fork 時 applicationId 書換ガイド」を追記 | [README.md](../README.md) | 不要 |
| T2 | README に "What's special about this project?" 節を追加 (日本語要約 4 行 + 英語本文)。英語本文は [docs/oss-publishing-notes.md:227-242](oss-publishing-notes.md#L227-L242) の草案を流用 | [README.md](../README.md) | 不要 |
| T3 | `THIRD_PARTY_NOTICES.md` 新規作成 ([docs/oss-publishing-notes.md:29-65](oss-publishing-notes.md#L29-L65) §2.2 / §2.3 / §2.5 を機械的に転記 + [assets/sounds/LICENSES.md](../assets/sounds/LICENSES.md) へのリンク) | ルート新規 | 不要 |
| T4 | `CONTRIBUTING.md` 新規 ([CLAUDE.md](../CLAUDE.md) の応答ポリシー / Auto 運用 / レビュー対応プロトコルから OSS 投稿者向けに要約) | ルート新規 | 不要 |
| T5 | `CODE_OF_CONDUCT.md` 配置 (Contributor Covenant 2.1 そのまま) | ルート新規 | 不要 |
| T6 | `.github/ISSUE_TEMPLATE/bug_report.md` + `feature_request.md` + `.github/PULL_REQUEST_TEMPLATE.md` を新規追加 | `.github/` 配下 | **必須** (`.github/` 配下) |
| T7 | `pubspec.yaml` に `homepage` / `repository` / `issue_tracker` フィールド追加 | [pubspec.yaml](../pubspec.yaml) | **必須** |
| T8 | 秘密情報最終 grep + commit author 全件確認 (`git log --pretty='%an <%ae>' \| sort -u`) | 読み取りのみ | 不要 |
| T8.5 | ~~**GitHub Privacy team にメール直送で個人情報削除申請**~~ → **2026-05-27 omit 決定**。2026-05-16 に GitHub 登録メールから `privacy@github.com` 宛にメール直送済みだが、11 日経過 (5/16 → 5/27) しても **auto-ack / ticket 番号 / bounce 通知すべてゼロ** で処理されている形跡なし。並行して orphan commit `f2e46e3` の実物 (`gh api .../contents/docs/opus-startup-prompt.md?ref=f2e46e3`) を取得 → 残留内容を確認したところ、典型 PII (氏名 / 連絡先 / 住所 / financial / credentials / API キー / 写真) が **一切含まれず**、技術スキル列挙 + 自宅 PC 構成 + 使用 SaaS 列挙の粒度のみ (公開 GitHub プロフィール程度の独自性)。ユーザー判断でリスク許容、**本タスクは omit して T10 を T8.6 非依存に変更**。詳細は [docs/dev-log.md](dev-log.md) の「Phase 11.8 T8.5 / T8.6 omit 決定 — Public 化のブロック解除 (2026-05-27)」セクションと、ローカルメモリ `feedback_filter_branch_github_cache.md` (リポジトリ外、開発者個人の `~/.claude/` 配下) の「コスト・ベネフィット例外」セクション参照 | (omit) | (omit) |
| T8.6 | ~~T8.5 申請完了後、再度 `gh api repos/Bonkoturyu/TimerUtility/contents/docs/opus-startup-prompt.md?ref=f2e46e3` が 404 を返すことを確認~~ → **T8.5 omit に伴い同時 omit**。本日時点で 200 OK 継続 (sha `838c0fa...` / size 7311 bytes)。Public 化後も Privacy team の事後処理が進めば 404 化する可能性はあるが、**T10 ブロッカーとしては扱わない** | (omit) | (omit) |
| T9 | BACKLOG.md / tasklist.md / docs/dev-log.md に Phase 11.8 完了記録を追記 | `docs/` + ルート md | **必須** (`docs/`) |
| T10 | GitHub Settings → Visibility を Public に変更 + Description / Topics 設定。**T8.5 / T8.6 を omit したため、T9 完了 + Phase 11.8 PR (T1-T9) main マージ済が唯一の前提** (旧記述: 「T8.6 の確認が取れていることが前提」は 2026-05-27 撤回)。**✅ 完了 (2026-05-27)**: Visibility=PUBLIC、Description は本計画 Context セクションの想定通り、Topics 9 件 (`alarm` / `android` / `claude-code` / `clean-architecture` / `dart` / `drift` / `flutter` / `riverpod` / `timer`) を設定。`gh api .../community/profile` で health_percentage=100% 確認、シークレットウィンドウで Public URL アクセス成功確認済 | GitHub Web | **必須** (不可逆) |

### DoD

- ✅ README に スクショ枠 / ビルド手順 / Architecture リンク / fork ガイド / "What's special" 揃う (PR #67)
- ✅ community standards (LICENSE / README / CoC / Contributing / ISSUE_TEMPLATE / PR_TEMPLATE) が揃う (PR #67)
- ✅ `flutter analyze` / `flutter test` / CI が緑 (PR #67 時点で 642 緑 / 1 skipped)
- ✅ GitHub の「Insights → Community Standards」で 100% 達成 (2026-05-27、`gh api .../community/profile` で `health_percentage: 100` 確認)
- ~~**GitHub Support による sensitive data removal 完了** (T8.5 → T8.6 で 404 確認)~~ → **2026-05-27 撤回** (T8.5/T8.6 omit に伴い DoD から除外。理由は上記タスク表参照)
- ✅ Public 化済、シークレットウィンドウで Public URL アクセス成功 (2026-05-27)

### 検証

1. ✅ `flutter analyze --fatal-infos` / `flutter test` ローカル緑 (PR #67)
2. ✅ main merge 後 CI 緑 (PR #67 / #68 / #69)
3. ✅ GitHub Community Standards 100% (2026-05-27 確認)
4. ~~`gh api repos/Bonkoturyu/TimerUtility/contents/docs/opus-startup-prompt.md?ref=f2e46e3` が **404 を返す** (T8.6)~~ → **2026-05-27 omit**。本検証項目は撤回
5. ✅ シークレットウィンドウで Public URL アクセス → README 表示 / LICENSE バッジ表示 (2026-05-27、ユーザ確認済)
6. ✅ Pixel 6a 実機: 既存挙動に回帰なし (doc-only 変更のため回帰なし、PR #67 時点で確認済)

---

## Phase 11.9: Play 提出準備 (素材 + 配線)

**目的**: applicationId 変更・アイコン・Splash・keystore・プライバシーポリシー・ストア掲載素材を一気に揃える。ユーザ確認必須ファイルが密集するため、タスク単位で承認 → 編集 → commit を細かく回す。

### タスク

| # | タスク | 編集対象 | 確認必須 |
| --- | --- | --- | --- |
| T0 | **applicationId 変更** (`com.bonkotu.timer.timer_utility` → `io.github.bonkoturyu.timer_utility`)。[android/app/build.gradle.kts:25](../android/app/build.gradle.kts#L25) の `namespace` + applicationId、[android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) の receiver `android:name` 接頭辞、`MainActivity.kt` の package、Kotlin ディレクトリ移動、Pixel 6a 実機の旧 install 削除 + 新 install 動作確認 (Drift DB は新パスで再生成、テストデータで OK) | Native 一式 | **必須** |
| T1 | アイコン素材作成 (1024×1024 PNG + Adaptive Icon foreground / background + monochrome SVG/PNG) | `design/icon/` 新規 | 不要 |
| T2 | `flutter_launcher_icons` を dev_dependency 追加 + `flutter_launcher_icons.yaml` 設定 (adaptive_icon_background / foreground / monochrome 指定) | [pubspec.yaml](../pubspec.yaml) + 新規 yaml | **必須** (依存追加) |
| T3 | `flutter pub run flutter_launcher_icons` 実行 → `mipmap-*/ic_launcher*` + `mipmap-anydpi-v26/ic_launcher.xml` + monochrome drawable 自動生成、差分レビュー | Native res 大量改変 | **必須** |
| T4 | `AndroidManifest.xml` の `android:label` を `@string/app_name` 参照に変更 (`.gemini/styleguide.md` の「翻訳文字列のハードコード禁止」準拠)。`res/values/strings.xml` (default = en) / `res/values-ja/strings.xml` / `res/values-zh/strings.xml` / `res/values-b+zh+Hant/strings.xml` / `res/values-ko/strings.xml` に各言語のアプリ名を定義。`android:roundIcon` 追加 | [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) + `res/values*/strings.xml` 新規 5 件 | **必須** |
| T5 | `flutter_native_splash` を dev_dependency 追加 + `flutter_native_splash.yaml` (android_12 セクション必須) | [pubspec.yaml](../pubspec.yaml) + 新規 yaml | **必須** |
| T6 | `flutter pub run flutter_native_splash:create` 実行 → `values-v31/styles.xml` 等自動生成、既存 [android/app/src/main/res/values/styles.xml](../android/app/src/main/res/values/styles.xml) との差分マージ | Native res | **必須** |
| T7 | 実機 Pixel 6a で Splash → アイコン切替を 4 パターン (cold / warm / light / dark) 確認 | 検証のみ | — |
| T8 | `docs/privacy-policy.md` (日本語) + `docs/privacy-policy.en.md` (英語) 作成。骨子: 収集データなし / 共有データなし / GPS は世界時計の TZ 推定のみ非永続 / ローカル DB のみ / 8 権限の利用根拠 (Phase D 診断ログの取扱い含む) | `docs/` 新規 | **必須** (`docs/`) |
| T9 | `docs/_config.yml` (Jekyll 設定) 作成 → GitHub Pages 設定で Source = `docs/` 有効化、Privacy Policy の安定 URL を取得 | `docs/_config.yml` 新規 + GitHub Web | **必須** |
| T10 | `docs/play-store-listing.md` 作成: 短い説明 80 字 / 長い説明 4000 字 / What's new 500 字 / Data Safety 申告内容 / 対象年齢 / コンテンツレーティング自己評価質問への回答 / 8 権限の Play Console 用説明文 | `docs/` 新規 | **必須** (`docs/`) |
| T11 | スクリーンショット撮影 (Pixel 6a 実機 7 シナリオ: Stopwatch / Timer / 複数 Timer / Alarm List / 世界時計 / 設定 / アラーム鳴動)、横幅 1080 以上 | `design/screenshots/` | 不要 |
| T12 | `docs/release-signing.md` に upload keystore 生成手順を文書化 (`keytool` コマンド、validity 25 年以上、別アプリ流用禁止、Play App Signing 加入フロー)。**生成はユーザ手元で実施** | `docs/` 新規 | **必須** (`docs/`) |
| T13 | `android/key.properties.template` (storeFile / storePassword / keyAlias / keyPassword の雛形) をコミット。実体は [.gitignore:29](../.gitignore#L29) で除外済を再確認 | `android/` 新規 | **必須** (Native 隣接) |
| T14 | [android/app/build.gradle.kts:35-40](../android/app/build.gradle.kts#L35-L40) の release signingConfig を `key.properties` 経由に書換、TODO コメント解消 | [android/app/build.gradle.kts](../android/app/build.gradle.kts) | **必須** |
| T15 | `versionCode` / `versionName` を Play 用に bump (`pubspec.yaml` の `1.0.0+1` を `1.0.0+2` に) | [pubspec.yaml](../pubspec.yaml) | **必須** |
| T16 | README の "fork 時 applicationId 書換ガイド" を新 ID に追従更新 | [README.md](../README.md) | 不要 |
| T17 | `flutter build appbundle --release` ローカル成功、`bundletool` で APK 展開して実機 install テスト | — | — |
| T18 | BACKLOG.md / tasklist.md / docs/dev-log.md に Phase 11.9 完了記録を追記 | `docs/` + ルート md | **必須** (`docs/`) |

### 進捗 (2026-06-15 同期)

- [x] T0: PR #72 で applicationId / MethodChannel 移行、Pixel 6a 8 シナリオ確認
- [x] T1〜T6: PR #77 の事前配線後、PR #91 (`954eea2`) で素材投入・
  launcher / themed icon / light・dark Splash リソース生成
- [ ] T7: Pixel 6a で cold / warm / light / dark と Themed Icon を実機確認
- [x] T8: Privacy Policy 日英草稿作成済み
- [x] T9: GitHub Pages 有効化と安定 URL 確認（Source = `main` / `/docs`。PR #96 / #97 で `docs/index.md` 追加 + Jekyll/Liquid build error 修正済。登録用 URL: `https://bonkoturyu.github.io/TimerUtility/privacy-policy`）
- [x] T10: Play Store listing / Data Safety 草稿作成済み
- [x] T11: 512 px icon と 1024x500 Feature Graphic は PR #91 で完了。
  Pixel 6a スクリーンショット 7 シナリオも ja / 1080×2400 で撮影し、
  `design/screenshots/phone/ja/` に配置済み。
- [x] T12: release signing 手順書作成済み
- [ ] T13〜T18: signing 配線、version bump、AAB 検証、完了記録

PR #91 検証: `flutter analyze`、`flutter test` (673 passed / 1 skipped)、
`flutter build apk --debug`、`dart run tool/check_translations_doc.dart` 成功。
実機表示確認は PR 本文の「残確認」に記載されており未完。

### DoD

- 実機 Pixel 6a で新 applicationId + 新アイコン + Android 12+ SplashScreen が cold start で正しく表示
- `flutter build appbundle --release` がローカル成功、サイズ計測済
- Privacy Policy が GitHub Pages の安定 URL で公開
- Data Safety 申告草稿が `docs/play-store-listing.md` にレビュー可能形で揃う
- upload keystore はユーザ手元、`key.properties` は gitignore 除外、template のみ commit
- 全テスト緑、回帰なし

### 検証

1. `flutter analyze` / `flutter test` 緑
2. `flutter build appbundle --release` 成功
3. 実機 Pixel 6a で `adb install` 後、cold start アイコン + Splash 確認、8.5 follow-up シナリオ (アラーム単音化) 回帰なし、Phase 6 FullScreenIntent 3 パターン回帰なし
4. Privacy Policy URL を HTTPS でモバイルブラウザ表示、折返し OK
5. 旧 applicationId のアプリが Pixel 6a に残らないこと (uninstall 確認)

---

## Phase 11.10: Play 提出本体

**目的**: Play Console 操作 + CI 拡張 + 段階リリース。外部仕様の最新確認を伴うため独立 Phase。

### タスク

| # | タスク | 編集対象 | 確認必須 |
| --- | --- | --- | --- |
| T1 | Play Console アカウント開設 ($25) + Play App Signing 加入 + アプリ作成 (パッケージ名 = `io.github.bonkoturyu.timer_utility`) | Play Console Web | **必須** |
| T2 | **WebFetch で公式仕様裏取り** ([CLAUDE.md:25-44](../CLAUDE.md#L25-L44) ソース信用原則): Data Safety フォーム / Play App Signing 加入要件 / Internal Testing 人数・期間 / 新規 Personal developer account 向け Closed Testing 12 testers・14 日連続 opt-in 要件 / Adaptive Icon monochrome 必須化時期 / 現行要求 target SDK / SCHEDULE_EXACT_ALARM + USE_FULL_SCREEN_INTENT 事前申請審査の有無 / Pixabay Content License 2024 改定影響 | 読み取りのみ | — |
| T3 | T2 結果を `docs/play-store-listing.md` に反映、必要なら Phase 11.9 の決定 (targetSdk 固定値・権限申告文言) を差し戻し再修正 | `docs/play-store-listing.md` + 必要時 Native | **必須** |
| T4 | [android/app/build.gradle.kts:29-31](../android/app/build.gradle.kts#L29-L31) の `targetSdk = flutter.targetSdkVersion` の実 SDK 版数を確認、Play 要求と乖離があれば明示値固定 | [android/app/build.gradle.kts](../android/app/build.gradle.kts) | **必須** |
| T5 | aab ビルド → Play Console に手動 upload (Internal Testing track) | — | — |
| T6 | Internal Testing で 1-3 人 (ユーザ + 親しい人) 配信、最低 3 日動作確認 | — | — |
| T7 | Closed Testing or Open Testing の経路を T2 結果に従い判断・実施 | — | **必須** |
| T8 | Production Rollout (段階公開 5% → 20% → 50% → 100%) | — | **必須** |
| T9 | CI 拡張: `.github/workflows/release.yml` 新規 (tag push `v*.*.*` トリガで `flutter build appbundle`、upload key は GitHub Secrets `UPLOAD_KEYSTORE_BASE64` / `UPLOAD_KEY_PASSWORD` 等)。fastlane supply 連携は本 Phase 完了後の継続改善として保留 | [.github/workflows/release.yml](../.github/workflows/release.yml) 新規 | **必須** (`.github/workflows/`) |
| T10 | `docs/release-signing.md` に Play App Signing 加入の事後ログ追記 + BACKLOG.md / tasklist.md / docs/dev-log.md に Phase 11.10 完了記録 | `docs/` + ルート md | **必須** (`docs/`) |
| T11 | (任意) ProGuard/R8 オン化の再検討。オンにする場合は別 PR で `proguard-rules.pro` + 各 OSS の keep ルール + 全実機シナリオ回帰テスト | [android/app/build.gradle.kts](../android/app/build.gradle.kts) + 新規 | **必須** |

### DoD

- Internal Testing で実機 Pixel 6a + テスタ環境で 7 シナリオ全部 OK
- Data Safety / Content Rating / Target Audience すべて Play Console で「準備完了」
- Production rollout 開始
- GitHub Release tag → `release.yml` が aab を artifact 化

### 検証

1. Internal track の Play Store URL を実機でインストール → アイコン / 起動 / アラーム / 通知ロック画面 7 シナリオ
2. Play Console Pre-launch report (Firebase Test Lab) で警告ゼロ
3. GitHub Release tag を切って `release.yml` 動作確認
4. Production rollout 5% で 48 時間クラッシュ率を Play Console で監視

---

## 公開チェックリスト対応マップ

[docs/oss-publishing-notes.md](oss-publishing-notes.md) §5 との対応:

| oss-publishing-notes 項目 | 対応タスク |
| --- | --- |
| §5.1 README OSS 向け整備 (スクショ / ビルド / Architecture / License / "What's special" / fork ガイド) | 11.8-T1 / T2 + 11.9-T11 (実物スクショ) + 11.9-T16 (新 ID 追従) |
| §5.1 秘密情報 grep / commit author email チェック | 11.8-T8 |
| §5.2 `THIRD_PARTY_NOTICES.md` | 11.8-T3 |
| §5.2 ISSUE_TEMPLATE / PR_TEMPLATE | 11.8-T6 |
| §5.2 `CODE_OF_CONDUCT.md` / `CONTRIBUTING.md` | 11.8-T4 / T5 |
| §5.3 `publish_to: 'none'` 維持 | (変更なし) |
| §5.3 `CLAUDE.md` 公開維持 | (変更なし) |
| §5.4 手順 1-3 (README 加筆 / analyze・test 緑 / Public 化) | 11.8-T1〜T2 / DoD / T10 |
| §5.4 手順 4 (pub.dev publish) | 対象外 (アプリのため見送り) |

赤旗なし。oss-publishing-notes に未記載の Play 関連は Phase 11.9 / 11.10 で新規に補う。

---

## 保留論点 (Phase 11.10 着手前に裏取り)

CLAUDE.md ソース信用原則に従い、以下は計画段階で断定せず Phase 11.10-T2 で WebFetch:

1. Data Safety フォームの最新項目構成
2. Play App Signing の 2026 年加入フロー (新規アプリ強制か任意か)
3. Internal Testing 人数上限・期間
4. 新規 Personal developer account 向け Closed Testing 12 testers・14 日連続 opt-in 要件の Play Console 実画面確認
5. Adaptive Icon monochrome 必須化時期 (Android 13 themed icon との関係)
6. 現行 Play 要求 target SDK (Android 14 / 15 / 16 のどれが minimum か)
7. SCHEDULE_EXACT_ALARM + USE_FULL_SCREEN_INTENT の事前申請審査要否
8. Pixabay Content License 2024 改定とアプリ同梱再配布の現行解釈 ([docs/oss-publishing-notes.md:79-81](oss-publishing-notes.md#L79-L81))

---

## 全体検証

- Phase 11.8 完了時: GitHub Public 化、Community Standards 100%、回帰なし
- Phase 11.9 完了時: 新 applicationId + 新アイコンの aab がローカル build 成功、642 テスト緑、Privacy Policy 公開
- Phase 11.10 完了時: Production rollout 開始、CI 緑、Pre-launch report 警告ゼロ

---

## Critical Files

- [README.md](../README.md)
- [pubspec.yaml](../pubspec.yaml)
- [android/app/build.gradle.kts](../android/app/build.gradle.kts)
- [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml)
- [android/app/src/main/kotlin/](../android/app/src/main/kotlin/) (Phase 11.9-T0 で package 移動)
- [docs/oss-publishing-notes.md](oss-publishing-notes.md)
- [docs/architecture.md](architecture.md)
- [BACKLOG.md](../BACKLOG.md) / [tasklist.md](../tasklist.md) / [docs/dev-log.md](dev-log.md)
- [.github/workflows/release.yml](../.github/workflows/release.yml) (Phase 11.10-T9 で新規追加)
