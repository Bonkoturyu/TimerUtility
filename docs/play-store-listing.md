# Play Store 掲載素材 (TimerUtility)

作成日: 2026-05-17 (Phase 11.9 準備、Play Store 提出は Phase 11.10)
状態: 草稿。2026-06-17 に Play Console 公式 Help を再確認し、
short description / target SDK / closed testing 要件の現行仕様を反映済み。
Play Console 実画面で Data Safety / Content Rating / 権限申告を最終確認して確定する。

本ファイルは Play Console アップロード時に貼り込むテキスト + Data Safety 申告 +
Content Rating 自己評価の暫定回答を集約する。実物のスクリーンショットは
`design/screenshots/` に Phase 11.9-T11 で Pixel 6a 実機撮影後配置。

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
| 配布元 | Google Play (予定)、ソースコードは GitHub Public |

---

## 2. 短い説明 (Short Description、80 文字以内)

### 日本語

```text
複数タイマー、指定時刻アラーム、世界時計、ロック画面表示対応。Android 16 向けの実用タイマー。
```

### English

```text
Multi-timer, alarms, world clock, and lock-screen alerts for modern Android.
```

---

## 3. 長い説明 (Full Description、4000 文字以内)

### 日本語

```text
TimerUtility は、複数のタイマーを同時に動かせる Android 用タイマーアプリです。
シンプルな見た目でありながら、現代の Android (Android 8 〜 16) で「アラームが
ちゃんと鳴る」「ロック画面でしっかり気付ける」「端末を再起動しても消えない」
という基本的な期待にきっちり応える実装を目指しています。

【主な機能】
■ ストップウォッチ — ラップ記録、ミリ秒精度
■ 複数タイマー — 最大 10 本まで同時稼働。それぞれにラベル、音源、スヌーズ設定
■ 指定時刻アラーム — 曜日繰り返し、once モード、3 / 5 / 10 分スヌーズ
■ 世界時計 — 最大 6 都市、アナログ・デジタル・コンパクトの 3 デザインを切替表示
■ プリセット — 一般 / 料理 / Pomodoro の 3 テンプレートを内蔵
■ カスタムアラーム音 — 3 種類の内蔵音源 + 個別タイマー単位での音源指定

【こだわっている点】
■ ロック画面でしっかり鳴る — Android 14+ の USE_FULL_SCREEN_INTENT 制約と
  SCHEDULE_EXACT_ALARM 制約に正面から対応し、Doze モードを回避します。
■ 再起動後も復元 — 端末を再起動してもタイマーとアラームの予約は自動的に
  復元されます。
■ ダークモード対応 — システム設定に追従、または手動切替が可能。
■ 色覚多様性 (CVD) への配慮 — 重要度ラベル ([重要] / [推奨] / [補助]) と
  フォントウェイト差、色帯の幅で形状的にも差別化。
■ 5 言語対応 — 日本語、英語、中国語 (簡体字 / 繁体字)、韓国語。
■ ベータテスター向けの診断ログ機能 — 必要なときだけオンにできるトグル付き、
  位置情報やユーザーが入力したラベル文字列は記録対象から除外。

【プライバシー】
TimerUtility は個人情報を一切収集・送信しません。すべてのデータは端末内に
のみ保存されます。広告 SDK、解析 SDK、クラッシュレポート SDK は同梱して
いません。位置情報は世界時計の現在地タイムゾーン推定にのみ一時利用され、
緯度経度の値は端末を離れません。
詳細: https://bonkoturyu.github.io/TimerUtility/privacy-policy

【オープンソース】
本アプリは MIT ライセンスのオープンソースとして GitHub で公開されています。
Flutter + Clean Architecture + Android 16 アラーム制約への対応事例として、
ソースコード自体が学習・参考資料の役目も果たします。
リポジトリ: https://github.com/Bonkoturyu/TimerUtility
```

### English

