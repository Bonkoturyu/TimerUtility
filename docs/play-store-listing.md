# Play Store 掲載素材 (TimerUtility)

作成日: 2026-05-17
最終同期: 2026-08-03
状態: ja/en Main store listing と Content Rating / Target Audience / 権限申告は
Play Console へ送信済み。Release notes は v1.1.5 まで記録済み。Data Safety は
Android `Geocoder` のプロバイダー処理を踏まえて再確認する。

本ファイルは Play Console アップロード時に貼り込むテキスト + Data Safety 申告 +
Content Rating 回答を集約する。実物のスクリーンショットは Pixel 6a で撮影し、
`design/screenshots/` に ja/en 各7枚を配置済み。

---

## 0. Play Console 転記順

Play Console 実画面では項目名や順序が変わり得る。再提出時は公式 Help / 実画面を
再確認し、以下の順で現行資料を転記する。

1. Store settings / Main store listing:
   - App name: §1 `TimerUtility`
   - Short description: §2
   - Full description: §3
   - App category: §1 `Tools`
   - Contact details: §10
   - Privacy Policy URL: §9 / §10
2. Release:
   - What's new: §4
   - AAB: `build/app/outputs/bundle/release/app-release.aab`
3. Store graphics:
   - App icon / Feature graphic / phone screenshots: §9
4. App content:
   - Data Safety: §5
   - Content Rating: §6
   - Target Audience and Content: §7
   - Permissions explanations: §8

---

## 1. アプリ基本情報

| 項目 | 値 |
| --- | --- |
| アプリ名 | TimerUtility |
| パッケージ名 | `io.github.bonkoturyu.timer_utility` (Phase 11.9-T0 で移行確定) |
| 配信形態 | 無料、広告なし、アプリ内課金なし |
| カテゴリ | ツール (Tools) |
| 対象 OS | Android 8.0 (API 26) 以上、Android 16 (API 36) 主ターゲット |
| 対応言語 | 日本語、英語、中国語簡体字、中国語繁体字、韓国語 |
| 開発元 | BON (`@Bonkoturyu` / GitHub) |
| 配布元 | Google Play (Internal Testing 実施済み)、ソースコードは GitHub Public |

---

## 2. 短い説明 (Short Description、80 文字以内)

### 日本語

```text
複数タイマー、指定時刻アラーム、世界時計、ロック画面表示対応。Android 向けの実用タイマー。
```

### English

```text
Multi-timer, alarms, world clock, and lock-screen alerts for modern Android.
```

---

## 3. 長い説明 (Full Description、4000 文字以内)

### 日本語

段落・箇条書きの各項目は改行なしの1行で記載している (Play Console のテキスト
エリアに貼るとそのまま改行として扱われるため)。空行のみが意図した段落区切り。

