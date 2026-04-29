# CLAUDE.md

このファイルは Claude Code が本プロジェクトで作業する際に **毎セッション最初に読む** 絶対制約集です。
詳細は `docs/` 配下に分離しています。本ファイルは最小限の制約とインデックスのみを記載します。

---

## プロジェクト概要

Flutter 製のストップウォッチ + タイマーアプリ。Android 16 (API 36) を主ターゲットとし、
複数タイマー同時稼働、カスタムアラーム音、ロック画面上でのアラーム表示（フルスクリーン Intent）に対応する。

---

## 応答ポリシー

- **言語**: 日本語で応答
- **Plan 優先**: 実装前に必ず計画と設計方針を提示し、ユーザー確認後にコードを書く
- **コード生成は明示的に求められた時のみ**: 「実装して」等の明示があるまで、コードブロックは出さない
- **専門用語 OK**: ユーザーは C/C++/C# 5年以上のエンジニア。冗長な基礎説明は不要
- **アーキテクチャ的根拠を必ず添える**: 「なぜこの設計か」を Plan に含める

---

## 絶対遵守の制約

### コードレベルの禁止事項

- ❌ `lib/domain/` 配下で `package:flutter/*` を import すること（Pure Dart 限定）
- ❌ `DateTime.now()` の直接呼び出し（必ず `Clock` 経由）
- ❌ `Stopwatch`（dart:core）の直接利用（`StopwatchService` 経由）
- ❌ `Timer.periodic` / `Future.delayed` をドメイン層で使用
- ❌ 通知 ID / 予約 ID のハードコード（`NotificationIdGenerator` 経由）
- ❌ `assets/sounds/` のパスを文字列リテラルで散在させる（`AlarmSoundCatalog` 経由）

### 依存方向の絶対原則

```text
Presentation → Application(Riverpod) → Domain ← Infrastructure
```

Domain は外部に **何も** 依存しない（Pure Dart）。Infrastructure は Domain の `ports/` を実装する。
詳細は `docs/architecture.md`。

### テストポリシー

- 新規ロジック追加時は **必ず Unit Test を同時作成**
- 新規 Screen 追加時は **必ず Widget Test を同時作成**
- ドメイン層は `package:test` を使用（`flutter_test` ではない）
- 時間制御テストは `fake_async` を使用、実時間 sleep 禁止
- Mock は `mocktail`（`mockito` ではない）
- **テストは Flutter 標準フレームワーク（`flutter test` / `flutter test integration_test/`）で記述すること**。Android Studio / IntelliJ の Run/Debug 設定から実行可能であることを必須要件とする

### 編集時にユーザー確認が必要なファイル

- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml`
- `android/app/build.gradle.kts`
- `analysis_options.yaml`
- `.github/workflows/`
- `CLAUDE.md` および `docs/` 配下のすべてのドキュメント

---

## ドキュメント参照ガイド

| 作業内容 | 参照先 |
| --- | --- |
| Phase 計画 / 進捗確認 | `BACKLOG.md` |
| 短期タスクリスト | `tasklist.md` |
| レイヤー構造・命名規則・ディレクトリ構造 | `docs/architecture.md` |
| Entity / ValueObject 定義 | `docs/domain-model.md` |
| Riverpod Provider 一覧 | `docs/state-management.md` |
| Android 16 制約・Doze・FullScreenIntent | `docs/android-constraints.md` |
| Native ↔ Flutter メッセージ仕様 | `docs/platform-channels.md` |
| テスト戦略・自動化範囲 | `docs/testing-strategy.md` |
| 権限取得フロー | `docs/permissions.md` |
| 同梱音源仕様 | `docs/assets-spec.md` |
| 過去の意思決定の経緯 | `docs/adr/*.md` |

---

## エスカレーション基準

以下の場合は **作業を停止してユーザーに相談** すること:

- 既存の ADR と矛盾する設計が必要になった
- `docs/` の記述と異なる実装が必要になった
- 新規パッケージの追加が必要になった
- Native 側（Kotlin）の修正が必要になった
- Android Manifest の権限追加が必要になった
- テスト不可能な領域に踏み込む必要があると判断した

---

最終更新日: 2026-04-29