```text
TimerUtility is an Android timer app that lets you run multiple timers
simultaneously. While the interface stays minimal, the implementation aims
to meet the basic expectations of modern Android (8 through 16): "the alarm
actually rings," "you notice it on the lock screen," and "it survives a
reboot."

[Features]
- Stopwatch with lap timing and millisecond precision.
- Multi-timer (up to 10 concurrent). Each timer has its own label, sound,
  and snooze configuration.
- Scheduled alarms with weekday repeat, once mode, and 3/5/10-minute snooze.
- World clock with up to 6 cities and three display designs (analog,
  digital, compact) switchable via swipe.
- Built-in presets for general use, cooking, and the Pomodoro technique.
- Three bundled alarm sounds, with per-timer sound selection.

[What we cared about]
- Reliable lock-screen ringing. Properly handles the Android 14+
  USE_FULL_SCREEN_INTENT and SCHEDULE_EXACT_ALARM constraints, working
  around Doze.
- Survives reboot. Timers and alarms are automatically restored after the
  device restarts.
- Dark mode support, following system settings or set manually.
- Color-vision-deficiency (CVD) awareness with severity labels
  ([Critical] / [Recommended] / [Supplementary]), font-weight steps, and
  color-band width differences so that shape, not color alone, conveys
  meaning.
- Five languages: Japanese, English, Chinese (Simplified / Traditional),
  Korean.
- Beta tester-friendly diagnostic logging — an opt-in toggle, with location
  data and user-entered label strings excluded from logs.

[Privacy]
TimerUtility collects and transmits no personal information. All data is
stored only on the device. The App does not bundle any ad, analytics, or
crash-reporting SDK. Location data is used ephemerally for world-clock
timezone inference and never leaves the device.
Details: https://bonkoturyu.github.io/TimerUtility/privacy-policy.en

[Open source]
The App is open source under the MIT license, published on GitHub. The
source is also intended as a reference implementation of Flutter + Clean
Architecture + Android 16 alarm constraints handling.
Repository: https://github.com/Bonkoturyu/TimerUtility
```

---

## 4. What's new (Release notes、500 文字以内)

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

> Phase 11.10-T2 で Play Console の最新フォーム構成を WebFetch 確認し、項目順 /
> 文言を再調整する前提。本セクションは現時点 (知識ベース) の Data Safety フォーム
> 構成に基づく草稿。

| Data Safety 項目 | 申告内容 | 根拠 |
| --- | --- | --- |
| Does your app collect or share any of the required user data types? | **No** | [docs/privacy-policy.md](privacy-policy.md) §2、ネットワーク通信機能なし |
| Is all of the user data collected by your app encrypted in transit? | **N/A** (収集なし) | 同上 |
| Do you provide a way for users to request their data to be deleted? | **N/A** (収集なし) | 同上 |
| Approximate location | **Not collected** (端末内のみで一時利用、緯度経度は端末外に送信しない、永続化しない) | [docs/privacy-policy.md](privacy-policy.md) §4 |
| Crash logs / diagnostics | **Not collected** (診断ログはユーザー明示オン時のみ端末内に保存、Share Sheet 経由のユーザー操作でのみ外部に渡る、自動送信なし) | [docs/privacy-policy.md](privacy-policy.md) §6 |

→ Data Safety フォームの結論: 「No data collected」「No data shared」両方申告。

---

## 6. Content Rating 自己評価

> Play Console の IARC 質問票への暫定回答。Phase 11.10 で実際の質問項目を見て
> 再評価。

| 質問カテゴリ | 回答 | 補足 |
| --- | --- | --- |
| Violence / Gore | None | タイマー / アラーム / 時計表示のみ |
| Sexual content | None | 同上 |
| Profanity | None | 全テキストは機能説明のみ |
| Controlled substances (alcohol, tobacco, drugs) | None | 言及なし |
| Gambling / Simulated gambling | None | 該当なし |
| User-generated content / Social features | None | チャット / SNS / シェア機能なし (診断ログの Share Sheet は OS 機能の呼び出しのみで本アプリ内に投稿先がない) |
| Location sharing | None | 位置情報を端末外に送信しない |
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
| `ACCESS_COARSE_LOCATION` | 世界時計の現在地タイムゾーン推定にのみ使用。緯度経度の値は端末を離れず、永続化もしません。 |
| `POST_NOTIFICATIONS` | タイマー / アラームの通知を表示します。 |
| `SCHEDULE_EXACT_ALARM` | 指定時刻にアラームを正確に発火させるため、Doze モードを回避します。 |
| `USE_EXACT_ALARM` | Android 14+ で時計 / アラームカテゴリのアプリに認められる代替権限。 |
| `USE_FULL_SCREEN_INTENT` | ロック画面でアラーム画面を表示します。 |
| `WAKE_LOCK` | アラーム鳴動時に CPU をスリープから起こします。 |
| `VIBRATE` | 通知 / アラームのバイブレーションを発生させます。 |
| `RECEIVE_BOOT_COMPLETED` | 端末再起動後にタイマー / アラームを自動的に復元します。 |

