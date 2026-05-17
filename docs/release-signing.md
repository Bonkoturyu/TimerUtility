# Release Signing 手順 (TimerUtility)

作成日: 2026-05-17 (Phase 11.9 準備、Phase 11.9-T12〜T14 で実施)
状態: 草稿。Phase 11.10-T2 で Play Console + Android Developers 公式ドキュメントを
WebFetch して、本書の手順と現行仕様を突き合わせてから確定値に差し替える前提

本ファイルは TimerUtility を Google Play Store に署名済みの aab として提出するために
必要な署名鍵 (upload keystore) の生成・配置・ビルド配線手順を集約する。

---

## 1. 方針サマリ

| 項目 | 採用方針 |
| --- | --- |
| 署名方式 | **新規 upload keystore + Play App Signing 加入** |
| keystore 種別 | JKS (`.jks`)、PKCS#12 (`.p12`) でも可だが互換性のため JKS 採用 |
| keystore 配置 | **ユーザー手元のみ** (リポジトリへの commit 厳禁) |
| `key.properties` 配置 | ローカル `android/key.properties`、[.gitignore:29](../.gitignore#L29) で除外済 |
| パスワード管理 | パスワードマネージャ (1Password / Bitwarden / KeePassXC 等) で別途保管 |
| Validity | 25 年以上 (Google 推奨) |
| 鍵長 | RSA 2048 bit (最小)、推奨は 4096 bit |
| 別アプリへの流用 | **禁止** (鍵を共有すると 1 つ漏れたとき全アプリが影響を受ける) |

### 1.1 なぜ Play App Signing 加入か

Play App Signing は Google が「App Signing Key」を Play 側で保管し、開発者は
「Upload Key」のみを管理するスキーム。

- **メリット**: Upload Key を紛失しても Play Console から再発行可能 (古典的な
  「keystore 紛失で再申請不可」事態を回避できる)。
- **デメリット**: App Signing Key は Google が保管するため、Play 経由でしか
  配布できなくなる (ストア外配布したい場合は Upload Key で直接署名した APK を
  別途用意できる)。
- TimerUtility のように Play Store 中心で配布するアプリでは加入が現実的。
  GitHub Release で APK を追加配布したい場合も、Upload Key で署名したものを
  別途 attach する運用で並立可能。

> 加入フローの実画面は 2026 年時点で Play Console のオンボーディング途中で
> 強制提示されるはず。Phase 11.10-T2 で「新規アプリは Play App Signing 加入が
> 強制 / 任意」「opt-out 手順の有無」を再確認。

---

## 2. Upload Keystore の生成 (ユーザー手元で実施)

### 2.1 keytool コマンド

JDK 17 同梱の `keytool` を使う。コマンドプロンプト / PowerShell / bash いずれでも可。

```sh
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 4096 \
  -validity 9125 \
  -alias upload \
  -storetype JKS
```

- `-keystore upload-keystore.jks`: 出力ファイル名 (任意)。慣例として `upload-keystore.jks`
- `-keyalg RSA`: 公開鍵アルゴリズム
- `-keysize 4096`: 鍵長 (4096 bit 推奨。最小は 2048)
- `-validity 9125`: 有効日数。9125 日 ≒ 25 年。Google 推奨は **2068 年 10 月 22 日まで**
  または **少なくとも 25 年**
- `-alias upload`: alias 名 (任意。fast follow-up の混乱を避けるため `upload` 推奨)

実行時に対話的に聞かれる項目:

| プロンプト | 入力内容 |
| --- | --- |
| keystore password | 強固なパスワード (パスワードマネージャから生成) |
| Re-enter | 同じパスワード |
| First and last name (CN) | 開発者名または個人名 (例: `Bonkoturyu`) |
| Organizational unit (OU) | 任意 (空欄可、Enter で skip) |
| Organization (O) | 任意 (例: `Personal`) |
| City or locality (L) | 任意 |
| State or province (ST) | 任意 |
| Country code (C) | 2 文字 ISO 3166-1 alpha-2 (例: `JP`) |
| Key password (同じパスワードで良ければ Enter) | **Enter で keystore パスワードと同一にする推奨** (Android Studio はキー個別パスワードを必須化していない) |

`upload-keystore.jks` ファイルと、その keystore パスワード + key alias パスワード
の 2 つを **厳重に保管** すること。

### 2.2 検証

生成直後に内容を確認:

```sh
keytool -list -v -keystore upload-keystore.jks -alias upload
```

出力に `Valid from` / `Valid until` (= 約 25 年後) が想定通りであることを確認。
`SHA-1` / `SHA-256` fingerprint も Play Console で控えるためメモ。

### 2.3 バックアップ

- パスワードマネージャの「セキュアノート」機能で keystore のパスワードを保存
- `.jks` ファイル自体を別の暗号化済みストレージ (USB ドライブ、暗号化 cloud
  storage、ハードウェアセキュリティモジュール) に複製
- パスワード単独 / `.jks` ファイル単独のどちらかを失っても署名できなくなるため、
  **両方** をバックアップ

---

## 3. `key.properties` 配置

リポジトリのローカル作業ディレクトリ (`android/`) に `key.properties` を新規作成。

```properties
# android/key.properties
storePassword=<keystore password>
keyPassword=<key alias password、同じなら storePassword と同じ値>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

- `storeFile` は絶対パス推奨 (相対パスは `android/app/` 起点で解釈される)
- このファイルは [.gitignore:29](../.gitignore#L29) (`**/android/key.properties`)
  で除外済なので git に上がらない。Phase 11.9 着手前に再確認: `git check-ignore
  android/key.properties` が 1 を返せばトラッキング外
- `android/key.properties.template` (中身は上記コマンドラインの placeholder 版)
  を commit して fork 開発者に書き方を示す予定 (Phase 11.9-T13)

---

## 4. `build.gradle.kts` 配線 (Phase 11.9-T14)

現状の `release` ビルドは debug keystore を流用する暫定設定:

```kotlin
// android/app/build.gradle.kts (現状、L34-40)
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        // Signing with the debug keys for now, so `flutter run --release` works.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

これを `key.properties` 経由で upload keystore を読む構成に書き換える。

### 4.1 改修後の例

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // 既存 namespace / compileSdk / kotlinOptions / defaultConfig ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

注意: `key.properties` が存在しない CI 環境 (現状の GitHub Actions) では
`storeFile` が `null` になり release ビルド時にエラーになる。CI で release
ビルドを走らせる場合は GitHub Secrets から `key.properties` 相当の値を環境変数で
受け取り、ビルド直前に動的生成するスクリプトを噛ませる
(Phase 11.10-T9 `release.yml` で実装予定)。

### 4.2 ローカル動作確認 (Phase 11.9-T17)

```sh
flutter build appbundle --release
```

成功すれば `build/app/outputs/bundle/release/app-release.aab` が生成される。
`bundletool` で APK を展開して Pixel 6a に install テストできれば release 署名は完了。

```sh
# bundletool は Google が配布する jar
java -jar bundletool.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app-release.apks \
  --mode=universal
unzip -p app-release.apks universal.apk > app-release.apk
adb install -r app-release.apk
```

---

## 5. Play App Signing 加入 (Play Console 操作、Phase 11.10-T1)

> 以下は知識ベースに基づく草稿。Phase 11.10-T2 で Play Console の現行画面と
> 突き合わせて確定。

1. Play Console にログイン → 「アプリを作成」で新規アプリを登録 (パッケージ名 =
   `io.github.bonkoturyu.timer_utility`、初回はあらゆる項目が空欄)
2. 「設定」→「アプリの署名」(または「Play App Signing」) を開く
3. 加入オプション (新規アプリでは強制の場合あり):
   - **Option A (推奨)**: Play が App Signing Key を生成する。Upload Key だけ
     開発者が管理 (本書 §2 で生成した `upload-keystore.jks` をそのまま使用)
   - Option B: 既存の App Signing Key をアップロードする (Play App Signing
     に乗せる)。古典的な keystore 運用からの移行用、新規アプリでは不要
4. Upload Key を Play Console に登録:
   - `keytool -export -rfc -keystore upload-keystore.jks -alias upload -file upload_certificate.pem`
     で証明書 (.pem) を export
   - Play Console の「アプリの署名」画面でアップロード
5. 以降は aab を作って Play Console に upload するたびに、Play 側が Upload Key
   署名を検証 → App Signing Key で再署名 → ユーザーに配信

### 5.1 紛失時の復旧

Upload Key を紛失した場合は Play Console の「キーをリセット」フォームから
申請可能 (Google サポート経由、本人確認 + 数日待ち)。App Signing Key 自体は
Play 側に残っているため、ユーザーのアプリがアップデート不可になる事態は回避できる。

---

## 6. Phase 11.10 以降の運用 (CI 自動署名)

Phase 11.10-T9 で `.github/workflows/release.yml` を新規追加し、tag push
(`v*.*.*`) トリガで aab を自動ビルドする予定。署名に必要な情報は GitHub Secrets
として:

| Secret 名 | 内容 |
| --- | --- |
| `UPLOAD_KEYSTORE_BASE64` | `upload-keystore.jks` を base64 エンコードしたもの |
| `UPLOAD_KEY_ALIAS` | `upload` (本書 §2.1) |
| `UPLOAD_KEY_PASSWORD` | key alias パスワード |
| `UPLOAD_STORE_PASSWORD` | keystore パスワード |

CI ジョブ内で:

1. `UPLOAD_KEYSTORE_BASE64` を decode して一時 `.jks` ファイルを生成
2. 動的に `android/key.properties` を生成
3. `flutter build appbundle --release` 実行
4. 生成 aab を GitHub Release の artifact として upload
5. fastlane supply 連携で Play Console に自動 upload — これは本 Phase 完了後の
   継続改善として保留 (まず手動 upload 経路を確立する)

---

## 7. セキュリティ注意事項

- **`.jks` ファイルとそのパスワードは TimerUtility に対する完全な署名権限**。漏れた
  場合、攻撃者が偽装 update を Play Store に push できる
- パスワードマネージャに保存する際、項目名は **アプリ名と紐付かない** ものを推奨
  (例: 「dev-keystore-2026」など、リポジトリ名検索でヒットしない名前)
- リポジトリ Issue / commit message / PR description / Slack 等に **絶対に貼らない**。
  `git log -S "<keystore password>"` の grep がヒットしてはいけない
- 万一漏れた疑いがある場合: 即座に §5.1 の Play Console 「キーをリセット」を実施

---

## 8. 未確定項目 (Phase 11.10-T2 で本格裏取り)

[CLAUDE.md](../CLAUDE.md) のソース信用原則に従い、Phase 11.10-T2 で確認:

1. Play App Signing は新規アプリで **強制** か **任意** か (本書 §5 では「強制の
   場合あり」と曖昧記述、確定後に断定文に書き換え)
2. Upload Key 紛失時の Reset フォームの 2026 年現行 URL / フロー
3. keytool の推奨パラメータ (`-keysize 4096` / `-validity 9125` 等) の Google
   推奨値が現行も維持されているか
4. `fastlane supply` ベースの自動 upload と Play Developer API の現行制約
