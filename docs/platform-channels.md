# Platform Channels

Native (Kotlin) ↔ Flutter (Dart) 間のメッセージ仕様。
Phase 6 までに **採用された Channel** と、当初予定で **採用見送り** になった
Channel をそれぞれ記載する。実装の細部は本ドキュメントよりも実コード
(`MainActivity.kt` / `permission_channel.dart`) を正とする。

---

## 全体方針

### Channel 設計の基本

- **MethodChannel**: Dart → Native への呼び出し（戻り値あり）
- **EventChannel**: Native → Dart への一方向イベント（Stream）
- **BasicMessageChannel**: 双方向の汎用メッセージ（本プロジェクトでは未使用）

### Channel 命名規則

- 形式: `<reverse-domain>/<feature>`
- ベース: `io.github.bonkoturyu.timer_utility`

### エラーハンドリング規約

- Native 側のエラーは `MethodChannel.Result.error(code, message, details)` で返す
- Dart 側で `PlatformException` を catch し、ドメイン例外 / フォールバック値に変換
- エラーコードは大文字スネークケース（例: `PERMISSION_DENIED`）

実態として現在実装されている `io.github.bonkoturyu.timer_utility/permission` は、Native 側から
明示的な error code を投げる箇所が無く、未対応メソッドは `result.notImplemented()`
にフォールバックする。Dart 側ラッパは `bool?` を `false` にデフォルトする防御
コードを持つ（[permission_channel.dart](../lib/infrastructure/platform/permission_channel.dart)
の `canUseFullScreenIntent`）。

---

## 実装済み Channel

唯一実装されている Channel は `io.github.bonkoturyu.timer_utility/permission`（MethodChannel）。
4 メソッドを提供する。

### `io.github.bonkoturyu.timer_utility/permission` (MethodChannel)

`permission_handler` パッケージで扱えない権限・OS 操作を Dart 側から呼び出す
ための Channel。実装は [MainActivity.kt](../android/app/src/main/kotlin/io/github/bonkoturyu/timer_utility/MainActivity.kt)
にすべて寄せている。

#### `canUseFullScreenIntent` (Phase 6b)

- 引数: なし
- 戻り値: `bool`
- 内部: API 34+ (Android 14 / `UPSIDE_DOWN_CAKE`) で
  `NotificationManager.canUseFullScreenIntent()`、それ未満では `true` を返す
  （OS が自動付与するため）
- 用途: FSI 通知の事前チェック。`false` のときヘッドアップ通知にフォールバック
  （Phase 6c）

#### `openFullScreenIntentSettings` (Phase 6b)

- 引数: なし
- 戻り値: `null`
- 内部:
  - API 34+: `Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` を発行
  - API 33 以下、または上記 Intent の `ActivityNotFoundException` 時:
    `Settings.ACTION_APPLICATION_DETAILS_SETTINGS` にフォールバック
- 用途: FSI 権限がない状態でユーザを設定画面に誘導する

#### `clearShowWhenLocked` (Phase 6 実機検証フォローで導入)

- 引数: なし
- 戻り値: `null`
- 用途: FSI 経由で起動された Activity が立てた
  `setShowWhenLocked(true)` / `setTurnScreenOn(true)` を解除する
