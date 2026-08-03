# Play Console 提出パック

作成日: 2026-06-20
最終同期: 2026-08-03
状態: v1.1.5 公開後の現行索引。Closed Testing と Data Safety 再確認が残作業

関連: [play-store-listing.md](play-store-listing.md) /
[closed-test-plan.md](closed-test-plan.md) /
[oss-and-play-release-plan.md](oss-and-play-release-plan.md)

---

## 現行リリース

| 項目 | 値 |
| --- | --- |
| Version | `1.1.5` |
| Version code | `9` |
| GitHub Release | [v1.1.5](https://github.com/Bonkoturyu/TimerUtility/releases/tag/v1.1.5) |
| Target commit | `21eda8f8655830709cfc91c468ffabec3bc77d0c` |
| AAB | Release Workflow で署名付き成果物を公開済み。ローカル生成先は `build/app/outputs/bundle/release/app-release.aab` |
| Android | targetSdk `36`、署名検証済み |

秘密鍵と実体の `android/key.properties` は gitignore 対象。リポジトリには
`android/key.properties.template` だけを含める。

---

## 提出成果物

| 用途 | パス / URL | 状態 |
| --- | --- | --- |
| Play Store icon | `design/icon/play-store-icon-512.png` | 512 px PNG、配置済み |
| Feature graphic (ja) | `design/store/feature-graphic-1024x500.png` | 配置済み |
| Feature graphic (en) | `design/store/feature-graphic-1024x500-en.png` | 配置済み |
| Phone screenshots (ja) | `design/screenshots/phone/ja/*.png` | Pixel 6a、7 枚、1080x2400 |
| Phone screenshots (en) | `design/screenshots/phone/en/*.png` | Pixel 6a、7 枚、1080x2400 |
| Privacy Policy (ja) | `https://bonkoturyu.github.io/TimerUtility/privacy-policy` | 日本語正典 |
| Privacy Policy (en) | `https://bonkoturyu.github.io/TimerUtility/privacy-policy.en` | 英語 |
| Privacy Policy (zh-Hans) | `https://bonkoturyu.github.io/TimerUtility/privacy-policy.zh-Hans` | 簡体字中国語 |
| Privacy Policy (zh-Hant) | `https://bonkoturyu.github.io/TimerUtility/privacy-policy.zh-Hant` | 繁体字中国語 |
| Privacy Policy (ko) | `https://bonkoturyu.github.io/TimerUtility/privacy-policy.ko` | 韓国語 |
| Store listing / release notes | `docs/play-store-listing.md` | ja / en、v1.1.5 まで記録 |
| Closed test plan | `docs/closed-test-plan.md` | 募集文と記録テンプレートあり |

---

## スクリーンショット

| # | ja | en |
| --- | --- | --- |
| 1 | `design/screenshots/phone/ja/01_timer_multi_running.png` | `design/screenshots/phone/en/01_timer_multi_running.png` |
| 2 | `design/screenshots/phone/ja/02_stopwatch_laps.png` | `design/screenshots/phone/en/02_stopwatch_laps.png` |
| 3 | `design/screenshots/phone/ja/03_alarm_list_repeat_once.png` | `design/screenshots/phone/en/03_alarm_list_repeat_once.png` |
| 4 | `design/screenshots/phone/ja/04_world_clock_analog_6_cities.png` | `design/screenshots/phone/en/04_world_clock_analog_6_cities.png` |
| 5 | `design/screenshots/phone/ja/05_alarm_ringing_screen.png` | `design/screenshots/phone/en/05_alarm_ringing_screen.png` |
| 6 | `design/screenshots/phone/ja/06_settings_theme_language_diagnostics.png` | `design/screenshots/phone/en/06_settings_theme_language_diagnostics.png` |
| 7 | `design/screenshots/phone/ja/07_preset_manage.png` | `design/screenshots/phone/en/07_preset_manage.png` |

---

## Play Console 状態

- [x] アプリ作成と Internal Testing
- [x] ja / en Main store listing と画像素材
- [x] Content Rating
- [x] Target Audience and Content (13 歳以上)
- [x] 広告 ID、FullScreenIntent、Exact Alarm のアプリコンテンツ申告
- [x] Data Safety を「No data collected / No data shared」で送信
- [ ] Android `Geocoder` のプロバイダー処理を踏まえて Approximate location の
  Data Safety 回答を再確認し、必要なら修正
- [ ] v1.1.5 (9) を Closed Testing へ公開し、12 テスター × 14 日間の opt-in を完了
- [ ] 本番アクセス申請の文章質問票を提出

Data Safety の再確認方針と転記文は [play-store-listing.md §5](play-store-listing.md#5-data-safety-申告)、
データ処理の正典は [privacy-policy.md](privacy-policy.md) を参照する。

---

## 注意

Play Console のフォーム、要件、表示順は変更され得る。提出時は公式 Help と実画面を
再確認し、リポジトリの草稿より実時間の validator / Console 表示を優先する。
