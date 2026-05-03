# Copilot Code Review スタイルガイド (TimerUtility)

このリポジトリの Pull Request をレビューするとき、および
コード補完・コード生成を行うときは、以下の制約を必ず参照してください。
違反があれば該当行に指摘コメントを残し、
コード生成時はこれらの規約に沿った提案だけを出してください。

本ガイドは [CLAUDE.md](../CLAUDE.md) と
[docs/architecture.md](../docs/architecture.md) のプロジェクト規約を
Copilot 向けに集約したものです。
Gemini Code Assist 向けの並行ガイドが [.gemini/styleguide.md](../.gemini/styleguide.md)
にあります。両者は同一の規約をミラーしているため、内容に差分が出たら同期してください。

---

## レビュー時のソース信用原則

外部仕様 (GitHub / Flutter / Riverpod / Drift 等) に関する指摘を出すときは、
以下の優先順位で必ず裏取りしてからコメントしてください:

1. **実時間 API / validator の出力** (例: `gh api .../codeowners/errors`、
   `flutter analyze`、各種 SDK CLI) — 最も信頼度高
2. **公式ドキュメント (URL 提示可能)** — 信頼度高、コメント本文に URL を必ず添える
3. **コード本体の grep / 実装の直接確認** — 信頼度高
4. **訓練データ / 過去経験** — 根拠提示できないなら指摘しない

PR #7 で「CODEOWNERS の owner 空行は無効構文」という誤指摘を Copilot 自身が
出した実例があります。実際には GitHub validator API と公式 docs の両方が
有効構文として裏付けていました。**「たぶんそうだろう」で指摘せず、
1〜3 で裏取りした内容のみを根拠付きでコメントしてください。**

裏取り手段が見当たらない場合は、断定を避けて「要確認」「公式 docs URL を
添えて確認してください」のような提案形に留めてください。

---

## アーキテクチャ層構造

依存方向は厳格に下記のみ:

```text
Presentation → Application(Riverpod) → Domain ← Infrastructure
```

- `lib/domain/` は **Pure Dart** のみ。`package:flutter/*` を import してはいけない
- `lib/infrastructure/` は `lib/domain/ports/` のインタフェースを実装する形でのみ Domain と接続する
- Domain は `lib/application/`, `lib/presentation/`, `lib/infrastructure/` のいずれにも依存してはならない
- レイヤー間の逆流（Domain が Application を import 等）は必ず指摘してください

## コードレベルの禁止事項

以下のパターンは review でフラグを立ててください:

- `DateTime.now()` の直接呼び出し → 必ず `Clock` 経由 (`ref.read(clockProvider).now()` または注入された `Clock` を使う)
- `Stopwatch`（dart:core）の直接利用 → `StopwatchService` 経由
- Domain 層 (`lib/domain/`) での `Timer.periodic` / `Future.delayed` 使用
- 通知 ID / 予約 ID のハードコード → `NotificationIdGenerator` 経由
- `assets/sounds/` のパスを文字列リテラルで散在 → `AlarmSoundCatalog` 経由
- 翻訳文字列のハードコード → `AppLocalizations.of(context)` 経由（presentation 層）または
  `notificationStringsNotifierProvider` 経由（application 層）
- `mockito` の使用 → `mocktail` を使用すること（既存テストすべて mocktail）

## テストポリシー

- 新規ロジック追加時は **必ず Unit Test を同時作成**
- 新規 Screen 追加時は **必ず Widget Test を同時作成**
- 時間制御テストは `fake_async` を使用、実時間 `sleep` / `Future.delayed` で待機するのは禁止
- Domain 層テストでも production code (`lib/domain/`) は Pure Dart 厳守
- テストは `flutter test` から実行可能であること（Flutter SDK ピン留めにより
  `package:test` を直接依存として追加しない）

## ユーザ確認が必要なファイル

以下のファイルへの編集が含まれる PR では、PR description にユーザ確認の経緯が
記載されているかを確認してください:

- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml`
- `android/app/build.gradle.kts`
- `analysis_options.yaml`
- `.github/workflows/`
- `CLAUDE.md` および `docs/` 配下のすべてのドキュメント

## レビュー対象外（generated）

以下は codegen / vendored 出力で人間が直接編集しないため、style review は不要です。
Copilot Code Review の対象外は repo Settings → Copilot → Code review の
ruleset (`Copilot review for default branch`) で除外する想定ですが、
万が一含まれた場合もスタイルコメントは付けないでください:

- `**/*.g.dart` (riverpod_generator / drift / freezed 出力)
- `**/*.freezed.dart`
- `lib/l10n/app_localizations*.dart` (gen-l10n 出力)
- `assets/sounds/LICENSES.md` (third-party 帰属表記)

## レビューコメントの言語

レビューコメントは原則 **日本語** でお願いします（プロジェクト本体が日本語管理のため）。
コードサンプルや英語のキーワードはそのままで構いません。
