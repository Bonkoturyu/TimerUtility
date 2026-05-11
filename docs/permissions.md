# Permissions

本プロジェクトで使用する Android 権限の取得フロー、UX 方針、フォールバック設計を定義する。
Phase 4 / Phase 6 着手前に必ず本ドキュメントを参照すること。

---

## 権限一覧

| 権限 | Android 必要バージョン | 取得方法 | 必須度 |
|---|---|---|---|
| `POST_NOTIFICATIONS` | 13+ | ランタイム要求 | ★★★ 必須 |
| `USE_EXACT_ALARM` | 13+ | マニフェスト宣言のみ（Play 審査） | ★★ 推奨 |
| `SCHEDULE_EXACT_ALARM` | 12+ | 設定画面誘導 | ★★ フォールバック |
| `USE_FULL_SCREEN_INTENT` | 14+ | 設定画面誘導（カテゴリ承認で自動付与） | ★★ 強く推奨 |
| `WAKE_LOCK` | 全バージョン | マニフェスト宣言のみ | ★★★ 必須 |
| `RECEIVE_BOOT_COMPLETED` | 全バージョン | マニフェスト宣言のみ | ★ Phase 10 で必要 |
| `VIBRATE` | 全バージョン | マニフェスト宣言のみ | ★★ 必須 |
| `ACCESS_COARSE_LOCATION` | 全バージョン | ランタイム要求 | ★ 任意（Phase 10.5 世界時計、初回起動の現在地検出のみ） |
| バッテリー最適化除外 | 全バージョン | 設定画面誘導 | ★ 推奨（メーカー対策） |

---

## 取得タイミングの方針

### 原則

- **必要な瞬間の直前に要求する**（初回起動時にまとめて要求しない）
- 各権限の必要性を**事前に説明**してから要求
- 拒否されても**機能を完全に停止せず、フォールバックで継続**

### タイミング表

| 権限 | 要求タイミング |
|---|---|
| POST_NOTIFICATIONS | 初回タイマー作成時（ストップウォッチのみ使う場合は要求しない） |
| SCHEDULE_EXACT_ALARM | 初回タイマー作成時（USE_EXACT_ALARM が無効な端末のみ） |
| USE_FULL_SCREEN_INTENT | 初回タイマー作成時 |
| バッテリー最適化除外 | 初回タイマー作成時 or タイマーが期待通り動かなかった旨をユーザーが報告した時 |
| ACCESS_COARSE_LOCATION | 初回時計画面起動時のみ（現在地時計を 1 度だけ自動登録するため）。一度許可 / 拒否したら以降は再要求しない |

ストップウォッチ機能のみを使うユーザーには通知系権限の要求をしない設計とする。
時計機能を使わないユーザーにも位置情報権限を要求しない（時計タブを開いた瞬間が初回トリガー）。

---

## 取得フロー

### 1. POST_NOTIFICATIONS

#### 対象 Android バージョン

13+（API 33 以降）。それ以前は不要。

#### フロー

```
[初回タイマー作成画面を開く]
   ↓
permission_handler で notification 状態確認
   ↓
status == granted ?
   ├─ Yes → スキップ
   └─ No → 説明ダイアログ表示
              ↓
           「通知が必要な理由」を説明
              ↓
           [許可する] [後で]
              ↓
           [許可する] → permission_handler.request()
              ↓
           OS の許可ダイアログ
              ↓
           granted → 続行
           denied → フォールバック（通知なしモード）
           permanentlyDenied → 設定画面誘導ダイアログ
```

#### 拒否時のフォールバック

- 通知なしでもタイマー機能は動作させる
- アプリ起動中のみアラーム画面を表示（バックグラウンドでは検知不可になる）
- UI で「通知が無効になっています、バックグラウンドではアラームが鳴りません」と警告表示

---

### 2. USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM

#### 概要

- `USE_EXACT_ALARM`（API 33+）: マニフェスト宣言のみで使用可能、Play 審査でアラームアプリと認められる必要あり
- `SCHEDULE_EXACT_ALARM`（API 31+）: ユーザー手動許可、より広く使える

