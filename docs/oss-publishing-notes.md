# OSS Publishing Notes

本プロジェクトを OSS として公開する際の検討メモ。
ライセンス監査・特許リスク評価・プロジェクトの特異性・公開チェックリスト
を集約する。

最終更新日: 2026-05-02

---

## 1. 公開方針サマリ

| 項目 | 結論 |
| --- | --- |
| ライセンス | **MIT** (`LICENSE` 既に配置済み) |
| OSS 公開可否 | **可** (ブロッカーなし) |
| 特許抵触リスク | **なし** (公知技術 / 標準 API / 既存 OSS のみ使用) |
| 取得可能特許 | **なし** (新規性 / 進歩性のある発明的要素なし) |
| 推奨位置付け | 「機能で勝負するアプリ」ではなく、Flutter + Clean Architecture + Android 16 アラーム制約対応 + AI 支援開発プロセスの **リファレンス実装** |

---

## 2. ライセンス監査

### 2.1 ルートライセンス

`LICENSE` (MIT, `Copyright (c) 2026 BON`) を配置済み。

### 2.2 dependencies (production)

| パッケージ | ライセンス | 備考 |
| --- | --- | --- |
| `flutter` (SDK) | BSD-3-Clause | |
| `cupertino_icons` | MIT | |
| `flutter_riverpod` | MIT | |
| `riverpod_annotation` | MIT | |
| `go_router` | BSD-3-Clause | flutter.dev 公式 |
| `clock` | BSD-3-Clause | dart.dev 公式 |
| `drift` | MIT | |
| `drift_flutter` | MIT | |
| `flutter_local_notifications` | BSD-3-Clause | |
| `audioplayers` | MIT | |
| `permission_handler` | MIT | |
| `uuid` | MIT | |
| `logger` | MIT | |
| `freezed_annotation` | MIT | |
| `timezone` | BSD-2-Clause | |
| `flutter_timezone` | BSD-3-Clause | |

### 2.3 dev_dependencies

| パッケージ | ライセンス |
| --- | --- |
| `flutter_test` (SDK) | BSD-3-Clause |
| `flutter_lints` | BSD-3-Clause |
| `riverpod_generator` | MIT |
| `build_runner` | BSD-3-Clause |
| `drift_dev` | MIT |
| `mocktail` | MIT |
| `fake_async` | BSD-3-Clause |
| `custom_lint` | MIT |
| `riverpod_lint` | MIT |
| `freezed` | MIT |
| `analyzer_plugin` (override) | BSD-3-Clause |

### 2.4 結論

すべて MIT または BSD 系。**GPL / AGPL / LGPL のようなコピーレフトは
一切含まれない**。MIT ライセンスのアプリとして安心して再配布可能。

### 2.5 同梱アセット (assets/sounds/)

`assets/sounds/LICENSES.md` で全 3 音源の出典・ライセンスを記録済み:

- `alarm_default.mp3` — Pixabay (`freesound_community`)
- `alarm_gentle.mp3` — Pixabay (`JeremayJimenez`)
- `alarm_urgent.mp3` — Pixabay (`JeremayJimenez`)

**Pixabay Content License** (商用利用可・帰属表示不要・再配布可)。
2024 年に追加された「Pixabay コンテンツのみで作られた音源コレクションの
再配布禁止」条項にも該当しない (アプリの一部としての同梱は対象外)。

### 2.6 Native コード (Android)

- `MainActivity.kt` / `AndroidManifest.xml`: 自作
- `build.gradle.kts`: Flutter 標準テンプレート
- `desugar_jdk_libs:2.1.4`: BSD-3-Clause (Google)
- `applicationId = "com.bonkotu.timer.timer_utility"`: 個人識別の
  リバースドメインだが OSS 上は問題なし。fork 時はユーザーが書き換える
  運用 (README で明示推奨)

---

## 3. 特許リスク評価

### 3.1 抵触リスク

**認識しているリスクなし**。本アプリの構成要素はすべて以下のカテゴリに
該当し、特許訴訟リスクは事実上ゼロ:

1. **OS 標準 API** — Android `AlarmManager` / `NotificationManager` /
   `KeyguardManager` / `FullScreenIntent` / `SCHEDULE_EXACT_ALARM`。
   Google が API として公開しているもの
