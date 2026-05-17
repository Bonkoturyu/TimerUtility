# Phase 11.9 事前検討メモ

作成日: 2026-05-17 (Phase 11.8 OSS 公開準備の T8.5 GitHub Privacy team 申請後、
返信待ち期間の有効活用として作成)。
寿命: Phase 11.9 全件完了時点で削除予定 (内容は実タスクに消化される)。
親計画: [docs/oss-and-play-release-plan.md](oss-and-play-release-plan.md) Phase 11.9 セクション

本ファイルは Phase 11.9 (T0〜T18) 実行前に判断確定しておきたい 4 項目 (A / B / C / G)
を集約する。実アーティファクト (プライバシーポリシー / Play Store listing /
release-signing 手順) は本ファイルと別建てで `docs/` 直下に同 PR で作成。

---

## A. 依存パッケージ版数 (Phase 11.9-T2 / T5 前準備)

### `flutter_launcher_icons`

- 最新版: **0.14.4** (pub.dev 確認、本セッション時点)
- ライセンス: MIT
- Adaptive Icon 対応: `adaptive_icon_background` / `adaptive_icon_foreground` /
  `adaptive_icon_foreground_inset` / `adaptive_icon_monochrome` 全対応
- 既知の breaking change (pub.dev 上の明示記載): なし。歴史的に
  `#AABBGGRR` → `#AARRGGBB` のカラーフォーマット切替があった旨が
  troubleshooting に記述
- 採用版: `^0.14.4` (dev_dependency)

### `flutter_native_splash`

- 最新版: **2.4.7** (pub.dev 確認、本セッション時点)
- ライセンス: MIT
- Android 12+ SplashScreen API 対応: `android_12` 設定セクションあり
  (center-logo / icon-background-color の独立指定)
- 採用版: `^2.4.7` (dev_dependency)

### pubspec.yaml への追加案 (T2 / T5 で実施)

```yaml
dev_dependencies:
  # 既存 ...
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.7
```

Dart SDK 制約 (`^3.11.5`) との衝突は事前確認の限り見当たらない。実際の `flutter pub get`
時点で改めて検証する。

---

## B. applicationId 移行影響範囲 (Phase 11.9-T0 前準備)

移行先: `com.bonkotu.timer.timer_utility` → **`io.github.bonkoturyu.timer_utility`**
(計画書 L28 で確定)。

### B.1 必須変更ファイル (Native / コード)