```text
TimerUtility は、複数のタイマーを同時に動かせる Android 用タイマーアプリです。シンプルな見た目でありながら、現代の Android (Android 8 〜 16) で「アラームがちゃんと鳴る」「ロック画面でしっかり気付ける」「端末を再起動しても消えない」という基本的な期待にきっちり応える実装を目指しています。

【主な機能】
■ ストップウォッチ — ラップ記録、ミリ秒精度
■ 複数タイマー — 最大 10 本まで同時稼働。それぞれにラベル、音源、スヌーズ設定
■ 指定時刻アラーム — 曜日繰り返し、once モード、3 / 5 / 10 分スヌーズ
■ 端末内音声停止 — 設定で有効化すると、鳴動中に「停止」と話して止められます。音声は保存・送信しません。
■ 世界時計 — 最大 6 都市、アナログ・デジタル・コンパクトの 3 デザインを切替表示
■ プリセット — 一般 / 料理 / Pomodoro の 3 テンプレートを内蔵
■ カスタムアラーム音 — 3 種類の内蔵音源を試聴でき、端末内の音源も取り込めます。タイマー、アラーム、プリセットごとに音源を指定できます。
■ アプリ音量 — アラーム音を 10〜100% で調整できます。

【こだわっている点】
■ ロック画面でしっかり鳴る — Android 14+ の USE_FULL_SCREEN_INTENT 制約と SCHEDULE_EXACT_ALARM 制約に正面から対応し、Doze モードを回避します。
■ 再起動後も復元 — 端末を再起動してもタイマーとアラームの予約は自動的に復元されます。
■ ダークモード対応 — システム設定に追従、または手動切替が可能。
■ 色覚多様性 (CVD) への配慮 — 重要度ラベル ([重要] / [推奨] / [補助]) とフォントウェイト差、色帯の幅で形状的にも差別化。
■ 5 言語対応 — 日本語、英語、中国語 (簡体字 / 繁体字)、韓国語。
■ ベータテスター向けの診断ログ機能 — 必要なときだけオンにできるトグル付き、位置情報やユーザーが入力したラベル文字列は記録対象から除外。

【プライバシー】
TimerUtility は開発者のバックエンドへ個人情報を送信せず、広告 SDK、解析 SDK、クラッシュレポート SDK も同梱していません。位置情報は、世界時計の登録が空の初回初期化時に Android のシステムサービスで一時処理され、アプリには保存されません。
詳細: https://bonkoturyu.github.io/TimerUtility/privacy-policy

【オープンソース】
本アプリは MIT ライセンスのオープンソースとして GitHub で公開されています。Flutter + Clean Architecture + Android 16 アラーム制約への対応事例として、ソースコード自体が学習・参考資料の役目も果たします。
リポジトリ: https://github.com/Bonkoturyu/TimerUtility
```

### English

```text
TimerUtility is an Android timer app that lets you run multiple timers simultaneously. While the interface stays minimal, the implementation aims to meet the basic expectations of modern Android (8 through 16): "the alarm actually rings," "you notice it on the lock screen," and "it survives a reboot."

[Features]
- Stopwatch with lap timing and millisecond precision.
- Multi-timer (up to 10 concurrent). Each timer has its own label, sound, and snooze configuration.
- Scheduled alarms with weekday repeat, once mode, and 3/5/10-minute snooze.
- Optional on-device voice stop for ringing alarms and timers. Audio is never stored or transmitted.
- World clock with up to 6 cities and three display designs (analog, digital, compact) switchable via swipe.
- Built-in presets for general use, cooking, and the Pomodoro technique.
- Preview three bundled alarm sounds, import audio from the device, and choose a sound per timer, alarm, or preset.
- Adjustable in-app alarm volume from 10% to 100%.

[What we cared about]
- Reliable lock-screen ringing. Properly handles the Android 14+ USE_FULL_SCREEN_INTENT and SCHEDULE_EXACT_ALARM constraints, working around Doze.
- Survives reboot. Timers and alarms are automatically restored after the device restarts.
- Dark mode support, following system settings or set manually.
- Color-vision-deficiency (CVD) awareness with severity labels ([Critical] / [Recommended] / [Supplementary]), font-weight steps, and color-band width differences so that shape, not color alone, conveys meaning.
- Five languages: Japanese, English, Chinese (Simplified / Traditional), Korean.
- Beta tester-friendly diagnostic logging — an opt-in toggle, with location data and user-entered label strings excluded from logs.

[Privacy]
TimerUtility sends no personal information to a developer-operated backend and bundles no advertising, analytics, or crash-reporting SDK. When an empty world-clock list is initialized for the first time, location is processed transiently by an Android system service and is not persisted by the App.
Details: https://bonkoturyu.github.io/TimerUtility/privacy-policy.en

[Open source]
The App is open source under the MIT license, published on GitHub. The source is also intended as a reference implementation of Flutter + Clean Architecture + Android 16 alarm constraints handling.
Repository: https://github.com/Bonkoturyu/TimerUtility
```

---

## 4. What's new (Release notes、500 文字以内)

