# TimerUtility

Flutter 製のストップウォッチ + タイマー + アラーム + 世界時計アプリ。Android 16 (API 36)
を主ターゲットとし、ロック画面上のアラーム表示 (FullScreenIntent) と複数タイマー同時稼働、
端末再起動後の復元に対応する。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Screenshots

> Phase 11.9 (Play Store 提出準備) で Pixel 6a 実機スクリーンショットを差し込み予定。
> 現状はデフォルト Flutter ロゴ + プレースホルダ。

| Stopwatch | Timer | Alarm | World Clock |
| --- | --- | --- | --- |
| _(TBD)_ | _(TBD)_ | _(TBD)_ | _(TBD)_ |

---

## 主な機能

- **ストップウォッチ**: Lap 記録、ms 精度、`fake_async` で完全テスト可能な `Clock` 注入設計
- **複数タイマー**: 同時稼働上限 10 本、Drift で永続化、端末再起動後も復元
- **指定時刻アラーム**: 曜日繰り返し / once / スヌーズ (3/5/10 分)、Doze 回避のため
  `SCHEDULE_EXACT_ALARM` 経由
- **ロック画面アラーム鳴動**: `USE_FULL_SCREEN_INTENT` + `setShowWhenLocked` で
  ロック解除なしに鳴動画面を直接表示
- **世界時計**: 最大 6 都市、3 デザイン (PageView 切替)、初回 GPS で現在地登録、
  拒否時は `FlutterTimezone` fallback
- **プリセット**: 一般 / 料理 / Pomodoro の 6 件 × 3 テンプレ、♪ ボタンで音源差替
- **多言語対応**: ja / en (Public)、`--dart-define=ENABLE_EXPERIMENTAL_LOCALES=true` で
  zh / zh-Hant / ko も内部対応
- **ダークモード**: `MaterialApp.darkTheme` + MD3 semantic role 化済
- **CVD (色覚多様性) 対応**: バナーに重大度ラベル `[重要]` / `[推奨]` / `[補助]` 併記
- **診断ログ**: 設定画面でトグル → JSON Lines をローテーション → zip で OS Share Sheet
  に渡せる Phase D 機構 (PII 排除済)

---

## What's special about this project?

このリポジトリは「機能で勝負するタイマーアプリ」ではなく、以下のリファレンス実装として
設計されている:

- Flutter で **Clean Architecture の Pure Dart 厳守 domain 層** を維持する実例
- Android 13 / 14 / 16 の **アラーム / 通知制約 (FullScreenIntent, SCHEDULE_EXACT_ALARM,
  POST_NOTIFICATIONS, audio channel 二重再生回避)** に対応した実装サンプル
- Claude Code (Anthropic) と協業する **AI 支援開発ワークフロー** の運用例
  ([CLAUDE.md](CLAUDE.md) / [BACKLOG.md](BACKLOG.md) / [docs/adr/](docs/adr/))

### What's special about this project? (English)

This isn't trying to be the next great timer app. It's:

- A worked example of **Clean Architecture in Flutter** with a strict Pure-Dart
  domain layer (no `package:flutter` imports, no `DateTime.now()`, no
  `Stopwatch` from `dart:core` — all time is injected via
  [`Clock`](docs/adr/0004-clock-injection-pattern.md))
- A reference for **Android 13/14/16 alarm constraints** — FullScreenIntent
  permission gating, exact-alarm permission flow, notification audio channel
  routing to avoid double-playback, lock-screen visibility via
  `setShowWhenLocked`, and boot-time timer restoration
- A test bed for **AI-assisted development workflow** with Claude Code (see
  [CLAUDE.md](CLAUDE.md), [BACKLOG.md](BACKLOG.md), [docs/adr/](docs/adr/) for the
  playbook)

If you are building an Android timer / alarm app and you hit weird issues with
notification audio, lock-screen behavior, or the Recent Apps button vanishing after
unlock, check the **"Phase 6 implementation retrospective"** notes in
[docs/android-constraints.md](docs/android-constraints.md).

---

## 技術スタック

- **言語 / フレームワーク**: Flutter (Dart SDK `^3.11.5`)
- **状態管理**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod` 2.x +
  `riverpod_generator`)
- **ルーティング**: [go_router](https://pub.dev/packages/go_router) 14.x
- **永続化**: [Drift](https://drift.simonbinder.eu/) (SQLite、schemaVersion 5)
- **通知**:
  [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)
  19.x
- **音声再生**: [`audioplayers`](https://pub.dev/packages/audioplayers) 6.x
- **権限**: [`permission_handler`](https://pub.dev/packages/permission_handler) 12.x +
  自前 `MethodChannel` (`com.bonkotu.timer/permission`)
- **時刻**: [`clock`](https://pub.dev/packages/clock) (依存性注入) +
  [`timezone`](https://pub.dev/packages/timezone) +
  [`flutter_timezone`](https://pub.dev/packages/flutter_timezone)
- **テスト**: `flutter_test` + [`mocktail`](https://pub.dev/packages/mocktail) +
  [`fake_async`](https://pub.dev/packages/fake_async)

依存全件のライセンス内訳は [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) を参照。

---

## Build & Run

### 前提

- Flutter SDK `^3.11.5` (`flutter --version` で `Flutter 3.11.x` 系を確認)
- Android SDK Platform 36 (Android 16) + build-tools
- JDK 17

### セットアップ

```sh
git clone https://github.com/Bonkoturyu/TimerUtility.git
cd TimerUtility

