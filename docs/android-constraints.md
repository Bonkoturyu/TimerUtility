# Android Constraints

Android 16 (API 36) を主ターゲットとする本プロジェクトの OS 制約集。
Claude Code は Phase 4 以降の作業前に必ず本ドキュメントを参照すること。

---

## 対応バージョン

- `compileSdk`: 36 (Android 16)
- `targetSdk`: 36 (Android 16)
- `minSdk`: 26 (Android 8.0)（要件次第で 24 まで下げ可能）

`minSdk = 26` の理由:
- Notification Channel の API 24+ 制約
- AlarmManager の挙動変化が API 26 以降で安定
- 通知音のカスタマイズが API 26+ で Channel 単位に変更

---

## バックグラウンド実行制約の進化

各バージョンでの制約変化を把握しておく。

| バージョン | 主な制約 | 影響 |
|---|---|---|
| Android 6 (API 23) | Doze Mode 導入 | スリープ中のネットワーク / Wakelock 制限 |
| Android 7 (API 24) | Doze on the Go | 移動中も Doze 適用 |
| Android 8 (API 26) | Background Service 制限、Notification Channel 必須 | Foreground Service 必須化 |
| Android 9 (API 28) | App Standby Buckets | アプリ使用頻度で制限 |
| Android 12 (API 31) | SCHEDULE_EXACT_ALARM 権限化 | ユーザー許可必須に |
| Android 13 (API 33) | POST_NOTIFICATIONS ランタイム要求 | 通知許可ダイアログ必須 |
| Android 14 (API 34) | Foreground Service Type 厳格化、USE_FULL_SCREEN_INTENT 制限 | アラームアプリの審査強化 |
| Android 15 (API 35) | dataSync 型 FGS の 6h/24h 制限、Edge-to-Edge 強制 | 長時間 FGS 困難に |
| **Android 16 (API 36)** | **dataSync / mediaProcessing 型 FGS のさらなる制限** | **specialUse への移行が事実上必須** |

---

## 本プロジェクトの戦略

### Foreground Service は使わない

詳細は `docs/adr/0003-fullscreen-intent-strategy.md`。

採用方針:
- **AlarmManager + 通知スケジュール方式**
- アラーム発火そのものは OS に予約（`flutter_local_notifications` 経由）
- カウントダウン表示はフォアグラウンド時のみ
- バックグラウンドではアプリは何もしない

メリット:
- Android 16 の FGS 制約を回避
- バッテリー消費最小
- 端末スリープ中も時計は止まらないため、絶対時刻ベースで正確
- Play Store の specialUse 審査不要

デメリット:
- 通知のリアルタイム秒数更新は不可（許容）

---

## AlarmManager の挙動

### 使用 API

`flutter_local_notifications` 内部で以下を使用:

| API | 用途 | 必要権限 |
|---|---|---|
| `setExactAndAllowWhileIdle` | Doze 中も正確に発火 | `SCHEDULE_EXACT_ALARM` または `USE_EXACT_ALARM` |
| `setAndAllowWhileIdle` | Doze 中だが ±15 分の不正確 | なし |
| `setAlarmClock` | アラームアプリ向け、最高優先度 | なし |

本プロジェクトでは **`setExactAndAllowWhileIdle` 相当**を使用。

### Doze Mode の影響

- 端末が完全スリープになると CPU / ネットワーク制限
- `setExactAndAllowWhileIdle` は Doze を一時解除して発火可能
- ただし**頻繁な exact alarm はバッテリー警告対象**になる

### App Standby Buckets

ユーザーがアプリをほぼ使わない場合、buckets が悪化:

| Bucket | 制約 |
|---|---|
| Active | 制限なし |
| Working set | 軽い遅延 |
| Frequent | 中程度の遅延 |
| Rare | 強い遅延 |
| Restricted | ほぼ実行不可 |

- タイマーアプリは「使うときだけ起動」されるため Rare 落ちしやすい
- `setExactAndAllowWhileIdle` は bucket 制限を一部回避するが、保証されない

---

## SCHEDULE_EXACT_ALARM vs USE_EXACT_ALARM

正確なアラームを撃つために必要な権限。

### `SCHEDULE_EXACT_ALARM`

