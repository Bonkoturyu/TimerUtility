# Platform Channels

Native (Kotlin) ↔ Flutter (Dart) 間のメッセージ仕様を定義する。
Phase 4 以降、Native 連携が必要になった時点で本ドキュメントを参照・更新すること。

---

## 全体方針

### Channel 設計の基本

- **MethodChannel**: Dart → Native への呼び出し（戻り値あり）
- **EventChannel**: Native → Dart への一方向イベント（Stream）
- **BasicMessageChannel**: 双方向の汎用メッセージ（本プロジェクトでは使わない）

### Channel 命名規則

- 形式: `<reverse-domain>/<feature>`
- ベース: `com.bonkotu.timer`
- 例:
  - `com.bonkotu.timer/notification` — 通知関連
  - `com.bonkotu.timer/alarm_event` — Native → Flutter のアラームイベント
  - `com.bonkotu.timer/boot` — 起動時復元

### エラーハンドリング

- Native 側のエラーは `MethodChannel.Result.error(code, message, details)` で返す
- Dart 側で `PlatformException` を catch し、ドメイン例外に変換
- エラーコードは大文字スネークケース（例: `PERMISSION_DENIED`）

---

## Channel 一覧

| Channel | 種別 | 方向 | 用途 |
|---|---|---|---|
| `com.bonkotu.timer/notification` | MethodChannel | Dart → Native | 通知の予約・キャンセル（flutter_local_notifications で代替の場合は不要） |
| `com.bonkotu.timer/alarm_event` | EventChannel | Native → Dart | アラーム発火・通知タップのイベント |
| `com.bonkotu.timer/boot` | MethodChannel | Native → Dart | 端末再起動時のタイマー復元トリガ |
| `com.bonkotu.timer/permission` | MethodChannel | Dart → Native | 各種権限の状態取得 / 設定画面遷移 |
| `com.bonkotu.timer/lockscreen` | MethodChannel | Dart → Native | ロック画面解除リクエスト等 |

---

## Channel 仕様

### `com.bonkotu.timer/alarm_event` (EventChannel)

Native 側でアラーム発火 / 通知タップを検知したときに Flutter に通知。

#### イベント形式

JSON 形式で送信。

```json
{
  "type": "ALARM_FIRED",
  "timerId": "uuid-string",
  "notificationId": 12345,
  "firedAt": "2026-04-29T12:34:56.789Z"
}
```

#### イベントタイプ

| type | 発生タイミング | 必須フィールド |
|---|---|---|
| `ALARM_FIRED` | アラーム時刻到達、通知発火時 | timerId, notificationId, firedAt |
| `NOTIFICATION_TAPPED` | 通知タップ時 | timerId, notificationId, tappedAt |
| `NOTIFICATION_DISMISSED` | 通知スワイプ削除時 | timerId, notificationId, dismissedAt |
| `SNOOZE_ACTION` | 通知のスヌーズアクションボタン押下 | timerId, notificationId |
| `STOP_ACTION` | 通知の停止アクションボタン押下 | timerId, notificationId |

#### Dart 側の購読

```
final eventChannel = EventChannel('com.bonkotu.timer/alarm_event');
eventChannel.receiveBroadcastStream().listen((event) {
  // JSON parse → AlarmEventDto → ドメインイベント変換
});
```

`AlarmRingingNotifier` がこの Stream を購読し、適切な処理を実行。

---

### `com.bonkotu.timer/boot` (MethodChannel)

端末再起動時の復元処理。

#### Native → Dart 呼び出し

```
methodName: "onBootCompleted"
arguments: null
```

Native 側の `BootReceiver` が `BOOT_COMPLETED` を受信したときに Flutter Engine を起動して呼び出す。

#### Dart 側の処理

`TimerCollectionNotifier` が DB から全タイマーを読み出し、`status == running` のものを再予約する。

#### 戻り値

- 成功: `null`
- エラー: `PlatformException(code: "RESTORE_FAILED", message: ..., details: ...)`

---

### `com.bonkotu.timer/permission` (MethodChannel)

権限状態の取得と設定画面誘導。
基本的には `permission_handler` パッケージで対応するが、`USE_FULL_SCREEN_INTENT` のような特殊権限は本 Channel で扱う。

#### Method 一覧

##### `canUseFullScreenIntent`

引数なし。

戻り値: `bool`

```
NotificationManager.canUseFullScreenIntent()
```

##### `canScheduleExactAlarm`

引数なし。

戻り値: `bool`

```
AlarmManager.canScheduleExactAlarms()
```

##### `openFullScreenIntentSettings`

引数なし。

戻り値: `null`

`Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` Intent を発行。

##### `openExactAlarmSettings`

引数なし。

戻り値: `null`

`Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM` Intent を発行。

##### `openBatteryOptimizationSettings`

引数なし。

戻り値: `null`

バッテリー最適化除外の設定画面を開く。

#### エラーコード

| code | 状況 |
|---|---|
| `ACTIVITY_NOT_FOUND` | 設定画面の Intent が解決できない |
| `UNSUPPORTED_API_LEVEL` | 当該 API レベルでサポートされていない |

---

### `com.bonkotu.timer/lockscreen` (MethodChannel)

ロック画面解除リクエスト等の特殊操作。

#### Method 一覧

##### `requestDismissKeyguard`

