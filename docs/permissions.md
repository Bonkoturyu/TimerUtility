# Permission Flow

TimerUtility が Android で利用する権限、拒否時のフォールバック、UI での案内方針を
現行実装に合わせて定義する。

---

## 宣言している権限

[AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml) では次の 11 権限を宣言する。

| 権限 | 用途 | ユーザー操作 |
| --- | --- | --- |
| `ACCESS_COARSE_LOCATION` | 世界時計の初期登録で現在地のタイムゾーンを推定 | 登録が空の初回初期化時に OS ダイアログ |
| `RECORD_AUDIO` | 鳴動中の端末内音声認識による停止 | 設定で音声停止を有効化した時に OS ダイアログ |
| `POST_NOTIFICATIONS` | タイマー / アラーム通知 | Android 13+ で OS ダイアログ |
| `SCHEDULE_EXACT_ALARM` | Exact Alarm の予約 | 対象 OS では設定画面へ誘導 |
| `USE_EXACT_ALARM` | 時計 / アラーム用途の Exact Alarm | OS が付与、ダイアログなし |
| `USE_FULL_SCREEN_INTENT` | ロック画面上の鳴動画面 | 対象 OS では設定画面へ誘導 |
| `WAKE_LOCK` | 鳴動開始時に CPU を起床状態へ移行 | 自動付与 |
| `VIBRATE` | 通知 / アラームの振動 | 自動付与 |
| `RECEIVE_BOOT_COMPLETED` | 再起動後の予約復元 | 自動付与 |
| `FOREGROUND_SERVICE` | バックグラウンドのアラーム再生 Service | 自動付与 |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | 上記 Service の media playback 種別 | 自動付与 |

バッテリー最適化除外 (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) は宣言しておらず、
設定画面への誘導も未実装。通常の権限フローとは分離して扱う。

---

## Exact Alarm とフォールバック

予約時に Exact Alarm の利用可否を確認し、次のどちらか一方を選ぶ。

### Exact を利用できる場合

1. Native の `AlarmManager` で Exact 予約する。
2. 予約時刻に `AlarmPlaybackService` を media playback Foreground Service として起動する。
3. タイマー / アラームで選択された同梱音源または取込音源を、保存済みのアプリ音量で
   予約時刻から直接ループ再生する。
4. Stop / Snooze で Native 再生と保留中の再生世代を停止する。

### Exact を利用できない場合

Exact が未許可または利用不能な場合に限り、予約を inexact へ落とす。Exact が利用可能な
通常経路まで inexact に変更するものではない。

1. `setAndAllowWhileIdle` 相当の inexact 予約で OS 通知を発火する。
2. 固定の短い通知音を鳴らし、FullScreenIntent が許可されていれば鳴動画面を開く。
3. Flutter 側は通知音との重複を避けるため 3200 ms 待ち、選択音源のループ再生へ移行する。
4. Stop / Snooze は待機中の開始も無効化し、後から音が再開しないようにする。

inexact は OS の省電力制御により発火時刻が遅れる可能性がある。UI では Exact Alarm の
許可を推奨しつつ、拒否しても予約作成自体は継続できる。

---

## FullScreenIntent

FullScreenIntent は予約精度と独立して毎回利用可否を確認する。

- 許可あり: ロック画面上に `AlarmRingingScreen` を表示する。
- 許可なし: 通知をヘッドアップ表示へ落とす。予約と鳴動自体は継続する。
- Android 14+ で利用不可の場合は、共通の `PermissionBanners` から設定画面へ誘導する。

---

## 通知権限

Android 13+ では `POST_NOTIFICATIONS` を要求する。拒否時は共通バナーで再要求または
アプリ設定への導線を表示する。権限がない状態では OS 通知を保証できないため、タイマー /
アラームの利用前に許可を促す。

---

## マイク権限

`RECORD_AUDIO` は音声停止をユーザーが有効化した場合にだけ要求する。入力は鳴動画面が
表示されている間だけ Android の端末内認識へ渡し、録音・保存・診断ログ記録を行わない。
拒否時はボタンによる Stop / Snooze をそのまま利用できる。

---

## 位置情報権限

`ACCESS_COARSE_LOCATION` は世界時計の登録が空の初回初期化時にだけ要求する。
OS ダイアログで許可された場合、取得した座標を Android `Geocoder` システムサービスへ渡す。端末・OS・サービス
プロバイダーによってはネットワークを利用する場合がある。アプリ自身は座標を永続化せず、
タイムゾーン識別子だけを保存する。拒否時は端末のシステムタイムゾーンへフォールバックする。

Android `Geocoder` の仕様: <https://developer.android.com/reference/android/location/Geocoder>

---

## アプリ内の権限状態

Application 層の `PermissionState` は UI で継続的に案内する次の 3 状態を保持する。

```text
PermissionState {
  postNotifications: DomainPermissionStatus
  scheduleExactAlarm: DomainPermissionStatus
  fullScreenIntent: DomainPermissionStatus
}
```

位置情報とマイクは各機能の明示操作時に個別確認する。設定画面は音声停止の有効化と
マイク権限導線を管理し、タイマー / アラーム画面の共通 `PermissionBanners` は通知、
Exact Alarm、FullScreenIntent を案内する。

---

## 実装境界

- Domain: `domain/ports/permission_manager.dart` の Pure Dart interface
- Application: `application/permission_notifier.dart` と各 feature provider
- Infrastructure: `permission_handler` と
  `io.github.bonkoturyu.timer_utility/permission` MethodChannel
- Presentation: `PermissionBanners`、設定画面、各機能の要求導線
- Native: `MainActivity`、`NativeAlarmScheduler`、`AlarmPlaybackService`

関連パッケージは `permission_handler ^12.0.0`、`geolocator ^14.0.2`、
`geocoding ^4.0.0`。追加の設定画面起動は既存の platform API / adapter を利用する。

---

最終更新日: 2026-08-03（11 権限、Native Exact 再生、inexact フォールバックへ同期）
