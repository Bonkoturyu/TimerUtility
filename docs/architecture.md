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
│   │   ├── snooze_calculator.dart          # Phase 7 で実装済み
│   │   ├── timer_collection.dart           # Phase 8 で実装済み（最大 10 本、集約ルート）
│   │   ├── exceptions.dart                 # Phase 8 で実装済み（MaxTimerCountExceededException 等）
│   │   ├── preset.dart                     # Phase 9 で実装済み
│   │   ├── preset_collection.dart          # Phase 9 で実装済み（集約ルート、最大 10 件）
│   │   ├── preset_service.dart             # Phase 9 で実装済み
│   │   ├── preset_templates.dart           # Phase 9 で実装済み（3 プロファイル定数）
│   │   └── preset_exceptions.dart          # Phase 9 で実装済み
│   ├── alarm/                              # Phase 9.5 で実装済み（指定時刻アラーム、ADR 0005 で Timer と分離）
│   │   ├── day_of_week.dart                # Pure Dart enum（DateTime.weekday と互換）
│   │   ├── time_of_day_value.dart          # Pure Dart 版 TimeOfDay（material 非依存）
│   │   ├── alarm_repeat.dart               # sealed: Once / Weekly(Set<DayOfWeek>)
│   │   ├── alarm_entity.dart               # freezed Entity
│   │   ├── alarm_service.dart              # nextFireAt / advanceAfterFire / snoozeUntil
│   │   └── exceptions.dart                 # AlarmNotFoundException 等
│   ├── clock/                              # Phase 10.5 で実装済み（世界時計、Phase 11 で ClockEntry にリネーム）
│   │   ├── clock_entry.dart                # ClockEntry Entity
│   │   ├── clock_entry_collection.dart     # 集約ルート（最大 6 件）
│   │   ├── clock_time.dart                 # ClockTime ValueObject + TimezoneResolver port
│   │   ├── timezone_catalog.dart           # 25 都市プリセット（pure Dart、IANA TZ ID マップ）
│   │   └── exceptions.dart
│   ├── shared/
│   │   └── duration_formatter.dart
│   └── ports/
│       ├── notification_scheduler.dart     # Phase 4 で実装済み（Phase 8 で show() 追加）
│       ├── permission_manager.dart         # Phase 4 で実装済み
│       ├── alarm_sound_player.dart         # Phase 5 で実装済み
│       ├── timer_repository.dart           # Phase 8 で実装済み
│       ├── preset_repository.dart          # Phase 9 で実装済み
│       ├── user_preferences.dart           # Phase 9 で実装済み（SharedPreferences 抽象）
│       ├── alarm_repository.dart           # Phase 9.5 で実装済み
│       ├── clock_entry_repository.dart     # Phase 10.5 で実装済み（Phase 11 で ClockEntry にリネーム）
│       └── location_detector.dart          # Phase 10.5 で実装済み（GPS → IANA TZ）
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
│   ├── location/                                    # Phase 10.5 で実装済み
│   │   └── location_detector_adapter.dart           # geolocator + geocoding、失敗時 FlutterTimezone fallback
│   ├── clock/                                       # Phase 10.5 で実装済み
│   │   └── tz_database_timezone_resolver.dart       # IANA TZ → wall clock 変換 (timezone パッケージ)
│   ├── preferences/
│   │   └── shared_preferences_user_preferences.dart # Phase 9 で実装済み
│   └── database/
│       ├── app_database.dart                        # Phase 8 で実装済み（Phase 9 で Presets / Phase 9.5 で Alarms テーブル追加）
│       ├── app_database.g.dart                      # 自動生成
│       ├── drift_timer_repository.dart              # Phase 8 で実装済み
│       ├── drift_preset_repository.dart             # Phase 9 で実装済み
│       ├── drift_alarm_repository.dart              # Phase 9.5 で実装済み
│       ├── mappers/
│       │   ├── timer_mapper.dart                    # Phase 8 で実装済み（TimerEntity ⇔ TimerRow）
│       │   ├── preset_mapper.dart                   # Phase 9 で実装済み
│       │   └── alarm_mapper.dart                    # Phase 9.5 で実装済み
│       └── drift_clock_entry_repository.dart        # Phase 10.5 で実装済み（Phase 11 で clock_locations → clock_entries にリネーム、schemaVersion 4→5）
│
├── application/                  # Riverpod Providers
│   ├── clock_provider.dart                # Clock 抽象 (ADR 0004)
│   ├── stopwatch_notifier.dart
│   ├── timer_service_provider.dart           # Phase 8 で分離済み（旧 timer_notifier.dart から）
│   ├── timer_repository_provider.dart        # Phase 8 で実装済み（main.dart で override）
│   ├── timer_collection_notifier.dart        # Phase 8 で実装済み（複数タイマー、起動時 DB 復元）
│   ├── notification_scheduler_provider.dart  # Phase 4 で実装済み
│   ├── permission_notifier.dart              # Phase 4 で実装済み
│   ├── alarm_sound_player_provider.dart      # Phase 5 で実装済み
│   ├── alarm_ringing_notifier.dart           # Phase 5 で実装済み（Phase 9.5 で AlarmSource 両用化）
│   ├── preset_repository_provider.dart       # Phase 9 で実装済み
│   ├── preset_collection_notifier.dart       # Phase 9 で実装済み
│   ├── user_preferences_provider.dart        # Phase 9 で実装済み
│   ├── notification_strings_provider.dart    # Phase 8.5 で実装済み（OS 通知本文の i18n）
│   ├── alarm_repository_provider.dart        # Phase 9.5 で実装済み
│   ├── alarm_service_provider.dart           # Phase 9.5 で実装済み
│   ├── alarm_collection_notifier.dart        # Phase 9.5 で実装済み（最大 50 件、起動時 DB 復元）
│   ├── clock_entry_collection_notifier.dart  # Phase 10.5 で実装済み（Phase 11 で ClockEntry にリネーム）
│   ├── clock_entry_repository_provider.dart  # Phase 10.5 で実装済み（Phase 11 で ClockEntry にリネーム）
│   ├── location_detector_provider.dart       # Phase 10.5 で実装済み
│   ├── timezone_resolver_provider.dart       # Phase 10.5 で実装済み（keepAlive、TZ DB を 1 度だけ load）
│   └── clock_tick/
│       └── current_time_stream_provider.dart # Phase 10.5 で実装済み（1 秒周期、autoDispose）
│
├── presentation/
│   ├── screens/
│   │   ├── home/                            # Phase 11: PageView ベース HomeScreen と各タブの Page widget 群
│   │   │   ├── home_screen.dart             # Phase 11 で実装済み（4 タブの動的 AppBar / FAB / DotIndicator / lastHomePageIndex 復元）
│   │   │   ├── stopwatch_page.dart          # Phase 11: 旧 StopwatchScreen の body を Page widget 化
│   │   │   ├── timer_list_page.dart         # Phase 11: 旧 TimerListScreen の body を Page widget 化（FAB / Add 動線は static helper として公開）
│   │   │   ├── alarm_list_page.dart         # Phase 11: 旧 AlarmListScreen の body を Page widget 化
│   │   │   └── clock_page.dart              # Phase 11: 旧 ClockScreen の body を Page widget 化（SegmentedButton で 3 design 切替）
│   │   ├── stopwatch_screen.dart            # Phase 11 で薄ラッパ化（/stopwatch deep link、body は StopwatchPage に委譲）
│   │   ├── timer_list_screen.dart           # Phase 11 で薄ラッパ化（/timer deep link、body は TimerListPage に委譲）
│   │   ├── alarm_ringing_screen.dart        # Phase 5 で実装済み（Phase 8 Collection / Phase 9.5 alarm payload 両用化）
│   │   ├── preset_manage_screen.dart        # Phase 9 で実装済み
│   │   ├── alarm_list_screen.dart           # Phase 11 で薄ラッパ化（/alarms deep link、body は AlarmListPage に委譲）
│   │   ├── alarm_edit_screen.dart           # Phase 9.5 で実装済み（新規 / 編集両用、TimePicker + WeekdaySelector）
│   │   ├── licenses_screen.dart             # Phase 11 ライセンス画面（先行実装）
│   │   ├── clock_screen.dart                # Phase 11 で薄ラッパ化（/clock deep link、body は ClockPage に委譲）
│   │   └── clock_entry_edit_screen.dart      # Phase 10.5 実装、Phase 11 でリネーム（時計の追加 / 並替 / 削除）
│   ├── widgets/
│   │   ├── lap_list.dart
│   │   ├── duration_picker.dart             # Phase 7 で実装済み（Phase 9 で wheel 部分を再利用可能化）
│   │   ├── preset_select_sheet.dart         # Phase 9 で実装済み
│   │   ├── preset_edit_sheet.dart           # Phase 9 で実装済み
│   │   ├── preset_delete_confirm_dialog.dart # Phase 9 で実装済み
│   │   ├── preset_label_formatter.dart      # Phase 9 で実装済み
│   │   ├── sound_select_sheet.dart          # Phase 9 で実装済み
│   │   ├── alarm_delete_confirm_dialog.dart # Phase 9.5 で実装済み
│   │   ├── weekday_selector.dart            # Phase 9.5 で実装済み（FilterChip 7 個の multi-select）
│   │   ├── analog_clock_widget.dart         # Phase 10.5 で実装済み（CustomPainter）
│   │   ├── digital_clock_widget.dart        # Phase 10.5 で実装済み
│   │   ├── clock_design_a.dart              # Phase 10.5 で実装済み（2x3 アナログ大型 grid）
│   │   ├── clock_design_b.dart              # Phase 10.5 で実装済み（縦 list + 日付）
│   │   ├── clock_design_c.dart              # Phase 10.5 で実装済み（3x2 コンパクト grid）
│   │   ├── utc_offset_formatter.dart        # Phase 10.5 で実装済み（"UTC+09:00" 形式）
│   │   ├── home_dot_indicator.dart          # Phase 11 で実装済み（HomeScreen PageView 用ドットインジケータ、Phase 10.5 ClockScreen 内部 PageView の private _DotIndicator から昇格）
│   │   └── page_navigation_hint.dart        # Phase 10.5 で実装済み（PageView インジケータ）
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
└── io/github/bonkoturyu/timer_utility/
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