2. **公開 OSS パッケージの API** — Flutter / Riverpod / Drift /
   flutter_local_notifications / audioplayers 等。各 OSS の
   ライセンス条項 (多くは特許グラント含む BSD/MIT) に従う限り
   特許リスクは各 OSS が処理済み
3. **一般的なソフトウェア技法** — Clean Architecture / Repository /
   Notifier / Pub-Sub / 状態遷移マシン / SQLite 永続化。教科書レベルで
   公知
4. **タイマー / ストップウォッチ / アラーム機能そのもの** — 1970 年代
   から存在する一般機能、特許の新規性なし

### 3.2 警戒した方がよい一般領域 (本アプリでは該当なし)

| 領域 | 該当 |
| --- | --- |
| 音声認識 (Siri/Alexa 系) | なし |
| カメラ画像認識 | なし |
| 位置情報を絡めた業務ロジック (ジオフェンス等) | なし (Phase 10.5 で GPS 使うが「現在地のタイムゾーン取得」のみ、機能特許の対象外) |
| 決済 / IAP | なし |
| 暗号化 / DRM | なし |
| AR / VR / 3D | なし |
| 機械学習モデル | なし |
| 動画ストリーミング (MPEG-LA 系) | なし (mp3 ローカル再生は audioplayers が処理、MP3 特許は期限切れ) |

### 3.3 取得可能特許の有無

**なし**。特許要件 (新規性 / 進歩性 / 産業上の利用可能性) を満たす
発明的要素なし。

唯一「実装上の工夫」と言える部分:

- Phase 6 で確立した「FullScreenIntent + audioplayers の二重再生回避設計」
- Phase 8 で確立した「アプリ再起動時の過去到達タイマーの completed +
  show 通知 1 回」設計

これらはいずれも Android 開発者コミュニティ (Stack Overflow / GitHub
issue 等) で類似解決策が散見される範囲。特許庁の審査では「公知技術の
単なる組合せ」として拒絶される。

### 3.4 ライセンス上の特許保護の余地

- **MIT** (現状): 明示的な特許グラント条項なし。OSS コミュニティの慣行
  として暗黙的なライセンスは認められる
- **Apache 2.0 への切替候補**: 明示的特許グラント + パテントトロール
  訴訟時の自動失効条項を持つ。より厳密な防護が必要なら検討
- 本アプリ規模では MIT のままで十分

---

## 4. プロジェクトの特異性

### 4.1 機能面の特異性

**ほぼゼロ**。標準的なタイマー / ストップウォッチ / アラーム / 世界時計
の集約アプリ。Google 時計 / iOS 時計 / 多数のサードパーティアプリと
機能的に重複する。

### 4.2 実装 / 設計面の特徴

OSS としての本当の価値はここにある:

#### Clean Architecture の徹底

- Domain 層 Pure Dart 厳守 (`package:flutter` import 禁止 /
  `DateTime.now()` 直接呼出禁止 / `Stopwatch` 直接利用禁止)
- `Clock` 注入による完全な時間制御 (ADR 0004)
- ports/ + adapters パターンで Infrastructure を完全に置換可能
- Flutter の小〜中規模アプリでここまで徹底している例は稀

#### テスト戦略の徹底

- 180 件のテスト全件パス
- domain 層カバレッジ 90% 以上
- `fake_async` + `Clock` 注入で時間依存ロジックを完全に決定的にテスト
- in-memory Drift (`NativeDatabase.memory()`) で永続化レイヤーも
  自動テスト

#### ドキュメント駆動開発

- `CLAUDE.md` / `BACKLOG.md` / `tasklist.md` / `docs/architecture.md` /
  `docs/domain-model.md` / `docs/state-management.md` /
  `docs/android-constraints.md` / `docs/adr/*` 等の構造化ドキュメント
- ADR (Architecture Decision Record) で意思決定経緯を保存
- 「AI 支援開発のドキュメント運用例」としての価値

#### AI (Claude Code) と協業する開発フロー

- `CLAUDE.md` で Auto モードのルール明文化
- Phase 別 BACKLOG 管理
- 「ユーザー確認必須ファイル」「自動実行可能範囲」「停止条件」の明示
- Plan 駆動 + 段階コミット + ローカル → push の人間確認分離
- 「AI 支援を前提にした開発プロセス設計のリファレンス」としての価値

#### Android 16 の最新制約への対応