| # | ファイル | 変更内容 |
| --- | --- | --- |
| 1 | [android/app/build.gradle.kts:9](../android/app/build.gradle.kts#L9) | `namespace = "com.bonkotu.timer.timer_utility"` → `"io.github.bonkoturyu.timer_utility"` |
| 2 | [android/app/build.gradle.kts:25](../android/app/build.gradle.kts#L25) | `applicationId = "..."` 同じ値に |
| 3 | [android/app/src/main/kotlin/com/bonkotu/timer/timer_utility/MainActivity.kt:1](../android/app/src/main/kotlin/com/bonkotu/timer/timer_utility/MainActivity.kt#L1) | `package com.bonkotu.timer.timer_utility` → `package io.github.bonkoturyu.timer_utility` |
| 4 | Kotlin ディレクトリ | `android/app/src/main/kotlin/com/bonkotu/timer/timer_utility/` → `android/app/src/main/kotlin/io/github/bonkoturyu/timer_utility/` (`git mv` でファイル移動) |

[android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml)
は **編集不要**。PR #67 のレビューで確認済 (`<activity android:name=".MainActivity">`
は相対パスで `namespace` から自動解決、`${applicationName}` プレースホルダも同様、
`<receiver>` は `com.dexterous.flutterlocalnotifications.*` のサードパーティ
クラス参照のため fork 側で書き換える対象ではない)。

### B.2 MethodChannel 名 (T0 と同時にやるか別タスクか判断要)

現状の MethodChannel 名は `applicationId` プレフィックスではなく、ベース
`com.bonkotu.timer` + `/permission` という命名 (= applicationId の途中 prefix
を流用したが完全一致はしていない)。

| # | ファイル | 現状 | 推奨変更後 |
| --- | --- | --- | --- |
| 5 | [android/app/src/main/kotlin/.../MainActivity.kt:23](../android/app/src/main/kotlin/com/bonkotu/timer/timer_utility/MainActivity.kt#L23) | `PERMISSION_CHANNEL = "com.bonkotu.timer/permission"` | `"io.github.bonkoturyu.timer_utility/permission"` (or 同等の新 prefix) |
| 6 | [lib/infrastructure/platform/permission_channel.dart:11](../lib/infrastructure/platform/permission_channel.dart#L11) | `channelName = 'com.bonkotu.timer/permission'` | 同上 |
| 7 | [lib/presentation/screens/alarm_ringing_screen.dart:23](../lib/presentation/screens/alarm_ringing_screen.dart#L23) | `'com.bonkotu.timer/permission'` (ハードコード) | `PermissionChannel.channelName` 定数参照に refactor + 新名 |

**判断ポイント**: MethodChannel 名は OS から見えない内部識別子なので、移行
**しなくてもアプリは動く**。ただし fork ガイドの一貫性 / `io.github.*` 名前空間の
徹底のために移行が望ましい。Phase 11.9-T0 と同 PR で扱うか、別 PR にするかは
ユーザ判断ポイント。

### B.3 ライブドキュメント追従更新 (live = 削除不可)

実装と乖離させたくない docs:

- [README.md](../README.md) (L88 / L205 / L219 / L222) — fork ガイド + 技術スタック
- [BACKLOG.md](../BACKLOG.md) (L102) — 過去サマリの 1 行 (歴史記述として残すか追従するかは判断)
- [docs/architecture.md:199](architecture.md#L199) — Kotlin ディレクトリ図
- [docs/android-constraints.md](android-constraints.md) (L362 / L421) — Channel 名 2 箇所
- [docs/permissions.md:426](permissions.md#L426) — Channel 名 1 箇所
- [docs/platform-channels.md](platform-channels.md) — Channel 名 + パス参照多数

### B.4 履歴ドキュメント (= 旧 ID 記述を維持)

- [docs/dev-log.md](dev-log.md) — 各 Phase 実装当時の applicationId 記述、
  歴史記録として旧 ID のまま据置
- [docs/oss-publishing-notes.md](oss-publishing-notes.md) (L88 / L257) — 監査時点の記述、据置
- [docs/oss-and-play-release-plan.md](oss-and-play-release-plan.md) (L28 / L83) —
  移行計画自体で旧 ID + 新 ID を併記しているため意図的に両方残す

### B.5 テスト / Dart コードへの影響

`git grep "timer_utility"` で 96 ファイル hit したが、`pubspec.yaml` の
`name: timer_utility` (Dart パッケージ名) は **applicationId とは独立** で
変更不要。test/ ディレクトリの `package:timer_utility/...` import 文も Dart
パッケージ名の参照なので変更不要。

実質的に Dart 側で触る必要があるのは B.2 の MethodChannel 名移行を採用する場合の
2 ファイル (`permission_channel.dart` + `alarm_ringing_screen.dart`) のみ。

### B.6 実機検証チェックポイント (T0 実施後)

- 旧 applicationId のアプリを Pixel 6a から `adb uninstall com.bonkotu.timer.timer_utility`
  (Drift DB / SharedPreferences が新 applicationId 配下に再生成されるので、
  既存テストデータは消える前提)
- 新 applicationId で `flutter run -d <device>` → cold start
- Phase 6 FullScreenIntent 3 パターン回帰確認 (Doze / ロック / 通常)
- Phase 8.5 follow-up シナリオ (アラーム鳴動の単音化) 回帰確認

---

## C. 5 言語アプリ名テキスト (Phase 11.9-T4 前準備)

### C.1 現状

[lib/l10n/](../lib/l10n/) 配下の 5 ARB ファイルすべてで `appTitle: "TimerUtility"`
を共通定義済 (ja / en / zh / zh_Hant / ko)。アプリ内表示はすでに 5 言語で
`TimerUtility` 統一。

### C.2 採用方針

`res/values{,-ja,-zh,-b+zh+Hant,-ko}/strings.xml` の `app_name` も全 5 言語
**`TimerUtility`** で統一。ARB の `appTitle` と一致させ、OS 上のアイコン名 = アプリ内
表示名のブランド統一を維持する。

```xml
<!-- res/values/strings.xml (default = en) -->
<resources>
    <string name="app_name">TimerUtility</string>
</resources>
```

`values-ja` / `values-zh` / `values-b+zh+Hant` / `values-ko` も同内容で複製。
将来的にローカライズ表記 (例: 「タイマーユーティリティ」/「计时实用工具」) を
採用する場合は、ARB の `appTitle` も同時に切替が必要 (今回は不採用)。

### C.3 ディレクトリ修飾子の対応

| 言語 | フォルダ名 |
| --- | --- |
| 既定 (en fallback) | `res/values/` |
| 日本語 | `res/values-ja/` |
| 中国語簡体字 | `res/values-zh/` |
| 中国語繁体字 | `res/values-b+zh+Hant/` (BCP 47 形式、Android で `scriptCode` を表現する標準形) |
| 韓国語 | `res/values-ko/` |

`values-zh-rTW` / `values-zh-rHK` 形式は古い `localeQualifier` で zh_Hant の
区別ができないため不採用。Phase 11 A-3 で確立した方針 (Locale.fromSubtags +
scriptCode) と整合する。

---

## G. アイコン仕様要件 (Phase 11.9-T1 前準備、Phase 11.10-T2 で再裏取り必須)

> **裏取り注意**: 本セクションは知識ベース (cutoff: 2026-01) からの記述で、
> WebFetch で公式ページに到達できなかった (developer.android.com / m3.material.io
> の対象 URL が 404 を返した)。Phase 11.10-T2 で公式ページにアクセスし、
> Adaptive Icon 仕様 + Play Store の icon 要求が現行のまま (= 本セクションの
> 内容と一致) であることを再確認すること。乖離があれば本セクションを訂正、
> または T1 / T11 設計に反映してから素材を作る。

### G.1 Adaptive Icon (Android 8 / API 26〜)

- 2 レイヤー構造: foreground PNG + background (PNG または solid color)
- 各レイヤーの canvas サイズ: **108 × 108 dp**
- 安全ゾーン (Safe Zone): 中央 **72 × 72 dp** の円 (OEM ごとに mask 形状が
  異なるため、コア要素は安全ゾーン内に収める)
- 推奨ソース解像度: **1024 × 1024 px** PNG (`flutter_launcher_icons` が
  各 mipmap density に scale して生成)
- 周辺 18 dp はクロップされる前提でデザインする

### G.2 Themed Icon / Monochrome Layer (Android 13 / API 33〜)

- 第 3 レイヤー: monochrome (modulo alpha)
- 形式: **VectorDrawable XML** または PNG (32-bit、alpha のみ意味を持つ)
- レンダリング: OS が動的に背景色 / 前景色を適用してテーマ整合
- 必須化: 知識カットオフ時点では **任意** だが、Play Store / ランチャー
  ベンダ要求が今後上がる傾向。Phase 11.10-T2 で再確認 (もし monochrome 必須化が
  確定していれば T1 で素材を必ず作る)
- TimerUtility 案: 時計アイコンのシルエットを monochrome 化、白 + 透過のみ

### G.3 mipmap density (`flutter_launcher_icons` 自動生成)

| Density | 解像度 (px) |
| --- | --- |
| mdpi | 48 × 48 |
| hdpi | 72 × 72 |
| xhdpi | 96 × 96 |
| xxhdpi | 144 × 144 |
| xxxhdpi | 192 × 192 |

`mipmap-anydpi-v26/ic_launcher.xml` に Adaptive Icon XML、
`mipmap-anydpi-v33/ic_launcher.xml` に themed icon XML が配置される。

### G.4 Play Store 高解像度アイコン

- サイズ: **512 × 512 px** PNG (32-bit、Play Console upload 用)
- ファイルサイズ上限: 1 MB
- 透過: 非推奨 (Play Console が square crop する)
- ストア掲載素材として `design/icon/play-store-512.png` を別途準備
  (Phase 11.9-T1 で同時作成)

### G.5 デザイン素材の置き場所案

```text
design/
├── icon/
│   ├── source-1024.png                # マスター 1024 × 1024 PNG
│   ├── adaptive-foreground-1024.png   # Adaptive 前景
│   ├── adaptive-background.png        # Adaptive 背景 (もしくは solid color 指定)
│   ├── monochrome.xml                 # themed icon の VectorDrawable
│   └── play-store-512.png             # Play Console 用
└── screenshots/
    └── (Phase 11.9-T11 で Pixel 6a 実機撮影)
```

`design/` ディレクトリはアプリビルドには含まれない (`assets:` ディレクティブで
参照しない) ため、`pubspec.yaml` の変更は不要。

---

## H. 横断的ロードマップ (Phase 11.9 サブ PR 分割案)

計画書 T0〜T18 を、ユーザ確認必須ファイルの密度で 3 サブ PR にまとめる案:

1. **Sub-PR α**: T0 (applicationId 変更、Native 一式 + Pixel 6a 実機検証)
   + B.2 MethodChannel 名移行 (採用する場合) + B.3 ライブドキュメント追従
2. **Sub-PR β**: T1 / T2 / T3 (アイコン素材 + `flutter_launcher_icons`) +
   T5 / T6 (`flutter_native_splash`) + T4 (Manifest `@string/app_name` 化 +
   strings.xml 5 言語) + T7 (Pixel 6a 実機 4 パターン確認)
3. **Sub-PR γ**: T8 (privacy-policy、本 PR で骨子完成、T9 で GitHub Pages 公開) +
   T10 (play-store-listing、本 PR で骨子完成) + T11 (スクリーンショット) +
   T12 (release-signing、本 PR で骨子完成) + T13 / T14 (key.properties 配線) +
   T15 (versionCode bump) + T16 (README 追従) + T17 (aab ビルド) +
   T18 (ドキュメント反映)

サブ PR 分割は機械的整理であって、各サブの先頭で Plan 確認は別途実施。

---

## I. 残論点 (Phase 11.9 着手前にユーザ判断必要)

1. **B.2 MethodChannel 名移行**: T0 と同 PR で実施するか、別 PR にするか
   (アプリ機能には影響しないが fork ガイド一貫性に影響)
2. **G.2 monochrome layer**: 知識ベース時点では任意。Phase 11.10-T2 で必須化
   状況を確認した上で素材作成順を決める
3. **C.2 アプリ名ローカライズ**: 全 5 言語 `TimerUtility` 統一案で確定で良いか、
   日本語/中国語/韓国語だけ現地表記にするか
4. **H サブ PR 分割案**: 提示の α / β / γ 分割で進めるか、より細分化するか

これらは Phase 11.8 完了 → 11.9 着手前のキックオフで確認する。
