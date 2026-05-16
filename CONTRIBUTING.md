# Contributing to TimerUtility

PR / Issue 歓迎です。本プロジェクトは Claude Code (Anthropic) との **AI 支援開発** を
前提に運用されており、参加者にもいくつかのルールに沿っていただきます。本ドキュメントは
[CLAUDE.md](CLAUDE.md) (AI 向け制約集) から OSS 貢献者向けに要点を抽出したもの。
大原則として「CLAUDE.md と本ファイルが矛盾した場合は CLAUDE.md が優先」。

---

## 連絡先 / コミュニケーション

- バグ報告 / 機能提案: GitHub Issues に
  [bug_report](.github/ISSUE_TEMPLATE/bug_report.md) /
  [feature_request](.github/ISSUE_TEMPLATE/feature_request.md) テンプレートあり
- 質問: GitHub Discussions または Issue
- セキュリティ: 公開 Issue ではなく、可能なら直接コンタクト (公開リポジトリ Owner の
  GitHub プロフィール参照)
- 行動規範: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) (Contributor Covenant 2.1)

---

## 開発フロー (大枠)

```text
1. Issue で議論 (任意だが推奨)
2. fork → feature branch を main から切る
3. ローカルで実装 + テスト追加
4. dart format . / flutter analyze / flutter test を緑にする
5. PR を main 向けに作成 (本リポジトリの main 直 push は禁止)
6. CI / レビュー対応
7. メンテナがマージ
```

main への直接 push / force push は禁止。merge は **メンテナによる明示承認後** のみ。

---

## ローカル環境セットアップ

[README.md](README.md) の "Build & Run" セクションを参照。要点:

```sh
git clone https://github.com/Bonkoturyu/TimerUtility.git
cd TimerUtility
git config core.hooksPath tool/git-hooks   # pre-commit dart format チェック
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## コードベース規約 (絶対遵守)

[CLAUDE.md](CLAUDE.md) と [docs/architecture.md](docs/architecture.md) の規約をそのまま
適用する。主要なものを抜粋:

### 依存方向

```text
Presentation → Application(Riverpod) → Domain ← Infrastructure
```

Domain は外部に **何も** 依存しない (Pure Dart 厳守)。Infrastructure は Domain の
`ports/` を実装する。

### 禁止事項

- `lib/domain/` 配下で `package:flutter/*` を import すること
- `DateTime.now()` の直接呼出 (必ず `Clock` 経由、[ADR 0004](docs/adr/0004-clock-injection-pattern.md))
- `Stopwatch` (dart:core) の直接利用 (`StopwatchService` 経由)
- `Timer.periodic` / `Future.delayed` をドメイン層で使用
- 通知 ID / 予約 ID のハードコード (`NotificationIdGenerator` 経由)
- `assets/sounds/` のパスを文字列リテラルで散在させる (`AlarmSoundCatalog` 経由)
- 翻訳文字列をハードコード (ARB / `AppLocalizations` 経由)

### テストポリシー

- 新規ロジック追加時は **必ず Unit Test を同時作成**
- 新規 Screen 追加時は **必ず Widget Test を同時作成**
- ドメイン層のテストは `package:flutter_test` の `test()` / `expect()` API を使用
  (Flutter SDK ピン留めにより `package:test` 直接依存は不可)
- 時間制御テストは [`fake_async`](https://pub.dev/packages/fake_async) を使用、
  実時間 sleep 禁止
- Mock は [`mocktail`](https://pub.dev/packages/mocktail) (mockito ではない)
- テストは Flutter 標準フレームワーク (`flutter test` / `flutter test integration_test/`)
  で記述。Android Studio / IntelliJ の Run/Debug 設定から実行可能であることを必須要件
  とする

### 編集時にメンテナ承認が必要なファイル

下記は変更スコープが広いため、PR 内で明示的に **理由とロールバック計画** を書くこと:

- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml` (依存追加 / バージョンバンプ)
- `android/app/build.gradle.kts`
- `analysis_options.yaml`
- `.github/workflows/`
- `CLAUDE.md` および `docs/` 配下のすべてのドキュメント

---

## コミット / PR 規約

### コミットメッセージ

Conventional Commits に近い形式を採用 (厳密ではない):

```text
<type>(<scope>): <subject>

<body>

<footer>
```

例:

- `feat(timer): support custom snooze intervals`
- `fix(notification): single-fire channel v6`
- `docs(adr): add 0005 alarm vs timer separation`
- `chore: bump go_router to 14.3`
- `ci: add ARB <-> translations.md diff check`

PR タイトルも同様の形式を推奨。

### PR 説明

[.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md) のテンプレートに沿って:

- 何を変更したか / なぜ変更したか
- どうテストしたか (`flutter test` 結果、実機検証シナリオ)
- 関連 Issue / Phase

### CI

PR push 毎に [.github/workflows/ci.yml](.github/workflows/ci.yml) が走る:

- `dart format --set-exit-if-changed .`
- `flutter analyze --fatal-infos`
- `flutter test`
- ARB <-> `docs/translations.md` キー集合 diff チェック

すべて緑になるまでマージしない。

---

## レビュー対応の心得

メンテナや AI レビュアー (Copilot / Gemini code-assist 等) の指摘は **仮説扱い** で、
裏取りした上で適用 / 却下を判断する ([CLAUDE.md](CLAUDE.md) の「ソース信用原則」)。

優先順位:

1. 実時間 API / validator の出力 (`flutter analyze`, `flutter test`, `gh api ...`)
2. 公式ドキュメント (URL 提示可能)
3. コード本体の grep / 実装の直接確認
4. AI レビュアーの指摘 (仮説、1〜3 で裏取り必須)
5. 経験則 / 過去事例

却下時は根拠 (URL or API 出力) を明示してリプライ。

---

## ライセンス

本プロジェクトへの貢献は [MIT License](LICENSE) の条件下で行われる。PR を送信した時点で、
あなたは「自分の貢献を MIT で配布することに同意する」ものとみなされる。

DCO / CLA は要求しない (フォーマルな legal sign-off プロセスは設けていない)。