- Android 13+ の `POST_NOTIFICATIONS` runtime 権限
- Android 14+ の `USE_FULL_SCREEN_INTENT` (新規アプリ事前申請必須化)
- Android 14+ の `SCHEDULE_EXACT_ALARM` 制限強化
- これらを `permission_handler` + 自前 `MethodChannel` で適切に処理
  (Phase 6b)

#### Phase 6 実機検証の落とし穴ドキュメント

`docs/android-constraints.md` の「Phase 6 実機検証で見つかって修正した
問題」セクションに以下を記録:

- OS 通知音と audioplayers の二重再生問題
- FullScreenIntent が背景で表示されない問題
- ロック解除後に Recents ボタンが消える問題
- 単一 Notifier の cold-start で audio が start されない問題

→ Android のアラーム実装で踏みやすい落とし穴と解決策のドキュメント
として実用価値あり

### 4.3 OSS としての位置付け案

「機能で勝負するアプリ」ではなく、以下のリファレンス実装として打ち出す:

- Flutter + Clean Architecture
- Android 13/14/16 アラーム制約対応
- AI 支援開発ワークフロー

README の "What's special about this project?" 節案 (英語):

```markdown
## What's special about this project?

This isn't trying to be the next great timer app. It's:
- A worked example of **Clean Architecture in Flutter** with a strict
  Pure-Dart domain layer
- A reference for **Android 13/14/16 alarm constraints**
  (FullScreenIntent, exact alarm permissions, audio channel routing)
- A test bed for **AI-assisted development workflow** with Claude Code
  (see CLAUDE.md, BACKLOG.md, docs/adr/ for the playbook)

If you're building an Android timer/alarm app and hit weird issues with
notification audio / lock screen / recent apps button, check the
"Phase 6 implementation retrospective" notes in
`docs/android-constraints.md`.
```

---

## 5. 公開チェックリスト

### 5.1 公開前必須

- [ ] README.md を OSS 向けに整備
  - スクリーンショット
  - ビルド手順 (`flutter pub get` → `flutter run`)
  - Architecture 概要 (Clean Architecture の図か `docs/` への
    リンク)
  - License 表記 (MIT)
  - Section 4.3 の「What's special」案
  - 「fork したら `applicationId` を `com.bonkotu.timer.timer_utility`
    から自分のものに書き換えてください」の明記
- [ ] `git ls-files | grep -iE "(secret|key|token|password|env)"`
  で秘密情報の混入チェック
- [ ] `git log --pretty=format:"%an <%ae>"` で commit author email が
  公開可能なものか確認 (個人 email を匿名化したい場合は
  `git filter-repo` で書き換え)

### 5.2 公開直後でもよい

- [ ] ルートに `THIRD_PARTY_NOTICES.md` 配置 (もしくは README から
  `assets/sounds/LICENSES.md` を参照)
- [ ] `.github/ISSUE_TEMPLATE/` / `.github/PULL_REQUEST_TEMPLATE.md`
- [ ] `CODE_OF_CONDUCT.md` / `CONTRIBUTING.md`
  (GitHub Community Standards 達成用、任意)

### 5.3 検討事項

- `pubspec.yaml` の `publish_to: 'none'` はそのまま OK
  (pub.dev に publish しない前提)
- `CLAUDE.md` は残してもよい (AI 支援開発の参考例として価値あり、
  個人的なメモが含まれていなければそのまま公開可)

### 5.4 公開手順

1. README が上記項目を満たすまで加筆
2. `flutter analyze` / `flutter test` が緑
3. GitHub リポジトリの Settings → Visibility を Private → Public
4. (任意) `pubspec.yaml` の `publish_to` を削除して pub.dev へ publish

---

## 6. 関連ドキュメント

- `LICENSE` — MIT
- `assets/sounds/LICENSES.md` — 同梱音源ライセンス
- `pubspec.yaml` — 依存パッケージ一覧
- `docs/architecture.md` — レイヤー構造 / ディレクトリ規約
- `docs/adr/0001-use-riverpod.md` — 状態管理選定
- `docs/adr/0002-use-drift.md` — 永続化選定
- `docs/adr/0003-fullscreen-intent-strategy.md` — FSI 戦略
- `docs/adr/0004-clock-injection-pattern.md` — Clock 注入規約
- `docs/adr/0005-alarm-vs-timer-separation.md` — Alarm/Timer 分離
- `docs/android-constraints.md` — Android 制約と Phase 6 実機検証
  retrospective
- `CLAUDE.md` — AI 支援開発のルール
