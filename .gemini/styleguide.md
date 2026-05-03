# Gemini Code Assist スタイルガイド (TimerUtility)

このリポジトリの Pull Request をレビューするときは、以下の制約を必ず参照してください。
違反があれば該当行に指摘コメントを残してください。本ガイドは
[CLAUDE.md](../CLAUDE.md) と [docs/architecture.md](../docs/architecture.md) の
プロジェクト規約を Gemini 向けに集約したものです。

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
これらは `.gemini/config.yaml` の `ignore_patterns` でも除外していますが、
万が一含まれた場合もスタイルコメントは付けないでください:

- `**/*.g.dart` (riverpod_generator / drift / freezed 出力)
- `**/*.freezed.dart`
- `lib/l10n/app_localizations*.dart` (gen-l10n 出力)
- `assets/sounds/LICENSES.md` (third-party 帰属表記)

## レビューコメントの言語

レビューコメントは原則 **日本語** でお願いします（プロジェクト本体が日本語管理のため）。
コードサンプルや英語のキーワードはそのままで構いません。