- Android 12+ で導入
- ユーザーが**設定画面から手動で許可**する必要あり
- アプリ内でダイアログ表示はできない（`Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM` Intent で設定画面に飛ばす）
- ユーザーがいつでも取り消し可能
- Android 14+ で取り消されると `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` で通知

### `USE_EXACT_ALARM`

- Android 13+ で導入
- マニフェスト宣言のみで使用可能（ランタイム要求なし）
- **ただし「アラーム / カレンダー / 通話」用途のアプリのみ Play Store で承認**
- タイマーアプリは正当な用途として認められる
- ユーザーが取り消せない（強い権限）

### 採用方針

**両方を宣言**し、以下の順で確認:

1. `USE_EXACT_ALARM` が付与されていればそれを使う（Android 13+）
2. `SCHEDULE_EXACT_ALARM` の状態を確認、未許可ならユーザーに設定画面誘導
3. どちらも取れない場合: `setAndAllowWhileIdle` でフォールバック（精度低下を許容）

---

## フルスクリーン Intent

### 概要

通知発火時に、ロック画面の上に Activity を起動する仕組み。
本プロジェクトのアラーム鳴動 UI に必須。

### 必要権限

- `USE_FULL_SCREEN_INTENT`（Android 14+ で制限）

### Android 14+ での挙動

- **新規インストールアプリはデフォルトで拒否**
- 例外: アプリのカテゴリが `Alarm` / `Calendar` / `Phone` の場合は自動付与
- それ以外: ユーザーが設定画面で手動許可
- `NotificationManager.canUseFullScreenIntent()` で状態確認可能

### Play Store 審査

- アプリの主要機能としてアラームを宣言（カテゴリ: `Tools` / `Productivity` 配下のアラームサブカテゴリ）
- `USE_FULL_SCREEN_INTENT` を使う正当性を Play Console で説明
- 審査通過後は新規インストールでも自動付与される

### 実装注意点

- `flutter_local_notifications` の `AndroidNotificationDetails` で `fullScreenIntent: true`
- 通知の `importance` は `Importance.max`、`priority` は `Priority.high` 必須
- 通知 Channel の `importance` も `IMPORTANCE_HIGH` 以上
- MainActivity 側に `showOnLockScreen` / `turnScreenOn` 属性必須

### フォールバック設計

権限が取れない場合の代替動作:
- ヘッドアップ通知（`Importance.max` で画面上部にバナー表示）
- 通知タップでアラーム画面に遷移
- 体験は劣るが機能は動作

---

## 通知関連

### POST_NOTIFICATIONS（Android 13+）

- ランタイム要求が必須
- 拒否時は通知が一切表示されない
- **タイマーアプリでは絶対に必要**な権限

### 通知 Channel 設計

| Channel ID | 用途 | importance | サウンド | バイブ |
|---|---|---|---|---|
| `timer_alarm` | タイマー鳴動 | HIGH (5) | カスタム音源 | あり |
| `timer_status` | タイマー実行中の表示（任意） | LOW (2) | なし | なし |

`timer_alarm` Channel:
- `setBypassDnd(true)`（おやすみモードを突破、要ユーザー許可）
- `enableVibration(true)`
- `setShowBadge(false)`
- `lockscreenVisibility = VISIBILITY_PUBLIC`

### カスタム音源

- 通知の `setSound()` で `assets/sounds/` の音源は **直接指定不可**
- `flutter_local_notifications` の `RawResourceAndroidNotificationSound` で `android/app/src/main/res/raw/` 配下の音源を指定する方法がある
- 本プロジェクトでは: **通知音は通知 Channel の標準音 + アラーム画面起動後に audioplayers でカスタム音再生** の二段構え

詳細は `docs/assets-spec.md` 参照。

---

## RECEIVE_BOOT_COMPLETED

端末再起動後にタイマー予約を復元するために使用。

- マニフェスト宣言のみ（ランタイム要求なし）
- BroadcastReceiver で `BOOT_COMPLETED` を受信
- Native (Kotlin) 側で受信 → Flutter Engine 起動 → タイマー DB 読み出し → 再予約

### 制約

- BootReceiver の処理時間は数秒以内に抑える
- DB 読み出しは Coroutine / Background Thread で
- Direct Boot Aware にはしない（暗号化解除後の通常ブートで OK）

詳細実装は `docs/platform-channels.md` で扱う。

---

## メーカー独自省電力

