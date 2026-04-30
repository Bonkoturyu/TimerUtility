# Architecture

本プロジェクトのレイヤー構造、依存方向、命名規則を定義する。
Claude Code は実装前に必ず本ドキュメントを参照すること。

---

## レイヤー構造

```
┌──────────────────────────────────────────────┐
│  Presentation Layer                          │
│  (lib/presentation/)                         │
│  ・Widget / Screen                           │
│  ・Riverpod を ref.watch / ref.read で参照   │
└──────────────────┬───────────────────────────┘
                   │ depends on
┌──────────────────▼───────────────────────────┐
│  Application Layer                           │
│  (lib/application/)                          │
│  ・Riverpod Provider / Notifier              │
│  ・UI 状態の保持と Domain への委譲            │
└──────────────────┬───────────────────────────┘
                   │ depends on
┌──────────────────▼───────────────────────────┐
│  Domain Layer (Pure Dart)                    │
│  (lib/domain/)                               │
│  ・Entity / ValueObject                       │
│  ・ドメインサービス                            │
│  ・ports/ にインターフェース定義              │
└──────────────────▲───────────────────────────┘
                   │ implements
┌──────────────────┴───────────────────────────┐
│  Infrastructure Layer                        │
│  (lib/infrastructure/)                       │
│  ・ports の実装（Adapter）                    │
│  ・外部 API / DB / OS との接続                │
└──────────────────────────────────────────────┘
```

### 依存方向の絶対原則

- **下位レイヤーは上位レイヤーを知らない**
- **Domain は他のすべてのレイヤーから独立**（外部パッケージへの依存も最小）
- **Infrastructure は Domain の `ports/` を実装する形でのみ Domain と関わる**
- 依存の逆流は `analysis_options.yaml` の lint で検出する

---

## ディレクトリ構造（厳守）

```
lib/
├── domain/                       # Pure Dart のみ
│   ├── stopwatch/
│   │   ├── stopwatch_state.dart
│   │   └── stopwatch_service.dart
│   ├── timer/
│   │   ├── timer_status.dart
│   │   ├── timer_entity.dart
│   │   ├── timer_service.dart
│   │   ├── notification_id_generator.dart  # Phase 4 で実装済み（domain 層配置）
│   │   ├── alarm_sound.dart                # Phase 5 で実装済み
│   │   ├── alarm_sound_catalog.dart        # Phase 5 で実装済み
│   │   ├── timer_collection.dart           # Phase 8 予定
│   │   ├── snooze_calculator.dart          # Phase 7 予定
│   │   └── preset.dart                     # Phase 9 予定
│   ├── shared/
│   │   └── duration_formatter.dart
│   └── ports/
│       ├── notification_scheduler.dart     # Phase 4 で実装済み
│       ├── permission_manager.dart         # Phase 4 で実装済み
│       ├── alarm_sound_player.dart         # Phase 5 で実装済み
│       ├── timer_repository.dart           # Phase 8 予定
│       └── preset_repository.dart          # Phase 9 予定
│
├── infrastructure/
│   ├── notification/
│   │   └── flutter_local_notification_adapter.dart  # Phase 4 で実装済み（Phase 6c で FSI フォールバック対応）
│   ├── permission/
│   │   └── permission_handler_adapter.dart          # Phase 4 で実装済み（Phase 6b で PermissionChannel 注入）
│   ├── platform/
│   │   └── permission_channel.dart                  # Phase 6b で実装済み（USE_FULL_SCREEN_INTENT 用 MethodChannel ラッパ）
│   ├── audio/
│   │   └── audioplayers_adapter.dart                # Phase 5 で実装済み
│   └── database/
│       ├── app_database.dart                        # Phase 8 予定
│       ├── drift_timer_repository.dart              # Phase 8 予定
│       └── drift_preset_repository.dart             # Phase 9 予定
│
├── application/                  # Riverpod Providers
│   ├── clock_provider.dart                # Clock 抽象 (ADR 0004)
│   ├── stopwatch_notifier.dart
│   ├── timer_notifier.dart
│   ├── notification_scheduler_provider.dart  # Phase 4 で実装済み
│   ├── permission_notifier.dart              # Phase 4 で実装済み
│   ├── alarm_sound_player_provider.dart      # Phase 5 で実装済み
│   ├── alarm_ringing_notifier.dart           # Phase 5 で実装済み
│   ├── timer_collection_notifier.dart        # Phase 8 予定
│   └── preset_notifier.dart                  # Phase 9 予定
│
├── presentation/
│   ├── screens/
│   │   ├── stopwatch_screen.dart
│   │   ├── timer_screen.dart                # Phase 3 で実装済み（Phase 8 で list 化予定）
│   │   ├── alarm_ringing_screen.dart        # Phase 5 で実装済み
│   │   ├── timer_list_screen.dart           # Phase 8 予定
│   │   ├── timer_create_screen.dart         # Phase 8 予定
│   │   └── preset_manage_screen.dart        # Phase 9 予定
│   ├── widgets/
│   │   ├── lap_list.dart
│   │   ├── timer_card.dart
│   │   └── duration_picker.dart
│   └── routing/
│       └── app_router.dart
│
└── main.dart

test/                             # Unit Test + Widget Test
├── domain/
├── application/
├── infrastructure/
└── presentation/

integration_test/                 # 実機テスト

android/app/src/main/kotlin/      # Native 実装
└── com/bonkotu/timer/timer_utility/
    ├── MainActivity.kt
    ├── BootReceiver.kt
    └── alarm/
        └── AlarmReceiver.kt

docs/                             # 設計ドキュメント
└── (本ドキュメント等)
```

