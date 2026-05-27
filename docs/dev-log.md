# 開発ログ

本ファイルは `tasklist.md` および `BACKLOG.md` から移管された、完了済みの
タスク / Phase 実装ログ / Follow-up 対応の詳細記録。各 Phase の実装過程・
実機検証結果・仕様判断のスナップショットを保持する。

- 現在進行中のタスク: `tasklist.md`
- Phase 別の高レベル進捗管理: `BACKLOG.md`
- アーキテクチャ・ドメインモデル等の設計: `docs/` 配下の各文書

移管日:

- 2026-05-12: `tasklist.md` 1505 行 → 約 50 行に整理 (完了タスク詳細を本ファイルに集約)
- 2026-05-14: `BACKLOG.md` 790 行 → 316 行に整理 (完了 Phase 0〜10.5 の
  `[x]` チェックリスト・実機検証詳細を本ファイルに集約。BACKLOG.md は
  Phase ヘッダ + 1 行要約 + 進捗サマリ + 進行中/未着手 Phase の詳細のみ保持)

---

## Phase 11.9 サブ PR α — applicationId + MethodChannel rename (2026-05-27)

Phase 11.9 計画書 [docs/oss-and-play-release-plan.md](oss-and-play-release-plan.md)
の T0 (applicationId 変更) と事前検討メモ
[docs/phase-11.9-prep-notes.md](phase-11.9-prep-notes.md) §I.1 (MethodChannel
名移行) を 1 PR にまとめて実施。事前検討で確定した推奨案 A (T0 と同 PR で
MethodChannel rename + alarm_ringing_screen ハードコード解消) に従い、Native +
Dart + live docs を atomic に切替。

branch: `phase-11.9-alpha` (ベース: `phase-11.8-close-out` → Phase 11.8 完全
クローズ commit を含む)

### 変更内容

#### Native (Kotlin + Gradle)

- Kotlin ディレクトリ移動: `android/app/src/main/kotlin/com/bonkotu/timer/timer_utility/`
  → `android/app/src/main/kotlin/io/github/bonkoturyu/timer_utility/`
  (`git mv` で rename 検出、旧 `com/` 階層は空のため `rm -rf` で削除)
- `MainActivity.kt:1` package 宣言を `io.github.bonkoturyu.timer_utility` に
- `MainActivity.kt:23` `PERMISSION_CHANNEL` 定数を
  `io.github.bonkoturyu.timer_utility/permission` に
- `build.gradle.kts:9` `namespace` を `io.github.bonkoturyu.timer_utility` に
- `build.gradle.kts:25` `applicationId` を同じ値に
- `AndroidManifest.xml` は **触らず** (`.MainActivity` 相対参照 +
  `${applicationName}` プレースホルダ + flutter_local_notifications の
  third-party receiver は変更不要、事前検討メモ §B.1 で確認済)

#### Dart (MethodChannel 名 + refactor)

- `lib/infrastructure/platform/permission_channel.dart:11` `channelName` を新名に、
  dartdoc も追従
- `lib/presentation/screens/alarm_ringing_screen.dart:22-24` ハードコード
  `MethodChannel('com.bonkotu.timer/permission')` を
  `MethodChannel(PermissionChannel.channelName)` に refactor + import 追加
  (事前検討メモ §I.1 で確定した「ハードコード解消も同時実施」方針)
- `lib/infrastructure/permission/permission_handler_adapter.dart:9` dartdoc を新名に

#### Live docs (実装と乖離させたくない docs、事前検討メモ §B.3)

- `README.md` 3 箇所 (L88 Channel 名 / L205 applicationId 説明 / L219 fork
  ガイド Channel 名 + 推奨案) + Phase 11.9 移行予告ブロック削除 (移行完了したため)
- `docs/architecture.md:199` Kotlin ディレクトリ図の namespace 部分
- `docs/android-constraints.md` 2 箇所 (L362 / L421、`replace_all`)
- `docs/permissions.md:426` Channel 名 (`replace_all`)
- `docs/platform-channels.md` 約 22 箇所 (ベース名前空間 + 各 Channel 名 +
  Kotlin path 参照、`replace_all` 2 回で機械的に置換)

### 履歴 docs は据置 (事前検討メモ §B.4)

- `docs/dev-log.md` の Phase 1〜11 実装ログ内の旧 applicationId / Channel 名言及
- `docs/oss-publishing-notes.md` (L88 / L257) — 監査時点の記述
- `docs/oss-and-play-release-plan.md` — 移行計画自体で旧/新併記
- `docs/phase-11.9-prep-notes.md` — Phase 11.9 全件完了時点で削除予定
- `BACKLOG.md` Phase 6 ヘッダ要約 (歴史記述) + 過去の更新エントリ
- `tasklist.md` 過去の更新エントリ

### 検証

| 項目 | 結果 |
| --- | --- |
| `flutter analyze --fatal-infos` | ✅ No issues found! (9.4s) |
| `flutter test` | ✅ 642 passed / 1 skipped |
| `dart run tool/check_translations_doc.dart` | ✅ ARB 171 / Doc 171 aligned |
| Grep `com\.bonkotu\.timer` (live files) | ✅ hit 0 (履歴 docs のみ残存、§B.4 据置対象) |
| Grep `com/bonkotu/timer` (Kotlin path) | ✅ hit 0 (`phase-11.9-prep-notes.md` のみ、§B.4 据置) |

### Pixel 6a 実機検証待ち (ユーザ実施、事前検討メモ §B.6)

- [ ] `adb uninstall com.bonkotu.timer.timer_utility` で旧版削除
  (Drift DB / SharedPreferences は新 ID 下で再生成、テストデータ消える前提)
- [ ] `flutter run -d <device>` で新 ID build cold start
- [ ] Phase 6 FullScreenIntent 3 パターン回帰 (Doze / ロック / 通常)
- [ ] Phase 8.5 follow-up アラーム単音化回帰
- [ ] 通知 + アラーム + DB 動作確認

実機検証 OK → main マージはユーザ判断。

### 次の着手単位

**Phase 11.9 サブ PR β** (`phase-11.9-beta` 新規 branch):

- T1〜T3: アイコン素材作成 (1024×1024 + adaptive foreground/background +
  monochrome、事前検討メモ §I.2 で 3 層常時作成方針) + `flutter_launcher_icons`
  追加 (`^0.14.4`、事前検討メモ §A)
- T5〜T6: `flutter_native_splash` 追加 (`^2.4.7`) + `flutter pub run
  flutter_native_splash:create`
- T4: AndroidManifest `android:label` を `@string/app_name` 参照に +
  `res/values*/strings.xml` 5 言語作成 (`appTitle` と整合する `TimerUtility`
  統一、事前検討メモ §I.3)
- T7: Pixel 6a 実機 4 パターン確認 (cold / warm / light / dark)

`pubspec.yaml` 編集 + `flutter pub add` を含むため、ユーザ確認必須ファイル該当。

---

## Phase 11.8 完全クローズ — T10 (Public 化) 完了 (2026-05-27)

同日午前に T8.5/T8.6 omit 判断で T10 を unblock した後、ユーザが GitHub Settings
で T10 (Visibility = Public + Description + Topics 設定) を実施。Phase 11.8 完全
クローズ。Phase 11.9 サブ PR α (T0 + MethodChannel rename + live docs 追従) 着手
可能状態に到達。

### T10 実施結果 (gh api スナップショット)

`gh repo view --json visibility,description,repositoryTopics,url,isPrivate` 出力:

| 項目 | 値 |
| --- | --- |
| Visibility | **PUBLIC** (`isPrivate: false`) |
| URL | <https://github.com/Bonkoturyu/TimerUtility> |
| Description | "Multi-timer / alarm / world-clock for Android 16. Reference implementation of Flutter Clean Architecture + Android alarm constraints handling." |
| Topics (9 件) | `alarm` / `android` / `claude-code` / `clean-architecture` / `dart` / `drift` / `flutter` / `riverpod` / `timer` |

Description は Phase 11.8 計画書の想定 (Flutter Clean Architecture + Android alarm
constraints のリファレンス実装) と整合。Topics 9 件は discoverability 向けに
言語 / プラットフォーム / 機能 / アーキテクチャ / 由来の各カテゴリをカバー。

### 検証結果

| 項目 | 結果 | 確認方法 |
| --- | --- | --- |
| Public 化 | ✅ | `gh repo view --json visibility` → `"PUBLIC"` |
| Community Standards | ✅ **100%** | `gh api repos/Bonkoturyu/TimerUtility/community/profile` → `"health_percentage": 100` |
| 同梱 community files | ✅ | LICENSE (MIT) / README / CODE_OF_CONDUCT / CONTRIBUTING / PULL_REQUEST_TEMPLATE すべて検出 |
| シークレットウィンドウで Public URL アクセス | ✅ | ユーザ確認済 (本日、正しく表示確認) |
| `flutter analyze` / `flutter test` 回帰 | (doc-only のため未実行) | T1〜T9 PR #67 時点で 642 緑 / 1 skipped |

`community/profile` API 上 `issue_template: null` と表示されるが、これは API が
単一ファイル `.github/ISSUE_TEMPLATE.md` 形式のみを issue_template として認識する
仕様であり、ディレクトリ形式 `.github/ISSUE_TEMPLATE/{bug_report,feature_request}.md`
(PR #67 で配置済) は別経路で OK 判定されるため、health_percentage は 100% に到達。
GitHub Issues 画面でテンプレート選択 UI が正しく表示されることでも間接確認可能。

### Phase 11.8 全タスク最終状況

| # | タスク | 状態 |
| --- | --- | --- |
| T1〜T7 | README 再構成 / community files / pubspec metadata | ✅ PR #67 (2026-05-16) |
| T8 | 秘密情報 grep + commit author 全件確認 | ✅ PR #67 (hit 0) |
| T8.5 | GitHub Privacy team メール直送 (orphan commit cache 削除) | ⊘ **omit** (2026-05-27、11 日無反応 + 典型 PII ゼロ確認) |
| T8.6 | 申請完了後 404 確認 | ⊘ **omit** (T8.5 連動) |
| T9 | BACKLOG / tasklist / dev-log 反映 | ✅ PR #67 (T1-T8 範囲) + 本コミット (T10 完了反映) |
| T10 | GitHub Settings → Visibility = Public + Description / Topics | ✅ **完了 (2026-05-27)** |

### 文書更新 (本コミット)

- `docs/dev-log.md` (本ファイル): 本セクションを冒頭に追加
- `docs/oss-and-play-release-plan.md`: Phase 11.8 ヘッダに「完了 (2026-05-27)」
  マーカー追加、T10 行に達成内容 (Description / Topics 実値) 注記、DoD 各項目に
  達成チェック (T8.5/T8.6 omit 関連は前回コミット d18150b で打消し済)
- `BACKLOG.md`: 進捗サマリの Phase 11.8 行を「完了 (2026-05-27)」に書換、
  最終更新エントリを T10 完了内容で更新
- `tasklist.md`: Phase 11.8 進行中エントリを削除 (残作業ゼロ)、Phase 11.9
  エントリを「Phase 11.8 完了 → サブ PR α 着手可能」状態に更新、最終更新
  エントリを T10 完了内容で書換

### 次の着手単位

**Phase 11.9 サブ PR α** (`phase-11.9-prep` branch ベースで新規 branch):

- T0: applicationId `com.bonkotu.timer.timer_utility` → `io.github.bonkoturyu.timer_utility`
  への変更 (Native build.gradle.kts + AndroidManifest.xml + MainActivity.kt の
  package 移動 + Kotlin ディレクトリ移動)
- 同 PR で MethodChannel 名 `com.bonkotu.timer/permission` →
  `io.github.bonkoturyu.timer_utility/permission` を rename
  (alarm_ringing_screen.dart のハードコード解消含む)
- live docs (CLAUDE.md / docs/platform-channels.md 等で MethodChannel 名 / package
  名を参照している箇所) を新 ID に追従

Native (Kotlin / AndroidManifest) + pubspec.yaml + build.gradle.kts の編集を
含むため、CLAUDE.md「編集時にユーザー確認が必要なファイル」に該当。タスク
単位で承認 → 編集 → commit の細かいループで進行。

---

## Phase 11.8 T8.5 / T8.6 omit 決定 — Public 化のブロック解除 (2026-05-27)

Phase 11.8 残作業の T8.5 (GitHub Privacy team へのメール直送による orphan commit
`f2e46e3` の cache 削除申請) / T8.6 (申請完了後の 404 確認) を **omit** することを
ユーザー判断で確定。T10 (GitHub Settings → Visibility = Public) を T8.6 非依存に
変更して進行解除する。

### 経緯

- 2026-05-16: PR #66 (リリース計画策定) の T8.5 指示に従い、ユーザーが GitHub
  登録メールから `privacy@github.com` 宛に削除申請メールを直送
- 2026-05-17: 同日に T8.6 検証 (`gh api repos/Bonkoturyu/TimerUtility/contents/docs/opus-startup-prompt.md?ref=f2e46e3`)
  で 200 OK (sha `838c0fa45841c94c6887170fcfe1c1a923402e99` / size 7311 bytes)
  確認、cache 削除未処理を確認
- 2026-05-17 〜 2026-05-27 (本日): 11 日経過するも `privacy@github.com` から
  **auto-ack / ticket 番号 / bounce 通知すべてゼロ**。Gmail spam / promotions /
  all-mail / mailer-daemon すべて検索 hit ゼロ (ユーザー側確認済)。送信済み
  フォルダで宛先・本文ともに正常送信を確認
- 2026-05-27: ユーザー判断で orphan commit `f2e46e3` の実物内容を再確認。
  典型 PII ゼロを確定、T8.5/T8.6 omit を決定

### orphan commit f2e46e3 残留内容の実物確認結果

`gh api repos/Bonkoturyu/TimerUtility/contents/docs/opus-startup-prompt.md?ref=f2e46e3 --jq '.content' | base64 -d`
で取得した本文 76 行を sanitization 後 (commit `5734ad0`) との diff で比較した
結果、orphan commit 側だけに残っている個人プロファイル情報は **§2「ユーザーの
前提スキル」セクション** のみ。具体的内容:

| カテゴリ | 露出していた内容 |
| --- | --- |
| 属性 | 「C/C++/C# で 5 年以上の実務経験を持つ現役エンジニア」 |
| 使用言語 | C/C++/C#、Dart/Flutter、TypeScript/JavaScript、Python、GDScript |
| Web 開発スタック | Next.js (App Router) / React / NextAuth.js、Google OAuth 2.0 + JWT、Google Drive REST API 連携 |
| ゲーム/VR/3D | Unity (VRChat / lilToon / AudioLink shader)、Godot、UE5、Blender、SteamVR オーバーレイ、OpenVR Skeletal Input、DXGI Desktop Duplication |
| 自宅 PC 構成 | Ryzen + マルチ GPU、`CUDA_VISIBLE_DEVICES` UUID 指定で GPU 分離、`OLLAMA_HOST=0.0.0.0` で LAN 経由 LLM サービング、Windows/Linux 両方のコマンドライン |
| AI/ML スタック | Ollama、Continue.dev (config.yaml v1 + secrets.yaml)、ASR (faster-whisper + Silero VAD)、OCR (PaddleOCR + ONNX Runtime)、機械翻訳 (OPUS-MT / madlad400 / DeepL / Google / Azure / MyMemory BYOK)、OSS ライセンス判定 (NLLB-200 CC-BY-NC-4.0)、Claude Code (Opus/Sonnet)、GitHub Copilot、Gemini Flash routing/quota、GAS + Gemini マルチモーダル |

**含まれていなかった情報** (= 安全側):

- 実名 / 住所 / 電話番号 / メールアドレス
- API キー / トークン / パスワード / 認証情報
- 写真 / 顔識別情報
- 給与 / 雇用先 / 学歴
- ファイナンシャル情報

### リスク評価

| 観点 | 評価 |
| --- | --- |
| 個人特定性 | **低** (氏名・連絡先がないため `@Bonkoturyu` 本人と特定不可) |
| 悪用可能性 | **低** (API キー・認証情報ゼロのため、なりすまし / 侵入リスクなし) |
| 識別子結合リスク | **中** (`@Bonkoturyu` GitHub プロフィールと紐付けたとき、自宅 PC 構成 + 使用 SaaS の組合せはユニーク性高め。ただし GitHub プロフィール / 公開リポジトリで既に推測可能な範囲) |
| 到達難度 | **やや低** (`?ref=f2e46e3` という SHA を知らないと API で取得不可、orphan commit は通常の web crawler では辿りにくい) |
| Privacy team 挙動 | 11 日無反応 = GitHub 視点でも緊急性が低い判定の傍証 |

### 決定とその影響

- **T8.5 omit**: Privacy team 申請の完了は **待たない**。申請メール自体は
  既送信のまま放置 (削除されたら儲け、されなくても問題ない)
- **T8.6 omit**: 404 確認は本 Phase の DoD から外す。今後 Privacy team が
  事後処理で 404 化する可能性はあるが、blocking 条件ではない
- **T10 unblock**: 「T8.6 の確認が取れていることが前提」を撤回し、T10 を
  T8.6 非依存に変更。T1〜T9 main マージ済 + T9 完了 (本コミット) のみが
  T10 の前提

### 文書更新

- `docs/oss-and-play-release-plan.md` Phase 11.8 セクション:
  - T8.5 / T8.6 行を打消し線で omit 化、判断根拠を本 dev-log への参照付きで明記
  - T10 行の「T8.6 の確認が取れていることが前提」記述を撤回し、T9 完了 +
    Phase 11.8 PR (T1-T9) main マージ済のみを前提とする旨に書換
  - DoD / 検証セクションの T8.5/T8.6 関連項目も打消し線付きで撤回
- `BACKLOG.md` / `tasklist.md`: Phase 11.8 進行中エントリを「T10 待ち」状態に更新
- ローカルメモリ `feedback_filter_branch_github_cache.md` (リポジトリ外、
  開発者個人の `~/.claude/` 配下、本リポジトリからは参照不能):
  「コスト・ベネフィット例外」セクションを末尾追加。Privacy team 長期無反応 +
  典型 PII ゼロのとき omit する判定手順を将来再利用可能な形で固定化

### 将来再利用ポイント (memory に固定化)

- Privacy team 申請から 48-72h 経過しても auto-ack すらない場合、まず orphan
  commit 残留 content の実物確認 (`gh api .../contents/<path>?ref=<sha>`) を行う
- 典型 PII (氏名 / 連絡先 / 住所 / financial / credentials / API キー / 写真) が
  **ゼロ** であれば、ユーザー本人のリスク許容と組み合わせて「申請放置 + Public 化
  先行」を合理的選択肢として持つ
- それ以外 (技術スキル / 自宅 PC 構成 / 使用 SaaS / 個人ブログ程度の粒度) のみで
  ユニーク性のみが残るケースは、GitHub プロフィールから推測可能な範囲かで併せて
  評価
- 並行して Privacy team へのフォローアップは送る (削除されたら儲け、されなく
  ても blocking なし)

### 次の Phase 11.8 着手単位

T10 (GitHub Settings → Visibility = Public + Description / Topics 設定) はユーザー
作業 (不可逆)。完了で Phase 11.8 クローズ、サブ PR α (Phase 11.9-T0 +
MethodChannel rename + live docs 追従) 着手。

---

## Phase 11.9 事前検討 + 実アーティファクト草稿 (2026-05-17)

Phase 11.8 T8.5 GitHub Privacy team 申請 (2026-05-17 ユーザ送信済) の返信待ち期間を
活用し、Phase 11.9 (Play 提出準備) で必要になる事前判断項目と実アーティファクトを
branch `phase-11.9-prep` で先行作成。Native / pubspec.yaml は触らずに `docs/` 配下の
新規 md 5 件のみで完結。

### 経緯と目的

- Phase 11.8 PR #67 main マージ後、T8.5 (Privacy contact form → `Other` 経由で
  `privacy@github.com` メール直送) はユーザが実行済だが、Privacy team の返信は
  数営業日かかる想定。T8.6 (`gh api repos/.../contents/docs/opus-startup-prompt.md?ref=f2e46e3`
  が 404 を返すかの確認) は 2026-05-17 時点で 200 OK 継続 (sha `838c0fa...` /
  size 7311 bytes)、cache 削除未処理
- 待機期間中に Phase 11.9 を機械的に進めるための地ならしを完了させ、返信到着 →
  T10 (Public 化) 直後にすぐ Phase 11.9-T0 へ移行できる状態を作る
- 計画書 [docs/oss-and-play-release-plan.md](oss-and-play-release-plan.md) Phase
  11.9 セクションの T0〜T18 のうち、Native / pubspec.yaml を触らない範囲を
  すべて先行

### 作成物

| ファイル | 役割 | 寿命 |
| --- | --- | --- |
| [docs/phase-11.9-prep-notes.md](phase-11.9-prep-notes.md) | 事前検討 4 件 (A 依存版数 / B applicationId 影響範囲 grep / C 5 言語アプリ名 / G アイコン仕様) + サブ PR α/β/γ 分割案 + 残論点 4 件を集約 | Phase 11.9 全件完了時点で削除予定 (内容は実タスクに消化) |
| [docs/privacy-policy.md](privacy-policy.md) | プライバシーポリシー (日本語) — 8 権限の利用根拠 / GPS 一時利用方針 / 診断ログ取扱い / Data Safety 申告と整合 | 永続。Phase 11.9-T9 で GitHub Pages 公開 |
| [docs/privacy-policy.en.md](privacy-policy.en.md) | プライバシーポリシー英語版 | 永続 |
| [docs/play-store-listing.md](play-store-listing.md) | Play Console 提出素材集約 — 短い説明 80 字 / 長い説明 4000 字 / What's new 500 字 / Data Safety 申告内容 / Content Rating 自己評価 / 8 権限 Play Console 用説明文 / スクリーンショット 7 シナリオ / 連絡先 | Phase 11.10 提出後も維持 (継続更新) |
| [docs/release-signing.md](release-signing.md) | upload keystore 生成 / `key.properties` 配置 / `build.gradle.kts` 配線 / Play App Signing 加入 / CI 自動署名 / セキュリティ注意 | 永続。Phase 11.10-T2 で公式仕様裏取り後に未確定項目を確定 |

### 採用方針 / 確定事項

