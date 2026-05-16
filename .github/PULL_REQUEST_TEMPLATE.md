## 概要

<!-- 何を変えたか、1〜3 行 -->

## 動機 / 背景

<!-- なぜこの変更が必要か。関連 Issue / Phase / ADR があれば link -->

Closes #<!-- issue 番号 -->

## 変更内容

- [ ] Domain 変更あり
- [ ] Application 変更あり
- [ ] Infrastructure 変更あり
- [ ] Presentation 変更あり
- [ ] Native (Android) 変更あり
- [ ] ドキュメント / メタファイル変更あり

主要な変更点:

-
-
-

## テスト

- [ ] `dart format .` 適用済
- [ ] `flutter analyze --fatal-infos` 緑
- [ ] `flutter test` 緑 (件数: <!-- 例: 642 / 1 skipped -->)
- [ ] 新規ロジックに対する Unit Test 追加
- [ ] 新規 Screen に対する Widget Test 追加
- [ ] 実機検証 (Pixel 6a / Android 16) 実施: <!-- シナリオを箇条書きで -->

## レビュー観点 (任意)

<!-- レビュアーに特に見てほしい箇所 -->

## チェックリスト

- [ ] [CLAUDE.md](../CLAUDE.md) の禁止事項 (Domain で `package:flutter` import,
      `DateTime.now()` 直接呼出, `Stopwatch` 直接利用, 翻訳文字列ハードコード等) に
      違反していない
- [ ] [docs/architecture.md](../docs/architecture.md) の依存方向を守っている
- [ ] 編集時にメンテナ承認が必要なファイル (AndroidManifest / pubspec.yaml /
      build.gradle.kts / analysis_options.yaml / .github/workflows / docs/) を
      触っている場合は、PR 説明で理由とロールバック計画を明記
- [ ] AI レビュアー (Copilot / Gemini code-assist 等) の指摘は裏取り済 (`docs/` /
      公式仕様 URL / `flutter analyze` 等)

## スクリーンショット / 動画 (UI 変更時)

<!-- before / after を貼る -->

## 関連

<!-- 関連 PR / Phase / dev-log -->