---

## レイヤーごとの責務と禁止事項

### Domain Layer

**責務**:
- ビジネスロジックの中核
- Entity / ValueObject の定義
- ドメインサービス（純粋な計算・状態遷移ロジック）
- ports/（外部システムとの境界インターフェース）

**禁止事項**:
- ❌ `package:flutter/*` の import
- ❌ `package:flutter_riverpod` の import
- ❌ `dart:io` 等のプラットフォーム依存 API
- ❌ `DateTime.now()` の直接呼び出し
- ❌ `Stopwatch`（dart:core）の直接利用
- ❌ `Timer.periodic` / `Future.delayed` の使用

**依存可能なパッケージ**:

- `package:meta`
- `package:clock`
- `package:collection`
- `package:uuid`（ID 生成のみ）

**注**: `NotificationIdGenerator` は OS 通知に必要な int ID を導出するロジックだが、
TimerEntity の生成時に決定的に発番されるドメインルールであり、外部依存も持たないため
domain 層（`domain/timer/notification_id_generator.dart`）に配置する。
infrastructure 層から見ると Pure Dart の値オブジェクト相当として参照される。

### Application Layer

**責務**:
- Riverpod Provider / Notifier
- Domain と Presentation の橋渡し
- UI 表示用の状態保持
- AppLifecycle の購読（必要な Notifier のみ）

**禁止事項**:
- ❌ ビジネスロジックの実装（Domain に委譲）
- ❌ Widget / BuildContext への直接依存
- ❌ `DateTime.now()` の直接呼び出し（`clockProvider` 経由）

### Infrastructure Layer

**責務**:
- Domain の `ports/` インターフェースの実装
- 外部 API / DB / OS / ファイルシステムとの接続
- Platform Channel の呼び出し

**禁止事項**:
- ❌ Application / Presentation からの直接 import（必ず ports 経由）
- ❌ ビジネスロジックの実装

### Presentation Layer

**責務**:
- Widget / Screen の構築
- Riverpod の `ref.watch` / `ref.read` による状態購読
- ユーザー入力のハンドリング
- Navigation

**禁止事項**:
- ❌ Domain Service の直接呼び出し（必ず Notifier 経由）
- ❌ Infrastructure への直接 import
- ❌ ビジネスロジックの実装

---

## 命名規則

### ファイル名

- Dart ファイル: `snake_case.dart`
- テストファイル: `<対象ファイル名>_test.dart`
  - 例: `stopwatch_service.dart` → `stopwatch_service_test.dart`

### クラス名

| 種別 | 命名 | 例 |
|---|---|---|
| Entity | `XxxEntity` | `TimerEntity` |
| ValueObject | 役割名 | `Duration`, `AlarmSound` |
| ドメインサービス | `XxxService` | `StopwatchService`, `TimerService` |
| ドメイン計算ロジック | `XxxCalculator` / `XxxFormatter` | `SnoozeCalculator`, `DurationFormatter` |
| Port | `XxxScheduler` / `XxxRepository` / `XxxPlayer` 等 | `NotificationScheduler` |
| Adapter | `XxxAdapter` | `FlutterLocalNotificationAdapter` |
| Notifier | `XxxNotifier` | `TimerNotifier` |
| Screen | `XxxScreen` | `StopwatchScreen` |
| Widget | 役割名 | `LapList`, `TimerCard` |

### 変数名

- public: `camelCase`
- private: `_camelCase`（先頭アンダースコア）
- 定数: `camelCase`（Dart 慣習）
- enum 値: `camelCase`

### Riverpod Provider

- `xxxProvider`（小文字始まり）
- 例: `clockProvider`, `stopwatchNotifierProvider`, `timerCollectionProvider`

### テストの describe / group

- `group('<対象クラス名>', () { ... })` で囲む
- `test('<日本語で振る舞いを記述>', () { ... })`
- 例: `test('Start から 5 秒後に経過時間が 5 秒を返す', ...)`

---

## ファイル分割の指針

- **1 ファイル 1 クラス原則**（小さい ValueObject は同居可）
- **1 ファイル 300 行を超えたら分割を検討**
- **Entity と Service は別ファイル**
- **Notifier と State は別ファイル**