- 呼び出し元: `AlarmRingingScreen._leaveAlarmScreen` (Stop / Snooze 時、
  [alarm_ringing_screen.dart:439-447](../lib/presentation/screens/alarm_ringing_screen.dart#L439-L447))。
  Issue #73 で Presentation 直叩きを解消し、`keyguardOverrideControllerProvider`
  (Application) → [`MethodChannelKeyguardOverrideController`](../lib/infrastructure/platform/method_channel_keyguard_override_controller.dart)
  (Infrastructure) 経由で呼ぶ
- 対応 API: 27+ (Android 8.1 / `Build.VERSION_CODES.O_MR1`)、それ未満は no-op
- なぜ必要: `setShowWhenLocked(true)` は明示的に `false` に戻さないと残り続け、
  ロック解除後も Activity が「lock-screen overlay」モードに留まる。結果として
  recents (■) ナビゲーションボタンが消失したままになる不具合の修正
- Dart 側ラッパ:
  [`MethodChannelKeyguardOverrideController`](../lib/infrastructure/platform/method_channel_keyguard_override_controller.dart)
  経由で呼び出し、すべての platform 例外を握りつぶす (clear 失敗は recents
  ボタン表示にしか影響せず best-effort。`MethodChannelScreenLockQuery` と同方針)
- Domain port: [`KeyguardOverrideController`](../lib/domain/ports/keyguard_override_controller.dart)
  / Riverpod provider:
  [`keyguardOverrideControllerProvider`](../lib/application/keyguard_override_controller_provider.dart)
- 実装参照: [MainActivity.kt:77-80](../android/app/src/main/kotlin/io/github/bonkoturyu/timer_utility/MainActivity.kt#L77-L80)
  (handler 登録) + [MainActivity.kt:94-99](../android/app/src/main/kotlin/io/github/bonkoturyu/timer_utility/MainActivity.kt#L94-L99)
  (`clearShowWhenLockedInternal` 本体)

#### `isScreenLocked` (Issue #74 fix、2026-05-28)

- 引数: なし
- 戻り値: `bool`
- 内部: `KeyguardManager.isKeyguardLocked()` を返す。API level 16 から利用
  可能なので SDK_INT ガード不要。例外は投げず常に `success`
- 用途: `AlarmRingingNotifier.start` が cancel→play 間の delay を
  「unlock = 500 ms / Lock 画面 = 1800 ms」で分岐する。Pixel / Android 16
  では keyguard 表示中に OS の alarm-stream tone release が遅く、500 ms で
  は Channel sound と audioplayers が重なって二重音になる挙動の補正
- Dart 側ラッパ:
  [`MethodChannelScreenLockQuery`](../lib/infrastructure/platform/method_channel_screen_lock_query.dart)
  経由で読み込み、`PlatformException` / `MissingPluginException` は false
  にフォールバック (= unlock 経路扱い、500 ms delay 適用、安全側)
- Domain port: [`ScreenLockQuery`](../lib/domain/ports/screen_lock_query.dart)
  / Riverpod provider:
  [`screenLockQueryProvider`](../lib/application/screen_lock_query_provider.dart)

#### 不採用とした関連メソッド

旧仕様書に記載していた以下は `permission_handler` パッケージ（および周辺）で
代替されており、本 Channel には **実装していない**。

| 旧仕様メソッド | 代替 |
| --- | --- |
| `canScheduleExactAlarm` | `Permission.scheduleExactAlarm.status` (permission_handler) |
| `openExactAlarmSettings` | `openAppSettings()` (permission_handler) / パッケージ内部の Intent |
| `openBatteryOptimizationSettings` | 現状未使用（バッテリー最適化除外は要件外） |

#### 実装ファイル参照

- Dart 側ラッパ: [lib/infrastructure/platform/permission_channel.dart](../lib/infrastructure/platform/permission_channel.dart)
- Native 側ハンドラ: [android/app/src/main/kotlin/io/github/bonkoturyu/timer_utility/MainActivity.kt](../android/app/src/main/kotlin/io/github/bonkoturyu/timer_utility/MainActivity.kt)

---

## 採用見送りの当初設計

Phase 6 着手時 (2026-04-29) には Channel を 5 ch 立てる予定だったが、Phase
9.5 / 10 / 10.5 / 11 を進める過程で以下 4 Channel は不要と判明した。本セクション
では「予定 → 採用見送りの理由 → 代替手段 → 将来再採用する条件」を記録する。

### `io.github.bonkoturyu.timer_utility/notification` (MethodChannel)

- **採用見送り**: flutter_local_notifications パッケージで完結したため
- 代替: [lib/infrastructure/notification/flutter_local_notification_adapter.dart](../lib/infrastructure/notification/flutter_local_notification_adapter.dart)
  （通知の予約・キャンセル・チャンネル作成すべてをパッケージ経由で実施）
- 将来再採用する条件: パッケージで実現できない通知制御
  （カスタム receiver / 独自 AlarmManager 経由など）が必要になったとき

### `io.github.bonkoturyu.timer_utility/alarm_event` (EventChannel) ← Phase 6 残課題の本丸

- **採用見送り**: Native → Flutter の能動 push は結局不要だった
- 代替: flutter_local_notifications の payload + Activity の
  `onNewIntent` / `getNotificationAppLaunchDetails()` 経由で完結
  - 通知タップ時の Flutter 側受け口: `lib/main.dart` の
    `onDidReceiveNotificationResponse` および cold-launch 時の
    `getNotificationAppLaunchDetails()`
  - payload 形式: `timer:<id>` / `alarm:<id>` （ADR 0005 で確定）
  - `MainActivity.onNewIntent` で keyguard override を再適用
    （`applyKeyguardOverrideIfLocked`、FSI 経由 warm-launch 対応）
- 将来再採用する条件: Native 側で独自 receiver / service を持ち、Flutter に
  能動 push したい場合（例: 独自カスタムウィジェット連携、Phase 12 iOS 版の
  bridge 用途など）

### `io.github.bonkoturyu.timer_utility/boot` (MethodChannel)

- **採用見送り**: Phase 10 で純 Flutter 採用
- 代替: flutter_local_notifications 内蔵の `ScheduledNotificationBootReceiver`
  と、アプリ起動時の `TimerCollectionNotifier._restoreFromRepository` /
  `AlarmCollectionNotifier._loadFromRepository` の組合せ
- 詳細: [`docs/android-constraints.md`](android-constraints.md) の起動時復元
  セクション参照
- 将来再採用する条件: アプリ起動を待たず、boot 直後にバックグラウンドで復元
  処理を走らせたい要件が出てきたとき（現状はアプリ起動契機で十分）

### `io.github.bonkoturyu.timer_utility/lockscreen` (MethodChannel)

- **採用見送り（実態は同居）**: 1 メソッド (`clearShowWhenLocked`) のために
  独立 Channel を増やさず、`io.github.bonkoturyu.timer_utility/permission` Channel に同居
  させた
- 代替: 上記 `io.github.bonkoturyu.timer_utility/permission` の `clearShowWhenLocked`
- 将来再採用する条件: `requestDismissKeyguard` / `keepScreenOn` 等の追加
  lockscreen 操作が複数必要になったとき（Channel 分離による責務整理）

---

## Native 側のクラス設計

実態は **MainActivity 単体** で `io.github.bonkoturyu.timer_utility/permission` Channel を
直接登録している。当初設計にあった `AlarmEventChannelHandler` /
`LockscreenChannelHandler` / `PermissionChannelHandler` といったハンドラ分離は
行っていない（Channel が 1 つしかなく分離する利点が無いため）。

加えて、FSI 経由 cold-launch / warm-launch の双方で keyguard override を
適用するため、`applyKeyguardOverrideIfLocked` を `onCreate` と `onNewIntent`
の両方からフックしている。

実コード抜粋 (構造のみ、最新は [MainActivity.kt](../android/app/src/main/kotlin/io/github/bonkoturyu/timer_utility/MainActivity.kt) を参照):

```kotlin
class MainActivity : FlutterActivity() {
    companion object {
        private const val PERMISSION_CHANNEL = "io.github.bonkoturyu.timer_utility/permission"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyKeyguardOverrideIfLocked()  // FSI cold-launch 対応
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        applyKeyguardOverrideIfLocked()  // FSI warm-launch 対応
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
            .setMethodCallHandler { call, result -> /* 4 メソッドを dispatch */ }
    }
}
```

`BootReceiver` / `AlarmReceiver` の独自実装は **無い**。
flutter_local_notifications パッケージ内蔵の `ScheduledNotificationBootReceiver`
および AlarmManager 経由の receiver で完結している。

---

## Flutter 側のラッパクラス

実態は [lib/infrastructure/platform/permission_channel.dart](../lib/infrastructure/platform/permission_channel.dart)
の 1 ファイルのみ。

旧設計で予定していた以下のファイル / ディレクトリは **採用見送りで実ファイル
は存在しない**:

- `alarm_event_channel.dart`
- `lockscreen_channel.dart`
- `boot_channel.dart`
- `dto/` （Channel が 1 つで JSON DTO が不要になったため）

### Provider / 利用箇所

`PermissionChannel` クラス自体は Riverpod Provider 化していないが、
`io.github.bonkoturyu.timer_utility/permission` を叩く経路はすべて
Infrastructure 層に閉じている。利用箇所は 4 つ:

1. [`PermissionHandlerAdapter`](../lib/infrastructure/permission/permission_handler_adapter.dart)
   内部で `final PermissionChannel _channel` として保持し、FSI 権限の
   問い合わせ (`checkFullScreenIntent`) / 設定画面遷移
   (`openFullScreenIntentSettings`) に使用
2. [`FlutterLocalNotificationAdapter`](../lib/infrastructure/notification/flutter_local_notification_adapter.dart)
   内部で `final PermissionChannel _permissionChannel` として保持し、
   `_safeCanUseFullScreenIntent()` 経由で `schedule()` から FSI 可否を
   再問い合わせ（OS 設定がいつでも変わる可能性があるためキャッシュしない）
3. [`MethodChannelScreenLockQuery`](../lib/infrastructure/platform/method_channel_screen_lock_query.dart)
   が `MethodChannel(PermissionChannel.channelName)` を内部生成し
   `isScreenLocked` を呼ぶ (Issue #74)。`AlarmRingingNotifier.start` は
   domain port [`ScreenLockQuery`](../lib/domain/ports/screen_lock_query.dart) /
   [`screenLockQueryProvider`](../lib/application/screen_lock_query_provider.dart)
   (Application) 経由でこの adapter を取得し、cancel→play delay の判定に使う
4. [`MethodChannelKeyguardOverrideController`](../lib/infrastructure/platform/method_channel_keyguard_override_controller.dart)
   が `MethodChannel(PermissionChannel.channelName)` を内部生成し
   `clearShowWhenLocked` を呼ぶ (Issue #73)。`AlarmRingingScreen._leaveAlarmScreen`
   は domain port
   [`KeyguardOverrideController`](../lib/domain/ports/keyguard_override_controller.dart) /
   [`keyguardOverrideControllerProvider`](../lib/application/keyguard_override_controller_provider.dart)
   (Application) 経由でこの adapter を取得し、画面退出時に keyguard-override を解除する

> **過去の技術的負債（解消済、Issue #73）**: かつては上記 4 の `clearShowWhenLocked`
> を `AlarmRingingScreen` から `const MethodChannel(PermissionChannel.channelName)`
> 直生成で単発呼び出ししており、Presentation 層が Infrastructure 詳細
> (`MethodChannel`) を直接参照する依存方向違反（CLAUDE.md /
> `.gemini/styleguide.md` の `Presentation → Application → Domain ← Infrastructure`
> 原則に対する例外）になっていた。Issue #73 で、`isScreenLocked` (Issue #74) と
> 同型の domain port (`KeyguardOverrideController`) + infra adapter
> (`MethodChannelKeyguardOverrideController`) + Application provider
> (`keyguardOverrideControllerProvider`) に整理して解消した。Presentation 層は
> `MethodChannel` / `permission_channel.dart` を一切 import しない。

---

## メッセージ形式の規約

### 引数 / 戻り値のエンコード

- 現状 `io.github.bonkoturyu.timer_utility/permission` の 4 メソッドはすべて引数なし、戻り値も
  `bool` または `null` のみ。MethodChannel の standard codec で十分
- 将来複雑な型を渡す必要が出た場合は、メッセージを JSON 文字列で固める方針
  （オブジェクト境界での型ずれを避けるため）
- 日時を扱う場合は ISO 8601 (UTC)、ID は文字列のまま

### Null 安全

- Dart 側はすべての受信フィールドを nullable で受け取り、必須フィールドの欠損は
  例外 / 安全側フォールバックに倒す（例: `canUseFullScreenIntent` は `null` を
  `false` 扱い）
- Native 側は null 値の送信を避ける（欠損フィールドは省略）

### バージョニング

将来的に Channel 仕様を変更する場合、以下のいずれかで対応する想定（現状は
v1 固定、必要になった時点で導入）:

- メッセージに `version: 1` フィールドを追加
- Channel 名を `io.github.bonkoturyu.timer_utility/<feature>/v2` に変更

---

## エラーハンドリングパターン

### Dart 側

```dart
try {
  final result = await channel.invokeMethod<bool>('canUseFullScreenIntent');
  return result ?? false;
} on PlatformException catch (e) {
  // 現状の Channel では明示的な error code は飛ばない。
  // 将来 error code を導入する場合は switch (e.code) で分岐する。
  return false;
} on MissingPluginException {
  // テスト環境や Native 側 handler 未登録時に発生。
  // 実態として [`FlutterLocalNotificationAdapter._safeCanUseFullScreenIntent`](../lib/infrastructure/notification/flutter_local_notification_adapter.dart)
  // で同様の catch を行い、ヘッドアップ通知へフォールバックしている。
  return false;
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

現実態の `MainActivity.kt` は `openFullScreenIntentSettingsInternal` のみで
`ActivityNotFoundException` を catch し、汎用設定画面へフォールバックしている
（[MainActivity.kt:121-126](../android/app/src/main/kotlin/io/github/bonkoturyu/timer_utility/MainActivity.kt#L121-L126)）。
それ以外の handler は `result.success(...)` / `result.notImplemented()` のみで、
明示的な error code は投げていない。`canUseFullScreenIntent` についても現状の
最小実装で安定動作しているが、将来 SDK 変更で例外伝播が変わる可能性は残るので、
問題が観測されたら上記サンプルのような汎用 try / catch を追加する方針。

---

## テスト戦略

現状の `io.github.bonkoturyu.timer_utility/permission` 周辺の Native ↔ Dart 通信に対するテスト
状況:

- **Dart 側**:
  [`test/infrastructure/platform/permission_channel_test.dart`](../test/infrastructure/platform/permission_channel_test.dart)
  に MethodChannel モックベースの Unit Test が 4 ケースあり
  (`canUseFullScreenIntent` の true / false / null → false フォールバック +
  `openFullScreenIntentSettings` の呼び出し検証)。
  `clearShowWhenLocked` および `PermissionHandlerAdapter` /
  `FlutterLocalNotificationAdapter` の MethodChannel 経由パスは現時点で
  専用ユニットテスト未整備（実機検証でカバー）
- **Native 側**: 専用 Unit Test / Integration Test は無し。Phase 6 実機検証
  (Pixel 6a / Android 16、2026-04-30) と Phase 6 follow-up (2026-05-04 の
  recents ボタン消失修正) で動作確認済み

将来 Channel を拡張する場合の方針:

### Dart 側のテスト

- `MethodChannel` のモックは
  `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`
  を使用
- Adapter ラッパ（`PermissionChannel` 等）は Unit Test 可能

### Native 側のテスト

- Kotlin の Unit Test (JUnit) で MethodChannel ハンドラのロジック単体は
  テスト可能
- ただし MethodChannel 自体のモックは Robolectric 等が必要
- 実用上は Dart 側のテストでカバーし、Native 側は Integration Test / 実機検証で
  確認する方針

詳細は [`docs/testing-strategy.md`](testing-strategy.md) 参照。

---

## 実装事実

| Phase | 実装した Channel / メソッド | 備考 |
| --- | --- | --- |
| Phase 4 | (採用なし) | flutter_local_notifications で代替 |
| Phase 5 | (採用なし) | audioplayers で代替 |
| Phase 6 | `/permission/canUseFullScreenIntent`, `/permission/openFullScreenIntentSettings` | FSI 権限関連 |
| Phase 6 実機検証フォロー | `/permission/clearShowWhenLocked` 追加 | FSI 起動後の `setShowWhenLocked(true)` 解除 |
| Phase 7〜10.5 | (採用なし) | Native 連携なしで完結 |

---

## 関連ドキュメント

- [`docs/architecture.md`](architecture.md): Infrastructure 層の位置づけ
- [`docs/android-constraints.md`](android-constraints.md): OS 制約と Native API、
  起動時復元の純 Flutter 化経緯
- [`docs/permissions.md`](permissions.md): 権限管理フロー（FSI / exact alarm）
- [`docs/adr/`](adr/): ADR 0005 で通知 payload 形式を確定

---

最終更新日: 2026-05-13（Phase 6 docs cleanup。4 Channel 採用見送りを確定し、
`clearShowWhenLocked` を後付け文書化、構成を「実装済み Channel」と「採用見送りの
当初設計」に分離）
