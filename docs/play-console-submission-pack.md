# Play Console 提出パック

作成日: 2026-06-20
状態: Play Console 実画面作業前のローカル棚卸しメモ
関連: [play-store-listing.md](play-store-listing.md) / [oss-and-play-release-plan.md](oss-and-play-release-plan.md)

---

## 目的

Play Console を開いたときに、提出に必要なローカル成果物と転記元を迷わず参照できるようにする。
Play Console 実画面での Store listing / Data Safety 確定は後続作業とし、本ファイルでは
リポジトリ内で準備済みの素材だけを索引化する。

---

## 提出成果物

| 用途 | パス / URL | 状態 |
| --- | --- | --- |
| AAB | `build/app/outputs/bundle/release/app-release.aab` | 生成済み、51.4 MB |
| Upload key template | `android/key.properties.template` | commit 対象として配置済み |
| Upload key 実体 | `android/key.properties` | gitignore 除外、ローカル作成済み |
| Play Store icon | `design/icon/play-store-icon-512.png` | 512 px PNG、配置済み |
| Feature graphic (ja) | `design/store/feature-graphic-1024x500.png` | 配置済み |
| Feature graphic (en) | `design/store/feature-graphic-1024x500-en.png` | 配置済み |
| Phone screenshots (ja) | `design/screenshots/phone/ja/*.png` | Pixel 6a、7 枚、1080x2400 |
| Phone screenshots (en) | `design/screenshots/phone/en/*.png` | Pixel 6a、7 枚、1080x2400 |
| Privacy Policy (ja) | `https://bonkoturyu.github.io/TimerUtility/privacy-policy` | GitHub Pages 公開確認済み |
| Privacy Policy (en) | `https://bonkoturyu.github.io/TimerUtility/privacy-policy.en` | GitHub Pages 公開確認済み |
| Store listing text | `docs/play-store-listing.md` | ja / en 草稿あり |
| Closed test plan | `docs/closed-test-plan.md` | Phase 11.10 以降で使用 |

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

## 転記順

1. Main store listing:
   - App name: `TimerUtility`
   - Category: Tools
   - Short description / Full description: [play-store-listing.md](play-store-listing.md) §2 / §3
   - Contact details / Privacy Policy URL: [play-store-listing.md](play-store-listing.md) §10
2. Store graphics:
   - `design/icon/play-store-icon-512.png`
   - ja listing: `design/store/feature-graphic-1024x500.png` + `design/screenshots/phone/ja/*.png`
   - en listing: `design/store/feature-graphic-1024x500-en.png` + `design/screenshots/phone/en/*.png`
3. Release:
   - AAB: `build/app/outputs/bundle/release/app-release.aab`
   - Release notes: [play-store-listing.md](play-store-listing.md) §4
4. App content:
   - Data Safety: [play-store-listing.md](play-store-listing.md) §5
   - Content Rating: [play-store-listing.md](play-store-listing.md) §6
   - Target Audience and Content: [play-store-listing.md](play-store-listing.md) §7
   - Permissions explanations: [play-store-listing.md](play-store-listing.md) §8

---

## Phase 11.9 クローズ条件

- [ ] Play Console 実画面で Store listing の ja / en 転記内容を確定
- [ ] Play Console 実画面で Data Safety を「No data collected / No data shared」方針で確定
- [ ] Content Rating / Target Audience and Content を実画面の質問票で確定
- [ ] 必要な権限説明を Play Console 実画面に転記
- [ ] Phase 11.9 完了記録を `BACKLOG.md` / `tasklist.md` / `docs/dev-log.md` に反映

---

## 注意

Play Console の仕様・画面順・必要項目は変わり得る。外部仕様に関する最終判断は
Phase 11.10-T2 で公式 Help と Play Console 実画面を確認してから行う。