- **B applicationId 影響範囲**: `git grep "com\.bonkotu\.timer"` 結果から、Native
  3 ファイル (`build.gradle.kts` 2 行 / `MainActivity.kt` package + Kotlin
  ディレクトリ移動) + ライブドキュメント追従 (`README.md` / `BACKLOG.md` /
  `docs/architecture.md` / `docs/android-constraints.md` / `docs/permissions.md` /
  `docs/platform-channels.md`) の影響範囲を確定。`AndroidManifest.xml` は編集不要
  (PR #67 レビューで確認済)、Dart 側は MethodChannel 名移行を採用するか次第で
  `permission_channel.dart` + `alarm_ringing_screen.dart` の 2 ファイルが影響、
  test/`pubspec.yaml` の Dart パッケージ名 `timer_utility` は applicationId と
  独立で変更不要
- **C 5 言語アプリ名**: 全 5 言語 (ja / en / zh / zh_Hant / ko) で `TimerUtility`
  統一案を確定。既存 ARB の `appTitle` キーが全言語 `TimerUtility` で揃っており、
  OS 上のアイコン名 = アプリ内表示名のブランド統一を維持
- **G アイコン仕様**: 知識ベースで Adaptive Icon (108×108 dp、安全ゾーン 72×72 dp、
  1024×1024 PNG 推奨) / Themed Icon (monochrome、知識カットオフ時点では任意) /
  Play Store 512×512 を草稿。WebFetch で developer.android.com / m3.material.io
  の対象 URL がすべて 404 を返したため、ソース信用原則に従い「Phase 11.10-T2 で
  再裏取り必須」と明示
- **CoC / privacy-policy の連絡窓口**: Phase 11.8 で確立した `@Bonkoturyu`
  GitHub Issues + GitHub プロフィール contact の二段案内に統一
- **Data Safety 申告**: `docs/privacy-policy.md` §2-6 に基づき「No data collected」
  「No data shared」両方申告 (Phase 11.10-T2 で Play Console の 2026 年現行フォーム
  構成と突合せて確定)
- **release.yml CI 自動署名**: Phase 11.10-T9 で実装、`UPLOAD_KEYSTORE_BASE64` +
  3 パスワード Secret 構成は `docs/release-signing.md` §6 に記録

### キックオフ判断 4 件 (2026-05-17 ユーザ承認済、`phase-11.9-prep-notes.md` §I)

本セッション (2026-05-17) のキックオフ判断で、`phase-11.9-prep-notes.md` §I に
当初「残論点」として置いていた 4 件を、ユーザ承認のもと全件推奨案 A で確定:

1. **B.2 MethodChannel 名移行 = T0 同 PR**: `com.bonkotu.timer/permission` →
   `io.github.bonkoturyu.timer_utility/permission` をサブ PR α (T0 と同 PR) で
   移行。`alarm_ringing_screen.dart` のハードコードを `PermissionChannel.channelName`
   定数参照に refactor も同梱。理由: 純粋リネーム + 1 定数化で済む低リスク作業、
   中途半端な期間 (新 applicationId + 旧 Channel prefix) を作らない、fork
   ガイドが一本道
2. **G.2 monochrome layer = 常に作る**: Phase 11.9-T1 (アイコン素材作成) で
   foreground + background + monochrome layer の 3 層セットを設計。理由:
   monochrome 素材 1 件追加コスト (時計シルエット VectorDrawable) は低い、
   Android 13+ themed icon ランチャー UX 改善、Play Store 必須化の保険
3. **C.2 アプリ名 = 全 5 言語 `TimerUtility` 統一**: 既存 ARB の `appTitle` が
   5 言語すべて `TimerUtility` 統一済の運用と整合。`TimerUtility` は造語の固有
   ブランドで現地表記の機械翻訳は不自然になりがち、Play Store 検索ノイズ回避、
   後戻り可能 (将来 strings.xml に現地表記を追加すれば良い)
4. **H サブ PR 分割 = α/β/γ 3 PR 案**: 計画書 §H 提示案そのまま。α (T0 +
   MethodChannel + live docs) / β (T1-T7 アイコン+Splash+strings.xml+Pixel 6a
   検証) / γ (T8-T18 privacy-policy GitHub Pages + listing + signing + aab)
   の 3 段。理由: 各 PR が独立 concern、Pixel 6a 実機検証を α 後 + β 後の 2 回
   に分散して問題発見早期化、γ は signing / Play Console 連携を α/β 安定後に
   着手

### 検証

- `dart format --set-exit-if-changed .` — 254 ファイル / 変更 0
- `flutter analyze --fatal-infos` — No issues found
- `dart run tool/check_translations_doc.dart` — ARB (ja=171, en=171) / docs (171) 一致
- `flutter test` は doc-only のため CI 任せ (PR #67 で 642 緑 / 1 skipped を確認済)

### 次の Phase 11.8 / 11.9 着手単位

1. Privacy team 返信受領 → T8.6 で `gh api .../ref=f2e46e3` が 404 化を確認
2. T10 (GitHub Settings → Visibility = Public) 実施 → Phase 11.8 完全クローズ
3. キックオフで `phase-11.9-prep-notes.md` §I 残論点 4 件確定
4. Phase 11.9-T0 (applicationId 変更 + Pixel 6a 実機検証) からサブ PR α 着手

---

## Phase 11.8 OSS 公開準備 (T1〜T9 着手、2026-05-16)

Phase 11.8 計画書 [docs/oss-and-play-release-plan.md](oss-and-play-release-plan.md)
(PR #66 で承認済) の残タスクのうち、Claude 単独で完結可能な T1〜T9 を一括着手。
branch `phase-11.8-oss-prep` で実装。T8.5 (GitHub Privacy team へのメール直送) /
T8.6 (申請完了後の 404 確認) / T10 (GitHub Public 化) はユーザ作業のため本セッション
外で実施。

### 着手内容

| # | タスク | 成果物 |
| --- | --- | --- |
| T1+T2 | README 再構成: Screenshots プレースホルダ / Build & Run / Architecture 概要 + docs リンク表 / fork 時 applicationId 書換ガイド / "What's special about this project?" (日本語要約 4 行 + 英語本文 / [docs/oss-publishing-notes.md:225-242](oss-publishing-notes.md#L225-L242) 草案を流用) | [README.md](../README.md) |
| T3 | `THIRD_PARTY_NOTICES.md` 新規 (production / dev / Native / 同梱アセットの 4 セクション + LICENSES.md リンク) | [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) |
| T4 | `CONTRIBUTING.md` 新規 (CLAUDE.md の禁止事項 / テストポリシー / メンテナ承認必須ファイル / コミット規約 / ソース信用原則 を OSS 投稿者向けに要約) | [CONTRIBUTING.md](../CONTRIBUTING.md) |
| T5 | `CODE_OF_CONDUCT.md` 新規 (Contributor Covenant 2.1 を [www.contributor-covenant.org](https://www.contributor-covenant.org/version/2/1/code_of_conduct/code_of_conduct.md) から WebFetch、Enforcement の連絡窓口は `@Bonkoturyu` GitHub Issues 経由) | [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md) |
| T6 | `.github/ISSUE_TEMPLATE/bug_report.md` + `feature_request.md` + `.github/PULL_REQUEST_TEMPLATE.md` 新規 | [.github/](../.github/) 配下 |
| T7 | `pubspec.yaml` に `homepage` / `repository` / `issue_tracker` フィールド追加 (`publish_to: 'none'` は維持) | [pubspec.yaml](../pubspec.yaml) |
| T8 | 秘密情報 grep + commit author 全件確認 (read-only) | hit 0 / author `BON <43852430+Bonkoturyu@users.noreply.github.com>` 1 件のみ (GitHub 提供 noreply email、公開可) |
| T9 | BACKLOG.md / tasklist.md / 本ファイルに完了記録追記 | 本セッションの編集 |

### 採用方針 / 決定事項

- **CoC の連絡窓口**: 個人 email を CoC に直接記載せず、`@Bonkoturyu`
  GitHub Issues 経由 + GitHub プロフィール contact の二段案内とした。
  個人 email 公開を避けつつ、報告経路は確保
- **applicationId**: README の fork ガイドは現状値 `com.bonkotu.timer.timer_utility`
  を記載し、Phase 11.9-T0 で `io.github.bonkoturyu.timer_utility` 移行後に
  追従更新 (Phase 11.9-T16 で計上済)
- **Screenshots**: Phase 11.9-T11 で Pixel 6a 実機撮影予定のため、本 Phase では
  プレースホルダ表示のみ
- **markdownlint MD013 (line-length >80)**: README で 8 件警告が出たが、既存
  docs (CLAUDE.md / BACKLOG.md) も超過行多数 + markdownlint は CI 非強制のため、
  リンク密度の高い行のみ最低限の折返しで対応し、表行は据置

### 検証

- `dart format --set-exit-if-changed .` → 254 ファイル、変更 0
- `flutter analyze --fatal-infos` → No issues found
- `flutter test` → 642 件緑 (1 skipped、Phase 11 ローカライズ後の維持値と一致)
- `dart run tool/check_translations_doc.dart` → ARB (ja=171, en=171) と
  `docs/translations.md` (171) のキー集合一致確認 OK

### 残作業 (本セッション外)

- **T8.5**: GitHub Privacy team (`privacy@github.com`) へメール直送で、merged
  PR #57 が orphan commit `f2e46e3` 経由で `docs/opus-startup-prompt.md` 旧版を
  cache に残している件の削除申請。本人が自分のリポジトリから自身の個人情報を
  削除するケースのため [Private Information Removal Policy](https://docs.github.com/en/site-policy/content-removal-policies/github-private-information-removal-policy)
  経由、[Privacy contact form](https://github.com/contact/privacy) で `Other`
  を選ぶと `privacy@github.com` メール直送案内に分岐する。GitHub 登録メール
  から送信、リポジトリ名 `Bonkoturyu/TimerUtility` (Private) / 影響 PR 1 件 (#57)
  / First Changed Commit `f2e46e3` / 対象 `docs/opus-startup-prompt.md` /
  LFS なし を本文に明記。**Public 化 (T10) 前に完了必須**
- **T8.6**: T8.5 申請完了後、
  `gh api repos/Bonkoturyu/TimerUtility/contents/docs/opus-startup-prompt.md?ref=f2e46e3`
  が 404 を返すことを確認
- **T10**: GitHub Settings → Visibility を Public に変更 + Description / Topics
  設定。T8.6 完了が前提

### 次の Phase 11.8 着手単位

T8.5 のメール送信〜T8.6 確認はユーザ手元の作業。完了後、別 PR (or 同 PR の
本 commit 追加) で T10 を実施し Phase 11.8 完全クローズに進む。
GitHub Community Standards 100% の最終確認は T10 後に Insights タブで実施。

---

## docs/translations.md Phase 11 close out 一括同期 (2026-05-16)

Phase 11 ローカライズ系の最後の追従作業として、ARB と `docs/translations.md` の
差分を解消。tasklist.md の Follow-up エントリ「docs/translations.md 一括同期」を
クローズ。

### 経緯と目的

- A-3 (PR #61) で zh / zh_Hant / ko ARB の本格翻訳を完了した際、
  `docs/translations.md` は ja / en 2 列ミラーを据置きで運用切替 (方針 a) し、
  当時の close out 時点で `homeOpen*` / `timerListEmptyHint` / `alarmListEmptyHint`
  の 3 グループのみ部分同期を完了。残る Phase 9.5 以降追加キー (clock 系 /
  通知 channel 系 / `presetSheetManageButton` / permission severity / 言語切替 /
  診断ログ) は「Phase 11 close out PR で一括同期予定」として持ち越していた
- 本セッションで残 33 キー (138 → 171 / ja arb 総キー数と完全一致) を一括追加し、
  冒頭「既知の差分」段落と末尾「中国語 / 韓国語の experimental flag が立った
  段階で `zh` / `ko` 列を追加する」記述 (5 列ミラー不採用方針 a と矛盾) を解消

### 追加内容

| 種別 | セクション | 追加キー数 | 出典 |
| --- | --- | --- | --- |
| 既存セクション拡張 | 権限バナー | 3 (`permissionBannerSeverity{Critical,Recommended,Supplementary}`) | Phase 11 CVD / PR #39 |
| 既存セクション拡張 | プリセット選択シート | 1 (`presetSheetManageButton`) | プリセット管理発見性改善 / PR #35 |
| 既存セクション拡張 | 設定画面 (Phase 11) | 12 (`settingsLanguage{Label,System,DialogTitle}` + `settingsSectionDiagnostics` + `settingsDiagnostic{LogToggle,LogToggleDescription,ShareLogs,ShareLogsSubject,ShareLogsDescription,ShareLogsInProgress,ShareLogsSuccess,ShareLogsError}`) | Phase 11 言語切替 (PR #45) + Phase D 診断ログ (PR #49 / #52 / #51) |
| 新セクション | 世界時計（Phase 10.5） | 11 (`clockAppBarTitle` / `clockListAddFab` / `clockDesignSegment{Analog,Digital,Compact}` / `clockEntryEditAppBarTitle` / `clockEntryEditSection{Pinned,Available}` / `clockEntryEditLimitReached` / `clockEntryEditCatalogEmpty` / `clockEmptyHint`) | Phase 10.5 世界時計 |
| 新セクション | 通知 channel（Phase 11 A-2） | 6 (`notificationAlarmRinging{Title,Body}` / `notificationTimerAlarmChannel{Name,Description}` / `notificationTimerCompletedChannel{Name,Description}`) | A-2 (PR #59) の通知 channel i18n |

### 整合修正

- 冒頭 L18-22「既知の差分」段落を「同期状態」段落に書き換え (一括同期完了の旨)
- 末尾「中国語 / 韓国語の experimental flag が立った段階で `zh` / `ko` 列を追加する
  （Phase 8.5 ロードマップ）」を「zh / zh_Hant / ko は本書に載せない (5 列ミラー
  不採用 / A-3 2026-05-16) — 翻訳本体は ARB ファイルを直接参照する」に置換
- 権限バナーセクションに「CVD 対応として方針 (a) 冗長表示を採用 (Phase 11 / PR #39)」の
  説明段落を補記
- 通知 channel 新セクションに `NotificationStrings` の locale 切替メカニズムを補記

### 検証

- `Compare-Object` で ARB ja キーと translations.md 内コードフェンス済キー名の集合一致を確認:
  ARB 171 キー / Doc 171 キー、差分なし
- `flutter analyze` / `flutter test` で既存 642 テスト緑 (1 skipped) を維持

### 残作業

- CI で diff チェック自動化は **本タスクのスコープ外**。tasklist.md の
  「CI で diff チェックする方向は別途検討」記述は据置
- Phase 11 残作業はこれで「アプリアイコン・スプラッシュ」「Play Store 提出準備」の
  2 件のみ。Phase 11 ローカライズ系は **全件クローズ**

---

## A-3 zh / zh_Hant / ko ARB 本格翻訳 完了 + Pixel 6a 実機検証完了 (2026-05-16)

Phase 11 ローカライズ残作業の最後の山「中国語簡体字 / 繁体字 / 韓国語の本格翻訳」を
PR #61 で実装・マージ。Phase 11 のローカライズ系サブタスクはこれで全件クローズし、
残るは「アプリアイコン・スプラッシュ」と「Play Store 提出準備」のみ。

### 経緯と目的

- Phase 11 言語切替 UI (PR #45) と F-9 (`localeResolutionCallback` で en
  フォールバック) で UI 基盤は整っており、A-2 (PR #59) で通知 channel 名の
  i18n 経路も完成。zh / zh_Hant / ko の ARB ファイル自体は未作成で、
  experimental flag を立てても en にフォールバックしてしまう状態だった
- Auto セッションを別途立ち上げ、PR #61 で 3 言語 × 172 翻訳キー = 516 翻訳を
  一括投入。本格翻訳に踏み込むため、Auto 指示書
  (`auto-prompt-a3-zh-ko-translation.md`、ユーザのローカル `c:\tmp\` 配下、
  リポジトリ未追跡) を事前にユーザ作成し、翻訳指針 (用語選定、全角句読点、
  CLDR plural rule、`docs/translations.md` の 5 列ミラー不採用方針 a など)
  を凍結してから着手

### 採用方針

- `lib/l10n/app_ja.arb` (`l10n.yaml` の `template-arb-file`) を唯一の
  メタ情報ソースに据えて、新規 ARB は翻訳テキストのみ持つ薄い構造
- ICU plural は CLDR plural rule に従い、zh / zh_Hant / ko ともに
  `other` 1 分岐のみ (`presetTemplateReplaceLimitWarning` の `=0{}` 空分岐
  は呼び出し側互換のため維持)
- `permissionBannerSeverity*` の `[重要]` / `[推奨]` / `[補助]` 角括弧
  ラベルは ARB で翻訳、Dart 側 prefix 機構 (F-10) はそのまま動作
- 用語: zh = `闹钟 / 定时器 / 秒表 / 稍后提醒 / 预设` (Android 標準寄り) /
  zh_Hant = `鬧鐘 / 計時器 / 碼錶 / 貪睡 / 預設` (台湾標準寄り) /
  ko = `알람 / 타이머 / 스톱워치 / 다시 알림 / 프리셋` (대한민국 표준어)
- `docs/translations.md` は ja / en 2 列ミラー据置 + 3 言語は ARB 直接参照
  への運用切替 (方針 a)。5 列ミラー化はレビュー性低下で不採用

### 実装 PR と commit 構成

| commit | 内容 |
| --- | --- |
| `423feff` | 初版: `app_zh.arb` / `app_zh_Hant.arb` / `app_ko.arb` 3 ファイル新規作成 (各 172 翻訳キー)、`flutter gen-l10n` で `AppLocalizationsZh` / `AppLocalizationsZhHant` / `AppLocalizationsKo` を生成 (`app_localizations.dart` の `supportedLocales` / `lookupAppLocalizations` も自動更新)、`BACKLOG.md` / `tasklist.md` / `docs/translations.md` を方針 a で更新 |
| `652d236` | review round 1 対応: **重要 bug fix** — `lib/main.dart` の `_experimentalSupportedLocales` を `Locale('zh', 'Hant')` (countryCode 形式) から `Locale.fromSubtags(scriptCode: 'Hant')` に修正。`test/locale_resolution_test.dart` に「production list が scriptCode 形式で zh_Hant を宣言」する unit test を追加。Gemini 指摘 10 件 (韓国語スペース整合、中文の半角句読点 → 全角、`・` → `/`、半角括弧 → 全角、半角コロン → 全角) を全件適用。`docs/translations.md` の stale 行 (`homeOpen*` / `*EmptyHint`) を部分同期、残 stale は Phase 11 close out PR に持ち越し |
| `65896b8` | 実機検証 (ko) 由来: 韓国語空表示の wrap 問題修正。`추가할 수 있습니다` (declarative、ja 「追加できます」直訳) → `추가하세요` (imperative、en `Tap + ... to add one.` 同じ voice) に短縮、`timerListEmptyHint` / `alarmListEmptyHint` / `clockEmptyHint` の 3 キーで `다.` 文字単独行漏れを解消 |
| `ae593bc` | review round 2 対応: **真の指摘 2 件** — (i) round 1 で追加したテストが `kEnableExperimentalLocales=false` (CI 既定) で `zhHant.isEmpty → return` になり実質未検証だった点を、`lib/main.dart` に `@visibleForTesting const debugExperimentalSupportedLocales` を expose して flag 非依存にリライト。(ii) zh / zh_Hant の `alarmEditValidationWeekdaysEmpty` の `一个星期` / `一個星期` が「1 週間」と読める曖昧性を `请至少选择一天` / `請至少選擇一天` に修正。BACKLOG.md / tasklist.md の plural rule 説明文を `zh / ko` → `zh / zh_Hant / ko` に揃え、PR description 冒頭に「ユーザ確認の経緯」セクション追加 (`gh pr edit`) |

### 主な設計判断

- **`Locale('zh', 'Hant')` vs `Locale.fromSubtags(scriptCode: 'Hant')`**:
  `Locale` constructor の第 2 引数は countryCode のため、前者は
  `countryCode='Hant' / scriptCode=null` になる。gen-l10n の
  `lookupAppLocalizations` は `switch (locale.scriptCode) case 'Hant'` で
  振り分け、`settings_notifier.dart` の `parseLocaleTag('zh-Hant')` も
  `Locale.fromSubtags(scriptCode: 'Hant')` を返す。形式不一致だと
  繁體中文選択時に `basicLocaleListResolution` で `Locale('zh')` に
  フォールバックされ AppLocalizationsZh (Simplified) が選ばれてしまう。
  Copilot round 1 #11 で発見、`652d236` で修正。`Locale` ドキュメントの
  positional 引数仕様を読まないと埋もれやすいタイプの bug
- **`@visibleForTesting` で `_experimentalSupportedLocales` を expose**:
  最初は `supportedLocales` (public getter、experimental flag で制御) を
  テストから参照する形で書いたが、`flutter test` / CI の既定では flag が
  false になり `zhHant.isEmpty → return` で検証 0 件になっていた
  (Copilot round 2 #2)。`const debugExperimentalSupportedLocales =
  _experimentalSupportedLocales;` を expose してテスト側はそちらを
  直接見る形にリライト。CI workflow を experimental 用に分岐させる案も
  検討したが、テスト対象が「production const list の構造的不変条件」
  だけなので flag 非依存の直接参照で十分
- **韓国語空表示の voice 変更**: 当初 `추가할 수 있습니다` (declarative、
  ja の「追加できます」を直訳) で書いたが、Pixel 6a で wrap して `다.` が
  3 行目に追い出される問題が発生。imperative `추가하세요` に短縮することで
  1 行に収まり、modern Android UI で広く使われている voice と合致
- **中文の `一个星期` 曖昧性**: alarm 編集画面で「曜日を 1 つ以上選んで
  ください」を `请至少选择一个星期` と訳出していたが、中文では `一个星期`
  が「1 週間 (七日間)」とも読める。`一个星期几` (一つの曜日) が直訳に
  近いが SnackBar には冗長で、modern Android repeat-day picker で広く
  使われる `一天` (一日) を採用。zh / zh_Hant とも揃えた
- **`docs/translations.md` の 5 列ミラー不採用**: 既存 ja / en 2 列を
  そのまま維持し、zh / zh_Hant / ko は冒頭注記で「ARB 直接参照」とする
  運用に切替。`gen-l10n` 以前の翻訳粒度では表形式ミラーが有効だったが、
  3 言語追加で列が肥大化 + ARB 自体が一次ソースの中、ミラー維持コストの
  ほうが大きいと判断
- **partial sync of `homeOpen*` / `*EmptyHint`**: PR #45 (Phase 11) で
  homeOpen* が短縮版になっていたが translations.md は旧表記 (`Open
  Stopwatch` 等) が残存。PR #61 では自分が追加した「ja / en 列は維持する」
  注記の信頼性を保つ最低限の 4 グループだけ同期、clock 系 / 通知 channel
  系 / `presetSheetManageButton` / `alarmStop` 等の他 stale 行は
  Phase 11 close out PR に持ち越し (本 close out PR の Follow-up 引継ぎ
  対象)

### PR レビュー対応 (Gemini + Copilot × 2 round)

| comment id | reviewer | 指摘 | 分類 | 対応 |
| --- | --- | --- | --- | --- |
| 3251938011 | Gemini | 韓国語 `{minutes} 분` のスペース不整合 | (a) 自明な fix | スペース削除 |
| 3251938012 | Gemini | `settingsDefaultSnoozeOption` 同上 | (a) 自明な fix | 同期 |
| 3251938013 | Gemini | zh 半角カンマ → 全角 `，` | (a) 自明な fix | 5 箇所統一、半角 `?` / `!` も全角化 |
| 3251938014 | Gemini | zh `添加・编辑时钟` の中黒 → `/` | (a) 自明な fix | `/` に置換 |
| 3251938015 | Gemini | zh 半角括弧 → 全角 `（）` | (a) 自明な fix | 5 箇所統一、スラッシュ前後スペースも除去 |
| 3251938016 | Gemini | zh 半角コロン → 全角 `：` | (a) 自明な fix | 統一 |
| 3251938017 | Gemini | zh_Hant 半角カンマ → 全角 | (a) 自明な fix | 7 箇所統一 |
| 3251938018 | Gemini | zh_Hant 中黒 → `/` | (a) 自明な fix | 同期 |
| 3251938019 | Gemini | zh_Hant 半角括弧 → 全角 | (a) 自明な fix | 同期 |
| 3251938020 | Gemini | zh_Hant 半角コロン → 全角 | (a) 自明な fix | 同期 |
| 3251954491 | Copilot | **zh_Hant の `Locale` 形式不整合 bug** | (b) 真の指摘 | `Locale.fromSubtags(scriptCode: 'Hant')` に修正 + 回帰防止 test 追加 |
| 3251954507 | Copilot | docs 編集 PR にユーザ確認経緯記載要請 | (b) 規約準拠 | round 2 で PR description 冒頭追記、本対応漏れも round 2 で挽回 |
| 3251954523 | Copilot | tasklist.md Follow-up なしと矛盾 | (a) 自明な fix | A-3 実機検証を Follow-up 追加 |
| 3251954533 | Copilot | translations.md の ja/en が既存 stale | (b) 真の指摘 (部分対応) | `homeOpen*` / `*EmptyHint` を同期、残は Phase 11 close out PR |
| 3251954545 | Copilot | BACKLOG.md 親 `[~]` と子 `[x]` 不整合 | (a) 自明な fix | `[ ] A-3 実機検証` 子追加で整合 |
| 3252095050 | Copilot (r2) | docs ユーザ確認経緯記載 (再指摘) | (b) 規約準拠 | PR description に「ユーザ確認の経緯」セクション追加 |
| 3252095053 | Copilot (r2) | **新規 test が flag false で実質未検証** | (b) 真の指摘 / 致命 | `@visibleForTesting` で `_experimentalSupportedLocales` expose、flag 非依存に書き直し |
| 3252095058 | Copilot (r2) | BACKLOG.md plural rule 説明文に zh_Hant 抜け | (a) 自明な fix | `zh / zh_Hant / ko` に揃える |
| 3252095063 | Copilot (r2) | tasklist.md 同上 | (a) 自明な fix | 同期 |
| 3252095068 | Copilot (r2) | **zh `一个星期` が「1週間」と読める** | (b) 真の指摘 | `请至少选择一天` に修正 |
| 3252095073 | Copilot (r2) | zh_Hant 同上 | (b) 真の指摘 | `請至少選擇一天` に修正 |

却下 0 件、ユーザ判断委譲 0 件。全 21 件 (round 1: 15 件 + round 2: 6 件)
feature branch に commit + push、`--input tmp.json` 経由でリプライ済。

### Pixel 6a 実機検証 (2026-05-16)

ユーザ手動でアプリ内言語切替を ja / en / zh / zh_Hant / ko の 5 通り
試行 + 主要画面の目視確認。1.5 ラウンドで挙動を確定:

1. **言語切替 (Phase 11 既存挙動の regression なし)**: 設定 → 言語 で
   各 locale を選択 → AppBar / バナー / 空表示 / 通知文言などその場で
   切り替わる。ja / en は PR #61 で挙動変化なし
2. **zh_Hant が Simplified にフォールバックしない (round 1 bug fix の
   regression test)**: 繁體中文を選択した際に AppBar が `碼錶` / `計時器` /
   `鬧鐘` / `世界時鐘` (zh_Hant の用語) で表示されること。`Locale` 形式
   修正前は `秒表` / `定时器` 等の Simplified 用語にフォールバックして
   いた可能性がある (PR #61 では production で再現確認はしていないが、
   修正後の APK で繁体字用語が正しく表示)
3. **韓国語空表示 wrap**: round 1.5 で発見 → `65896b8` で修正。修正後の
   APK で `오른쪽 아래의 "+" 버튼으로 추가하세요.` が 1 行に収まり、
   `다.` 文字単独行が解消したことを確認
4. **中文 SnackBar `请至少选择一天` / `請至少選擇一天`**: round 2 で
   修正。アラーム編集画面で全曜日 OFF のまま保存 → SnackBar が
   `一天` 表記で表示され、「1 週間を選べ」の誤読が解消
5. **その他 (DurationPicker / Stopwatch / Preset bottom sheet /
   PermissionBanner / 通知本文)**: 表示崩れ・違和感なし。韓国語の
   `5분 / 10분 / 15분` (スペースなし、modern UI 標準) も SegmentedButton
   に詰まりすぎず読みやすい範囲

### 関連ファイル

- `lib/l10n/app_zh.arb` (新規、Simplified Chinese)
- `lib/l10n/app_zh_Hant.arb` (新規、Traditional Chinese)
- `lib/l10n/app_ko.arb` (新規、Korean)
- `lib/l10n/app_localizations_zh.dart` (gen-l10n 出力、zh + zh_Hant)
- `lib/l10n/app_localizations_ko.dart` (gen-l10n 出力)
- `lib/l10n/app_localizations.dart` (`supportedLocales` / `lookupAppLocalizations` 自動更新)
- `lib/main.dart` (`_experimentalSupportedLocales` zh_Hant エントリ修正 +
  `@visibleForTesting debugExperimentalSupportedLocales` const expose)
- `test/locale_resolution_test.dart` (locale-form 回帰防止 test 1 件追加、
  round 2 で flag 非依存に書き直し)
- `BACKLOG.md` / `tasklist.md` / `docs/translations.md` (Phase 11
  ローカライズ残作業の進捗反映 + ja/en 列の部分 stale 同期)

642 tests pass / 1 skipped / `flutter analyze` clean / experimental APK
build success:

```powershell
flutter build apk --debug --dart-define=ENABLE_EXPERIMENTAL_LOCALES=true
```

### 持ち越しタスク

- **`docs/translations.md` 一括同期**: PR #61 では `homeOpen*` /
  `*EmptyHint` の 4 行のみ部分同期。clock 系 (`clockAppBarTitle` /
  `clockListAddFab` / `clockDesignSegment*` / `clockEntryEditAppBarTitle` /
  `clockEntryEditSectionPinned` / `clockEntryEditSectionAvailable` /
  `clockEntryEditLimitReached` / `clockEntryEditCatalogEmpty` /
  `clockEmptyHint`) と通知 channel 系 (`notificationAlarmRingingTitle` /
  `notificationAlarmRingingBody` / `notificationTimerAlarmChannelName` /
  `notificationTimerAlarmChannelDescription` /
  `notificationTimerCompletedChannelName` /
  `notificationTimerCompletedChannelDescription`)、`presetSheetManageButton` /
  `alarmStop`、Phase 9.5 以降に追加された他キーを Phase 11 close out PR
  でまとめて同期予定。CI で diff チェックを入れる方向は別途検討
- **アプリアイコン・スプラッシュ / Play Store 提出準備**: Phase 11 残
  タスク (`BACKLOG.md` Phase 11 残タスク参照)。PR #61 スコープ外

---

## A-2 通知 channel 名 i18n + F-7 Manifest 整形 完了 + Pixel 6a 実機検証完了 (2026-05-16)

Phase 11 仕上げの「通知 channel 名の i18n (A-2)」と PR #20 から持ち越しの
「`AndroidManifest.xml` の `<uses-permission>` 整形統一 (F-7)」を 1 本の
Native 編集 PR (PR #59) にまとめて実装・マージ。

### 経緯と目的

- **A-2**: OS 設定 (Settings → Apps → TimerUtility → Notifications) の
  channel 一覧に表示される `name` / `description` が、ja モードでも英語
  ハードコード (`Timer Alarm`) と日英混在 (`タイマー終了時のアラーム通知`)
  のまま放置されていた。Phase 11 言語切替 UI (2026-05-14) で UI 側は
  完全 i18n 化されたが、OS 設定画面で「アプリ言語と通知設定画面で言語が
  乖離する」体験が残っていた
- **F-7**: PR #20 Copilot レビューで指摘されていた `AndroidManifest.xml`
  line 2 (`ACCESS_COARSE_LOCATION`) のみ `..."/>` で line 3-9 と書式不一致。
  cosmetic だが Manifest 編集が要ユーザー確認ファイルなので、次回 Native
  編集 PR の「おまけ」として保留中だった

### 採用方針

既存の `NotificationStrings` / `NotificationStringsNotifier` パターンを
再利用し、channel meta 4 文字列を value object に統合。`createNotificationChannel`
を同 id で再呼び出しすると name/description を上書きできるが
importance / sound / vibration は保護される Android 仕様を活用し、locale
切替時に adapter から `_recreateChannels` を再実行。

### 実装 PR と commit 構成

| commit | 内容 |
| --- | --- |
| `385504e` | 初版: ARB ja/en に 4 キー追加、`NotificationStrings` を `lib/domain/notifications/` 新設して domain に切り出し (application → domain 依存方向修正)、`NotificationScheduler` port に `updateChannelNames(NotificationStrings)` メソッド追加、`FlutterLocalNotificationAdapter` の const top-level (`timerAlarmChannelName` 等) 削除 → `late _strings` フィールド + `_recreateChannels()` ヘルパに分離、`main.dart` の `_refreshNotificationLocale` に `unawaited(scheduler.updateChannelNames(strings))` 配線、`AndroidManifest.xml` line 2 を `..." />` に統一 (F-7) |
| `e7910d0` | Copilot review 対応: en ARB の `Silent notification when a timer ended while the app was in the background` を `... ends ... is ...` に時制統一 + test helper stub も同期、`test/infrastructure/notification/flutter_local_notification_adapter_test.dart` を mocktail ベースで新規追加 (3 ケース: 再作成 / locale 切替 / importance 保持) |

### 主な設計判断

- **`NotificationStrings` の domain 移動**: Plan 段階では application 層
  据置を想定していたが、実装で adapter (infrastructure) が application を
  import するのは CLAUDE.md「絶対遵守の依存方向
  (`Presentation → Application → Domain ← Infrastructure`)」違反と判明。
  前例として `lib/domain/diagnostics/` があるため `lib/domain/notifications/`
  新設、`application/notification_strings_provider.dart` は re-export で
  API 互換を維持
- **port シグネチャに primitives 4 string ではなく `NotificationStrings`
  を渡す**: 4 個の named String args は冗長で読みづらい。`NotificationStrings`
  全体が domain に移ったので依存方向 OK
- **`schedule()` / `show()` 内の `AndroidNotificationDetails` も `_strings`
  経由に変更**: const top-level 削除した以上、参照箇所もすべて動的フィールド
  参照に変更。flutter_local_notifications 仕様では「channel id が同じなら
  2 回目以降このフィールドは OS に無視される」のでロジック影響はないが、
  コードベース内の name/description の唯一の出処が `_strings` に統一される
  副次効果
- **experimental locale (zh / zh_Hant / ko) の ARB 追加は本 PR で未実施**:
  ARB ファイル自体が未作成 (`app_zh.arb` 等は存在しない)。Flutter delegate
  は ARB 無しなら en にフォールバックする既存挙動を踏襲。本格翻訳は
  Phase 11 A-3 で別途
- **adapter unit test 追加 (Copilot review 対応)**: 当初「Phase 4 adapter
  unit test 前例なしを理由に省略」と判断したが、CLAUDE.md「新規ロジック
  追加時は必ず Unit Test を同時作成」に反するレビュー指摘を受けて方針変更。
  mocktail で `FlutterLocalNotificationsPlugin` + `AndroidFlutterLocalNotificationsPlugin`
  を mock、3 ケース (再作成 / locale 切替で最新 strings 勝ち /
  importance/sound/vibration 保持) で回帰ガード

### PR レビュー対応 (Copilot)

| comment id | 指摘 | 分類 | 対応 |
| --- | --- | --- | --- |
| 3249615550 | en ARB の `notificationTimerCompletedChannelDescription` の時制不統一 (`ended` / `was`) | (a) 自明な fix | `ends` / `is` に統一、ja は据置 (idiomatic) |
| 3249615588 | test helper stub も上記と同期 | (a) 自明な fix | 同期済 |
| 3249615619 | `updateChannelNames` / `_recreateChannels` の unit test 追加 | (a) 正当な指摘 (CLAUDE.md 整合) | mocktail ベース 3 ケースで新規追加 |

却下 0 件、ユーザー判断委譲 0 件。全件 feature branch に commit + push、
リプライ済。

### Pixel 6a 実機検証 (2026-05-16)

PR description 検証手順 5 項目すべて ✅ 完了:

1. **ja モードでの channel 名表示**: 「タイマーアラーム」(説明: 「タイマー
   終了時のアラーム通知」) / 「タイマー完了（バックグラウンド）」(説明:
   「バックグラウンド中にタイマーが終了したことを知らせる無音通知」) が
   OS 設定画面の通知 channel 一覧に正しく表示
2. **言語切替で channel 名が即時追従**: アプリ内 設定 → 言語 → English
   に切替後、OS 設定画面の channel 名が「Timer Alarm」「Timer Completed
   (Background)」に追従。アプリ再起動不要 (`updateChannelNames` の即時
   反映を確認)
3. **言語切替後の通知 body の regression なし**: 英語モードで 10 秒タイマー
   → `Timer` / `Time is up.` 通知、日本語モードで再実行 → `タイマー` /
   `時間になりました。` 通知。Phase 11 既存挙動を保持
4. **F-7 整形後の APK build**: `flutter build apk --debug` 通過 (Manifest
   パース OK の代理確認)
5. **アラーム発火経路 (Phase 6 FullScreenIntent) の regression なし**:
   1 分後のアラーム作成 → 画面ロック → 1 分後にフルスクリーンで
   AlarmRingingScreen が表示、バンドル音源 + バイブ動作、停止後の channel
   設定 (importance: 緊急 / サウンド: 有効 / バイブ: 有効) が保持されている
   ことを確認

### 関連ファイル

- `lib/domain/notifications/notification_strings.dart` (新規)
- `lib/domain/ports/notification_scheduler.dart` (port メソッド追加)
- `lib/infrastructure/notification/flutter_local_notification_adapter.dart` (locale-aware 化)
- `lib/application/notification_strings_provider.dart` (class → re-export に簡素化)
- `lib/main.dart` (`adapter.initialize(strings: ...)` + locale listener 配線)
- `lib/l10n/app_ja.arb` / `app_en.arb` (4 キー追加)
- `lib/l10n/app_localizations*.dart` (自動再生成)
- `test/helpers/test_notification_strings.dart` (channel meta stub 4 値追加)
- `test/infrastructure/notification/flutter_local_notification_adapter_test.dart` (新規、mocktail テスト 3 件)
- `android/app/src/main/AndroidManifest.xml` (line 2 整形)

641 tests pass / 1 skipped / `flutter analyze` clean。

---

## F-10 PermissionBanner 縦サイズ縮小 完了 + Pixel 6a 実機検証完了 (2026-05-15)

PR #47 (F-8 文中改行解消) 後の Pixel 6a 実機検証で「`[許可する]` TextButton を
description 下段に縦並びにした結果、バナー縦サイズが約 48dp 増加して『だいぶでかい』」
とユーザ判断。ユーザ提案で「バナー全体をタップ可能化し TextButton を削除する」方針が
確定し、F-10 として単独 PR #56 で実装。closeout (旧 ARB キー削除 + dev-log 移管)
は別 PR で対応。

### 実装 PR と commit 構成

| commit | 内容 |
| --- | --- |
| `7860bd7` | 初版: `_PermissionBanner` の root を `Semantics(button: true, container: true, onTap, label) + Material + InkWell` 構造に変更、`TextButton` + `Align(centerRight)` 削除、ARB `permissionBannerHintTapToAllow` / `permissionBannerHintTapToOpenSettings` 新設、accent / Icon / 本文 Column を `ExcludeSemantics` 配下に。F-8 座標 assert テスト削除 + Semantics 新規テスト 4 件追加 |
| `938f7fe` | TalkBack「ラベルなし 検出 テキスト4 有効にするにはダブルタップします」回帰修正: `InkWell` の暗黙 Semantics と外側 `Semantics` が競合し、`Text.rich` の TextSpan (severity + title) + description + hint = 4 ノードが descendant として残存していた。外側 `Semantics(excludeSemantics: true)` + `InkWell.excludeFromSemantics: true` で対処 (この時点で誤って `container: true` を削除) |
| `a427334` | 兄弟 Text 合流回帰修正: `container: false` に戻したことで props が祖先ノードへ合流し、`timerListEmptyHint` Text と同じノードに吸収されて画面全体が 1 ボタンとして読み上げられる症状を再発。`container: true` を復元し、兄弟 Text と並べた状態で `semantics.label` に兄弟文言が含まれないことを assert する回帰テストを追加 |
| `e45c87b` | PR レビュー反映: Semantics label の句点ハードコード (`'$severityLabel $title。$description $hint'`) を半角スペースに置換 (英語ロケールで `Notifications disabled。Timer-end...` のような非ローカライズ記号混入を回避)。`SemanticsHandle` 解放を `addTearDown` → `try/finally` に変更 (flutter_test の `_verifySemanticsHandlesWereDisposed` が `addTearDown` より前に走るため `addTearDown` は使用不可、`test/presentation/screens/home/home_screen_test.dart:709` の既存パターンと統一) |

### 主な設計判断と試行錯誤

- **Semantics 三点セット** (a427334 確立): 全体タップ可能 + TalkBack 単一ノード読み上げを
  両立するには以下 3 つすべてが必須:
  1. 外側 `Semantics(container: true)` — 独立した SemanticsNode を確保。`false` だと
     props が祖先ノードへ合流し、兄弟 widget と同じノードに吸収される
  2. 外側 `Semantics(excludeSemantics: true)` — descendant の SemanticsNode を全遮断。
     `Text.rich` の `TextSpan` は個別の semantics ノードを生成するため、
     個別の `ExcludeSemantics` ラップでは合流抑止が不十分
  3. `InkWell(excludeFromSemantics: true)` — InkWell がデフォルトで生成する暗黙の
     `Semantics(button: true)` を抑止。外側 Semantics の `button: true` + label と
     競合させない (競合すると TalkBack は内側 = ラベルなしノードにフォーカス)
- **Semantics label の組み立て**: `'$severityLabel $title $description $hint'`。
  区切りは半角スペースのみ。句読点は `description` / `hint` の ARB 訳側に委ねる
  (英語ロケールで日本語句点が混入しないように、`Tap anywhere to change this permission.`
  のように訳文末尾に英語句点を持たせる)
- **個別 `ExcludeSemantics` ラップは撤去** (a427334): 外側 `excludeSemantics: true` で
  descendant がすべて遮断されるため、accent Container / Icon / 本文 Column に個別の
  `ExcludeSemantics` を被せる必要は無い。代わりに `container: true` を確実に保つ
- **`SemanticsHandle.dispose()` は `try/finally` 限定**: `addTearDown(handle.dispose)`
  は機能しない。flutter_test は `_endOfTestVerifications` 内で
  `_verifySemanticsHandlesWereDisposed` を `addTearDown` コールバックより前に走らせる
  ため、ハンドル未解放と判定されてテストが fail する

### Pixel 6a / Android 16 実機検証 (2026-05-15)

| # | シナリオ | 結果 |
| --- | --- | --- |
| ① | TalkBack OFF: `[重要]` バナー (POST_NOTIFICATIONS denied) の全体タップで権限ダイアログが開く | OK |
| ② | TalkBack OFF: `[補助]` バナー (USE_FULL_SCREEN_INTENT denied) の全体タップで設定画面が開く | OK |
| ③ | TalkBack ON: `[重要]` バナーが「\[重要\] 通知が無効です タイマーが終了したときに通知が表示されません。 タップで権限を変更できます。 ボタン」と一つのノードとして読み上げられる | OK (a427334 までで「ラベルなし テキスト4」と画面全体合流の両方を解消) |
| ④ | TalkBack ON: バナーにフォーカスを当てた時、フォーカス枠がバナー部のみに収まる (画面全体に広がらない) | OK (`container: true` の効果) |
| ⑤ | TalkBack ON: ダブルタップで権限ダイアログが開く | OK |
| ⑥ | バナー縦サイズが PR #47 比で約 48dp 縮小 (TextButton + 余白分) | OK |
| ⑦ | permanentlyDenied 状態 (2 回拒否) で hint が「タップで設定を開けます。」に切り替わる | OK |

> `[推奨]` バナー (SCHEDULE_EXACT_ALARM denied) は USE_EXACT_ALARM 自動 grant のため
> Manifest 編集なしでは実機再現不可 (既知制約、tasklist.md F-7 参照)。本 F-10 では
> `[重要]` (POST_NOTIFICATIONS) と `[補助]` (USE_FULL_SCREEN_INTENT) で代替検証。

### PR レビュー対応 (Gemini + Copilot 計 4 件)

| Reviewer | 指摘 | 対応 |
| --- | --- | --- |
| Gemini | Semantics label に句点 `。` ハードコード | 半角スペース区切りに変更 (`e45c87b`) |
| Gemini | `InkWell.excludeFromSemantics: true` 推奨 | 実機検証で同じ結論に到達済み、`a427334` 時点で適用 (リプライで経緯説明) |
| Copilot | 句点ハードコード (Gemini と同内容) | 同 fix で対応 |
| Copilot | `ensureSemantics()` 解放は `try/finally` / `addTearDown` で | `try/finally` で対応 (`addTearDown` は使用不可と確認、リプライで根拠説明) |

### F-10 closeout (本 PR)

- 旧 ARB キー `permissionBannerActionAllow` / `permissionBannerActionOpenSettings` 削除
  (runtime 参照ゼロを `grep` で確認済)。生成物 `app_localizations*.dart` から該当
  getter も消去 (`flutter gen-l10n` 再実行)
- `docs/translations.md` の権限バナーセクションを更新 (旧 2 キー削除 + 新 2 キー
  `permissionBannerHintTapToAllow` / `permissionBannerHintTapToOpenSettings` 追加)
- `tasklist.md` から F-10 セクションを削除し、本 dev-log へ移管 (規約: 完了タスク
  詳細は本ファイルに集約、tasklist は現在進行中のみ)

---

## Phase D (Diagnostic Logging) 完了 + Pixel 6a 実機検証完了 (2026-05-15)

ベータテスター / 開発者向けに「アプリの動作ログを zip にまとめて OS Share Sheet で
送れる」観測機構を Domain → Application → Infrastructure → Presentation の
4 層に分けて 3 PR で実装。PR #49 (D-1) / PR #52 (D-2、当初 PR #50 が D-1 マージ後
auto-close したため再作成) / PR #51 (D-3) すべて main にマージ済。

### Phase 分割と各 PR の責務

| Phase | PR | コミット | 内容 |
| --- | --- | --- | --- |
| D-1 | #49 | `2416910` | Domain (`DiagnosticEvent` sealed class + `DiagnosticLogger` + `DiagnosticSink` port) + Application (`diagnosticSettingsNotifierProvider` / `diagnosticSinkProvider` / `diagnosticLoggerProvider` / `diagnosticExportControllerProvider`) + `UserPreferenceKeys.diagnosticLogEnabled` 永続化キー追加。Sink 実装は `InMemoryDiagnosticSinkAdapter` のみ (Infrastructure は D-2 で差し替え) |
| D-2 | #52 | `84da021` | Infrastructure (`FileDiagnosticSinkAdapter` JSON Lines 形式 + `DiagnosticLogRotator` retention 14 日 / 累計 50 MB / 1 ファイル 1 MB で分割) + `path_provider` 経由で `getApplicationSupportDirectory()/diagnostic_logs/` 配下に永続化。`LocationDetectorAdapter` に `loggerLookup` thunk を注入し、GPS / `FlutterTimezone` 解決失敗時に `DiagnosticEvent.uncaughtException` を記録 (`permissionTransition` / `notificationFired` / `timerAction` 系イベントは Application 層の `permission_notifier.dart` / `*_collection_notifier.dart` / `*_ringing_notifier.dart` / `stopwatch_notifier.dart` から発火)。`main.dart` で `ProviderContainer` 先行構築 → `FlutterError.onError` / `PlatformDispatcher.instance.onError` を `diagnosticLoggerProvider` 経由に配線し isEnabled ゲートを尊重 |
| D-3 | #51 | `46d593d` | Infrastructure (`ZipDiagnosticLogExporterAdapter` + `archive` 3.6.1 で zip 化、`share_plus` 10.x で OS Share Sheet 起動) + Presentation (`SettingsScreen` 末尾に「診断ログ」セクション、`_DiagnosticToggleTile` (SwitchListTile) + `_DiagnosticShareTile` (ListTile、SnackBar フィードバック) を追加)。zip ファイル名は `timer_utility_diagnostic_YYYYMMDD_HHmmss.zip`、件名は localizable (`settingsDiagnosticShareLogsSubject`) |

### 主な設計判断

- **Domain は Pure Dart 維持**: `DiagnosticEvent` は freezed を使わず手書き sealed class
  (`alarm_repeat.dart` 流儀)。factory redirect の引数名は subclass コンストラクタと一致
  させる必要があるため、`DiagnosticPermissionTransition` のフィールドを `kind`
  (親 `String get kind` ゲッタと衝突) から `permissionKind` にリネーム
- **PII 排除を Domain で担保**: factory は `timerId` / UUID / enum 値のみ受け取り、
  timer label / 緯度経度 / 任意文字列は受け取れない型設計。`DiagnosticEvent.digestStackTrace`
  は 3 フレームまで stack trace を要約 (PII セーフ)
- **isEnabled ゲートは Application 層で集中管理**: `DiagnosticLogger.log()` 内で
  `isEnabled()` と severity threshold をチェック。`FlutterError.onError` も
  直 `sink.write()` ではなく `diagnosticLoggerProvider.log(...)` 経由に統一
- **`DiagnosticSettingsNotifier._userMutated` フラグ** (PR #49 review fix): `_restore`
  非同期完了がユーザのトグル操作より遅れて上書きする race を防止
- **`DiagnosticExportController` re-entrancy guard** (PR #49 review fix): `inProgress`
  状態中の重複 export 呼び出しを早期 return で抑止
- **`p.join` でパス組み立て** (PR #50 review fix): プラットフォーム別の path separator
  差を吸収するため `pubspec.yaml` の `path: any` を direct dependency に昇格
- **`pruneOldFiles` の dir.list() try-catch** (PR #50 review fix): ディレクトリ未作成
  状態でも失敗しない
- **`ZipFileEncoder.addFile` / `close` の await**: archive 3.6.1 の
  `lib/src/io/zip_file_encoder.dart:209,235` で両 API とも `Future<void> async` で
  あることをソース確認し、Gemini code-assist の「await 不要」指摘を却下リプライで反論

### 設計判断の経緯メモ

- **PR #52 (D-2 再作成)**: PR #50 (D-1 base) は D-1 が squash merge された時点で
  base branch が消失し GitHub 側で auto-close された。同一内容を main rebase した
  上で PR #52 として再起こし
- **PR #51 (D-3) の rebase**: `git rebase --onto origin/main bf0c3d3 feature/diagnostic-log-phase-d3`
  で D-1/D-2 の squash 吸収済みコミットをスキップ。`main.dart` (UncontrolledProviderScope 構造 +
  `diagnosticLogExporterProvider` override 追加) と `pubspec.yaml` (archive / share_plus / path
  をすべて維持) で発生したコンフリクトを手動解決

### Pixel 6a 実機検証 (2026-05-15)

| # | シナリオ | 結果 |
| --- | --- | --- |
| ① | 設定 > 診断ログトグル ON → タイマー操作 → アプリ専有ディレクトリに `diagnostic_YYYY-MM-DD.log` が生成 | OK |
| ② | ログ内に PII (`label` / `latitude` / `longitude` / timer label 文字列) が混入していない | OK (端末側 `adb shell run-as ... cat ... \| grep -iE "..."` で確認) |
| ③ | トグル OFF → アプリ再起動 → トグル OFF 復元、ON → 再起動 → ON 復元 | OK |
| ④ | 「ログを共有」タップ → OS Share Sheet (subject = `TimerUtility 診断ログ`) → Gmail で自分宛送信 → 受信した zip を解凍して中身が JSON Lines であることを確認 | OK |

実機ログのサンプル (一部抜粋、PII 観点クリーン確認済):

```jsonl
{"t":"2026-05-15T08:49:47.193577Z","sev":"info","kind":"permissionTransition","permissionKind":"postNotifications","before":"unknown","after":"permanentlyDenied"}
{"t":"2026-05-15T08:49:47.196386Z","sev":"info","kind":"permissionTransition","permissionKind":"scheduleExactAlarm","before":"unknown","after":"granted"}
{"t":"2026-05-15T08:50:09.499960Z","sev":"debug","kind":"timerAction","timerId":"stopwatch","action":"start"}
{"t":"2026-05-15T08:50:23.042028Z","sev":"info","kind":"notificationFired","payloadId":"68ee0548-302f-41d1-8d4b-ac6fbbd1cec9","fireKind":"timerFired"}
{"t":"2026-05-15T08:57:04.667257Z","sev":"info","kind":"notificationFired","payloadId":"a0fab8b2-9465-42c2-84e9-54da803f806f","fireKind":"missedAlarmReconcile"}
```

`timerId` は UUID または `stopwatch` 固定値のみ、`permissionKind` / `fireKind` は enum
値のみ、`before` / `after` は enum 値のみ。仕様通り「ラベル文字列・座標」は payload に
乗らないことを実機ログで再確認した。

### 既知の運用上の注意

- **Windows での PII 検証**: `git grep` 系コマンドは PowerShell に `grep` が無いため
  動かない。① 端末側で grep する (`adb shell "run-as ... cat ... | grep -iE '(label|latitude|longitude|location)'"`)
  か、② Windows 側で `Select-String` / `findstr` を使う必要がある
- **share_plus の Manifest 自動マージ**: `<provider>` 宣言は share_plus 10.x の
  `manifest auto-merge` で自動付与されるため、`AndroidManifest.xml` を手動編集する
  必要は無かった (実機で FileProvider エラーなく Share Sheet が起動することを確認済)
- **`adb run-as` の到達範囲**: アプリ専有ディレクトリ (`/data/data/com.bonkotu.timer.timer_utility/files/`)
  のみアクセス可能。`getApplicationSupportDirectory()` がこの配下を返す前提

### 検証 DoD 達成

- [x] D-1: `DiagnosticEvent` sealed class + factory API、PII セーフ型設計、Pure Dart
- [x] D-2: ファイルローテーション (7 日 / 5 MB)、JSON Lines 形式、`LocationDetectorAdapter`
  経由のイベント発火、isEnabled ゲート遵守
- [x] D-3: zip 圧縮 + OS Share Sheet 起動、Settings UI 配線、Pixel 6a 4 シナリオ実機検証
- [x] 全 3 PR の review コメント完全クローズ (CI 緑 + AI 指摘の裏取り却下 1 件含む)
- [x] `flutter analyze` / `flutter test` 緑 (main マージ後の本流でも追加退行なし)

---

## Phase 11 言語切替 + F-9 Pixel 6a 実機検証完了 (2026-05-15)

PR #45 (Phase 11 言語手動切替 UI) および PR #43 (F-9 未対応 locale → en フォールバック) の
Pixel 6a / Android 16 (API 36) 実機検証を完了。

### 検証範囲と結果

| # | シナリオ | ビルド | 結果 |
| --- | --- | --- | --- |
| A-1 | 設定 > 言語 > English で全画面が即時英語化、再起動後も英語維持 | public | OK |
| A-2 | 「システムに合わせる」で端末ロケール (ja) に追従、`localeTag` remove | public | OK |
| A-3 | experimental ビルドで zh / zh-Hant / ko の 3 件が選択肢に追加表示 | `--dart-define=ENABLE_EXPERIMENTAL_LOCALES=true` | OK |
| A-4 | 走行中タイマーの通知バナーが手動 EN 切替直後に即時英語化 | public | OK (`ref.listen` → `_refreshNotificationLocale` → `rescheduleAllRunning`) |
| B | 端末言語 = 繁體中文 (台灣) / 한국어 で en にフォールバック (F-9) | public | OK |

A-4 は `lib/main.dart` の `ref.listen<SettingsState>` で `localeOverride` 変化を検知 →
`_refreshNotificationLocale()` 内で `NotificationStringsNotifier.set()` +
`timerCollectionNotifierProvider.notifier.rescheduleAllRunning()` を呼び、通知 OS 側へ
予約済みのペンディング banner も再投入される仕組みが期待通り動作することを確認。

### 副次確認: F-8 (PermissionBanner 折り返し品質) の再現確認

C-1: 設定 > アプリ > TimerUtility > 通知 を拒否すると `[重要] タイマーが終了したときに
通知が表示されません` バナーが表示され、本文が「通知が表」「示されません」と文中改行
する現象を実機スクリーンショットで再現確認。tasklist.md の F-8 (cosmetic) の記述通りで、
PR #45 起因ではない既存挙動。状態に変化なし、実装案 (縦並び化 / Wrap 化) は別 PR で対応する方針を維持。

### 検証 DoD 達成

- [x] 手動言語切替が即時 / 再起動後の両方で正しく動作
- [x] experimental flag で zh / zh-Hant / ko が出る (public ビルドでは出ない)
- [x] 走行中タイマーの通知文言が手動切替に追従
- [x] F-9 未対応 locale が en にフォールバック (繁体中文 / 韓国語)

### 残課題

- [推奨] バナー (SCHEDULE_EXACT_ALARM denied) は引き続き実機再現不可 (Manifest の
  `USE_EXACT_ALARM` install permission のため、Phase 11 CVD 検証時と同じ理由)。
  Widget Test 7 件で代替担保済み (2026-05-13 セクション参照)
- F-8 PermissionBanner 折り返し品質改善は別 PR で対応 (tasklist.md の F-8 セクション参照)

---

## Phase 11 CVD banner labels 実機検証完了 (2026-05-13)

PR #39 (Phase 11 CVD banner labels) の Pixel 6a / Android 16 (API 36) 実機検証を完了。

### 検証範囲と結果

Color correction (Settings → Accessibility → Color and motion → Color correction) を
切り替えながら、`PermissionBanners` の重大度識別性を目視確認:

| シナリオ | ライト | ダーク | 結果 |
| --- | --- | --- | --- |
| 色補正 OFF (基本表示) | ✓ | ✓ | OK |
| Protanomaly (1 型色覚) | ✓ | ✓ | OK |
| Deuteranomaly (2 型色覚) | ✓ | ✓ | OK |
| Tritanomaly (3 型色覚) | ✓ | ✓ | OK |
| Grayscale (色相完全排除) | ✓ | ✓ | OK (目視のみ判定、後述) |
| S11 タップ動作 (Allow / Open settings) | ✓ | — | OK (`requestNotification` / `openFullScreenIntentSettings` 呼出確認) |
| S12 言語切替 日 → 英 | ✓ | — | OK (`[Critical]` / `[Supplementary]` に切替) |
| S13 全 granted で `SizedBox.shrink` | ✓ | — | OK (バナー完全に消える) |

**判定基準**: 3 つの冗長要素 (ラベル `[重要]`/`[補助]` + 左端色帯幅 8pt/3pt +
タイトル `FontWeight` w900/w600) のすべてが各シナリオで視認可能であり、
色相情報に依存せず重大度の段階差が読み取れること。

Grayscale (最厳格条件、色相情報ゼロ) でも識別可能だったことで、
CVD 対応の本質的合格条件を満たした。

### 検証できなかった範囲とその理由

`[推奨]` バナー (`SCHEDULE_EXACT_ALARM` denied 状態) は実機では再現不可:

- `android/app/src/main/AndroidManifest.xml` で
  `android.permission.USE_EXACT_ALARM` (Android 13+ で導入された install
  permission) を宣言しており、`dumpsys package` で
  `USE_EXACT_ALARM: granted=true` が install permission として自動付与される
- `AlarmManager.canScheduleExactAlarms()` は `USE_EXACT_ALARM` OR
  ユーザの `SCHEDULE_EXACT_ALARM` special access の OR 判定なので、
  TimerUtility では常に true を返す
- → `permission_handler` の `Permission.scheduleExactAlarm.status` も常に granted、
  `state.scheduleExactAlarm == denied` 分岐が実機で発生しない
- → `[推奨]` バナーは Manifest を一時編集しないと実機表示できない (CLAUDE.md
  「編集時にユーザー確認が必要なファイル」のスコープ追加が必要)

本検証では Manifest 編集はスコープ外とし、`[推奨]` バナーの rendering
品質は Widget Test `test/presentation/widgets/permission_banners_test.dart`
の 7 件で代替担保とした。具体的には accent 幅 5.0pt を `Container.constraints.maxWidth`
で assert する 2 件 (個別 + 3 種同時表示) と、ラベル `[推奨]` 文字を
`find.textContaining` で確認する 1 件で間接的にカバー。`titleWeight` の
FontWeight 値そのものを assert するテストは現状無く、これは F-x 候補
(本 PR スコープ外、追加するなら別 PR で `tester.widget<Text>(...).style?.fontWeight`
を assert)。`flutter test` 558 件緑。

`[重要]` (critical, 8pt, w900) と `[補助]` (supplementary, 3pt, w600) の
2 種が実機で同時表示できることから、中間値 (5pt, w700) は線形補間で
識別可能と判定。

### 実機検証フローで使ったコマンド (再発時の手順メモ)

`appops` でユーザの special access 設定を deny:

```text
adb shell appops set com.bonkotu.timer.timer_utility USE_FULL_SCREEN_INTENT ignore
adb shell pm revoke com.bonkotu.timer.timer_utility android.permission.POST_NOTIFICATIONS
```

権限を元に戻す:

```text
adb shell pm reset-permissions com.bonkotu.timer.timer_utility
adb shell cmd appops reset com.bonkotu.timer.timer_utility
```

Pixel 6a / Android 16 の applicationId は `com.bonkotu.timer.timer_utility`
(`com.bonkotu.timer` だと `appops` が `No UID for ... in user 0` エラー、
今回の検証で 30 分時間ロスした実績あり)。

### Android の screenshot 仕様メモ

`Color correction` (Accessibility) は SurfaceFlinger の合成パイプライン
最終段で適用され、screencap API はその上流から取得するため、
**Color correction フィルタは screenshot に反映されない仕様**。
本検証の Protanomaly / Deuteranomaly / Tritanomaly のスクリーンショットは
オリジナルカラーで保存されており、Grayscale 状態の見え方は実機目視のみ判定。

「色覚補助は本人が見る画面のみで完結し、共有時には元の色情報を保持する」
という Accessibility 設計思想に沿った挙動。検証時は (a) 別端末/カメラで
物理撮影、(b) PC で screenshot を後加工してグレースケール変換、(c) 目視判定
の 3 択になる。本検証は (c) を採用。

### 副次発見

実機検証中に CVD 改修以前から存在する既存挙動を 2 件発見、`tasklist.md`
の follow-up として記録 (PR #41 にまとめて記録):

- **F-8**: `[重要]` バナーの本文が「許可する」ボタン幅を避けて折り返す
  ため、文の途中で改行 (例: 「タイマーが終了したときに通知が表」「示
  されません」)。CVD 識別性自体には影響しない cosmetic 課題
- **F-9**: S12 言語切替で繁体中文 (台湾) 選択時、英訳ではなく日本語に
  フォールバック。`lib/main.dart` の `_publicSupportedLocales` 先頭が
  `Locale('ja')` + `localeResolutionCallback` 未設定のため、Flutter の
  `basicLocaleListResolution` が `supportedLocales[0] = ja` にフォールバック
  する標準挙動。Phase 8.5 ローカライズ土台導入時からの既存仕様で、
  PR #39 起因ではない。修正案 (5 行程度の `localeResolutionCallback`
  追加で `Locale('en')` フォールバック化) を F-9 に記載。中韓 ARB 実翻訳
  タスクで吸収するか単独 PR で先行修正するかは別途検討

### 検証 DoD 達成

- [x] Grayscale (色相完全排除) で重大度識別可能 → **CVD 対応本質達成**
- [x] ライト / ダーク両モードでコントラスト保持
- [x] 第一 / 第二 / 第三色弱の 3 タイプで識別可能
- [x] タップ動作 (S11) / 言語切替 (S12 日英) / 全 granted で非表示 (S13)
  すべて実機 OK 確認
- [x] Widget Test 7 件 (`requestNotification` / `openSettings` 呼び出し +
  `SizedBox.shrink` 落ち + accent 幅 5.0pt assert + `[推奨]` ラベル文字
  `find.textContaining`) も緑

PR #39 の CVD 対応はこれでクローズ。Phase 11 残タスクは BACKLOG.md
進捗サマリ表を参照。

---

## Phase 11 CVD banner labels (2026-05-13)

Phase 11「設定画面」サブタスクの「色覚多様性 (CVD) 対応モード」を BACKLOG.md
方針 (a) 冗長表示で完結。`lib/presentation/widgets/permission_banners.dart`
の 3 種バナー (post_notifications / exact_alarm / full_screen_intent) に
以下の冗長表示を追加:

1. タイトル先頭に重大度ラベル `[重要]` / `[推奨]` / `[補助]` を併記 (ARB
   新規キー `permissionBannerSeverity{Critical,Recommended,Supplementary}`
   経由、日英のみ追加)
2. タイトル `FontWeight` を critical=w900 / recommended=w700 /
   supplementary=w600 に段階差
3. バナー左端に縦色帯 (幅 8 / 5 / 3 pt、色は `onColor` の alpha 60%) を
   追加して形状差。`Material(color, borderRadius)` の中を `ClipRRect` +
   `Row(IntrinsicHeight)` 構成に変更し、最左に accent `Container`、
   その右に既存の Padding + Row (Icon + 本文 + TextButton) を配置

MD3 semantic role による色相区別 (`errorContainer` / `tertiaryContainer`
/ `secondaryContainer`) は維持。CVD タイプ別の見え方は色相に依存しない
3 つの冗長情報で識別可能になった。

**実装サマリ (branch `feature/phase-11-cvd-banner-labels`)**:

- `lib/l10n/app_ja.arb` / `app_en.arb`: 3 重大度ラベルキーを ARB に追加
- `lib/l10n/app_localizations*.dart`: `flutter gen-l10n` で再生成
  (test 起動時に自動再生成された)
- `lib/presentation/widgets/permission_banners.dart`: file-private
  `enum _PermissionBannerSeverity { critical, recommended, supplementary }`
  追加、`_PermissionBanner` に `severity` / `accentKey` フィールド追加、
  タイトルを `Text.rich` でラベル + 既存タイトルの 2 TextSpan 化、
  最外殻を `Material` → `Material > ClipRRect > Row(IntrinsicHeight) >
  [accent Container, Expanded(既存 Padding+Row)]` に変更
- `test/presentation/widgets/permission_banners_test.dart` 新規 7 ケース
  (3 severity ごとのラベル + accent 幅検証、全 granted で SizedBox.shrink、
  Allow タップで `requestNotification`、Open settings タップで
  `openSettings`、3 種同時表示で accent 幅 8 > 5 > 3 の形状差検証)
- BACKLOG.md / docs/dev-log.md / tasklist.md の進捗反映

**スコープ外**:

- 設定画面への CVD ON/OFF トグル (方針 (b) は不採用、BACKLOG L600 で確定済)
- CVD-safe palette (Okabe-Ito / IBM Color Palette) への切替
- 中韓 ARB (`zh` / `zh-Hant` / `ko`) は別 PR (ローカライズ実翻訳タスク)
  と統合 — `ENABLE_EXPERIMENTAL_LOCALES=true` 起動時は
  `AppLocalizations` の fallback 仕様で英訳が当たる前提
- 他ウィジェット (`alarm_ringing_screen.dart` 等) の CVD レビュー

**現状**: 558 テストパス (旧 552 + 新規 7 - 旧 1)、`flutter analyze` 緑、
PR #39 作成済。実機検証 (Pixel 6a + Android「色補正」で Protanomaly /
Deuteranomaly / Tritanomaly 切替時の重大度識別、ライト / ダーク両モード
視認性) はユーザ側で PR レビュー時に実施予定。

---

## Phase 11 follow-up: プリセット管理の発見性改善 (2026-05-12)

Phase 11 ダークモード対応の Pixel 6a 実機検証 (2026-05-12) で、ユーザから
「プリセット管理が右上 overflow menu (3 点リーダー) だと発見しにくい」との
UX フィードバック。設計セッションで案 (a) 空状態ボタン / (b) 長押し /
(c) sheet 末尾エントリ / (d) 2 つ目 FAB / (e) 設定画面集約 を比較し、
発見性 / 既存 UX 影響 / 実装コストのバランスから **(c) sheet 末尾エントリ**
を採用。

**実装サマリ (commits, branch `feature/phase-11-preset-discoverability`)**:

- `PresetSelectResult` に `manageRequested` フィールド追加 (既存
  `preset` / `customRequested` と並ぶ 3 つ目の選択肢)
- `PresetSelectSheet` 末尾の custom button の下に Divider + `TextButton.icon`
  (`Icons.tune`、key `preset_sheet_manage_button`) で「プリセットを管理...」
  エントリ追加。primary action と secondary action を視覚的に分離
- caller `timer_list_page._onAddPressed` で `selection.manageRequested`
  分岐を追加し `unawaited(context.push(PresetManageScreen.routeLocation))`
  で遷移。go_router import 追加
- ARB ja/en に `presetSheetManageButton` 追加 (「プリセットを管理...」/
  "Manage presets...")、`flutter gen-l10n` で `AppLocalizations` 再生成
- `preset_select_sheet_test.dart`: 既存 2 件 (chip+custom 両表示 / empty
  collection) のアサート更新 + 新規 2 件 (manage button が manageRequested
  で pop / customRequested != manageRequested の排他確認) 追加
- Timer タブ AppBar overflow の旧「プリセット管理」エントリは残置
  (両方からアクセス可、慣れたユーザの shortcut を温存)

**現状**: 528 件全件緑 (旧 527 + 新規 1)、`flutter analyze` 緑、PR #35 (push 済 +
review 2 件対応済 + main rebase 済)、CI 緑、**Pixel 6a / Android 16 で 6 シナリオ
実機検証完了 (2026-05-12、不具合なし)**、**main にマージ済 (commit `f05a573`)**。

**実機検証結果**:

- S1 通常状態 (preset あり) で manage button 表示: OK
- S2 Manage button → `/presets` 遷移 + 戻る: OK
- S3 Empty 状態でも manage button 表示 / 遷移: OK
- S4 AppBar overflow 旧導線リグレッションなし: OK
- S5 ダークモードで視認性: OK
- S6 ライトモードで視認性: OK

---

## Phase 11 (ダークモード対応) 実装完了 → 実機検証完了 (2026-05-12)

実機検証完了。Pixel 6a / Android 16 で 7 シナリオ全 OK:

- S1〜S6: すべて期待通り
- **S2 (e)** preset 削除確認ダイアログ: 出ない = 仕様
  (`UserPreferenceKeys.skipPresetDeleteConfirm` が過去操作で永続化済み、
  `preset_manage_screen.dart:357` で skip 判定)。**今後の検証手順書には事前準備
  「`adb shell pm clear com.bonkotu.timer` でクリア」を入れる**
- **S7** Recent 画面のテーマ非追従: Android `TaskSnapshot` 仕様
  (Activity が onPause / onStop の間は再描画されない、フォアグラウンド復帰で
  最新 theme で描画)。**Flutter / アプリ側で対応しても意味がない**

実機検証フィードバックから派生した「プリセット管理発見性」は別 follow-up
(上記参照) で対応済 (PR #35、main にマージ済 commit `f05a573`)。

実機検証以前の元ログは過去セッションを参照。

---

## Phase 11 (ダークモード対応) 実装完了 → 実機検証待ち (2026-05-11)

BACKLOG.md L633「ダークモード対応」を Auto セッションで実装。設計判断は
事前に確定済み (`ThemeMode.system` 固定 / 手動切替 UI と `UserPreferences`
拡張は設定画面タスクに先送り / `ColorScheme.fromSeed` を素直に使う)。

**実装サマリ (commits, branch `feature/phase-11-dark-mode`)**:

- `527bbeb` Step 1: ハードコード色を MD3 semantic role に置換。
  `permission_banners.dart` の 3 種背景 (`Colors.<red|orange|amber>.shade100`)
  を `errorContainer` / `tertiaryContainer` / `secondaryContainer` に、
  `_PermissionBanner` を `DefaultTextStyle.merge` + `IconTheme.merge` で
  包んで `onXxxContainer` を Text/Icon 子孫に伝播、TextButton も
  `foregroundColor: onColor` で揃える。`analog_clock_widget.dart` の秒針
  `Colors.red` を `colorScheme.error` に置換 (両モードで適切な赤を MD3 が返す)
- `ddea3a7` Step 2: `MaterialApp.router` に `darkTheme:` を追加
  (deepPurple seed + `Brightness.dark`)。`themeMode:` は省略 → デフォルトの
  `ThemeMode.system` で OS 設定に追従

**現状**: 2 commit + docs commit (Step 3) で計 3 commit、527 件全件緑
(1 skipped)、`flutter analyze` 緑。

**残作業 (Step 4 = 実機検証、ユーザ push 承認後)**:

1. OS = ダーク設定で HomeScreen 4 タブ (Stopwatch / Timer / Alarm / Clock)
   すべて表示崩れなし
2. 各 modal/sheet がダーク対応:
   - `preset_select_sheet` / `sound_select_sheet` / `preset_edit_sheet`
   - `alarm_edit_screen` / `preset_delete_confirm_dialog` /
     `alarm_delete_confirm_dialog`
3. 権限拒否時の 3 種バナーがダークで視認可能
   (`onErrorContainer` / `onTertiaryContainer` / `onSecondaryContainer`)
4. `AnalogClockWidget` の秒針 (`scheme.error`) がダークで視認可能
5. `LicensesScreen` / `DurationPicker` / `AlarmRingingScreen` のダーク表示
6. OS = ライトに戻して上記すべてリグレッションなし
7. OS テーマ切替を runtime で実施 → アプリ再起動なしで追従する

DoD: 7 シナリオすべて OK。フィードバックは別 follow-up にする。

---

## Phase 11 (HomeScreen PageView) 着手 → 実装完了 → 実機検証待ち (2026-05-10)

Phase 10.5 実機検証 (2026-05-10) のフィードバックで起票された UX 改善
「HomeScreen を 4 機能 (Stopwatch / Timer / Alarm / Clock) の左右 swipe
切替に変える」を、Auto セッションで実装した。設計判断は事前に確定済み
(BACKLOG.md L592-593 + 本タスク Auto 開始時の指示書)。

**実装サマリ (commits, branch `feature/phase-11-home-pageview`)**:

- `a19c179` Step 1: ClockScreen 内部 PageView を SegmentedButton 化
  (Analog / Digital / Compact)。外側タブ swipe との gesture 競合を根本除去
- `44fdd14` Step 2: 各タブの body を Page widget として
  `lib/presentation/screens/home/<feature>_page.dart` に切り出し。deep link
  Screen は薄ラッパに縮退 (FAB / overflow ロジックは Page の static helper
  で共有)
- `d97026f` Step 3: `UserPreferences` port を `getInt` / `setInt` で拡張、
  `UserPreferenceKeys.lastHomePageIndex` を追加。テスト + adapter + 既存
  test mocks を更新
- `a76e6c8` Step 4: 新 HomeScreen 実装。`ConsumerStatefulWidget` +
  `PageController` + 動的 AppBar (`PageNavigationHint` leading + label-less
  trailing) + 動的 FAB + Stack mount の `HomeDotIndicator` (旧 ClockScreen
  の private `_DotIndicator` を public 化)。`lib/main.dart` の旧 4 ボタン
  HomeScreen を削除し import 切替。`homeOpen*` ARB 4 キーは短ラベルとして
  値変更で再利用 (旧用途は削除済み)
- `afb0ab5` Step 5: `home_screen_test.dart` を 10 シナリオで全面書き換え
  (デフォルト復元 / 復元 / 双方向 swipe / 末端 no-op / hint タップ /
  DotIndicator active / FAB 切替 / overflow → /licenses / overflow context
  別出し分け / setInt 永続化 verify)。`find.byType(<Page>)` ベースで
  AppBar title と隣接ヒントラベルの衝突を回避

**現状**: 6 commit 済、518 テストパス、`flutter analyze` 緑。
docs (`architecture.md` Presentation 節 + ディレクトリ図 /
`state-management.md` UserPreferences API 拡張) と `BACKLOG.md` 更新済。

**残作業 (Step 7 = 実機検証、ユーザ確認後)**:

1. 初回起動で Timer タブ表示
2. 横 swipe で 4 タブ切替が滑らか、DotIndicator 追従
3. 各タブの FAB / overflow が context に応じて出現
4. Clock タブで SegmentedButton による 3 デザイン切替 (横 swipe しても
   外側 PageView がそのまま動作)
5. アプリ強制終了 → 再起動で最後のタブが復元
6. 通知タップ deep link で `/alarm-ringing` 直接遷移、Stop で正しいパスに
   戻る (既存挙動)

DoD: 6 シナリオすべて OK。フィードバックは別 follow-up にする。

### Phase 11 follow-up #2 (2026-05-11): Clock タブの UX 一貫性改善

実機検証 (2026-05-11、Pixel 6a / Android 16) で Phase 11 基本動作 / PR #29
レビュー対応 (G1-C1) / 既存機能リグレッションは全て OK。あわせてユーザから
1 件の UX 改善要望:「Clock タブだけ overflow menu に『都市を編集』が置かれて
おり、Timer / Alarm の『右下 FAB で追加・編集画面に遷移』UX と一貫していない」。
世界時計は「複数都市の時差確認」が機能本質で、ユーザ視点では「時計を増やす」
操作なので、文言も「時計を追加・編集」に揃える方針で対応。

**実装内容 (PR #29 に積み増し、`feature/phase-11-home-pageview` の追加 commit)**:

- `c17dad8` feat(phase-11): Clock タブの overflow menu「都市を編集」を廃止して
  右下 FAB (`clock_list_add_fab`) に置換。HomeScreen / ClockScreen 薄ラッパー
  両方を同じ UX に揃え、ARB `clockListAddFab` 新規 + `clockLocationPickerAppBarTitle`
  を「時計を追加・編集」/「Add or edit clocks」に更新。テスト (g)/(i) 書き換え +
  新規 (o)、clock_screen_test の overflow テストを FAB 経由に書き換え

**内部識別子のリネームについて**: クラス名 `ClockLocationPickerScreen` / ルート
`/clock/locations` / ARB キー名 (`clockLocationPickerAppBarTitle` 等) は
`Location` (都市) 由来のまま残置。表示文言だけを「時計」観点に更新し、内部識別子
リネームは BACKLOG.md Phase 11 に future task として記録 (影響範囲が広いため別 PR)。

**現状**: 523 件全件緑 (旧 522 + 新規 (o) 1)、`flutter analyze` 緑、
`dart format` 通過済。push 承認待ち。

---

## Phase 10 完了内容（2026-05-09）

端末再起動後の Timer + Alarm 復元。採用方針は純 Flutter
(Native BootReceiver は新設しない)。詳細は
[docs/android-constraints.md](android-constraints.md) の起動時復元セクション参照。

- `RECEIVE_BOOT_COMPLETED` 権限は Phase 1 で宣言済
- flutter_local_notifications の `ScheduledNotificationBootReceiver` で
  boot 後の保留通知が再登録される (パッケージ標準動作)
- Timer の起動時状態復元は Phase 8 で完了 (過去到達は completed + show)
- Alarm の起動時状態復元: enabled な alarm を `AlarmService.nextFireAt`
  で再 schedule (Phase 9.5 で完了)
- Alarm 過去到達 once-mode: enabled=false に落として show 通知 1 回
  (`AlarmCollectionNotifier._loadFromRepository` に `_isPastDueOnce`
  ヘルパで判定追加)

### 実機検証 (Pixel 6a / Android 16、2026-05-09 完了)

1. 5 分後 timer 設定 → 端末再起動 → 4 分後に通知発火 (OK、1 巡目)
2. 翌朝の once-mode alarm 設定 → 端末再起動 → 翌朝定刻に発火
   (1 巡目 NG → manifest `exported="true"` 修正後の 2 巡目で OK)
3. 過去到達 once-mode alarm 擬似作成 → 起動後 enabled=false +
   show 通知 1 回 (Settings → Force stop → 日時進行 → launcher 起動の
   2 巡目手順で OK。cold-start 時に heads-up 1 回、AlarmRingingScreen
   自動遷移なし、通知タップで遷移、Stop 後にカード OFF)
4. weekly alarm (明日のみ) を再起動跨ぎで翌日定刻に発火 (OK、1 巡目)

392 テストパス。

---

## Phase 10.5 Application 層 + Infrastructure location adapter (2026-05-09 完了)

実装完了 (2026-05-09):

- [x] `lib/infrastructure/location/country_to_timezone.dart`: 約 40 ヶ国の
  ISO 3166-1 alpha-2 → 代表 IANA TZ マップ (大文字小文字混在対応、未登録 null)。
  `TimezoneCatalog` の単一 TZ 国 (US/CA の subdivision を除く) を全カバー。
- [x] `lib/infrastructure/location/location_detector_adapter.dart`:
  geolocator (coarse / 5s timeout) → geocoding (5s timeout) →
  `CountryToTimezone.lookup` → `FlutterTimezone.getLocalTimezone()` →
  最終 fallback `Asia/Tokyo` のチェーン。各段 try/catch で握りつぶし。
  Unit Test なし (MethodChannel 依存で mock 困難、実機検証で担保)。
- [x] `lib/application/clock_location_repository_provider.dart`:
  preset 流儀の stub (`@Riverpod(keepAlive: true)`)。
- [x] `lib/application/location_detector_provider.dart`: 同上の stub。
- [x] `lib/application/clock_collection_notifier.dart`:
  State = `ClockCollection` 集約直接 (preset 流儀)。
  `build()` 内 microtask で DB 復元 + 空なら detector で「現在地」種付け。
  `addPreset` / `remove` / `reorder` (replaceAll で atomic 永続化) /
  `update(displayName)` / `debugSetIdGenerator` 公開。
- [x] `lib/application/clock_tick/current_time_stream_provider.dart`:
  関数形式 `@riverpod` (autoDispose)。`Stream.multi` で初回即時 emit +
  `Timer.periodic(1s)` を `clockProvider` 経由で発火、`onCancel` で停止。
- [x] `lib/main.dart`: `DriftClockLocationRepository` +
  `LocationDetectorAdapter` を `ProviderScope.overrides` に追加。
- [x] Unit Test 3 ファイル (country_to_timezone 3 ケース /
  ClockCollectionNotifier 11 ケース / currentTimeStreamProvider 2 ケース、
  計 16 ケース全パス)。
- `flutter analyze`: No issues found
- `flutter test`: 465 件 pass (Phase 10.5 Infrastructure DB 完了時 449 件 + 16 件)

次セッションへの持ち越し: **Presentation 層のみ** —
`presentation/widgets/analog_clock_widget.dart` /
`digital_clock_widget.dart` / `clock_design_a/b/c.dart` /
`presentation/screens/clock_screen.dart` /
`clock_location_picker_screen.dart`、
`lib/main.dart` の `go_router` への `/clock` / `/clock/locations` 追加、
`HomeScreen` の Clock 導線追加。

### Session 1 完了 (2026-05-10): TZ resolver adapter + 低レベル時計 widget 2 種

- [x] `lib/infrastructure/clock/tz_database_timezone_resolver.dart`:
  `tz.initializeTimeZones()` を static flag で 1 度だけ実行、
  `tz.LocationNotFoundException` を `InvalidTimezoneIdException` に
  再 throw。
- [x] `lib/application/timezone_resolver_provider.dart`:
  `@Riverpod(keepAlive: true)` stub (preset / detector 流儀)。
- [x] `lib/main.dart`: `TzDatabaseTimezoneResolver` を生成、
  `ProviderScope.overrides` に 1 行追加 (HomeScreen / router 等は触らず)。
- [x] `lib/presentation/widgets/analog_clock_widget.dart`:
  `ConsumerWidget` + `CustomPaint`、文字盤 + 12 目盛 + 時/分/秒針、
  秒針赤、時/分は `colorScheme.onSurface`。
- [x] `lib/presentation/widgets/digital_clock_widget.dart`:
  `padLeft(2, '0')` の手書きフォーマット (preset_label_formatter 流儀、
  `intl` 直接 import を回避)、`tabularFigures()` で digit jitter 抑止。
- [x] Test 3 ファイル (resolver 3 ケース / analog 2 active + 1 skip /
  digital 3 ケース、計 8 active + 1 skip 全パス)。
- `flutter analyze`: No issues found
- `flutter test`: 473 active + 1 skipped = 474 件 (既存 465 + 新規 8 + skip 1)

次セッション (Session 2) へ: clock_design_a/b/c のいずれか + 親 screen の
1st スライス (本セッションでは導線追加・router 編集はスコープ外)。

### Session 2 完了 (2026-05-10): 3 種デザインバリアント widget

- [x] `lib/presentation/widgets/clock_design_a.dart` (94 行): GridView.count
  2x3、Card 内 AnalogClockWidget(96) + 名 + DigitalClock(HH:mm) +
  UTC offset。`_formatUtcOffset(Duration)` は分単位対応 (Kolkata/Adelaide)。
- [x] `lib/presentation/widgets/clock_design_b.dart` (90 行): ListView.separated、
  Row(Expanded(name + DigitalClock 36px), trailing(M/d + UTC offset))。
- [x] `lib/presentation/widgets/clock_design_c.dart` (67 行): GridView.count
  3x2、AnalogClock(64) + 名 ellipsis + DigitalClock(18, no seconds)。
  仕様通り UTC offset は省略 (cell budget 不足)。
- [x] Test 3 ファイル × 2 ケース = 6 件: 6 件 displayName 全表示 + 空 hint key。
  test surface を 800x1600 に拡大して GridView 全行 layout を保証。
- `flutter analyze`: No issues found
- `flutter test`: 480 件 pass (Session 1 の 474 + 新規 6)

次セッション (Session 3) へ: ClockScreen + currentTimeStreamProvider 配線 +
PageView/TabBar での 3 デザイン切替。

### Session 3 完了 (2026-05-10): ClockScreen + PageView デザイン切替

- [x] `lib/presentation/screens/clock_screen.dart`: `ConsumerStatefulWidget`、
  `currentTimeProvider` を 1 度 watch して 3 design widget に props 注入。
  AppBar overflow に「都市を編集」1 件、`context.push('/clock/locations')`
  (router 配線は Session 5)。Stack で PageView + 底辺 `_DotIndicator(3)` を
  重ね、`onPageChanged` で active dot 更新。FAB なし (閲覧画面)。
- [x] `test/presentation/screens/clock_screen_test.dart`: 4 シナリオ
  (初期表示 / 横スワイプ / overflow → push / 時刻 stream 伝搬 smoke)。
  `_SeededClockCollectionNotifier` で `build()` を直接 override し
  microtask 経由の repo/detector 呼び出しを回避。`currentTimeProvider`
  は `Stream.value(...)` か `Stream.fromIterable([t1,t2])` の finite
  stream で override (周期 stream で `pumpAndSettle` が hang する
  既知問題の回避)。
- `flutter analyze`: No issues found
- `flutter test`: 493 件 pass (Session 2 の 480 + 既存 +9 + 新規 4)

次セッション (Session 4) へ: ClockLocationPickerScreen の実装
(`/clock/locations` の中身)。

### Session 4 完了 (2026-05-10): ClockLocationPickerScreen + 上限ガード

- [x] `lib/presentation/screens/clock_location_picker_screen.dart`:
  `ConsumerWidget` 1 ファイル。Column ベースで上半分に
  `ReorderableListView.builder` (pinned + delete IconButton + drag 並替)、
  下半分に `ListView.builder` (TimezoneCatalog 重複除外)。
  `isFull` 時は catalog 全行 `enabled: false` + limit banner、
  `MaxClockLocationCountExceededException` を try/catch して
  SnackBar フォールバック。l10n キーは ja/en 両方追加 (gen-l10n 済)。
- [x] `test/presentation/screens/clock_location_picker_screen_test.dart`:
  5 シナリオ (初期表示 / catalog tap で addPreset / 上限到達で disable +
  banner / `ReorderableListView.onReorder` 直接呼び出しで reorder /
  delete IconButton で remove)。Notifier mock ではなく
  `_SeededClockCollectionNotifier` で初期 state を植え、実 mutation
  メソッドを ProviderContainer.read で観察 (clock_screen_test 流儀)。
  Surface 800x3000 で catalog 25 件 lazy build を全件 layout。
- `flutter analyze`: No issues found
- `flutter test`: 498 件 pass (Session 3 の 493 + 新規 5)

### Session 5 完了 (2026-05-10): router 配線 + HomeScreen ボタン + l10n 完成 + docs 更新 (Phase 10.5 クローズ)

- [x] `lib/main.dart`: `presentation/screens/clock_screen.dart` /
  `presentation/screens/clock_location_picker_screen.dart` の import
  を alphabetical 順で追加、`routes` 配列に `ClockScreen.routeLocation`
  / `ClockLocationPickerScreen.routeLocation` の 2 GoRoute を挿入、
  HomeScreen に「世界時計を開く」ボタン (`home_open_clock_button`,
  `context.push(ClockScreen.routeLocation)`) を追加。
- [x] `lib/l10n/app_ja.arb` / `lib/l10n/app_en.arb`: `homeOpenClock`
  と `clockEmptyHint` の 2 キーを追加 (description 不要、既存 7 キーは
  Session 1〜4 で追加済)。`flutter gen-l10n` warning 0。
- [x] `lib/presentation/widgets/clock_design_a.dart` /
  `clock_design_b.dart` / `clock_design_c.dart`: empty branch の英語
  固定文 `'No cities yet — tap menu to add'` を `l.clockEmptyHint`
  経由に置換 (Session 2 で deferred)。Key は `const Key(...)` に格上げ。
- [x] `test/presentation/screens/home_screen_test.dart` 新規:
  4 シナリオ (Stopwatch / Timer / Alarm / Clock の各ボタンタップで
  対応 route の placeholder text に到達する smoke test)。実画面では
  なく軽量 Scaffold placeholder を route builder にマウントし、
  HomeScreen 自身は provider 直 watch しないため override は空。
- [x] `test/presentation/widgets/clock_design_a_test.dart` /
  `clock_design_b_test.dart` / `clock_design_c_test.dart`:
  `MaterialApp` に `localizationsDelegates` /
  `supportedLocales` / `locale: Locale('ja')` を追加
  (l10n 化に伴い `AppLocalizations.of(context)` 解決のため)。
  アサート内容 (Key による empty 検証) は変更なし。
- [x] `docs/architecture.md`: `lib/` ツリーの Phase 10.5 注釈を
  「予定」→「で実装済み」に一括更新、`infrastructure/clock/` を
  実ファイル名 `tz_database_timezone_resolver.dart` に修正、
  `application/timezone_resolver_provider.dart` /
  `clock_location_repository_provider.dart` を追記、
  `presentation/widgets/` に `utc_offset_formatter.dart` /
  `page_navigation_hint.dart` を追記、`domain/clock/` に
  `timezone_catalog.dart` を追記。
- [x] `docs/state-management.md`: `currentTimeStreamProvider` /
  `clockCollectionNotifierProvider` /
  `clockLocationRepositoryProvider` /
  `locationDetectorProvider` の表記を「実装済み」へ、
  `timezoneResolverProvider` 行を Provider 表に追加、
  ClockCollectionNotifier 節タイトルと依存関係図 / lifecycle 表 /
  ディレクトリ構造図 (L408-) を「実装済み」表記に統一。
- [x] `docs/domain-model.md`: Clock Aggregate 節と例外表 / DB 表の
  「予定」を「実装済み」に書き換え、ClockTime 節末尾に新規サブ
  セクション「Presentation 層からの参照（Phase 10.5）」を追加
  (ClockScreen / ClockLocationPickerScreen の watch 対象 Provider
  と mutation 経路を 5 行で記述)。
- `flutter analyze`: No issues found
- `flutter test`: 502 件 pass (Session 4 の 498 + 新規 4 = HomeScreen
  4 シナリオ)

Phase 10.5 全体の DoD 達成。残るは BACKLOG.md L561-568 の実機検証
6 シナリオ (Pixel 6a, Android 16) のみ — ユーザ手動でクローズ予定。

### 内部判断 (本セッション中に発生、要確認)

- プラン記載のテスト「`TimezoneCatalog.presets` の全 timezoneId が
  CountryToTimezone の値域に含まれる」は、「1 国 1 TZ ルール」(US→NY,
  CA→Toronto) と数学的に両立しないため、テストを「subdivision のみで
  存在する 6 TZ (Chicago / Denver / LA / Vancouver / Anchorage / Honolulu)
  を除いた catalog エントリが lookup で到達可能」に書き換えた。これら
  6 TZ は picker 経由の手動選択でカバーする想定 (Phase 10.5 picker は
  Presentation 層スコープ)。

## Phase 10.5 実機検証 (Pixel 6a / Android 16、2026-05-10 完了)

Sessions 1〜5 (Domain / Infra / Application / Presentation / l10n / docs)
で Phase 10.5 本体実装完了後の実機検証。フィードバック対応 PR #26 / #27 を
含めて 8 シナリオすべて OK。

1. 初回「世界時計を開く」tap → 位置情報許可 → 「現在地」時計が自動追加
   (Tokyo として登録)
2. 同上で位置情報拒否 → 端末タイムゾーン (`Asia/Tokyo`) で「現在地」登録
3. 地域追加 (LA / NY / London 等) → Grid に表示、秒単位で更新
4. PageView スワイプでデザイン A/B/C 切替 (PR #26 で C↔A 循環追加、
   再検証で OK)
5. アプリ強制終了 → 再起動 → 時計リストが Drift から復元される
6. 並べ替え / 削除動作
7. 上限ガード (6 件 → 7 件目で SnackBar)
8. PR #26 で対応: ドットインジケータ可視性、都市カタログ A-Z 並び。
   再検証時に 3-button ナビゲーションバーとの重なりが指摘され、PR #27 で
   SafeArea 対応

504 テストパス。

---

## Phase 10.5 Infrastructure 層 DB スライス (2026-05-09 完了)

実装完了 (2026-05-09):

- [x] `lib/infrastructure/database/app_database.dart`: schemaVersion 3 → 4、
  `ClockLocations` テーブル追加、`onUpgrade` に v3 → v4 マイグレーション追加
- [x] `lib/infrastructure/database/mappers/clock_location_mapper.dart`:
  toRow / toCompanion / toEntity の 3 メソッド (preset 流儀)
- [x] `lib/infrastructure/database/drift_clock_location_repository.dart`:
  findAll は `displayOrder ASC` で order by、replaceAll は transaction
  内で delete → batch insert
- [x] `lib/infrastructure/clock/timezone_catalog.dart`: 主要都市 25 件
  プリセット (Pure Dart 定数、Tokyo / Seoul / Shanghai / HK / Singapore /
  Bangkok / Kolkata / Dubai / Moscow / Berlin / Paris / London /
  Sao Paulo / NY / Toronto / Mexico City / Chicago / Denver / LA /
  Vancouver / Anchorage / Honolulu / Sydney / Auckland)
- [x] Unit Test 3 ファイル (mapper 8 ケース / repository 12 ケース /
  catalog 5 ケース、計 25 ケース全パス)
- `flutter analyze`: No issues found
- `flutter test`: 449 件 pass (Phase 10.5 Domain 完了時 425 件 + 24 件)

次セッションへの持ち越し: Phase 10.5 Infrastructure 層の残り
(`location_detector_adapter` + 国コード→TZ マップ) と Application 層
(`clock_collection_notifier` / `current_time_stream_provider`)、
Presentation 層。`location_detector_adapter` 着手時に `pubspec.yaml` への
geolocator / geocoding 追加と `AndroidManifest.xml` への
`ACCESS_COARSE_LOCATION` 追加が必要 (要ユーザ確認)。

### 着手前 Plan (2026-05-09)

範囲を **Domain 層 6 ファイル + Unit Test 4 ファイル** に限定。Infrastructure /
Application / Presentation には踏み込まない。pubspec.yaml への
geolocator / geocoding 追加と AndroidManifest.xml への
`ACCESS_COARSE_LOCATION` 追加は別セッションで指示する想定。

### 確定方針 (2026-05-09 ユーザ判断)

- 論点 1 → **案 A**: clock_time.dart に ClockTime ValueObject (freezed)
  と abstract `TimezoneResolver` を同一ファイル同居。timezone パッケージは
  Infrastructure 層 adapter 側で wire (Domain は import しない)
- 論点 2 → **preset 流儀**: ClockLocationRepository は findAll / findById /
  upsert / delete / replaceAll の 5 メソッド (BACKLOG L499 の add/update
  分離案ではなく、既存 preset / alarm port と統一)
- 論点 3 → **追記**: `ClockLocationNotFoundException` を docs/domain-model.md
  L621 の例外一覧に追記

### 実装ファイル

1. lib/domain/clock/clock_location.dart (freezed Entity、id / displayName /
   timezoneId / isCurrentLocation / displayOrder / createdAt)
2. lib/domain/clock/clock_collection.dart (集約ルート、maxSize=6、
   reorder で displayOrder 0..N-1 再採番、currentLocation 一意性を集約で保証)
3. lib/domain/clock/clock_time.dart (案 A: ClockTime VO + abstract TimezoneResolver)
4. lib/domain/clock/exceptions.dart (3 例外: Max / NotFound / InvalidTimezoneId)
5. lib/domain/ports/clock_location_repository.dart (preset 流儀)
6. lib/domain/ports/location_detector.dart (`Future<String> detectTimezoneId()`)

不変条件 (displayName.length / displayOrder 範囲 / timezoneId 妥当性) は
alarm_entity 流儀で **Application 層 enforce**。freezed 上では throw しない。

### Unit Test (test/domain/clock/、4 ファイル)

- clock_location_test.dart (equality / copyWith)
- clock_collection_test.dart (empty / add / update / remove / reorder /
  fromList / currentLocation 一意性 / immutability、PresetCollection_test 流儀)
- clock_time_test.dart (ClockTime VO の equality / copyWith のみ。
  TimezoneResolver は abstract のためテストなし)
- clock_exceptions_test.dart (toString)

### docs 更新

- docs/domain-model.md L621 の例外一覧に
  `ClockLocationNotFoundException` を追記 (ユーザ承認済)

### 作業フロー

1. ファイル群を Write
2. `dart run build_runner build --delete-conflicting-outputs` で freezed 生成
3. `flutter analyze` 緑、`flutter test` 全件パス確認 (現状 392 件 → +Domain 分)
4. 1 commit (`feat(phase-10.5): clock domain layer`)
5. tasklist.md / BACKLOG.md L495-500 に [x] マーク (Phase 10.5 全体は未完)
6. ユーザに完了報告して停止 (Infrastructure 層は別セッション)

### 停止条件 / スコープ外 (本セッションで触らない)

- Infrastructure 層 (Drift schema migration / drift_clock_location_repository /
  location_detector_adapter / timezone_catalog)
- Application 層 (clock_collection_notifier / current_time_stream_provider)
- Presentation 層
- pubspec.yaml への geolocator / geocoding 追加 (要ユーザ確認)
- AndroidManifest.xml への ACCESS_COARSE_LOCATION 追加 (要ユーザ確認)

---

## Follow-up タスク (Phase 10 派生 / PR #16 レビュー対応で抽出)

### F-5. `TimerCollectionNotifier._restoreFromRepository` の cancel 漏れ ✅ 完了

**経緯**: PR #16 Copilot レビューで `AlarmCollectionNotifier._loadFromRepository`
の past-due once-mode 検知時に OS 側保留予約 (AlarmManager) を cancel していない
問題を修正済 ([fde2dbd](https://github.com/Bonkoturyu/TimerUtility/commit/fde2dbd))。
同じ構造が [`TimerCollectionNotifier._restoreFromRepository`](../lib/application/timer_collection_notifier.dart)
の overdue 処理 (running → completed 書き換え) にもあったため alarm 側と挙動を
揃える形で修正した。

**修正内容** (2026-05-09):

- [`TimerCollectionNotifier._restoreFromRepository`](../lib/application/timer_collection_notifier.dart)
  の overdue ループに `_cancelNotification(t.notificationId)` を 1 行追加。
  順序は `repo.upsert(t)` → `_cancelNotification` → `_showRestoredCompletionNotification`
  (alarm 側 `_persist` → `_cancel` → `_showMissedAlarmNotification` と同じ)。
- [`test/application/timer_collection_notifier_test.dart`](../test/application/timer_collection_notifier_test.dart)
  の「restoring a past-due running timer marks it completed and shows」に
  `verify(() => scheduler.cancel(1)).called(1)` を追加。
- 392 テストパス、`flutter analyze` 緑。

### F-6. テスト全件の `Future.delayed(Duration.zero)` → `fakeAsync` 一括リファクタ or styleguide 改定 ✅ 完了 (案 1: styleguide 改定)

**経緯**: PR #16 gemini-code-assist レビューで [`.gemini/styleguide.md` line 63](https://github.com/Bonkoturyu/TimerUtility/blob/main/.gemini/styleguide.md#L63)
「時間制御テストは fake_async を使用、実時間 sleep / Future.delayed で待機するのは禁止」
への違反として `Future<void>.delayed(Duration.zero)` が指摘された。本 PR は
スコープ外として却下したが、リポジトリ全 notifier 系テストで同パターンが
慣用句化している実態がある:

- `test/application/timer_collection_notifier_test.dart` (line 279, 324)
- `test/application/preset_collection_notifier_test.dart` (line 66, helper `settleRestore()` で共通化済)
- `test/application/alarm_ringing_notifier_test.dart` (line 91, 113, 128, 131, 151, 156)
- `test/application/alarm_collection_notifier_test.dart` (line 488-491, 535-536, 587-588, 641-642)
- `test/presentation/screens/alarm_list_screen_test.dart` (line 179)、`alarm_edit_screen_test.dart` (line 314, 346, 396, 408)、`alarm_ringing_screen_test.dart` (line 249)

**用途**: `build()` 内の `Future.microtask(_loadFromRepository)` を pump する
microtask flush。「実時間 sleep」ではない (styleguide line 63 が本来禁ずる
`Duration(seconds: N)` で時間進行を待つパターンとは性質が異なる)。

**対応案** (どれか 1 つ):

1. **styleguide 改定**: line 63 の文言を `Future.delayed(Duration.zero)` (microtask flush
   用途) を例外扱いと明文化する。実装変更なしで完了。
2. **全件 `fakeAsync` リファクタ**: 上記全テストファイルを `fakeAsync` ベースに
   書き換え、`Future.microtask` の pump は `async.flushMicrotasks()` で代替。
   スコープ大、Riverpod の microtask scheduling との相性検証が必要。
3. **共通 helper 化**: `preset_collection_notifier_test.dart` の `settleRestore()`
   ヘルパを `test/helpers/` に格上げして全テストで共通利用。styleguide 違反は
   残るが、慣用句化を明示できる。

**推奨**: 案 1 (styleguide 改定) → 実害なし、現実とドキュメントを揃える。
本格的に時間進行を伴うテストが増えてから案 2 を検討。

**優先度**: 低 (テストは全件緑で動作上の問題なし、スタイルガイドと実装の
ドリフト解消が目的)。

**最終対応** (2026-05-09): 案 1 を採用。
[`.gemini/styleguide.md` line 63](../.gemini/styleguide.md#L63) を改定し、
`Future<void>.delayed(Duration.zero)` / `Future<void>.value()` を
Riverpod Notifier の `build()` 内 `Future.microtask(_loadFromRepository)` を
pump する microtask flush 用途として明示的に許容、禁止対象は実時間
進行を伴う `Future.delayed(Duration(seconds: N))` 等に限定する形に整理。
実装変更なし、テスト緑のまま。

---

## Follow-up タスク (Phase 9.5 派生)

### F-4. cold-start FSI 後の戻るキーでアプリ終了 + Recent 二重起動 ✅ 完了

#### F-4 修正内容 (B + C 案併用、2026-05-04)

実機検証 (Pixel 6a / Android 16、2026-05-04) シナリオ 4 で観測した
2 種類の症状 (戻るキー押下でアプリ終了 / Recent に task 2 つ並ぶ) に
Native 側 + Flutter 側の両面で対処:

- **B 案 (Native)**: [`AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml)
  の MainActivity を `launchMode="singleTop"` → `"singleTask"` に強化、
  併せて `taskAffinity=""` 属性を削除。`taskAffinity=""` は Phase 1
  雛形に紛れ込んだまま放置されており、同一パッケージの Activity を
  別 task root として扱わせる副作用 (Recent 二重表示の主因) があった。
  デフォルト affinity (`com.bonkotu.timer.timer_utility`) に戻し、
  ランチャー起動 / 通知 cold-start / FSI のいずれの経路でも 1 task に
  収束させる。
- **C 案 (Flutter)**: [`alarm_ringing_screen.dart`](../lib/presentation/screens/alarm_ringing_screen.dart)
  `_leaveAlarmScreen` の cold-start fallback (`!context.canPop()`) を
  `context.go('/alarms' or '/timer')` 1 段スタックから、`router.go('/')` →
  `router.push(dest)` の Home → list の 2 段スタックに変更。これで
  list 画面で戻るキーを押すと Home → アプリ終了の順に正しく辿れる。
- **回帰テスト**: [`alarm_ringing_screen_test.dart`](../test/presentation/screens/alarm_ringing_screen_test.dart)
  に「cold-start: Stop rebuilds Home → list 2-stack so back returns to home」
  テスト 1 件追加。`initialLocation = '/alarm-ringing'` の cold-start 状態で
  起動 → Stop → `GoRouter.pop()` で home-stub に戻れることを検証 (PR #13
  Copilot review 反映)。

#### F-4 実機検証 (Pixel 6a / Android 16、2026-05-04 完了)

- [x] シナリオ 4 再現確認: cold-start FSI → AlarmRingingScreen → 停止 →
      list 表示 → 戻るキー → **Home に戻る** (アプリ終了しない)
- [x] Recent (□) 表示が 1 task のみ (2 つ並ばない)
- [x] 副作用なし確認:
  - 通常起動 (ランチャー) → 動作不変
  - warm-launch FSI (アプリ前面/背景) → 既存フロー通り
  - lock-screen FSI → keyguard override が引き続き効く
  - 通知タップ (warm) → AlarmRingingScreen → 停止 → 元画面に戻る
    (`context.canPop()` パス、Home 経由しない)

### F-3. permission UX バグ修正 (実機検証で発覚) ✅ 完了

実機検証 (Pixel 6a / Android 16、2026-05-04) でシナリオ 1 が再現せず、
原因調査の結果以下 2 段の問題が判明 → PR #11 に追加 commit で対応:

- (a) AlarmListScreen が `permissionNotifierProvider.refresh()` を呼ばず
  state が `unknown` のまま → `_scheduleAt` で `useExact = false` →
  `inexactAllowWhileIdle` schedule で発火が大幅遅延 (1 分後の発火が
  起きない実機事象の主因)
- (b) AlarmListScreen に permission banner が無く、ユーザは権限不足を
  画面上で気付けない (TimerListScreen にしか banner が無かった)

#### F-3 修正内容

- [PermissionBanners](../lib/presentation/widgets/permission_banners.dart)
  を共通 widget として切り出し (元は TimerListScreen の private クラス)
- [AlarmListScreen](../lib/presentation/screens/alarm_list_screen.dart) を
  `ConsumerStatefulWidget` 化、`initState` の microtask + `didChangeAppLifecycleState(resumed)` で
  `permissionNotifierProvider.refresh()` を呼ぶ TimerListScreen と
  同じパターンを移植、`PermissionBanners` を body 上部に配置
- [AlarmCollectionNotifier._scheduleAt](../lib/application/alarm_collection_notifier.dart)
  を内部で `_scheduleAtAsync` に分離し、`unknown` のとき先に `await
  refresh()` してから exact/inexact 判定 (画面遷移が高速な場合の race 対策)
- alarm_list_screen_test.dart に banner 表示 / 非表示の Widget Test
  2 件追加 (denied 状態 + 全 granted 状態)

### F-2. auto-request-copilot-review.yml の silent fail 対策 → workflow 廃止 ✅ 完了

優先度: 低 (手動で `gh pr edit N --add-reviewer @copilot` 実行で復旧可能)

#### F-2 背景

PR #11 で Action (`auto-request-copilot-review.yml`) が exit 0 success
で完了したものの、`gh api repos/.../pulls/11/requested_reviewers` 結果は
`{users: [], teams: []}` で **silent fail** していた。手動で同じコマンドを
実行すると正常に追加された。

#### F-2 調査結果 (PR #15 で実施、2026-05-04)

第 1 段で silent fail 検出ロジック (`set -euo pipefail` + API 読み返し
による exit 1) を入れて PR #15 で再現確認した結果:

- `gh pr edit --add-reviewer @copilot` は内部で REST `POST /pulls/N/requested_reviewers`
  を叩く。このエンドポイントは **user / team のみ受け付け、bot (Copilot) は
  silently 無視される** (GitHub maintainer 公式回答:
  [community#157751](https://github.com/orgs/community/discussions/157751))
- 手動 (個人 PAT) で動くのは `gh` CLI が PAT 認証時に Copilot 専用の
  GraphQL `requestReviews(input: { botIds: [...] })` 経路を使うため
  ([community#186152](https://github.com/orgs/community/discussions/186152))
- `secrets.GITHUB_TOKEN` でこの GraphQL 経路を叩くには追加の特別スコープが
  必要で、`pull-requests: write` だけでは不足。公式 docs にも
  「`pull-requests: write` で reviewer 追加可」の明記なし
- 公式の推奨自動化経路は **Settings → Copilot → Code review → 自動レビュー
  有効化** ([Configure automatic review](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/configure-automatic-review))

#### F-2 最終対応 (2026-05-04)

ユーザ確認の結果、Settings → Copilot → Code review は **PR #7 頃から
既に有効化済** だったことが判明:

- `Copilot review for default branch` ruleset (3 rules、main を target)
- `Automated code reviews on push` enabled
- Free private repo でも動作することを実機で確認

つまり過去 PR (#7〜#14) で Copilot review が付いていたのは **すべて
Settings ruleset 経由** であり、workflow は最初から silent fail し
続けていた (一度も機能していなかった)。workflow
`.github/workflows/auto-request-copilot-review.yml` は **冗長コード** で
あり、削除しても機能的リグレッションは発生しない。

最終対応:

- `.github/workflows/auto-request-copilot-review.yml` を削除
- 追加の Settings 操作は不要 (既に有効)

---

## Phase 9.5 実装ログ (2026-05-03 着手 → 2026-05-04 実装完了)

ブランチ: `feat/phase-9-5-scheduled-alarm` (PR #10) → 残作業を main に直接 commit
参照: BACKLOG.md L359-437 / docs/adr/0005-alarm-vs-timer-separation.md /
docs/domain-model.md L355-436 / docs/state-management.md L84/198-215

### Plan (Phase 8/9 のレイヤー単位 commit パターン踏襲)

各レイヤー完了で `flutter analyze` + `flutter test` 緑を確認 → commit。

1. **Domain 層** (lib/domain/alarm/)
   - `day_of_week.dart` (Pure Dart enum、`DateTime.weekday` と互換マッピング)
   - `alarm_repeat.dart` (sealed: `AlarmRepeatOnce` / `AlarmRepeatWeekly(Set<DayOfWeek>)`) + Unit Test
   - `alarm_entity.dart` (freezed、domain-model.md L362-373 の定義に従う)
   - `alarm_service.dart` (`Clock` 注入、`nextFireAt` / `advanceAfterFire` / `snoozeUntil`) + Unit Test
   - `exceptions.dart` (`AlarmNotFoundException` / `MaxAlarmCountExceededException`
     / `InvalidAlarmRepeatException` / `InvalidSnoozeMinutesException`)
   - `lib/domain/ports/alarm_repository.dart` (`add` / `update` / `delete` / `findById` / `findAll`)

2. **Infrastructure 層**
   - `app_database.dart` に `Alarms` テーブル追加 (schemaVersion 2 → 3 + onUpgrade)
   - `alarm_mapper.dart` (`AlarmEntity ⇔ AlarmRow / AlarmsCompanion`、
     `AlarmRepeat` は専用列 `repeatKind` (text) + `repeatDaysBitmask` (int) で永続化)
   - `drift_alarm_repository.dart` + Unit Test (in-memory)

3. **Application 層**
   - `alarm_repository_provider.dart` (override-required、main.dart で wire)
   - `alarm_service_provider.dart`
   - `alarm_collection_notifier.dart` + Unit Test
     - `load` / `create` / `update` / `toggle(id)` / `delete(id)` /
       `onFiredStop(id)` / `onFiredSnooze(id)`
     - enabled 化 / 編集時 → `nextFireAt` → `NotificationScheduler.schedule(payload: 'alarm:<id>')`
     - disabled / 削除時 → `cancel`
     - 鳴動 → 停止 → `advanceAfterFire` + 永続化 + 次回 schedule
     - 鳴動 → スヌーズ → `snoozeUntil` + schedule

4. **AlarmRingingNotifier 両用化 + main.dart payload 分岐**
   - `AlarmRingingNotifier.start` の `timerId` パラメータを `sourceId` 概念で扱い、
     payload prefix `timer:<id>` / `alarm:<id>` で起動元判別
   - `main.dart` の `onNotificationTap` で payload prefix を解析、
     alarm の場合は AlarmRingingScreen に alarm モードで遷移
   - `AlarmRingingScreen` の Stop / Snooze ハンドラで Timer / Alarm 分岐
   - 既存 Timer 由来のテストは全パス維持 (regression)

5. **Presentation 層**
   - `alarm_list_screen.dart` (一覧 + ON/OFF トグル + FAB) + Widget Test
   - `alarm_edit_screen.dart` (TimePicker + 曜日チップ + ラベル + 音源 + スヌーズ分) + Widget Test
   - `weekday_selector.dart` (multi-select 曜日チップ) + Widget Test
   - go_router に `/alarms` / `/alarms/edit/:id?` 追加
   - HomeScreen に Alarm 導線を追加 (Stopwatch / Timer / Alarm の 3 本柱)

6. **l10n**
   - `app_ja.arb` / `app_en.arb` に必要キー追加 (画面名、ラベル、空表示、曜日略称等)
   - `docs/translations.md` に新規キーをミラー

7. **docs 更新**
   - `docs/architecture.md` のディレクトリ構造図に `lib/domain/alarm/` 追記
   - 実装で乖離が出た部分があれば `docs/domain-model.md` に追記

### 自動停止ポイント

- pubspec.yaml / AndroidManifest / Native の編集が必要と判断したとき
- Drift schemaVersion bump で migration ロジックに不安が残るとき
- 100 行超の新規生成タイミング (節目で設計レビュー)
- 各レイヤー commit 完了時 (進捗報告)
- 全 7 ステップ完了 → 実機検証 (BACKLOG L420-424、4 シナリオ) 直前で停止

### 着手前 status check (2026-05-04, PR #10 マージ後)

PR #10 (b90c819) で Step 1〜5d までマージ済。実装ファイル直接確認の結果:

- **Step 1 Domain**: ✅ alarm_entity / alarm_repeat / alarm_service / day_of_week /
  time_of_day_value / exceptions すべて実装済 + Unit Test 完備
- **Step 2 Infrastructure**: ✅ drift_alarm_repository.dart + Drift schema migration 済
- **Step 3 Application**: ✅ alarm_collection_notifier.dart (create/update/toggle/delete/
  onFiredStop/onFiredSnooze) + alarm_repository_provider + alarm_service_provider
- **Step 4 AlarmRingingNotifier 両用化 + payload 分岐**: ✅ 完全実装済
  - [alarm_ringing_notifier.dart](../lib/application/alarm_ringing_notifier.dart) に
    `AlarmSource` enum + `currentSource` フィールド追加済
  - [alarm_ringing_screen.dart](../lib/presentation/screens/alarm_ringing_screen.dart) で
    `_parsePayload` (`timer:` / `alarm:` プレフィックス) + Stop / Snooze の
    AlarmCollectionNotifier 委譲済 (`onFiredStop` / `onFiredSnooze`)
  - [main.dart](../lib/main.dart) の `onNotificationTap` / cold-launch 両 path で
    payload を queryParameter に詰めて遷移する配線済
- **Step 5 Presentation**: 一部済
  - ✅ alarm_edit_screen.dart / weekday_selector.dart / alarm_delete_confirm_dialog.dart
  - ❌ **alarm_list_screen.dart** 未実装
  - ❌ **go_router の `/alarms` / `/alarms/edit/:id?` ルート未配線** (main.dart で
    `/alarms` の grep 0 ヒット確認)
  - ❌ **HomeScreen の Alarm 導線未追加** (現状 Stopwatch / Timer の 2 ボタンのみ)
- **Step 6 l10n**: 編集画面用キー (alarmEdit*) は追加済、一覧画面用 (alarmList*) は未追加
- **Step 7 docs 更新**: docs/architecture.md のディレクトリ構造図に
  `lib/domain/alarm/` 未追記

### 残作業の commit 計画 (実施結果)

Step 4 が既に完了済なため、当初 3 commit 計画を 2 commit に圧縮:

1. **Commit 1** (86f8847): AlarmListScreen + go_router 配線 + HomeScreen 導線 +
   ARB (alarmList* / homeOpenAlarm) + Widget Test 8 件追加 → 384 テストパス
2. **Commit 2**: docs 更新 (architecture.md ディレクトリ構造図) +
   tasklist/BACKLOG の Phase 9.5 完了マーク (実機検証だけ未完で残す)

Commit 2 完了後に停止し、実機検証 4 シナリオ (BACKLOG L420-424) はユーザに依頼。

### 実機検証 (Pixel 6a / Android 16、2026-05-04 完了)

PR #11 / #13 のレビュー対応 + 実機検証ループで発覚した 5 件のバグを fix 込みで完了:

1. 単発アラームを 1 分後にセット → 鳴動 → 停止 → enabled が false になる
2. 単発アラームを 1 分後にセット → 鳴動 → スヌーズ → 5 分後再鳴動
3. weekly アラーム (明日のみ) を翌日同時刻にセット → 鳴動 → 停止 → enabled
   維持、次回発火は次の該当曜日
4. アプリ強制終了 → アラーム時刻到達 → フルスクリーン Intent 発火

---

## Phase 9 完了内容（2026-05-02）

プリセット機能 + テンプレート差し替え（Plan A / Plan P / Plan Y）+ 削除確認ダイアログ +
音源変更 UI を実装。Phase 8 のレイヤー単位コミットパターンを踏襲して 5 commits でレイヤーを
積み上げ、その後フィードバック反映 4 commits で UX 微調整した。

### 実装サマリ

- Domain: Preset / PresetCollection / PresetService / PresetTemplates（3 プロファイル）/
  preset_exceptions / PresetRepository / UserPreferences ports
- Infrastructure: Drift schemaVersion 1 → 2、Presets テーブル + onCreate/onUpgrade で
  general profile を atomic seed、PresetMapper、DriftPresetRepository、
  SharedPreferencesUserPreferences
- Application: PresetCollectionNotifier（keepAlive、`replaceFromTemplate(profileId, mode)`、
  ReplaceTemplateResult で discardedCount 返却）、TimerCollectionNotifier に
  `changeSound(id, soundId)` 追加
- Presentation: PresetSelectSheet（FAB 経由 2x3 GridView）/ PresetEditSheet /
  PresetDeleteConfirmDialog / SoundSelectSheet / PresetManageScreen / TimerListScreen 編集
- ARB: 約 27 キー追加（plural ラベル + 音源 sheet + テンプレート差し替え）
- 実機検証 (Pixel 6a / Android 16): 10 シナリオすべて OK
- 計 275 テストパス、analyze 緑

### 実機検証フィードバック反映（合計 6 件、4 commits）

1. **テンプレート差し替えダイアログ**: 追加 = FilledButton、上書き = error 色 TextButton に
   強調入れ替え。実機で「追加」意図のタップが「上書き」に流れた事故への対処
2. **プリセット管理 リスト下端 padding 96 → 128 dp**: FAB と最下カードの右端 Delete
   ボタンが至近で被っていた件
3. **各プリセットカードに ♪ IconButton 追加**: TimerCard と同位置（Edit と Delete の間）、
   右上の音源 Chip は表示専用として維持
4. **音源 Chip の Material ink 起因の AppBar チラつき**: `IgnorePointer` で囲んで
   gesture を ListView に流す
5. **ラベル指定時に時間が見えない件**: プリセット管理カードはサブタイトル併記、
   タイマー一覧カードは duration の上に小さくラベル
6. **soundId 'urgent' → 'warning' に統一**: pre-release 段階のため互換性配慮なしで
   i18n キー / soundId / アセットファイル名 / Pomodoro テンプレート / テスト 全て更新

### 仕様変更ログ

- DurationPicker 内に音源 dropdown を統合する当初プランは取り下げ。
  CupertinoPicker と Dropdown の hit-test 干渉が発生したため、カスタム時間作成時は
  カタログ既定音 → カードの ♪ ボタンで後から変更、という UX に変更。実機で
  こちらの方が直感的との確認済

### 関連 docs 追加・更新

- `docs/translations.md` 新規（ARB 全キー × ja / en の対訳ミラー）
- `docs/assets-spec.md` / `docs/oss-publishing-notes.md` /
  `assets/sounds/LICENSES.md` を `alarm_warning.mp3` に追従

---

## Phase 9 Plan（着手前確認用、2026-05-02）

### 事前確定事項（ユーザ確認済、再確認不要）

| # | 項目 | 決定 |
| --- | --- | --- |
| 1 | Preset Entity フィールド | id (uuid) / label / duration / soundId / createdAt |
| 2 | Drift schema migration | schemaVersion 1 → 2、Presets 新設、既存 Timers 不変、migration 内で seed 6 件 atomic insert（案 X） |
| 3 | プリセット選択 UI 配置 | 案 A: FAB → bottom sheet（6 チップ + 区切り + カスタムボタン） |
| 4-1 | 削除確認 dialog | ON、「次から確認しない」チェック + SharedPreferences 保存 |
| 4-2 | 空状態表示 | 案 a: テキスト「プリセットがありません。+ ボタンから追加するか、テンプレートから差し替えてください」 |
| 4-3 | 管理画面導線 | 案 P: TimerListScreen AppBar overflow メニューに「プリセット管理」 |
| 4-4 | テンプレート差し替えラベル | 候補 1: "テンプレートから差し替え" / "Replace from template" |
| 5 | 件数上限 | 10 件（TimerCollection と同じ） |
| 7 | 切替 UX | 案 Y: 管理画面 overflow メニューから 3 プロファイル切替、3 択 dialog |
| 7 | 初期 seed | a) 一般用: 30s / 1m / 3m / 5m / 10m / 30m |
| 7 | label ローカライズ | ARB plural 3 キー + presentation 層フォーマッタ |
| 7 | 定数配置 | `lib/domain/timer/preset_templates.dart`（Pure Dart） |
| 7 | プロファイル | 一般用 (default), 料理向け (gentle), Pomodoro (urgent) |

(以下、Plan A〜C の詳細レイアウト案 / ARB 27 キー一覧 / 新規ファイル予定は
実装完了したため省略。実装結果は上記「Phase 9 完了内容」を参照)

---

## Phase 8.5 follow-up: アラーム再鳴動時の二重音修正（2026-05-02）

スヌーズ後の再鳴動時、heads-up 通知 → タップで AlarmRingingScreen に遷移する経路で、
OS チャンネル音 (alarm-stream の `RawResourceAndroidNotificationSound`) と
audioplayers のループ再生が重なって聞こえる問題を修正。

### 経緯

1. **Option A 試行**: [AlarmRingingNotifier.start()](../lib/application/alarm_ringing_notifier.dart) の `unawaited` を `await` 化して cancel→play の順序を保証。実機では二重音残留 (Pixel 6a / Android 16)。
2. **Option B 試行**: チャンネルの `playSound: false` でチャンネル音を切り audioplayers に一本化。FSI 経由は OK だが、heads-up 経路 (画面 ON で他アプリ操作中 / ホーム画面待機 / スヌーズ後再鳴動) で OS が FSI を抑制するため**音なし**になる UX 劣化が判明。
3. **Option C 採用**: チャンネルは `playSound: true` に戻し、`start()` で `cancel → 500ms 遅延 → play` の 3 段順序にして OS 通知音が完全に止まってから audioplayers が引き継ぐ動作に。

### 変更内容

- [x] [alarm_ringing_notifier.dart](../lib/application/alarm_ringing_notifier.dart): `start()` を `await cancel → await Future.delayed(500ms) → await play` に変更。why コメント追記
- [x] [flutter_local_notification_adapter.dart](../lib/infrastructure/notification/flutter_local_notification_adapter.dart): Channel id を `timer_alarm_v4` → `timer_alarm_v6` にバンプ (途中で v5 に下げて Option B を試したため)、`_legacyTimerAlarmChannelIds` に v4/v5 を追加。`playSound: true` + `RawResourceAndroidNotificationSound('alarm_default')` + `audioAttributesUsage: alarm` の v4 構成を維持。クラスドキュメントに Option B 試行と Option C 着地の経緯を記録
- [x] [alarm_ringing_screen_test.dart](../test/presentation/screens/alarm_ringing_screen_test.dart): 全 7 シナリオに `await tester.pump(Duration(milliseconds: 600))` を挿入して 500ms 遅延の Future を完了させる
- [x] flutter analyze: No issues found
- [x] flutter test: 180 / 180 passed
- [x] 実機検証 (Pixel 6a / Android 16、2026-05-02): 6 シナリオすべて単音、二重音解消
  - 初回 foreground (自動遷移) / 初回 background (heads-up タップ) / 初回 FSI (ロック画面) /
    強制終了 → ロック画面 / 強制終了 → ホーム画面待機 / **スヌーズ後再鳴動 (heads-up タップ)**

### 残タスク

- [x] [docs/android-constraints.md](android-constraints.md) の「Phase 6 実機検証で見つかって修正した問題」セクションに本件を追記 (Phase 8.5 follow-up サブセクション追加)

---

## ローカライズ土台導入完了内容（2026-05-02）

中国語簡体字 / 繁体字 / 韓国語までの拡張可能性を担保する設計を採用。

- [x] `pubspec.yaml`: `flutter_localizations` (SDK) + `intl` 追加、
  `flutter:` 配下に `generate: true` 追加
- [x] `l10n.yaml` 新規 (テンプレート ja、出力先 lib/l10n)
- [x] `lib/l10n/app_ja.arb` / `app_en.arb` 新規 (約 50 キー、ICU plural
  含む)
- [x] `lib/main.dart`: `localizationsDelegates` / `supportedLocales` 設定。
  `kEnableExperimentalLocales` (compile-time flag) で zh / zh-Hant / ko
  を社内ビルドのみ有効化可能
- [x] `lib/domain/timer/alarm_sound.dart`: `displayName` フィールドを削除
  (Pure Dart 制約遵守)。表示名は presentation 層で `AppLocalizations`
  経由で解決
- [x] `lib/domain/timer/alarm_sound_catalog.dart`: 同上、id + assetPath のみに
- [x] `lib/presentation/screens/timer_list_screen.dart`: AppBar / FAB /
  empty hint / カード内の表示・状態 chip・各ボタン / 上限 SnackBar /
  権限バナー 3 種すべて ARB 経由に置換
- [x] `lib/presentation/screens/alarm_ringing_screen.dart`: AppBar /
  Time's up! / Stop / Snooze / モーダル内タイトル + 分単位 + キャンセル
  すべて ARB 経由に置換
- [x] `lib/presentation/screens/stopwatch_screen.dart`: AppBar / Start /
  Pause / Resume / Lap / Reset すべて ARB 経由に置換
- [x] `lib/presentation/widgets/duration_picker.dart`: タイトル / 時 /
  分 / 秒 / キャンセル / 決定すべて ARB 経由に置換
- [x] `lib/presentation/widgets/lap_list.dart`: 空表示 / Lap N / Split /
  Total すべて ARB 経由に置換
- [x] `lib/main.dart` HomeScreen: appTitle / Open Stopwatch /
  Open Timer すべて ARB 経由に置換
- [x] テストハーネスに `localizationsDelegates` + 固定 Locale を追加
  (lap_list_test / stopwatch_screen_test は en、duration_picker_test /
  alarm_ringing_screen_test / timer_list_screen_test は ja)
- [x] `test/domain/timer/alarm_sound_catalog_test.dart`: displayName
  削除に追従
- [x] flutter analyze: No issues found
- [x] flutter test: 180 / 180 passed
- [x] dart format で整形済み
- [x] 通知本文の i18n 対応 (2026-05-03、PR #5): NotificationStringsNotifier +
      WidgetsBindingObserver.didChangeLocales で locale 切替追従、
      rescheduleAllRunning で in-flight banner も上書き
- [ ] 通知 channel 名の i18n 対応 (Phase 11)
- [ ] 設定画面での手動切替 UI (Phase 11)
- [ ] 中韓 ARB の本格翻訳 (Phase 11)

`docs/oss-publishing-notes.md` のローカライズ言語ポリシー記載は今後 Phase 11
着手時にまとめて更新する。

---

## Phase 8 Plan（着手前確認用、2026-05-01）

### 事前確定事項（ユーザー確認済）

| # | 項目 | 決定 |
| --- | --- | --- |
| 1 | 同時稼働上限 | **10 本**（`MaxTimerCountExceededException`） |
| 2 | `/timer` ルート | **一覧画面に置換**、単一画面 (`TimerScreen`) は廃止 |
| 3 | Provider 構造 | `timerNotifierProvider`（単一）廃止、`timerCollectionNotifierProvider` に統一。docs/state-management.md の `timerNotifierProvider(TimerId)` family 案も廃止（docs 反映時に削除提案） |
| 4 | 復元時の過去タイマー | `endAt < now` の running は **completed 扱い + `NotificationScheduler.show()` で 1 度だけ通知**。AlarmRingingScreen は起動しない、音も鳴らさない |

### 削除予定ファイル

- `lib/application/timer_notifier.dart` + `.g.dart`
- `lib/presentation/screens/timer_screen.dart`
- `test/application/timer_notifier_test.dart`
- `test/presentation/screens/timer_screen_test.dart`

### 新規作成ファイル

- `lib/infrastructure/database/app_database.dart` (+ `.g.dart`)
- `lib/infrastructure/database/mappers/timer_mapper.dart`
- `lib/infrastructure/database/drift_timer_repository.dart`
- `lib/domain/ports/timer_repository.dart`
- `lib/domain/timer/timer_collection.dart`
- `lib/domain/timer/exceptions.dart` (`MaxTimerCountExceededException`, `TimerNotFoundException`)
- `lib/application/timer_collection_notifier.dart` (+ `.g.dart`)
- `lib/application/timer_repository_provider.dart`
- `lib/presentation/screens/timer_list_screen.dart`
- 各レイヤーに対応する `test/`

### 編集予定ファイル

- `lib/domain/ports/notification_scheduler.dart`: `show(notificationId, title, body, payload)` メソッド追加
- `lib/infrastructure/notification/flutter_local_notification_adapter.dart`: `show()` 実装
- `lib/presentation/screens/alarm_ringing_screen.dart`: `_bootstrapRingingIfNeeded` / `_onSnoozeTap` を Collection 参照に書き換え、`Stop` ボタンも Collection.cancel + clear に書き換え
- `lib/main.dart`: `/timer` を `TimerListScreen` に差し替え、HomeScreen ボタン文言は維持
- `test/application/alarm_ringing_notifier_test.dart`: 必要に応じて regression 追加

### 影響を受ける既存テスト

- `test/presentation/screens/alarm_ringing_screen_test.dart` の `_SeededTimerNotifier` を `_SeededTimerCollectionNotifier` に置換
- `test/widget_test.dart`（HomeScreen スモーク）

---

## Phase 8「複数タイマー管理 + Drift 永続化」完了内容（2026-05-01）

- [x] `lib/domain/ports/timer_repository.dart` 新規（findAll / findById / upsert / delete）
- [x] `lib/domain/timer/timer_collection.dart` 新規（集約ルート、最大 10 件、add/update/remove）+ 13 テスト
- [x] `lib/domain/timer/exceptions.dart` 新規（`MaxTimerCountExceededException` / `TimerNotFoundException`）
- [x] `lib/domain/ports/notification_scheduler.dart` に `show()` 追加（復元時の即時通知用）
- [x] `lib/infrastructure/database/app_database.dart` 新規（Drift スキーマ、`Timers` テーブル + `forTesting` factory）
- [x] `lib/infrastructure/database/mappers/timer_mapper.dart` 新規（TimerEntity ⇔ TimerRow / TimersCompanion）+ 8 テスト
- [x] `lib/infrastructure/database/drift_timer_repository.dart` 新規（in-memory 対応）+ 8 テスト
- [x] `lib/infrastructure/notification/flutter_local_notification_adapter.dart` に `show()` 実装
- [x] `lib/application/timer_service_provider.dart` 新規（旧 timer_notifier.dart から TimerService Provider を分離）
- [x] `lib/application/timer_repository_provider.dart` 新規（main.dart で override）
- [x] `lib/application/timer_collection_notifier.dart` 新規 + 10 テスト（CRUD / 起動時 DB 復元 / 過去到達タイマーの completed 化 + show 通知 / 200ms ticker）
- [x] `lib/presentation/screens/timer_list_screen.dart` 新規 + 5 Widget テスト（empty hint / FAB / Start / Delete / FAB disabled at cap 10）
- [x] `lib/presentation/screens/alarm_ringing_screen.dart` を Collection ベースに書き換え（`findRinging` で対象選択、Stop で `cancel`、snooze で `snooze` 呼び出し）
- [x] `test/presentation/screens/alarm_ringing_screen_test.dart` を Collection 対応に全面書き換え（in-memory repo 経由でリンギング状態を seed）
- [x] `lib/main.dart`: AppDatabase + DriftTimerRepository を生成して `timerRepositoryProvider` に override、`/timer` を `TimerListScreen` に差し替え
- [x] **削除**: `lib/application/timer_notifier.dart` + `.g.dart` / `lib/presentation/screens/timer_screen.dart` / `test/application/timer_notifier_test.dart` / `test/presentation/screens/timer_screen_test.dart`
- [x] flutter analyze: No issues found
- [x] flutter test: 180 / 180 passed（既存 162 - 削除分 + 新規 50 強）
- [x] dart format で整形済み
- [x] docs/architecture.md / docs/domain-model.md / docs/state-management.md / docs/adr/0002-use-drift.md への Phase 8 反映 (1c585db)
- [x] 実機検証フィードバックでの 2 件修正 (62add6a): show() 用無音チャンネル timer_completed_v1 新設 / FAB は disable せず SnackBar 方式に変更
- [x] 実機検証 (Pixel 6a / Android 16、2026-05-02): 6 シナリオすべて想定通り
  - 検証 1: 複数タイマー (3 本) 同時稼働
  - 検証 2: アプリ強制終了 → 再起動で状態保持で復元
  - 検証 3: 過去到達 running が completed + 無音ヘッドアップ通知 1 回
  - 検証 4: 上限 10 本到達後の FAB タップで SnackBar
  - 検証 5: 各カードの個別操作 (Start/Pause/Resume/Delete/Reset/Stop) が独立
  - 検証 6: 通知タップ → AlarmRingingScreen → Stop で該当タイマー cancelled

---

## Phase 7「スヌーズ機能本体」完了内容（2026-05-01）

- [x] `lib/domain/timer/snooze_calculator.dart` 新規（Pure Dart、Clock 注入、3/5/10 分プリセット限定 + ArgumentError、Set 定数 `allowedMinutes`）
- [x] `test/domain/timer/snooze_calculator_test.dart` 新規（8 シナリオ: 3/5/10 分の正常 + 日付跨ぎ + プリセット外 3 種 + allowedMinutes 検証）
- [x] `lib/domain/timer/timer_service.dart` に `snooze(entity, snoozeMinutes)` 追加（ringing → running、endAt = now + N 分、duration 不変）
- [x] `test/domain/timer/timer_service_test.dart` にスヌーズ 9 シナリオ追加
- [x] `lib/application/timer_notifier.dart` に `snooze(int)` 追加（state 更新 + ticker 再開 + NotificationScheduler.schedule + AlarmRingingNotifier.stop で audioplayers 停止）
- [x] `test/application/timer_notifier_test.dart` にスヌーズ 3 シナリオ追加（5 分 re-arm + scheduler verify + StateError）
- [x] `lib/presentation/screens/alarm_ringing_screen.dart` のスヌーズボタンをモーダル + 3/5/10 分選択 + `TimerNotifier.snooze` 呼び出しに置き換え（snooze_calculator import）
- [x] `test/presentation/screens/alarm_ringing_screen_test.dart` 旧スヌーズテストを 3 つの新シナリオに置き換え（チョイスシート表示 / 5 分選択で running + 画面遷移 / キャンセルで現状維持）。`_SeededTimerNotifier` で ringing 状態をシード、`super.build()` で _ticker dispose を継承
- [x] flutter analyze: No issues found
- [x] flutter test: 162 / 162 passed（既存 140 + 新規 22）
- [x] dart format 整形済み
- [x] 実機検証: ringing → snooze 5 分 → 5 分後に再鳴動 + 通知音 + AlarmRingingScreen（heads-up タップで遷移）→ 単音化（Pixel 6a / Android 16、2026-05-02、Phase 8.5 follow-up で audioplayers と OS 通知音の二重音問題を修正後に確認済）

---

## カスタム時間タイマー UI 完了内容（2026-05-01）

- [x] `lib/presentation/widgets/duration_picker.dart` 新規（CupertinoPicker × 3 のホイール、確定/キャンセル）
- [x] `test/presentation/widgets/duration_picker_test.dart` 新規（7 シナリオ: 初期値表示 / 0:00:00 disabled / positive enabled / 99:00:00 確定 OK + 戻り値検証 / 99h+1s で disabled / Cancel で null pop / drag で値変化）
- [x] `lib/presentation/screens/timer_screen.dart` 編集: プリセット行末尾に「カスタム」FilledButton.tonal を追加 → `showModalBottomSheet<Duration>` 経由で DurationPicker 表示 → 確定値で `TimerNotifier.create` 呼び出し
- [x] `test/presentation/screens/timer_screen_test.dart` 編集: setup mode に 3 シナリオ追加（カスタムボタン表示 / モーダル表示 / 確定で active 遷移）+ 1 シナリオ（キャンセルで setup 維持）
- [x] flutter analyze: No issues found
- [x] flutter test: 136 / 136 passed（既存 126 + 新規 10）
- [x] dart format で整形済み
- [x] 実機で「カスタム時間（例: 1h 30m）→ Start → カウントダウン → 鳴動」の動作確認（Pixel 6a / Android 16、2026-05-02、初期表示 01:30:00 + Start 後の秒単位カウントダウン + Pause/Resume すべて想定通り）

---

## Phase 6 実機検証結果（2026-04-30、Pixel 6a / Android 16）

- [x] パターン 1（前面）: AlarmRingingScreen 遷移 + カスタム音再生 + Stop 動作
- [x] パターン 2（背景）: ロック画面上に AlarmRingingScreen + バンドル音源再生 + Stop 1 回で setup mode
- [x] パターン 3（強制終了）: コールドスタート deep link + バンドル音源がアラーム音量で再生 + Stop で setup mode
- [x] 権限なし時のヘッドアップ通知フォールバック（adapter の動的判定で動作）
- [x] 設定画面誘導の往復動作

検証中に発見した問題と修正は docs/android-constraints.md の「Phase 6 実機検証で
見つかって修正した問題（再発防止メモ）」に集約。

---

## Phase 6c 完了内容（2026-04-30）

- [x] FlutterLocalNotificationAdapter に PermissionChannel を注入
- [x] schedule 内で `canUseFullScreenIntent()` を毎回検査し、false 時は `fullScreenIntent: false` でヘッドアップ通知化
- [x] `MissingPluginException` / `PlatformException` 時は安全側（false）にフォールバック
- [x] docs/permissions.md / docs/architecture.md / docs/android-constraints.md を Phase 6 完了範囲で更新
- [x] 実機検証フォロー修正:
  - MainActivity.onCreate で `setShowWhenLocked(true)` / `setTurnScreenOn(true)` のランタイム呼び出し
  - main() の通知タップ callback と TimerScreen の ringing listener に重複ガード、`_leaveAlarmScreen` は `context.go('/timer')` で全置換
  - コールドスタート deep link（`getNotificationAppLaunchDetails()` で `initialLocation` 切替）
  - TimerNotifier.clear() で notification cancel
  - `assets/sounds/alarm_default.mp3` を `android/app/src/main/res/raw/` にもコピー、Channel に `RawResourceAndroidNotificationSound` + `AudioAttributesUsage.alarm` を明示。Channel id を v4 までバンプ（旧 id は init 時に削除）
- [x] flutter analyze: No issues found
- [x] flutter test: 126 / 126 passed

---

## Phase 6b 完了内容（2026-04-30）

- [x] `domain/ports/permission_manager.dart` に `checkFullScreenIntent` / `openFullScreenIntentSettings` 追加
- [x] `lib/infrastructure/platform/permission_channel.dart` 新規（`com.bonkotu.timer/permission` Channel ラッパ）
- [x] `lib/infrastructure/permission/permission_handler_adapter.dart` を const 解除し PermissionChannel 注入対応
- [x] Native `MainActivity.kt`: `com.bonkotu.timer/permission` Channel ハンドラ登録、`canUseFullScreenIntent()` (API 34+) と `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` Intent 発行を実装。古い API では true 返却 + アプリ詳細画面フォールバック
- [x] `application/permission_notifier.dart`: `PermissionState` に `fullScreenIntent` 追加（freezed 再生成）、`openFullScreenIntentSettings` メソッド追加、`refresh` で 3 軸読み込み
- [x] `presentation/screens/timer_screen.dart`: FSI 拒否時のバナー追加（'banner_full_screen_intent'）
- [x] `test/infrastructure/platform/permission_channel_test.dart` 新規 + 4 テスト
- [x] `test/application/permission_notifier_test.dart` を 3 軸対応 + FSI delegate テスト追加
- [x] `test/presentation/screens/timer_screen_test.dart` に FSI バナー Widget テスト追加 + 既存 banner テストを 3 軸対応
- [x] flutter analyze: No issues found
- [x] flutter test: 126 / 126 passed

---

## Phase 6a 完了内容（2026-04-30）

- [x] AndroidManifest に `USE_EXACT_ALARM` / `USE_FULL_SCREEN_INTENT` 追加
- [x] `<activity>` に `android:showOnLockScreen="true"` / `android:turnScreenOn="true"` 追加
- [x] FlutterLocalNotificationAdapter:
  - 通知 Channel の `importance: high` → `max`、`playSound: false` 追加
  - `AndroidNotificationDetails` を `importance: max` / `priority: max` / `fullScreenIntent: true` /
    `visibility: NotificationVisibility.public` / `playSound: false` に更新
- [x] flutter analyze: No issues found
- [x] flutter test: 120 / 120 passed

---

## Phase 5 完了内容（2026-04-30）

- [x] `assets/sounds/` に default / gentle / urgent の 3 音源を配置 + LICENSES.md
- [x] `pubspec.yaml` の `flutter:` セクションに `assets/sounds/` 登録
- [x] `lib/domain/timer/alarm_sound.dart`（freezed ValueObject、`AlarmSound.create` でバリデーション）
- [x] `lib/domain/timer/alarm_sound_catalog.dart`（all / defaultSound / findById）+ 6 ユニットテスト
- [x] `lib/domain/timer/timer_entity.dart` に `String? soundId` 追加（freezed 再生成）
- [x] `lib/domain/timer/timer_service.dart` の `createIdle` に `soundId` 引数追加
- [x] `lib/domain/ports/alarm_sound_player.dart`（play / stop / isPlaying / dispose）
- [x] `lib/infrastructure/audio/audioplayers_adapter.dart`（`ReleaseMode.loop` + `AssetSource`）
- [x] `lib/application/alarm_sound_player_provider.dart`
- [x] `lib/application/alarm_ringing_notifier.dart`（`AlarmRingingState` freezed + start / stop / snoozeRequested）+ 4 ユニットテスト
- [x] `lib/application/timer_notifier.dart` に ringing 連携: tick で ringing 化を検知して AlarmRingingNotifier.start を発火、cancel/reset で stop を発火
- [x] `lib/presentation/screens/alarm_ringing_screen.dart`(Stop / Snooze ボタン)+ 3 Widget テスト
- [x] `lib/main.dart`: `/alarm-ringing` ルート追加 + `onNotificationTap` callback で payload 経由 deep link
- [x] `lib/presentation/screens/timer_screen.dart`: ringing 遷移時に `context.push('/alarm-ringing')` で自動遷移
- [x] `lib/domain/ports/notification_scheduler.dart` の schedule に `payload` 引数追加（既存テストを更新）
- [x] flutter analyze: No issues found
- [x] flutter test: 120 / 120 passed
- [x] dart format で全体整形済み
- [x] 実機で 5s タイマー → カスタム音再生 → Stop で止まる動作確認（Phase 6 実機検証 2026-04-30 のパターン 1〜3 + Phase 8 検証 6 で実質カバー済）

---

## Phase 4 完了内容（2026-04-29）

- [x] `lib/domain/timer/notification_id_generator.dart`（Pure Dart、`timerId.hashCode & 0x7FFFFFFF`）+ 4 ユニットテスト
- [x] `lib/domain/ports/notification_scheduler.dart`（schedule / cancel / cancelAll）
- [x] `lib/domain/ports/permission_manager.dart`（DomainPermissionStatus enum + 5 メソッド）
- [x] `lib/domain/timer/timer_entity.dart` 拡張: `notificationId` フィールド追加
- [x] `lib/domain/timer/timer_service.dart` 更新: NotificationIdGenerator 注入で createIdle 時に id を発番
- [x] `lib/infrastructure/notification/flutter_local_notification_adapter.dart`（`zonedSchedule` + AndroidScheduleMode 切替）
- [x] `lib/infrastructure/permission/permission_handler_adapter.dart`
- [x] `lib/application/notification_scheduler_provider.dart`
- [x] `lib/application/permission_notifier.dart`（PermissionState freezed + Notifier）+ 5 ユニットテスト
- [x] `lib/application/timer_notifier.dart` に通知連携: start/resume で schedule、pause/cancel/reset で cancel
- [x] `lib/main.dart` で `WidgetsFlutterBinding.ensureInitialized()` + `Adapter.initialize()`
- [x] `lib/presentation/screens/timer_screen.dart` に権限拒否時バナー（POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM）+ 3 Widget テスト
- [x] AndroidManifest.xml に POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / WAKE_LOCK / VIBRATE 追加
- [x] android/app/build.gradle.kts: minSdk=26、coreLibraryDesugaring 有効化
- [x] pubspec.yaml に `flutter_local_notifications: ^19.0.0` `permission_handler: ^11.3.1` `timezone: ^0.10.1` `flutter_timezone: ^5.0.2` 追加
- [x] adapter で `tz.setLocalLocation` を実行（zonedSchedule の前提条件）
- [x] android/app/build.gradle.kts: desugar_jdk_libs を 2.1.4 へ更新（flutter_local_notifications 19 が要求）
- [x] flutter analyze: No issues found
- [x] flutter test: 106 / 106 passed
- [x] Emulator (Pixel 6a API 33) での権限フロー / バナー UI 動作確認済み
- [x] Emulator で `_plugin.show()` 経由の即時通知が表示できることを確認
- [x] AndroidManifest に `flutter_local_notifications` の `<receiver>` 2 つ + `RECEIVE_BOOT_COMPLETED` 権限を追加（プラグイン README で必須宣言）
- [x] **実機 (Pixel 6a / Android 16) で 5 秒タイマー → 通知発火 + バイブ動作確認**
- [x] docs/domain-model.md（TimerEntity に notificationId、NotificationIdGenerator 章）反映済み
- [x] docs/architecture.md（ports/permission_manager 追加 + ディレクトリ構造の Phase 4/5 実装状況反映）更新（2026-04-30）

---

## ドキュメント整備の仕上げ（Phase 0 完了済み）

- [x] ルート直下の `*.md` を `docs/` および `docs/adr/` へ移動
- [x] `CLAUDE.md` を最低限の制約集に圧縮
- [x] `tasklist.md` を新規作成
- [x] `BACKLOG.md` の Phase 0 チェック項目を更新（ドキュメント整備完了を反映）
- [x] `README.md` を最低限のプロジェクト説明に更新

---

## Phase 0 完了内容（2026-04-29）

ドキュメント整備のみ。実装コードなし。

- 作成: `CLAUDE.md` / `BACKLOG.md` / `tasklist.md`
- 作成: `docs/architecture.md` / `domain-model.md` / `state-management.md` /
  `testing-strategy.md` / `android-constraints.md` / `platform-channels.md` /
  `permissions.md` / `assets-spec.md`
- 作成: `docs/adr/0001-use-riverpod.md` / `0002-use-drift.md` /
  `0003-fullscreen-intent-strategy.md` / `0004-clock-injection-pattern.md`
- `CLAUDE.md` を最低限の制約集に圧縮、詳細を `docs/` に分離
- `README.md` を最低限のプロジェクト説明に整備

---

## Phase 1 完了内容（2026-04-29）

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

---

## Phase 3 完了内容（2026-04-29）

- [x] `lib/domain/timer/timer_status.dart` (enum 6 状態)
- [x] `lib/domain/timer/timer_entity.dart` (freezed クラス、Phase 3 最小フィールド)
- [x] `lib/domain/timer/timer_service.dart` (Clock + idGenerator 注入) + 31 ユニットテスト
- [x] `lib/application/timer_notifier.dart` (`@Riverpod` Notifier、Timer.periodic 200ms) + 10 fake_async テスト
- [x] `lib/presentation/screens/timer_screen.dart` (Setup/Active 2 モード) + 5 Widget テスト
- [x] `lib/main.dart` 更新: `/timer` ルート追加、HomeScreen に導線
- [x] flutter analyze: No issues found
- [x] flutter test: 93 / 93 passed (Phase 2 の 47 + Phase 3 の 46)
- [x] domain 層カバレッジ: timer_service 100%、stopwatch_service 100%、duration_formatter 100%
- [x] バックグラウンド復帰時に endAt 過ぎていれば即 ringing（Notifier テストで検証）

---

## Phase 2 完了内容（2026-04-29）

- [x] エコシステム互換性: `dependency_overrides: analyzer_plugin: ^0.13.0` で build_runner を解決
- [x] `lib/domain/shared/duration_formatter.dart` (Pure Dart) + 13 ユニットテスト
- [x] `lib/domain/stopwatch/stopwatch_state.dart` (freezed sealed class: Idle / Running / Paused + LapRecord)
- [x] `lib/domain/stopwatch/stopwatch_service.dart` (Clock 注入、Pure Dart) + 16 ユニットテスト
- [x] `lib/application/clock_provider.dart` (`@Riverpod(keepAlive: true)`)
- [x] `lib/application/stopwatch_notifier.dart` (`@Riverpod` Notifier + stopwatchServiceProvider) + 8 Notifier テスト
- [x] `lib/presentation/widgets/lap_list.dart` + 4 Widget テスト
- [x] `lib/presentation/screens/stopwatch_screen.dart` (ConsumerStatefulWidget + Timer.periodic in dispose) + 4 Widget テスト
- [x] `lib/main.dart` 更新: `/stopwatch` ルート追加、HomeScreen に導線
- [x] BACKLOG / docs/architecture.md の clock_provider 配置場所修正（ADR 0004 整合）
- [x] flutter analyze: No issues found
- [x] flutter test: 47 / 47 passed
- [x] domain 層カバレッジ: stopwatch_service 100%、duration_formatter 100%（DoD 90% を大幅クリア）

---

## Phase 1 着手準備

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

---

## Auto 運用開始前のユーザー側作業

- [x] GitHub リポジトリ作成済み（`https://github.com/Bonkoturyu/TimerUtility.git`）
- [x] `git remote -v` で push 先 URL 設定済み
- [x] `git ls-remote` で認証確認済み
- [x] Phase 0 ドキュメント push 完了
- [x] GitHub Settings → Actions → 有効化されていることを確認

---

## Phase 11: ClockLocationPicker リネーム (2026-05-11 完了)

PR #29 follow-up として内部識別子を表示文言に揃えるリファクタリング。
スコープは UI 動作・表示文言は変更せず、識別子のみリネーム。

- ARB キー: `clockLocationPicker*` → `clockEntryEdit*` (5 件)、
  未参照になった `clockMenuEditLocations` を削除
- クラス: `ClockLocationPickerScreen` → `ClockEntryEditScreen`
- ルート: `/clock/locations` → `/clock/entries`
- ファイル: `clock_location_picker_screen.dart` → `clock_entry_edit_screen.dart`
  (test も同様)
- Widget Key prefix: `clock_picker_*` → `clock_entry_edit_*`
- `clock_page.dart` の FAB push をリテラル直書きから
  `ClockEntryEditScreen.routeLocation` 定数参照に統一

Phase 10.5 履歴コメント中の `/clock/locations` 言及は履歴なので意図的に残す。

---

## Phase 11: Clock ドメイン層リネーム (2026-05-11 完了)

PR #30 gemini-code-assist レビュー G1 follow-up。presentation 層は
`ClockEntryEdit*` に揃ったが、ドメイン層 (`ClockLocation` / `ClockCollection` /
`ClockLocationRepository` / 例外名) は据置だった概念不整合を案 A
全面リネームで解消。Drift スキーマも含めて Phase 8 GA 前にクローズ。

- ドメイン: `ClockLocation` → `ClockEntry`、`ClockCollection` →
  `ClockEntryCollection`、`ClockLocationRepository` (port) →
  `ClockEntryRepository`、例外 `MaxClockLocationCountExceededException`
  / `ClockLocationNotFoundException` も `ClockEntry*` 化
- Application: `ClockCollectionNotifier` → `ClockEntryCollectionNotifier`、
  Provider 名も `clockEntryCollectionNotifierProvider` /
  `clockEntryRepositoryProvider` にリネーム
- Infrastructure: Drift テーブル `clock_locations` → `clock_entries`
  (schemaVersion 4 → 5、`INSERT INTO ... SELECT * FROM ...` 方式の
  migration)、`DriftClockLocationRepository` / `ClockLocationMapper` も
  `ClockEntry*` に統一
- テスト: 14 ファイルで識別子置換 + 5 ファイルを `git mv` で履歴保持 +
  `migration_v4_to_v5_test.dart` 新規 (Happy path / 空テーブル / bool
  保存の 3 ケース)
- docs / ADR / BACKLOG も追従

据置 (GPS 由来の概念として valid):
`isCurrentLocation` フィールド、`is_current_location` SQL カラム、
`LocationDetector` ポート、`InvalidTimezoneIdException`、
`infrastructure/location/` 配下。

実機検証 (2026-05-11、PR #31): 実機で v4 (commit 2842221) → v5 (commit cff04d8)
上書きインストール、登録エントリの件数・順序・displayName 保持を UI 上で
確認済み。`isCurrentLocation` フラグは UI 上に現在地マーカーが無く間接
確認のみだが、`migration_v4_to_v5_test.dart` の Case 3 でユニットテスト
カバー済み。fresh install / v3 → v5 二段飛ばしのケースはスコープ外。

---

### Phase 6 docs cleanup (2026-05-13)

Phase 6 最後の残課題「Native → Flutter のイベント送信仕様確定
(`docs/platform-channels.md` 更新)」を closing。

Phase 9.5 / 10 / 10.5 / 11 まで進めても Native → Flutter の能動イベントは
結局不要で、flutter_local_notifications の payload + `MainActivity.onNewIntent`
で完結したため、当初予定の 4 Channel (`/notification` / `/alarm_event` /
`/boot` / `/lockscreen`) を採用見送りとして整理。

整理内容:

- 実装済み Channel = `com.bonkotu.timer/permission` 1 つのみ
  (3 メソッド: `canUseFullScreenIntent` / `openFullScreenIntentSettings` /
  `clearShowWhenLocked`)
- `clearShowWhenLocked` は Phase 6 実機検証フォローで後付け追加されたが
  docs 未反映だったため、本セッションで正式に文書化 (用途・対応 API・
  なぜ必要かを含む)
- 4 採用見送り Channel について、それぞれの代替手段と「将来再採用する
  なら何が必要か」を docs に明記
- 旧 docs にあった `AlarmEventChannelHandler` / `LockscreenChannelHandler`
  などの架空クラス分離案、`alarm_event_channel.dart` / `boot_channel.dart`
  などの架空ラッパファイル参照を削除し、実態 (MainActivity 単体 +
  `permission_channel.dart` 1 ファイル) に整列

成果物: `docs/platform-channels.md` 全面リライト、`BACKLOG.md` Phase 6
残課題 [x] 化 + 進捗サマリ更新、本 dev-log エントリ追加、`tasklist.md`
最終更新日更新。コード変更なし。

---

## F-8 PermissionBanner 折り返し品質改善 実装 (2026-05-15)

PR #45 / PR #43 実機検証 (2026-05-15) で再確認された PermissionBanner
本文の文中改行を解消するため、`_PermissionBanner.build` のレイアウトを
横並び (`Row(Icon, Column(title, desc), TextButton)`) から縦並び
(`Row(Icon, Expanded(Column(title, desc, Align(ActionRow))))`) に再構成。

### F-8 変更内容

- `lib/presentation/widgets/permission_banners.dart` L186-228:
  - TextButton を Row の 3 番目要素から Column 末尾に移動
  - `Align(alignment: Alignment.centerRight)` でボタンを右寄せ
  - description と Action の間に `SizedBox(height: 8)` を挿入
  - Row の `crossAxisAlignment` を `start` に変更 (Icon がタイトル行に揃う)
  - accent 幅ロジック (8 / 5 / 3 pt)、severity / fontWeight、配色、ARB キーは一切変更なし
- `test/presentation/widgets/permission_banners_test.dart`:
  - 新規 1 件追加 (F-8): `tester.getRect` で `TextButton.top >= description.bottom`
    を assert し、ボタンが description の下に独立配置されていることを担保

### F-8 検証

- `flutter analyze`: No issues found
- `flutter test test/presentation/widgets/permission_banners_test.dart`: 8/8 緑
  (既存 7 件 + 新規 F-8 1 件、accent 幅 assert を含めて回帰なし)
- `flutter test`: 578/578 緑 (1 件は既存 skip)

### F-8 残課題

- Pixel 6a 実機での再検証は本セッションでは未実施 (Auto では行わない方針)。
  ユーザ側で `git push` → PR 作成 → 実機スクショで「文中改行が解消されたこと」を確認後、
  本ログに追記する想定。

### F-8 実機検証結果 (2026-05-15 追記)

PR #47 として main マージ完了 (commit `4cadcdf`)。Pixel 6a / Android 16 (API 36)
debug ビルドでの実機検証で **文中改行は完全に解消** されたことをスクリーンショットで確認。

ただし副次課題として、Column 末尾配置で TextButton が独立行になった結果、
**バナー全体の縦サイズが約 48dp 増加** し「だいぶでかい」とユーザ判断。
後継タスクとして F-10 (バナー全体タップ可能化 + TextButton 削除 + TalkBack 維持)
を `tasklist.md` に起票し、別 PR で対応する方針。

F-8 自体は文中改行解消の DoD を満たしたためクローズ。tasklist.md からは F-8 entry を
削除し、本ログに集約。

---

最終更新日: 2026-05-15（F-8 PermissionBanner 折り返し改善エントリ追加）

過去の更新:

- 2026-05-13（Phase 6 docs cleanup エントリ追加）
- 2026-05-12（`tasklist.md` から完了タスクログを本ファイルに集約）