---

## import 順序

`dart format` 標準に従う:

1. `dart:` 系
2. `package:` 系（Flutter 含む）
3. プロジェクト内相対 import（`../` または `package:<projectname>/`）

各グループ内はアルファベット順。

---

## エラーハンドリング方針

### Domain Layer

- ドメイン例外は専用クラスを定義（例: `TimerNotFoundException`）
- `Result<T, E>` 型は使わず、例外で表現する（Dart 慣習）
- 不正な状態遷移は `StateError` を throw

### Application Layer

- 例外を catch し、Riverpod の State として表現（`AsyncValue.error` など）

### Infrastructure Layer

- Platform Channel エラーは Domain の例外型に変換して throw

---

## ロギング方針

- `logger` パッケージ使用
- ロガーは Provider 経由で取得可能にする（テスト時にモック差し替え）
- ログレベル:
  - `debug`: 開発時のみ
  - `info`: 主要な状態遷移
  - `warning`: 異常だが回復可能
  - `error`: 例外発生
- 個人情報や機密情報をログに含めない

---

## iOS 対応方針

現状 Android 16 を主ターゲットとするが、Core 設計（domain / application 層）は
Pure Dart で OS 非依存に保ち、将来の iOS 対応に備える。実装は Phase 12 で着手。

### レイヤー別の OS 依存度

| レイヤー | OS 依存 | 移植性 |
|---|---|---|
| `lib/domain/` | なし（Pure Dart） | iOS でそのまま再利用可能 |
| `lib/application/` | なし（Riverpod、Pure Dart） | iOS でそのまま再利用可能 |
| `lib/presentation/` | なし（Flutter Widget） | iOS でも動く（UI は MaterialApp ベース） |
| `lib/infrastructure/` | **Android 固有ロジックあり** | Phase 12 で OS 別 Adapter を共存させる |

### Phase 12 で予定する infrastructure 層の構造

現状: 各 category 直下に Android 専用 Adapter のみ

```text
lib/infrastructure/
├── notification/flutter_local_notification_adapter.dart  // Android 固有ロジック含む
├── audio/audioplayers_adapter.dart                        // クロスプラットフォーム対応パッケージ使用
└── permission/permission_handler_adapter.dart             // SCHEDULE_EXACT_ALARM 等 Android 前提
```

Phase 12 着手後の想定:

```text
lib/infrastructure/
├── notification/
│   ├── android/flutter_local_notification_adapter.dart
│   └── ios/cupertino_notification_adapter.dart
├── audio/audioplayers_adapter.dart                        // 両 OS 共通でいける可能性が高い
└── permission/
    ├── android/permission_handler_adapter.dart
    └── ios/permission_handler_adapter.dart
```

Riverpod Provider 側で `defaultTargetPlatform` または `Platform.isAndroid` /
`Platform.isIOS` から実装を分岐する。

### iOS で実現できないことの明示

- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`: iOS には正確時刻アラームの概念なし。
  `UNCalendarNotificationTrigger` は OS 任せの精度（数秒〜数分の遅延あり）
- `USE_FULL_SCREEN_INTENT`（ロック画面上のフル画面アラーム）: iOS には対応する API がない。
  CallKit は通話用途のため代替不可
- `RECEIVE_BOOT_COMPLETED`: iOS は再起動後の通知予約復元を OS が自動処理、
  開発者が介入できない

結論として「ロック画面上で正確な時刻にアラーム鳴動 + フルスクリーン表示」という
本アプリの核心要件は、iOS では設計レベルで実現困難。Phase 12 着手時に **iOS 版の
要件を再定義** する必要がある（精度は妥協、フルスクリーン要件は外す等）。

### iOS 版の要件レベル（確定方針）

iOS 版を出す場合、Android 版と同等の体験は OS 制約により実現不可能。
以下の要件緩和を **確定方針** として受け入れる:

- **アラーム精度**: OS 任せ（±1 分程度のズレ許容）
- **ロック画面占有**: 不要（通知バナー / Critical Alert のみ）
- **フルスクリーン Intent**: 非対応
- **用途想定**: 料理タイマー等、厳密な時刻精度が不要なケース

Android 版の Phase 6（FullScreenIntent）/ Phase 7（exact alarm 完全対応）等で
実装する Android 固有機能は、iOS 版では **実装しない**。
この要件緩和を受け入れる代わりに、`lib/domain/` `lib/application/`
`lib/presentation/` のコード共通化メリットを優先する。

---

## 関連ドキュメント

- `docs/domain-model.md`: Entity / ValueObject の詳細
- `docs/state-management.md`: Riverpod Provider 一覧
- `docs/testing-strategy.md`: テスト方針
- `docs/adr/`: アーキテクチャ意思決定の経緯

---

最終更新日: 2026-04-30（Phase 6a/b/c の実装状況をディレクトリ構造に反映）
