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
│   │   ├── timer_collection.dart
│   │   ├── snooze_calculator.dart
│   │   ├── alarm_sound.dart
│   │   ├── alarm_sound_catalog.dart
│   │   └── preset.dart
│   ├── shared/
│   │   ├── duration_formatter.dart
│   │   └── clock_provider.dart
│   └── ports/
│       ├── notification_scheduler.dart
│       ├── alarm_sound_player.dart
│       ├── timer_repository.dart
│       └── preset_repository.dart
│
├── infrastructure/
│   ├── notification/
│   │   ├── flutter_local_notification_adapter.dart
│   │   └── notification_id_generator.dart
│   ├── audio/
│   │   └── audioplayers_adapter.dart
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── drift_timer_repository.dart
│   │   └── drift_preset_repository.dart
│   └── permission/
│       └── permission_manager.dart
│
├── application/                  # Riverpod Providers
│   ├── stopwatch_notifier.dart
│   ├── timer_notifier.dart
│   ├── timer_collection_notifier.dart
│   ├── alarm_ringing_notifier.dart
│   ├── preset_notifier.dart
│   └── permission_notifier.dart
│
├── presentation/
│   ├── screens/
│   │   ├── stopwatch_screen.dart
│   │   ├── timer_list_screen.dart
│   │   ├── timer_create_screen.dart
│   │   ├── alarm_ringing_screen.dart
│   │   └── preset_manage_screen.dart
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

## 関連ドキュメント

- `docs/domain-model.md`: Entity / ValueObject の詳細
- `docs/state-management.md`: Riverpod Provider 一覧
- `docs/testing-strategy.md`: テスト方針
- `docs/adr/`: アーキテクチャ意思決定の経緯

---

最終更新日: 2026-04-29