純正 Android 以外（Xiaomi MIUI, OPPO ColorOS, Huawei EMUI, Samsung One UI 等）では
独自の省電力機構が `setExactAndAllowWhileIdle` を無視することがある。

### 既知の問題

| メーカー | 機構 | 対策 |
|---|---|---|
| Xiaomi MIUI | Autostart 制限 | 設定で「自動起動」許可 |
| OPPO ColorOS | バッテリー最適化 | 「バックグラウンド凍結」除外 |
| Huawei EMUI | 保護されたアプリ | 「保護されたアプリ」リスト追加 |
| Samsung One UI | スリープ中のアプリ | 「スリープしないアプリ」追加 |

### アプリ側の対応

- 初回起動時に「メーカーごとの設定が必要な場合がある」旨を案内
- `dontkillmyapp.com` の情報を参考に、UI から各メーカーの設定画面に飛ぶリンクを提供（オプション）
- これは **完全な解決ではない**ため、`docs/permissions.md` の権限取得 UX で説明

---

## Edge-to-Edge（Android 15+）

Android 15 以降、デフォルトで edge-to-edge が強制適用される。

### 影響

- システムバー（ステータス / ナビ）の下にコンテンツが描画される
- `SafeArea` ウィジェットが必須
- 既存の `Scaffold` だけでは見切れる

### 対応

- `MaterialApp` レベルで全画面 `SafeArea` ラップ
- `theme` で `useMaterial3: true` 推奨
- システムバーの色 / アイコン色は `SystemUiOverlayStyle` で調整

---

## ProGuard / R8

リリースビルドでコード難読化が走る場合の注意。

`android/app/proguard-rules.pro` に必要なルールを追加:
- flutter_local_notifications の通知受信クラス
- BootReceiver
- カスタム Native クラス

各パッケージの公式ドキュメントを参照して keep ルールを設定。

---

## マニフェスト雛形

`android/app/src/main/AndroidManifest.xml` に必要な宣言:

```xml
<manifest>
    <!-- 通知 -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- 正確なアラーム -->
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />

    <!-- フルスクリーン Intent -->
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />

    <!-- 画面 ON / Wake Lock -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <!-- 起動時復元 -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

    <!-- バイブ -->
    <uses-permission android:name="android.permission.VIBRATE" />

    <application ...>
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:showOnLockScreen="true"
            android:turnScreenOn="true"
            ...>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- BootReceiver は Phase 10 で追加 -->
    </application>
</manifest>
```

**追加・変更時は CLAUDE.md の「編集時に確認が必要なファイル」ルールに従い、ユーザー確認必須**。

---

## build.gradle.kts 雛形

`android/app/build.gradle.kts` の重要設定:

```kotlin
android {
    compileSdk = 36
    defaultConfig {
        minSdk = 26
        targetSdk = 36
    }
    compileOptions {
        isCoreLibraryDesugaringEnabled = true  // flutter_local_notifications 用
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

`coreLibraryDesugaring` は `flutter_local_notifications` の要件。

---

## 検証チェックリスト（Phase 6 / Phase 10 で実施）

### アラーム発火
- [x] アプリ前面時に発火する（Phase 4 で確認済み、Pixel 6a / Android 16）
- [x] アプリ背面時に発火する（Phase 6c 実機検証、Pixel 6a / Android 16、2026-04-30）
- [x] アプリ強制終了状態で発火する（Phase 6c 実機検証、Pixel 6a / Android 16、2026-04-30。バンドル音源 + AudioAttributesUsage.alarm でアラーム音量で鳴動）
- [ ] 端末スリープ中に発火する（数分後 / 数時間後）
- [x] サイレントモード時の挙動が想定通り（パターン 3 検証時に「サイレントモード ON/OFF 問わず鳴動」を確認、2026-04-30）
- [ ] DND モード時の挙動が想定通り

### フルスクリーン Intent（Phase 6c 実機検証、Pixel 6a / Android 16、2026-04-30）
- [x] 権限あり: ロック画面上にアラーム画面が出る（MainActivity.onCreate で `setShowWhenLocked(true)` / `setTurnScreenOn(true)` をランタイム呼び出し）
- [x] 権限なし: ヘッドアップ通知で代替動作（adapter で `canUseFullScreenIntent()` を毎 schedule 検査して `fullScreenIntent` フラグを動的に切り替える）
- [x] 設定画面誘導が機能する（`com.bonkotu.timer/permission` Channel の `openFullScreenIntentSettings`）

### Phase 6 実機検証で見つかって修正した問題（再発防止メモ）

実機検証中に出現した症状とコード修正の対応。今後類似 Phase で再発したら同じ
チェックポイントを当てる。

- ロック画面上にアラーム画面が出ない（背景時 / 通知層は出るが Activity が
  キーガード下） → AndroidManifest の `showOnLockScreen` / `turnScreenOn`
  だけでは Android 14+ で不十分。MainActivity.onCreate で
  `setShowWhenLocked(true)` / `setTurnScreenOn(true)` をランタイム呼び出し
- Stop 押下しても "Time's up!" が再表示される（背景時のみ） →
  `main()` の通知タップ callback と `TimerScreen` の ringing listener が
  両方発火し AlarmRingingScreen が二重スタックになっていた。両経路に
  「現在地が `/alarm-ringing` なら no-op」のガードを入れ、`_leaveAlarmScreen`
  は常に `context.go('/timer')` でスタック全置換する
- 強制終了後の通知タップで HomeScreen に着地する →
  `onDidReceiveNotificationResponse` はプロセス生存時しか呼ばれない。
  `getNotificationAppLaunchDetails()` をコールドスタート判定に使い、
  `GoRouter.initialLocation` を `/alarm-ringing` に切り替える
- 通知音が鳴らない（背景時 / 強制終了時） → Channel の sound 未指定 +
  audioAttributesUsage 未指定が原因。`assets/sounds/alarm_default.mp3` を
  `android/app/src/main/res/raw/` にもコピーし、Channel の
  `sound: RawResourceAndroidNotificationSound('alarm_default')` と
  `audioAttributesUsage: AudioAttributesUsage.alarm` を明示する。Channel
  の sound / audio 設定は OS 上で変更不可のため、変更時は channel id を
  バンプして再作成する
- アラーム音が二重再生される（OS Channel の bundled sound + audioplayers
  のループが同時に鳴る） → Phase 6 のコメントでは「OS 音はフォールバック /
  AlarmRingingScreen が前面化したら audioplayers がレイヤー」設計だったが
  実装は両方常時鳴動になっていた。`AlarmRingingNotifier.start` に
  `notificationId` 引数を追加し、内部で `NotificationScheduler.cancel` を
  呼んで OS 通知（音含む）を停止する責務を負わせる。`start` 自体は
  `isPlaying` 検査で idempotent にし、複数経路から呼ばれても二重再生
  しないようにする
- 二重再生対策で OS 通知を即 cancel すると背景時に FullScreenIntent /
  heads-up banner が発火しない → `TimerNotifier._onTick` で ringing 検知と
  同時に cancel を呼んでいたため、AlarmManager が通知を発火する前にスケ
  ジュールが消えていた。ringing 起動時の cancel + audioplayers.play 責務
  を `AlarmRingingScreen.initState` の post-frame callback に一本化し、
  TimerNotifier 側からは start 呼び出しを削除する。これで「画面が表示
  されてから音が切り替わる」順序が保証され、FSI も普通に発火する
- 背景 (FSI) / コールドスタート経路で AlarmRingingScreen に着地しても音が
  出ない → `TimerNotifier._onTick` を起動源にしている設計だと、背景中は
  tick が走らずコールドスタート時はそもそも entity が無いので start が
  呼ばれない。AlarmRingingScreen を `ConsumerStatefulWidget` 化して
  `initState` の post-frame で「`isPlaying` が false なら自分で start を
  呼ぶ」フォールバックを入れる。entity が無ければ `AlarmSoundCatalog.defaultSound`
  と `notificationId = -1` (no-op cancel) で起動
- ロック → 復帰のたびに recents (■) ナビゲーションボタンが消える →
  Phase 6 で MainActivity に常時 `setShowWhenLocked(true)` /
  `setTurnScreenOn(true)` を立てていたため、Android が Activity を
  「ロック画面 overlay」として扱い recents を抑制していた。Manifest 属性
  と onCreate の常時呼び出しを削除し、`KeyguardManager.isKeyguardLocked()`
  が true の時だけフラグを立てる動的切替にする。`launchMode="singleTop"`
  で warm launch では `onCreate` ではなく `onNewIntent` が呼ばれるため、
  両ライフサイクルからヘルパーを呼ぶ必要がある
- アラーム発火後に AlarmRingingScreen から離れた後も recents が消えたまま
  → `setShowWhenLocked(true)` は明示的に false に戻さないと残り続ける。
  `com.bonkotu.timer/permission` Channel に `clearShowWhenLocked` を追加
  し、`AlarmRingingScreen._leaveAlarmScreen` から呼んで Stop / Snooze 時に
  確実に解除する

### Phase 8.5 follow-up: アラーム再鳴動時の二重音修正（2026-05-02）

Phase 6 で「`AlarmRingingNotifier.start` が `cancel` を呼ぶことで二重再生を
防ぐ」設計にしたつもりだったが、Phase 8 でスヌーズ機能を実機検証したところ
heads-up 経路で二重音が再現した。以下に経緯と着地を残す。

**問題**: スヌーズ後の再鳴動時、heads-up 通知 → タップで AlarmRingingScreen に
遷移する経路で、OS チャンネル音 (alarm-stream の
`RawResourceAndroidNotificationSound`) と audioplayers のループ再生が重なって
聞こえる。Pixel 6a / Android 16 で再現。

**根本原因**: `_plugin.cancel(notificationId)` は通知バナーを消すが、
`AudioAttributesUsage.alarm` で再生中のチャンネル音は別ライフサイクルで継続
再生され、cancel 後も数秒持続する。AlarmRingingScreen の bootstrap が
audioplayers.play() を即時実行すると、その間に重なる。Phase 6 の検証時は OS 音と
audioplayers が同じ MP3 を鳴らしていたため二重音が「位相のずれた一つの音」に
聞こえて気づかれず、Phase 7 / 8 でもこのまま残っていた。

**試行と着地**:

- **Option A (await 化)**: `AlarmRingingNotifier.start` の `cancel` と `play` を
  順次 await にして順序を保証。実機ではまだ二重音が残った（cancel 完了後も OS
  通知音が止まらないため）。
- **Option B (`playSound: false`)**: チャンネルの sound を切って audioplayers
  に音を一本化。FSI 経由は OK だが、heads-up 経路 (画面 ON で他アプリ操作中、
  ホーム画面待機、スヌーズ後再鳴動) で Android が FSI を抑制するため**音なし**
  になる別問題が発生したので不採用。
- **Option C (採用)**: チャンネル音は `playSound: true` のままにして、
  `AlarmRingingNotifier.start` を `cancel → 500ms 遅延 → play` の 3 段順序にし、
  OS 通知音が完全に止まってから audioplayers が引き継ぐ動作にした。500ms は
  Pixel 6a での empirical sweet spot（短すぎると重なる、長すぎると体感切替遅延
  が目立つ）。

**変更箇所**:

- `lib/application/alarm_ringing_notifier.dart`: `start()` を
  `await cancel → await Future.delayed(500ms) → await play` に変更
- `lib/infrastructure/notification/flutter_local_notification_adapter.dart`:
  Channel id を `timer_alarm_v4` → `timer_alarm_v6` にバンプ (Option B 試行で
  v5 を経由したため)。`_legacyTimerAlarmChannelIds` に v4 / v5 を追加。
  `playSound: true` + `RawResourceAndroidNotificationSound('alarm_default')` +
  `audioAttributesUsage: alarm` の v4 構成は維持
- `test/presentation/screens/alarm_ringing_screen_test.dart`: 全 7 シナリオで
  `await tester.pump(const Duration(milliseconds: 600))` を bootstrap 後に
  挿入し、500ms 遅延の Future を完了させて pending Timer を解消

**実機検証** (Pixel 6a / Android 16、2026-05-02): 6 シナリオすべて単音、
二重音解消。

| # | シナリオ | 結果 |
| --- | --- | --- |
| 1 | 初回 foreground 鳴動 (自動遷移) | OK 単音、500ms 待機は気にならないレベル |
| 2 | 初回 background 鳴動 (heads-up タップで遷移) | OK 単音、500ms でバトンタッチ |
| 3 | 初回 FSI 経由 (ロック画面) | OK 単音、二重音解消 |
| 4 | 強制終了 → ロック画面 (コールドスタート + FSI) | OK 単音 |
| 5 | 強制終了 → ホーム画面待機 (heads-up タップで遷移) | OK 単音 |
| 6 | **スヌーズ後再鳴動 (heads-up タップで遷移)** | **OK 単音、二重音解消** |

**再発防止メモ**:

- Channel に `RawResourceAndroidNotificationSound` + `AudioAttributesUsage.alarm`
  をセットしている限り、`_plugin.cancel(notificationId)` だけでは再生中の音が
  即座には止まらない。Pixel / Android 16 では数秒持続する。同じ MP3 を
  audioplayers でも鳴らす場合、cancel と play の間に 500ms 程度の遅延を必ず
  挟むこと。
- スヌーズなど「短い時間内に同じ通知 ID で再 schedule する」経路では、Android
  が FSI を抑制し heads-up になりやすい。FSI 経路だけ検証して通知音問題を
  「OK」と判定するのは不十分。heads-up 経路でも音と画面遷移の整合を確認する。

### 起動時復元（Phase 10、2026-05-04 確定 / 2026-05-09 manifest fix）

戦略: 純 Flutter (Native BootReceiver は新設しない)。

- 端末再起動後の通知再予約は flutter_local_notifications の
  ScheduledNotificationBootReceiver (`AndroidManifest.xml` で登録済) に委譲。
  保留中通知は AlarmManager に再登録される。
- **Android 12+ (API 31+) の制約**: BOOT_COMPLETED 等のシステムブロードキャスト
  を受ける receiver は `android:exported="true"` 必須。`false` だと OS が
  receiver を呼び出さない (Pixel 6a / Android 16 で 2026-05-09 実機再現、
  シナリオ 2 で再起動後に定刻発火せず、アプリ起動時の past-due 検知で
  ようやく救済される現象として観測)。flutter_local_notifications の README
  に従って `false` を貼ると Android 12+ で BootReceiver が機能しない罠。
  参考: <https://github.com/MaikuB/flutter_local_notifications/issues/2612>。
- アプリ起動時の in-memory 状態復元:
  - Timer: `TimerCollectionNotifier._restoreFromRepository` (Phase 8)
    が `endAt < now` の running を completed 化 + show 通知。
  - Alarm: `AlarmCollectionNotifier._loadFromRepository` (Phase 9.5 +
    Phase 10) が enabled な alarm を再 schedule し、過去到達 once-mode
    は `enabled=false` に落として show 通知 1 回。weekly は nextFireAt
    が次回曜日に自動で進むので reschedule のみ。BootReceiver と past-due
    検知の二段構えで「再起動中に時間が過ぎた once-mode alarm」も
    取りこぼさない。

検証チェックリスト:

- [x] 端末再起動後にタイマーが復元される (Pixel 6a / Android 16、2026-05-09)
- [ ] 端末再起動後に enabled な alarm が再予約される (manifest exported=true 修正後に再検証必要)
- [ ] 再起動中に過ぎた once-mode alarm が enabled=false に落ちて show 通知 1 回 (実機未確認、unit test 3 件で網羅)
- [x] 再起動中に過ぎた weekly alarm が次回曜日に進む (Pixel 6a / Android 16、2026-05-09)
- [x] 再起動中に過ぎた timer が completed 扱い + show 通知 (Pixel 6a / Android 16、2026-05-09)

### メーカー検証（可能なら）
- [ ] Pixel（純正）
- [ ] Samsung
- [ ] Xiaomi（できれば）
- [ ] その他

---

## 関連ドキュメント

- `docs/permissions.md`: 権限取得フロー詳細
- `docs/platform-channels.md`: Native ↔ Flutter 連携
- `docs/adr/0003-fullscreen-intent-strategy.md`: FGS 不採用の経緯

---

## 参考リンク

- Android Background Execution Limits: https://developer.android.com/about/versions/oreo/background
- Foreground Services: https://developer.android.com/develop/background-work/services/foreground-services
- Schedule Exact Alarms: https://developer.android.com/develop/background-work/services/alarms/schedule
- Full-Screen Intent Guidelines: https://developer.android.com/develop/ui/views/notifications/time-sensitive

---

最終更新日: 2026-05-09（Phase 10 実機検証で `ScheduledNotificationBootReceiver` の `exported="false"` が原因で再起動後に再登録されない問題を発見、`exported="true"` に修正。Android 12+ のシステムブロードキャスト要件、past-due 検知との二段構え方針を追記）