### Version 1.1.5

#### 日本語

```text
- アプリのアラーム音量を10〜100%で調整できるようにしました。
- 3種類の内蔵アラーム音を、選択する前に試聴できるようにしました。
- バックグラウンドやロック画面でも、選択した音源と音量で予約時刻から鳴動するよう改善しました。
```

#### English

```text
- Added app alarm volume control from 10% to 100%.
- Added previews for the three built-in alarm sounds before selection.
- Improved background and lock-screen alarms to start at the scheduled time with the selected sound and volume.
```

### Version 1.1.4

#### 日本語

```text
- Pixel端末で、端末内の日本語音声モデルの判定と取得処理を改善しました。
- 音声停止の安定性と停止表現の認識を改善しました。音声は保存・送信されません。
```

#### English

```text
- Improved detection and download handling for on-device Japanese speech models on Pixel devices.
- Improved voice-stop reliability and stop-phrase recognition. Audio is not saved or sent.
```

### Version 1.0.1

#### 日本語

```text
- 中国語（簡体字・繁体字）と韓国語をアプリ内の表示言語として追加しました。
- 繁体字を使用する地域で、端末の言語設定へ正しく追従するよう改善しました。
- 設定画面の「情報」にアプリのバージョンを表示するようにしました。
```

#### English

```text
- Added Simplified Chinese, Traditional Chinese, and Korean as in-app display languages.
- Improved system-language matching for regions that use Traditional Chinese.
- Added the app version to the About section in Settings.
```

### 初版リリース時 (1.0.0)

#### 日本語

```text
初版リリースです。
- 複数タイマー (最大 10 本)、指定時刻アラーム、世界時計を搭載
- Android 16 のアラーム / 通知制約 (FullScreenIntent、SCHEDULE_EXACT_ALARM、
  USE_FULL_SCREEN_INTENT) に対応
- 日本語、英語、中国語 (簡体字 / 繁体字)、韓国語
- ダークモード、色覚多様性 (CVD) 対応モード
- 端末再起動後の自動復元
- 個人情報の収集・送信はゼロ
ご利用いただきありがとうございます。
```

#### English

```text
Initial release.
- Multi-timer (up to 10), scheduled alarms, and world clock.
- Full coverage of Android 16's alarm and notification constraints
  (FullScreenIntent, SCHEDULE_EXACT_ALARM, USE_FULL_SCREEN_INTENT).
- Japanese, English, Chinese (Simplified / Traditional), Korean.
- Dark mode and color-vision-deficiency (CVD) awareness mode.
- Automatic restore after device reboot.
- Zero personal data collection or transmission.
Thank you for trying TimerUtility.
```

---

## 5. Data Safety 申告

> 2026-08-03 文書監査で位置情報の説明を訂正。Android `Geocoder` は端末・OS・
> サービスプロバイダーによってネットワークを利用し得るため、下表は Play Console
> 実画面と実機経路を再確認してから再提出する。公式仕様:
> <https://developer.android.com/reference/android/location/Geocoder>

| Data Safety 項目 | 申告内容 | 根拠 |
| --- | --- | --- |
| Does your app collect or share any of the required user data types? | **要再確認** | 開発者バックエンドはないが、`Geocoder` のプロバイダー処理を含めて Play の定義へ照合する |
| Is all of the user data collected by your app encrypted in transit? | **要再確認** | Approximate location の申告結論に合わせる |
| Do you provide a way for users to request their data to be deleted? | 開発者保有データなし。端末内データはストレージ消去 / アンインストールで削除 | [docs/privacy-policy.md](privacy-policy.md) §10 |
| Approximate location | **要再確認** (世界時計の登録が空の初回初期化時に Android `Geocoder` が一時処理。アプリは座標を永続化せず、開発者も受領しない) | [docs/privacy-policy.md](privacy-policy.md) §4 |
| Crash logs / diagnostics | **Not collected** (診断ログはユーザー明示オン時のみ端末内に保存、Share Sheet 経由のユーザー操作でのみ外部に渡る、自動送信なし) | [docs/privacy-policy.md](privacy-policy.md) §6 |
| Voice or sound recordings | **Not collected** (マイク入力は端末内認識へ一時的に渡すだけで、録音・保存・送信・ログ記録を行わない) | [docs/privacy-policy.md](privacy-policy.md) §3 |