#### フロー

```
[初回タイマー作成時]
   ↓
canUseExactAlarm() で状態確認
   ├─ USE_EXACT_ALARM 有効 → そのまま使用
   ├─ SCHEDULE_EXACT_ALARM 有効 → そのまま使用
   └─ 両方無効
       ↓
       説明ダイアログ表示
         「正確な時刻でアラームを鳴らすため、設定画面で許可をお願いします」
       ↓
       [設定を開く] [後で]
       ↓
       Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM Intent 発行
       ↓
       ユーザーが OS 設定画面で許可
       ↓
       アプリに戻ってきたら状態再確認
```

#### canUseExactAlarm() の判定ロジック

```
1. Android 14+ で USE_EXACT_ALARM が manifest 宣言済み:
   → 自動的に true を返す（ただし Play 審査通過が前提）

2. Android 12+ で SCHEDULE_EXACT_ALARM:
   → AlarmManager.canScheduleExactAlarms() の結果

3. Android 11 以下:
   → 常に true（権限不要）
```

#### 拒否時のフォールバック

- `setAndAllowWhileIdle` を使用（精度が ±15 分程度低下）
- UI で「アラームに数分の遅延が発生する可能性があります」と警告表示

---

### 3. USE_FULL_SCREEN_INTENT

#### 対象 Android バージョン

14+（API 34 以降）で制限。それ以前は宣言のみで使用可能。

#### Play Store カテゴリ承認

アプリのカテゴリを `Tools` または `Productivity` 配下のアラーム / タイマーとして登録すると、Android 14+ でも新規インストール時に**自動付与**される。

カテゴリ承認のために必要な準備:
- アプリ名にタイマー / アラーム要素を含む
- 機能説明にタイマー / アラームを明記
- スクリーンショットで主要機能を示す
- Play Console での審査時に正当性を説明

#### フロー（カテゴリ未承認 or 個別ユーザー拒否時）

```
[初回タイマー作成時]
   ↓
NotificationManager.canUseFullScreenIntent() で確認
   ↓
true → そのまま使用
false:
   ↓
   説明ダイアログ表示
     「アラーム時にロック画面でも気付けるよう、許可をお願いします」
   ↓
   [設定を開く] [後で]
   ↓
   Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT Intent 発行
   ↓
   ユーザーが OS 設定画面で許可
   ↓
   アプリに戻ってきたら状態再確認
```

#### 拒否時のフォールバック

- `Importance.max` のヘッドアップ通知で代替
- 通知タップでアラーム画面に遷移
- 体験は劣るがアラームとしては機能

---

### 4. ACCESS_COARSE_LOCATION（Phase 10.5）

#### 概要

世界時計の「初回起動時の現在地検出」のみで使用。市区町村レベルの精度で十分なため
`ACCESS_FINE_LOCATION` ではなく COARSE のみ。許可後は緯度経度 → 国コード逆引き
→ 代表 TZ マップで IANA TZ ID を解決し、`ClockEntry(isCurrentLocation: true)`
として 1 件登録する。**継続的な位置追跡は行わない**（旅行先での自動更新は将来 Phase）。

#### フロー

```
[初回時計画面を開く] (ClockEntryCollection が空)
   ↓
permission_handler で locationWhenInUse 状態確認
   ↓
status == granted ?
   ├─ Yes → geolocator.getCurrentPosition (timeout: 10s)
   │           ↓
   │        geocoding.placemarkFromCoordinates
   │           ↓
   │        国コード + administrative_area_1 → 代表 TZ マップで解決
   │           ↓
   │        ClockEntry(isCurrentLocation: true) を Drift に保存
   │
   └─ No → 説明ダイアログ表示
              ↓
           「現在地のタイムゾーンを自動取得するため、位置情報の許可をお願いします」
              ↓
           [許可する] [後で]
              ↓
           [許可する] → permission_handler.request()
              ↓
           granted → 上記処理続行
           denied / permanentlyDenied → FlutterTimezone fallback
```

#### 拒否時のフォールバック