#### Phase 11: HomeScreen PageView と Page widget 分離パターン

Phase 11 で HomeScreen を `PageView` 化したことに伴い、各タブ
(Stopwatch / Timer / Alarm / Clock) を 2 段構成で実装している:

- `lib/presentation/screens/home/<feature>_page.dart` — body のみを
  返す `Page widget`。Scaffold / AppBar / FAB は持たない。タブ固有の
  状態 (Timer.periodic / WidgetsBindingObserver / ref.listen) はこの
  Page widget が所有する。HomeScreen の PageView から直接 mount され
  る。
- `lib/presentation/screens/<feature>_screen.dart` — `/stopwatch` 等の
  deep link 経路用。`Scaffold(appBar: ..., body: const <Feature>Page(),
  floatingActionButton: <Feature>Page.buildFab(...))` の薄ラッパに縮退
  しており、HomeScreen と同じ Page widget を共有する。

タブ固有の FAB / AppBar overflow ロジックは `static Widget? buildFab(...)`
や `static Future<void> handleAddTap(...)` のような形で Page widget の
class 名前空間に置く。HomeScreen と deep link Screen の両方が同じ
helper を呼ぶことで、ロジックの duplicate を避ける。

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

### Phase 10.5（世界時計）の iOS 親和性

世界時計は OS 固有の機能（exact alarm / FSI 等）に一切依存しないため、
iOS 移植時の追加コストは最小:

- Domain / Application / Presentation 層: そのまま再利用可能
- `geolocator` / `geocoding` / `flutter_timezone` はいずれも iOS 対応済みパッケージ
- 必要な iOS 設定は `Info.plist` の `NSLocationWhenInUseUsageDescription` 追加のみ
- App Widget 化（将来 Phase）は OS 別に Native 実装が分岐するが、本 Phase スコープ外

---

## 関連ドキュメント

- `docs/domain-model.md`: Entity / ValueObject の詳細
- `docs/state-management.md`: Riverpod Provider 一覧
- `docs/testing-strategy.md`: テスト方針
- `docs/adr/`: アーキテクチャ意思決定の経緯

---

最終更新日: 2026-05-01（Phase 8 完了反映: infrastructure/database/ + timer_collection_notifier 等を実装済みに更新、timer_screen は timer_list_screen に置換）