→ 過去の「No data collected / No data shared」申告は、Approximate location の扱いを
再評価してから維持または修正する。

---

## 6. Content Rating 自己評価

> Play Console の IARC 質問票へ送信済みの回答要約。全地域で最年少レーティングが
> 確定済み。再提出時は実画面の質問項目を再確認する。

| 質問カテゴリ | 回答 | 補足 |
| --- | --- | --- |
| Violence / Gore | None | タイマー / アラーム / 時計表示のみ |
| Sexual content | None | 同上 |
| Profanity | None | 全テキストは機能説明のみ |
| Controlled substances (alcohol, tobacco, drugs) | None | 言及なし |
| Gambling / Simulated gambling | None | 該当なし |
| User-generated content / Social features | None | チャット / SNS / シェア機能なし (診断ログの Share Sheet は OS 機能の呼び出しのみで本アプリ内に投稿先がない) |
| Location sharing | None | 他ユーザーや開発者への共有機能なし。現在地推定時は Android `Geocoder` が一時処理 |
| Personal information sharing | None | 個人情報を扱わない |
| In-app purchases | None | 課金なし |
| Loot boxes / Gacha | None | 該当なし |

→ 想定レーティング: **Everyone** (全年齢、IARC: ESRB E / PEGI 3 相当)。

---

## 7. Target Audience and Content

| 項目 | 回答 |
| --- | --- |
| Primary target audience | 18+ adults (一般生産性ツール) |
| Secondary target audience | 13-17 (利用に支障なし、保護者同意は要件外) |
| Designed primarily for children | **No** |
| Family policy compliance | 該当なし (子ども向け申告しない) |

---

## 8. 権限の説明 (Play Console / プライバシーポリシー連動)

Play Console の "Permissions" セクションに貼る短い説明文。同内容は
[docs/privacy-policy.md](privacy-policy.md) §5 にも掲載。

| Manifest 上の権限 | Play Console 用説明文 (短縮版) |
| --- | --- |
| `ACCESS_COARSE_LOCATION` | 世界時計の登録が空の初回初期化時に現在地のタイムゾーンを推定。Android `Geocoder` が一時処理し、アプリは座標を永続化しません。 |
| `RECORD_AUDIO` | ユーザーが有効化した端末内音声認識で、鳴動を停止します。録音・保存はしません。 |
| `POST_NOTIFICATIONS` | タイマー / アラームの通知を表示します。 |
| `SCHEDULE_EXACT_ALARM` | 指定時刻にアラームを正確に発火させるため、Doze モードを回避します。 |
| `USE_EXACT_ALARM` | Android 14+ で時計 / アラームカテゴリのアプリに認められる代替権限。 |
| `USE_FULL_SCREEN_INTENT` | ロック画面でアラーム画面を表示します。 |
| `WAKE_LOCK` | アラーム鳴動時に CPU をスリープから起こします。 |
| `VIBRATE` | 通知 / アラームのバイブレーションを発生させます。 |
| `RECEIVE_BOOT_COMPLETED` | 端末再起動後にタイマー / アラームを自動的に復元します。 |
| `FOREGROUND_SERVICE` | バックグラウンドでアラーム音を継続再生します。 |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | アラーム再生 Service を media playback 種別として実行します。 |

---

## 9. ストア掲載素材リスト