引数なし。

戻り値: `bool`（解除成功 / 失敗）

`KeyguardManager.requestDismissKeyguard()` を呼び出し。
セキュアロック（PIN 等）が設定されている場合は失敗する。

##### `keepScreenOn`

引数: `{ "enable": true }`

戻り値: `null`

WindowFlags の操作。アラーム鳴動中は ON、停止後 OFF。

---

## Native 側のクラス設計

### MainActivity.kt

```kotlin
package com.bonkotu.timer

class MainActivity : FlutterActivity() {
    private val alarmEventChannel = "com.bonkotu.timer/alarm_event"
    private val bootChannel = "com.bonkotu.timer/boot"
    private val permissionChannel = "com.bonkotu.timer/permission"
    private val lockscreenChannel = "com.bonkotu.timer/lockscreen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 各 Channel の登録
        AlarmEventChannelHandler.register(flutterEngine, this)
        PermissionChannelHandler.register(flutterEngine, this)
        LockscreenChannelHandler.register(flutterEngine, this)
        // boot は別途 BootReceiver から呼ばれる
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 通知タップで起動された場合のイベント送信
        AlarmEventChannelHandler.dispatchFromIntent(intent)
    }
}
```

### BootReceiver.kt

```kotlin
package com.bonkotu.timer

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        // FlutterEngine を起動して onBootCompleted を呼ぶ
        // 詳細は Phase 10 で実装
    }
}
```

### AlarmReceiver.kt（必要に応じて）

`flutter_local_notifications` の AlarmManager 経由で呼ばれる場合は、パッケージ内部の Receiver で処理されるため、独自実装は基本不要。
カスタム動作が必要な場合のみ追加する。

---

## Flutter 側のラッパクラス

Native 連携は **Infrastructure 層に閉じ込め**、Domain / Application からは抽象（port）経由でのみアクセス。

### NativeBridgeProvider 群（infrastructure/platform/）

```
infrastructure/platform/
├── alarm_event_channel.dart       // EventChannel ラッパ
├── permission_channel.dart        // permission Channel ラッパ
├── lockscreen_channel.dart        // lockscreen Channel ラッパ
├── boot_channel.dart              // boot Channel ラッパ
└── dto/
    ├── alarm_event_dto.dart       // JSON ↔ Dart 変換
    └── ...
```

各クラスは Provider 経由で公開:

| Provider | 提供型 |
|---|---|
| `alarmEventStreamProvider` | `Stream<AlarmEvent>` |
| `permissionChannelProvider` | `PermissionChannel` |
| `lockscreenChannelProvider` | `LockscreenChannel` |

---

## メッセージ形式の規約

### JSON エンコード

- すべてのイベント / 引数は JSON 文字列で送受信（MethodChannel の standard codec を使うが、複雑な型は JSON で固める）
- 日時: ISO 8601（UTC）
- ID: 文字列（UUID は文字列のまま）

### Null 安全

- Dart 側はすべての受信フィールドを nullable で受け取り、必須フィールドの欠損は例外
- Native 側は null 値の送信を避ける（欠損フィールドは省略）

### バージョニング

将来的に Channel 仕様を変更する場合、以下のいずれかで対応:
- メッセージに `version: 1` フィールドを追加
- Channel 名を `com.bonkotu.timer/alarm_event/v2` に変更

現状は v1 固定、将来必要になった時点で導入。

---

## エラーハンドリングパターン

### Dart 側

```
try {
  await channel.invokeMethod('canUseFullScreenIntent');
} on PlatformException catch (e) {
  switch (e.code) {
    case 'UNSUPPORTED_API_LEVEL':
      return false;  // 古い API では常に true 扱いなど
    default:
      throw NativeBridgeException(e.message ?? 'Unknown error');
  }
}
```

### Native 側

```kotlin
try {
    val result = nm.canUseFullScreenIntent()
    methodResult.success(result)
} catch (e: Exception) {
    methodResult.error("INTERNAL_ERROR", e.message, e.stackTraceToString())
}
```

---

## テスト戦略

### Dart 側

- `MethodChannel` のモック（`TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`）
- EventChannel のモック（`MockStreamHandler` 相当を自前実装 or モックパッケージ使用）
- Adapter ラッパは Unit Test 可能

### Native 側

- Kotlin の Unit Test（JUnit）で MethodChannel ハンドラのロジック単体をテスト可能
- ただし MethodChannel 自体のモックは Robolectric 等が必要
- 実用上は Dart 側のテストでカバーし、Native 側は Integration Test で確認

詳細は `docs/testing-strategy.md` 参照。

---

## 実装順序

| Phase | 実装する Channel | 備考 |
|---|---|---|
| Phase 4 | （flutter_local_notifications で代替） | 通知予約は package が処理 |
| Phase 5 | （音再生は audioplayers で代替） | |
| Phase 6 | `permission` (一部), `alarm_event` | フルスクリーン Intent 関連 |
| Phase 6 | `lockscreen` | アラーム画面の Window flag |
| Phase 10 | `boot` | 起動時復元 |

---

## 関連ドキュメント

- `docs/architecture.md`: Infrastructure 層の位置づけ
- `docs/android-constraints.md`: OS 制約と Native API
- `docs/permissions.md`: 権限管理フロー

---

最終更新日: 2026-04-29