GPS 拒否 / オフライン / 逆ジオコーディング失敗のいずれかでも、
`FlutterTimezone.getLocalTimezone()` で端末タイムゾーンを取得し、
`ClockEntry(isCurrentLocation: true, timezoneId: <端末 TZ>)` として登録する。
ユーザーが端末で「Asia/Tokyo」を設定しているなら、それが「現在地」時計になる。
位置情報権限がなくても時計機能は完全に動作する（劣化体験ゼロに近い）。

#### 「後で」を選んだ場合

- 同じセッション内では再要求しない
- 次回時計画面を開いたとき、ClockEntryCollection が依然空ならもう一度ダイアログ
- ClockEntryCollection に手動追加されたエントリが既にある場合は再要求しない（ユーザーが
  手動運用に切り替えた意思表示として扱う）

---

### 5. バッテリー最適化除外

#### 概要

- 純正 Android では `setExactAndAllowWhileIdle` で十分
- ただしメーカー独自省電力（Xiaomi / OPPO / Huawei 等）では追加対応が必要

#### フロー

```
[初回タイマー作成時 or タイマーが動かなかった報告時]
   ↓
PowerManager.isIgnoringBatteryOptimizations() で確認
   ↓
true → スキップ
false:
   ↓
   説明ダイアログ表示
     「正確にアラームを鳴らすため、バッテリー最適化の対象外に設定してください」
   ↓
   [設定を開く] [後で]
   ↓
   Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS Intent 発行
```

#### メーカー固有の追加対策

`docs/android-constraints.md` の「メーカー独自省電力」セクション参照。
本プロジェクトでは設定画面誘導までで対応、それ以上は端末固有のため UI で案内のみ。

---

## 権限状態の管理

### PermissionState

```
PermissionState {
  notification: PermissionStatus
  exactAlarm: PermissionStatus
  fullScreenIntent: PermissionStatus
  batteryOptimization: PermissionStatus
  coarseLocation: PermissionStatus  // Phase 10.5 で追加
}

enum PermissionStatus {
  granted,         // 取得済み
  denied,          // 拒否されたが再要求可能
  permanentlyDenied, // 「次回確認しない」を選択された
  notRequired,     // この OS バージョンでは不要
  unknown,         // 未確認
}
```

### PermissionNotifier

`application/permission_notifier.dart` で状態を管理。

責務:

- アプリ起動時の全権限状態確認
- 各権限の要求トリガ提供
- アプリ復帰時 (resumed) の状態再確認

### Phase 4 / 6 実装状況

- [x] `domain/ports/permission_manager.dart`: `PermissionManager` インターフェース + `DomainPermissionStatus` enum
- [x] `infrastructure/permission/permission_handler_adapter.dart`: `permission_handler` 経由の実装 + Phase 6b で `PermissionChannel` を注入
- [x] `application/permission_notifier.dart`: `PermissionState` (postNotifications + scheduleExactAlarm + fullScreenIntent) + Notifier
- [x] `presentation/screens/timer_screen.dart`: 権限拒否時バナー UI（denied → 許可ボタン、permanentlyDenied → 設定を開く、FSI denied → 設定を開く）
- [x] AndroidManifest 宣言: POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM / USE_FULL_SCREEN_INTENT / WAKE_LOCK / VIBRATE
- [x] USE_FULL_SCREEN_INTENT 権限取得 UX（Phase 6b、自前 MethodChannel 経由）
- [x] FSI 拒否時の通知フォールバック（Phase 6c、adapter で `canUseFullScreenIntent()` を毎 schedule 検査し、false なら fullScreenIntent フラグを落としてヘッドアップ通知化）
- [ ] RECEIVE_BOOT_COMPLETED / バッテリー最適化除外（Phase 10 で対応予定）
- [ ] ACCESS_COARSE_LOCATION（Phase 10.5 世界時計、初回起動時の現在地検出。拒否時は FlutterTimezone fallback）

Phase 6b で `PermissionState` に `fullScreenIntent` フィールドを追加。
`batteryOptimization` は Phase 10 で再起動時復元と一緒に扱う方針（ADR でなく運用判断）。

---

## 説明ダイアログの UX 方針