---

## 9. ストア掲載素材リスト

| 素材 | 必須 | サイズ / 形式 | 配置場所 (予定) |
| --- | --- | --- | --- |
| アプリアイコン (高解像度) | 必須 | 512 × 512 PNG、32-bit、1 MB 以内 | `design/icon/play-store-icon-512.png` |
| Feature graphic | 推奨 | 1024 × 500 PNG / JPEG | `design/store/feature-graphic-1024x500.png` |
| スクリーンショット (スマホ) | 2 枚以上 | 横幅 1080 px 以上、最大 8 枚 | `design/screenshots/phone/ja/*.png` |
| スクリーンショット (7" タブレット) | 推奨 | 横幅 1080 px 以上 | 当面不提出 (Pixel 6a 実機のみのため) |
| スクリーンショット (10" タブレット) | 推奨 | 横幅 1080 px 以上 | 当面不提出 |
| プロモーション動画 | 任意 | YouTube URL | 当面不提出 |
| プライバシーポリシー URL | 必須 | HTTPS | `https://bonkoturyu.github.io/TimerUtility/privacy-policy` (Phase 11.9-T9 で GitHub Pages 有効化後に確定) |

### 9.1 スクリーンショット撮影シナリオ (Phase 11.9-T11、Pixel 6a 実機)

1. Home (Timer タブ、複数タイマー実行中)
2. Stopwatch (ラップ記録あり)
3. Alarm List (曜日繰り返しと once 混在)
4. World Clock (アナログデザイン、6 都市登録)
5. Alarm Ringing 画面 (ロック画面上のフルスクリーン Intent 表示、撮影は通常画面で代用)
6. Settings (テーマ / 言語 / 診断ログトグル可視)
7. Preset Manage Screen (プリセット管理)

各撮影は ja / en の 2 言語で行い、Play Console の locale 別 listing にそれぞれ
アップロード予定。zh / zh_Hant / ko の listing は Phase 11.10 以降の追加対応とする
(初版リリース時は ja / en のみで提出)。

### 9.2 撮影済みファイル (2026-06-17、Pixel 6a / profile APK)

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

---

## 10. 連絡先 / サポート

| 項目 | 値 |
| --- | --- |
| Developer name | BON |
| Developer GitHub | https://github.com/Bonkoturyu |
| Support URL | https://github.com/Bonkoturyu/TimerUtility/issues |
| Privacy Policy URL | (Phase 11.9-T9 で確定) |
| Marketing site URL | (なし、リポジトリ URL で代用) |
| Email contact | GitHub プロフィールの contact 経由 (Play Console で必須項目化されている場合のみ Privacy 申請と同じメールアドレスを使用) |

---

## 11. 未確定項目 (Phase 11.10-T2 で本格裏取り)

[CLAUDE.md](../CLAUDE.md) のソース信用原則に従い、以下は Phase 11.10-T2 で WebFetch
してから確定:

1. Data Safety フォームの最新項目構成 (2026 年現行)
2. Play App Signing の 2026 年加入フロー (新規アプリで強制 / 任意)
3. Internal Testing の人数上限・期間
4. 新規 Personal developer account 向け Closed Testing 要件の Play Console 実画面確認
5. Adaptive Icon monochrome layer の必須化時期
6. 現行 Play 要求 target SDK と Flutter / Gradle の実 targetSdkVersion 解決値の突き合わせ
7. SCHEDULE_EXACT_ALARM + USE_FULL_SCREEN_INTENT の事前申請審査要否
8. Pixabay Content License 2024 改定とアプリ同梱再配布の現行解釈

→ これらは [docs/oss-and-play-release-plan.md](oss-and-play-release-plan.md)
「保留論点」セクションと一致。本ファイルは確定後に該当箇所を上書き予定。

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
