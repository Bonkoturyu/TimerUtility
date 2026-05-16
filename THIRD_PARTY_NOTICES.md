# Third-Party Notices

TimerUtility は MIT ライセンスで配布される。本ファイルは TimerUtility が依存する
サードパーティ製ソフトウェア (production / dev 依存 + 同梱アセット + Native 依存) の
ライセンス内訳を一覧化し、各ライセンス本文への参照を提供する。

最終更新日: 2026-05-16 (Phase 11.8 OSS 公開準備)

---

## 1. Production dependencies (`pubspec.yaml` → `dependencies`)

| パッケージ | ライセンス | 備考 |
| --- | --- | --- |
| `flutter` (SDK) | BSD-3-Clause | https://github.com/flutter/flutter |
| `cupertino_icons` | MIT | https://pub.dev/packages/cupertino_icons |
| `flutter_riverpod` | MIT | https://pub.dev/packages/flutter_riverpod |
| `riverpod_annotation` | MIT | https://pub.dev/packages/riverpod_annotation |
| `go_router` | BSD-3-Clause | flutter.dev 公式 |
| `clock` | BSD-3-Clause | dart.dev 公式 |
| `drift` | MIT | https://pub.dev/packages/drift |
| `drift_flutter` | MIT | https://pub.dev/packages/drift_flutter |
| `flutter_local_notifications` | BSD-3-Clause | https://pub.dev/packages/flutter_local_notifications |
| `audioplayers` | MIT | https://pub.dev/packages/audioplayers |
| `permission_handler` | MIT | https://pub.dev/packages/permission_handler |
| `uuid` | MIT | https://pub.dev/packages/uuid |
| `logger` | MIT | https://pub.dev/packages/logger |
| `freezed_annotation` | MIT | https://pub.dev/packages/freezed_annotation |
| `timezone` | BSD-2-Clause | https://pub.dev/packages/timezone |
| `flutter_timezone` | BSD-3-Clause | https://pub.dev/packages/flutter_timezone |
| `intl` | BSD-3-Clause | dart.dev 公式 |
| `shared_preferences` | BSD-3-Clause | https://pub.dev/packages/shared_preferences |
| `geolocator` | MIT | https://pub.dev/packages/geolocator |
| `geocoding` | MIT | https://pub.dev/packages/geocoding |
| `path_provider` | BSD-3-Clause | https://pub.dev/packages/path_provider |
| `path` | BSD-3-Clause | dart.dev 公式 |
| `archive` | MIT (Apache 2.0 互換) | https://pub.dev/packages/archive |
| `share_plus` | BSD-3-Clause | https://pub.dev/packages/share_plus |

---

## 2. Development dependencies (`pubspec.yaml` → `dev_dependencies` / overrides)

| パッケージ | ライセンス |
| --- | --- |
| `flutter_test` (SDK) | BSD-3-Clause |
| `flutter_lints` | BSD-3-Clause |
| `riverpod_generator` | MIT |
| `build_runner` | BSD-3-Clause |
| `drift_dev` | MIT |
| `mocktail` | MIT |
| `fake_async` | BSD-3-Clause |
| `custom_lint` | MIT |
| `riverpod_lint` | MIT |
| `freezed` | MIT |
| `analyzer_plugin` (override) | BSD-3-Clause |

すべて MIT または BSD 系。**GPL / AGPL / LGPL 等のコピーレフトは一切含まれない**。

---

## 3. Native (Android) dependencies

| 項目 | 出典 / ライセンス |
| --- | --- |
| `MainActivity.kt` / `AndroidManifest.xml` | 自作 (MIT、本リポジトリ) |
| `android/app/build.gradle.kts` | Flutter 標準テンプレート |
| `com.android.tools:desugar_jdk_libs:2.1.4` | BSD-3-Clause (Google) |

---

## 4. 同梱アセット (assets/sounds/)

3 件の MP3 はすべて [Pixabay Content License](https://pixabay.com/service/license-summary/)
で配布されているもの。商用利用可・帰属表示不要・再配布可。2024 年改定の「Pixabay
コンテンツのみで作られた音源コレクションの再配布禁止」条項にも該当しない
(アプリの一部としての同梱は対象外)。

| ファイル | 作者 | 出典 |
| --- | --- | --- |
| `alarm_default.mp3` | `freesound_community` | https://pixabay.com/sound-effects/film-special-effects-digital-watch-alarm-81203/ |
| `alarm_gentle.mp3` | `JeremayJimenez` | https://pixabay.com/sound-effects/technology-bhutan-eas-alarm-bhutan-not-a-ai-515416/ |
| `alarm_warning.mp3` | `JeremayJimenez` | https://pixabay.com/sound-effects/spain-eas-alarm-spain-437846/ |

詳細 (取得日 / 加工有無等) は [assets/sounds/LICENSES.md](assets/sounds/LICENSES.md) を参照。

---

## 5. ライセンス本文

各ライセンスの本文は配布元 (pub.dev / GitHub) で参照すること。アプリ実行時には
`LicenseRegistry` 経由で同梱音源ライセンスとソフトウェアライセンス一覧を設定画面の
「ライセンス」項目から表示できる ([lib/main.dart](lib/main.dart) の
`LicenseRegistry.addLicense` 配線参照)。

---

## 6. 参照ドキュメント

- [LICENSE](LICENSE) — 本プロジェクト本体 (MIT)
- [assets/sounds/LICENSES.md](assets/sounds/LICENSES.md) — 同梱音源詳細
- [docs/oss-publishing-notes.md](docs/oss-publishing-notes.md) — 公開可否・特許リスク監査
- [pubspec.yaml](pubspec.yaml) — 依存パッケージ一覧 (transitive 含む全体は
  `flutter pub deps` で確認可能)