### 文言の原則

- **なぜ必要か** を最初に述べる
- 専門用語を避ける（「Foreground Service」「Doze」等は使わない）
- 拒否しても機能が動くなら、その旨を併記

### サンプル文言

#### POST_NOTIFICATIONS

> タイマーが終了したときにお知らせするため、通知の許可をお願いします。
> 許可しない場合、アプリを開いていない時はタイマーの終了を確認できません。
>
> [許可する] [後で]

#### USE_FULL_SCREEN_INTENT

> アラーム時にロック画面でもしっかり気付けるよう、設定で許可をお願いします。
> 許可しない場合は、通知バナーでお知らせします。
>
> [設定を開く] [後で]

#### SCHEDULE_EXACT_ALARM

> 正確な時刻にアラームを鳴らすため、設定画面で許可をお願いします。
> 許可しない場合、アラームが数分遅れる可能性があります。
>
> [設定を開く] [後で]

#### バッテリー最適化除外

> 端末がスリープ中でも正確にアラームが鳴るよう、設定をお願いします。
> 許可しない場合、機種によってはアラームが鳴らないことがあります。
>
> [設定を開く] [後で]

#### ACCESS_COARSE_LOCATION（世界時計、Phase 10.5）

> 現在地のタイムゾーンを自動取得して時計に登録するため、位置情報の許可をお願いします。
> 許可しない場合は、端末の設定タイムゾーンを「現在地」として使用します（時計機能は問題なく動作します）。
>
> [許可する] [後で]

---

## 「後で」を選んだ場合の再要求

- 同じセッション内では再要求しない
- 次回タイマー作成時に再度ダイアログ表示
- 3 回連続で「後で」を選ばれた場合は、しばらく要求しない（任意機能）

---

## permanentlyDenied 時の対応

`POST_NOTIFICATIONS` で「次回確認しない」を選ばれた場合:

- アプリ内ダイアログでは要求できない
- 「アプリ設定を開く」ボタンで `app_settings` パッケージ等を使い、アプリ詳細画面に飛ばす
- ユーザーが手動で許可するのを待つ

---

## 権限状態の確認 UI

設定画面（Phase 11 で実装予定）に「権限の状態」セクションを設置。
各権限の現在状態を表示し、未取得のものは設定画面に飛べるようにする。

```
[権限状態]
✓ 通知                  [取得済み]
✓ 正確なアラーム         [取得済み]
✗ ロック画面でのアラーム  [許可する]
? バッテリー最適化       [確認する]
```

---

## マニフェスト宣言

`android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Phase 4 で追加済み -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Phase 6 / Phase 10 で追加予定 -->
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

<!-- Phase 10.5 で追加予定（世界時計の現在地検出） -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**追加・変更時は CLAUDE.md の規約に従いユーザー確認必須**。

---

## ライブラリ

- `permission_handler` ^11.x: 主要権限の取得
- `app_settings` ^5.x: アプリ設定画面誘導（permission_handler でも可、要確認）
- `com.bonkotu.timer/permission` Channel（Phase 6 で実装）: フルスクリーン Intent 等の特殊権限
- `geolocator` ^14.x（Phase 10.5 で追加予定）: 現在地の緯度経度取得
- `geocoding` ^4.x（Phase 10.5 で追加予定）: 緯度経度 → 国コード逆引き

---

## テスト方針

### 自動化可能

- `PermissionNotifier` の状態管理ロジック（Mock PermissionManager）
- フロー分岐のロジック
- 拒否時のフォールバック動作

### 手動確認

- 実機での実際の権限ダイアログ表示
- 設定画面遷移の動作
- 各メーカーでの挙動

詳細は `docs/testing-strategy.md` 参照。

---

## 関連ドキュメント

- `docs/android-constraints.md`: OS 制約の詳細
- `docs/platform-channels.md`: 特殊権限の Native 連携
- `docs/state-management.md`: PermissionNotifier の設計

---

最終更新日: 2026-05-01（Phase 10.5 ACCESS_COARSE_LOCATION の取得フローと FlutterTimezone fallback を追記）