| 素材 | 必須 | サイズ / 形式 | 配置場所 |
| --- | --- | --- | --- |
| アプリアイコン (高解像度) | 必須 | 512 × 512 PNG、32-bit、1 MB 以内 | `design/icon/play-store-icon-512.png` |
| Feature graphic | 推奨 | 1024 × 500 PNG / JPEG | ja: `design/store/feature-graphic-1024x500.png` / en: `design/store/feature-graphic-1024x500-en.png` |
| スクリーンショット (スマホ) | 2 枚以上 | 横幅 1080 px 以上、最大 8 枚 | `design/screenshots/phone/{ja,en}/*.png` |
| スクリーンショット (7" タブレット) | 推奨 | 横幅 1080 px 以上 | 当面不提出 (Pixel 6a 実機のみのため) |
| スクリーンショット (10" タブレット) | 推奨 | 横幅 1080 px 以上 | 当面不提出 |
| プロモーション動画 | 任意 | YouTube URL | 当面不提出 |
| プライバシーポリシー URL | 必須 | HTTPS | ja: `/privacy-policy` / en: `/privacy-policy.en` / zh-Hans: `/privacy-policy.zh-Hans` / zh-Hant: `/privacy-policy.zh-Hant` / ko: `/privacy-policy.ko` (host: `https://bonkoturyu.github.io/TimerUtility`) |

### 9.1 スクリーンショット撮影シナリオ (Phase 11.9-T11、Pixel 6a 実機)

1. Home (Timer タブ、複数タイマー実行中)
2. Stopwatch (ラップ記録あり)
3. Alarm List (曜日繰り返しと once 混在)
4. World Clock (アナログデザイン、6 都市登録)
5. Alarm Ringing 画面 (ロック画面上のフルスクリーン Intent 表示、撮影は通常画面で代用)
6. Settings (テーマ / 言語 / 診断ログトグル可視)
7. Preset Manage Screen (プリセット管理)

各撮影は ja / en の 2 言語で行い、Play Console の locale 別 listing にそれぞれ
アップロード済み。2026-06-17 時点で ja / en とも 7 枚を撮影済み。
zh / zh_Hant / ko の listing は Phase 11.10 以降の追加対応とする (初版リリース時は
ja / en のみで提出)。

### 9.2 撮影済みファイル (2026-06-17、Pixel 6a / profile APK、ja)

すべて 1080×2400 PNG。DEBUG バナーを避けるため profile APK で撮影。

| シナリオ | ファイル |
| --- | --- |
| Home (Timer タブ、複数タイマー実行中) | `design/screenshots/phone/ja/01_timer_multi_running.png` |
| Stopwatch (ラップ記録あり) | `design/screenshots/phone/ja/02_stopwatch_laps.png` |
| Alarm List (曜日繰り返しと once 混在) | `design/screenshots/phone/ja/03_alarm_list_repeat_once.png` |
| World Clock (アナログデザイン、6 都市登録) | `design/screenshots/phone/ja/04_world_clock_analog_6_cities.png` |
| Alarm Ringing 画面 | `design/screenshots/phone/ja/05_alarm_ringing_screen.png` |
| Settings (テーマ / 言語 / 診断ログトグル可視) | `design/screenshots/phone/ja/06_settings_theme_language_diagnostics.png` |
| Preset Manage Screen (プリセット管理) | `design/screenshots/phone/ja/07_preset_manage.png` |

### 9.3 撮影済みファイル (2026-06-17、Pixel 6a / profile APK、en)

すべて 1080×2400 PNG。撮影時のみ `localeTag=en` を設定し、撮影後はシステム追従へ戻した。

| シナリオ | ファイル |
| --- | --- |
| Home (Timer タブ、複数タイマー実行中) | `design/screenshots/phone/en/01_timer_multi_running.png` |
| Stopwatch (ラップ記録あり) | `design/screenshots/phone/en/02_stopwatch_laps.png` |
| Alarm List (曜日繰り返しと once 混在) | `design/screenshots/phone/en/03_alarm_list_repeat_once.png` |
| World Clock (アナログデザイン、6 都市登録) | `design/screenshots/phone/en/04_world_clock_analog_6_cities.png` |
| Alarm Ringing 画面 | `design/screenshots/phone/en/05_alarm_ringing_screen.png` |
| Settings (テーマ / 言語 / 診断ログトグル可視) | `design/screenshots/phone/en/06_settings_theme_language_diagnostics.png` |
| Preset Manage Screen (プリセット管理) | `design/screenshots/phone/en/07_preset_manage.png` |

### 9.4 英語版 Store listing 用素材

| 素材 | ファイル / 状態 |
| --- | --- |
| Short Description | §2 English を Play Console へ保存済み |
| Full Description | §3 English を Play Console へ保存済み |
| What's new | §4 English に v1.1.5 まで記録 |
| Privacy Policy | `https://bonkoturyu.github.io/TimerUtility/privacy-policy.en` |
| Feature Graphic | `design/store/feature-graphic-1024x500-en.png` |
| Phone screenshots | `design/screenshots/phone/en/` に ja と同 7 シナリオを配置済み |

---

## 10. 連絡先 / サポート

| 項目 | 値 |
| --- | --- |
| Developer name | BON |
| Developer GitHub | https://github.com/Bonkoturyu |
| Support URL | https://github.com/Bonkoturyu/TimerUtility/issues |
| Privacy Policy URL | https://bonkoturyu.github.io/TimerUtility/privacy-policy |
| Marketing site URL | (なし、リポジトリ URL で代用) |
| Email contact | GitHub プロフィールの contact 経由 (Play Console で必須項目化されている場合のみ Privacy 申請と同じメールアドレスを使用) |

---

## 11. 外部仕様の確認状況 (2026-07-24 に Phase 11.10-T2 相当を前倒し完了)

[CLAUDE.md](../CLAUDE.md) のソース信用原則に従い、Google Play Developer 登録完了
(2026-07-24) を機に以下 8 項目を WebFetch / WebSearch で裏取り済み。詳細は §11.2。
大きな仕様変更・ブロッカーは検出されず、既存の草稿方針のまま提出可と判断。

> **2026-08-03 追記:** 上記は 2026-07-24 時点の判断。Android `Geocoder` が
> プロバイダーによってネットワークを利用し得る点を今回の監査で確認したため、
> Data Safety の Approximate location だけは §5 のとおり再確認対象へ変更した。

1. ✅ Data Safety フォームの最新項目構成 (2026 年現行)
2. ✅ Play App Signing の 2026 年加入フロー (新規アプリで強制 / 任意)
3. ✅ Internal Testing の人数上限・期間
4. ✅ 新規 Personal developer account 向け Closed Testing 要件の Play Console 実画面確認
5. ✅ Adaptive Icon monochrome layer の必須化時期
6. ✅ 現行 Play 要求 target SDK と Flutter / Gradle の実 targetSdkVersion 解決値の突き合わせ
7. ✅ SCHEDULE_EXACT_ALARM + USE_FULL_SCREEN_INTENT の事前申請審査要否
8. ⚠️ Pixabay Content License 2024 改定とアプリ同梱再配布の現行解釈 (公式ページ本文取得がブロックされ、スニペット経由の確認にとどまる。公開前に目視再確認推奨)

→ これらは [docs/oss-and-play-release-plan.md](oss-and-play-release-plan.md)
「保留論点」セクションと一致 (同日付で同期済み)。

### 11.1 2026-06-17 公式確認済みメモ

- Store listing: App name 30 文字、Short description 80 文字、Full description
  4000 文字。全角 / 半角とも同一カウント。
  参照: <https://support.google.com/googleplay/android-developer/answer/9859152>
- Target SDK: 2025-08-31 以降、新規アプリ / アプリ更新は Android 15
  (API level 35) 以上が必要。TimerUtility は API 36 主ターゲット方針だが、
  提出前に `targetSdk = flutter.targetSdkVersion` の実解決値を確認する。
  参照: <https://support.google.com/googleplay/android-developer/answer/11926878>
- Closed testing: 2023-11-13 後に作成された Personal developer account は、
  Production access 申請前に closed test で最低 12 testers が 14 日連続
  opt-in している必要がある。テスター募集・記録テンプレは
  [closed-test-plan.md](closed-test-plan.md) を使用する。
  参照: <https://support.google.com/googleplay/android-developer/answer/14151465>

### 11.2 2026-07-24 追加確認済みメモ (Phase 11.10-T2 相当)

Google Play Developer 登録完了を機に、残り論点を WebFetch / WebSearch で裏取り。

- Data Safety (2026-07-24 時点の判断): データを一切収集しないアプリも申告フォーム
  入力は必須。「No」回答 + Privacy Policy URL 提示で「No data collected /
  No data shared」と表示される。当時は §5 の方針のまま提出可と判断したが、
  2026-08-03 の `Geocoder` 再評価により Approximate location は再確認対象。
  参照: <https://support.google.com/googleplay/android-developer/answer/10787469>
- Play App Signing: 新規アプリは aab 初回アップロード時に「quantum-ready hybrid
  signing (Google 生成鍵)」へ自動 enroll される。能動的な「加入」操作は不要
  (独自鍵に変更したい場合のみ Change signing key を使う)。
  参照: <https://support.google.com/googleplay/android-developer/answer/9842756>
- Internal Testing: 上限 100 人、期間制限の記載なし。
  参照: <https://support.google.com/googleplay/android-developer/answer/9845334>
- Closed Testing (新規 Personal account): 12 testers が 14 日間連続 opt-in と
  いう現行値を再確認 (2023-11 開始の 20 人から 2024-12 に 12 人へ緩和済の版)。
  途中で opt-out すると連続日数がリセットされる点に注意。
  参照: <https://support.google.com/googleplay/android-developer/answer/14151465>
- Adaptive Icon monochrome layer: 公式ページでは「必須ではない、推奨」。
  Android 16 QPR2 以降は未提供でも自動生成される。一部ブログは
  「2025-10-15 必須化」と主張しているが公式ページに同記載はなく、CLAUDE.md
  ソース信用原則によりブログ側は却下 (仮説扱い)。本アプリは Phase 11.9-T1/T3 で
  monochrome layer 実装済みのため実務影響なし。
  参照: <https://developer.android.com/develop/ui/views/launch/icon_design_adaptive>
- targetSdk 実値: `flutter.targetSdkVersion` の実解決値をコード直接確認
  (手元 Flutter SDK の `packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`
  に `targetSdkVersion: Int = 36` とハードコード)。Play 要求 (2025-08-31 以降
  API35 以上) を満たす。
- USE_FULL_SCREEN_INTENT: 事前審査ではなく Play Console App content 画面での
  自己申告。Alarm/Calling core functionality 申告により 2025-01-22 以降も
  デフォルト許可対象。
  参照: <https://support.google.com/googleplay/android-developer/answer/13392821>
- SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM: 事前審査ではなく Play Console
  Permissions Declaration Form への自己申告。restricted permission review 対象は
  `USE_EXACT_ALARM` のみで、「alarm/timer アプリ」は acceptable use case に
  明記されており本アプリは該当。
  参照: <https://support.google.com/googleplay/android-developer/answer/9888170>
- ⚠️ Pixabay Content License: 「Standalone (単体) での再配布・販売」は禁止だが、
  アプリ内蔵アセットとしてのバンドルは許可範囲内という解釈。ただし公式ページ
  (`pixabay.com/service/license-summary` / `/terms`) は WebFetch が 403 Forbidden
  で本文を直接取得できず、WebSearch スニペット経由の確認にとどまる (通常の公式
  ページ本文確認より信頼度が一段階低い)。公開前にブラウザで目視再確認を推奨。
  参照 (スニペット経由): <https://pixabay.com/service/license-summary/>