# pre-commit hook (dart format チェック) を有効化
git config core.hooksPath tool/git-hooks

flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

`build_runner` は freezed / riverpod_generator / drift_dev のコード生成に必要。
詳細は [tool/git-hooks/README.md](tool/git-hooks/README.md)。

### 実行 (Debug)

```sh
flutter run -d <device-id>
```

実験的な多言語 (zh / zh-Hant / ko) を有効化したい場合:

```sh
flutter run --dart-define=ENABLE_EXPERIMENTAL_LOCALES=true
```

### テスト + 静的解析

```sh
dart format .
flutter analyze --fatal-infos
flutter test
```

CI ([.github/workflows/ci.yml](.github/workflows/ci.yml)) と同じチェックがローカルで
走る。`flutter test` は 642 件 (1 skipped) すべて緑になる前提。

### Release build (任意)

Phase 11.9 完了までは **debug 署名で release ビルド** する暫定設定 ([android/app/build.gradle.kts:35-40](android/app/build.gradle.kts#L35-L40))。
upload keystore の配線は Phase 11.9 で行う予定。

```sh
flutter build apk --release
# または
flutter build appbundle --release
```

---

## Architecture

レイヤー構造:

```text
Presentation → Application (Riverpod Notifier) → Domain ← Infrastructure
```

- **Domain** (`lib/domain/`): Pure Dart (`package:flutter` import 禁止 /
  `DateTime.now()` 禁止 / `Stopwatch` 禁止 / `Timer.periodic` 禁止)
- **Application** (`lib/application/`): Riverpod Notifier。ドメインオブジェクトの
  オーケストレーション
- **Infrastructure** (`lib/infrastructure/`): Drift / flutter_local_notifications /
  audioplayers / permission_handler 等への adapter (Domain `ports/` を実装)
- **Presentation** (`lib/presentation/`): Widget tree、`go_router` 配線

詳細ドキュメント:

| 内容 | 参照先 |
| --- | --- |
| レイヤー構造 / 命名規則 / ディレクトリ規約 | [docs/architecture.md](docs/architecture.md) |
| Entity / ValueObject 定義 | [docs/domain-model.md](docs/domain-model.md) |
| Riverpod Provider 一覧 | [docs/state-management.md](docs/state-management.md) |
| Android 16 制約 / Doze / FullScreenIntent | [docs/android-constraints.md](docs/android-constraints.md) |
| Native ↔ Flutter メッセージ仕様 | [docs/platform-channels.md](docs/platform-channels.md) |
| テスト戦略 / 自動化範囲 | [docs/testing-strategy.md](docs/testing-strategy.md) |
| 権限取得フロー | [docs/permissions.md](docs/permissions.md) |
| 同梱音源仕様 | [docs/assets-spec.md](docs/assets-spec.md) |
| 翻訳 (ja / en) | [docs/translations.md](docs/translations.md) |
| 過去の意思決定 | [docs/adr/](docs/adr/) (ADR 0001〜0005) |

Phase 別タスク管理:

- [BACKLOG.md](BACKLOG.md) — Phase 0 〜 12 のロードマップ
- [tasklist.md](tasklist.md) — 短期タスク
- [docs/dev-log.md](docs/dev-log.md) — 完了 Phase の実装ログ
- [docs/oss-and-play-release-plan.md](docs/oss-and-play-release-plan.md) — OSS 公開 →
  Play Store 提出の Phase 11.8 / 11.9 / 11.10 計画

---

## Fork 時の `applicationId` 書換ガイド

本リポジトリの Android `applicationId` は `com.bonkotu.timer.timer_utility` (作者の
個人リバースドメイン)。fork してビルド・配布する場合は、以下を自分のドメインに置換すること:

| ファイル | 該当箇所 |
| --- | --- |
| [android/app/build.gradle.kts](android/app/build.gradle.kts) | `namespace` / `applicationId` |
| [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) | `<receiver android:name="...ScheduledNotificationBootReceiver">` 等の Kotlin クラス参照 |
| [android/app/src/main/kotlin/](android/app/src/main/kotlin/) | `MainActivity.kt` の `package` 宣言、ディレクトリ階層 |

自前 `MethodChannel` のチャネル名 `com.bonkotu.timer/permission` も `com.<your-domain>/permission`
に置換することを推奨 (衝突防止)。詳細は [docs/platform-channels.md](docs/platform-channels.md)。

> 作者は Phase 11.9 で `io.github.bonkoturyu.timer_utility` へ移行予定
> ([docs/oss-and-play-release-plan.md](docs/oss-and-play-release-plan.md))。本 README は
> 完了次第新 ID に追従する。

---

## Contributing

PR / Issue 歓迎。詳細は [CONTRIBUTING.md](CONTRIBUTING.md) を参照。
Code of Conduct は [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) (Contributor Covenant 2.1)。

---

## License

[MIT](LICENSE) — Copyright (c) 2026 BON

同梱音源 (Pixabay Content License) と全依存パッケージ (MIT / BSD 系) のライセンス内訳は
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) および
[assets/sounds/LICENSES.md](assets/sounds/LICENSES.md) を参照。
