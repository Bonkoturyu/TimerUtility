# Release Signing 手順 (TimerUtility)

作成日: 2026-05-17 (Phase 11.9 準備、Phase 11.9-T12〜T14 で実施)
状態: 運用中。Play App Signing と Upload Key Reset の外部仕様は 2026-08-03 に再確認し、
GitHub Actions の所有者限定手動リリースは 2026-07-29 に実装 (詳細は §6)。
fastlane supply 連携は継続課題として残存。

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
| Validity | 9125 日 (約 25 年。本プロジェクトの採用値) |
| 鍵長 | RSA 2048 bit 以上が Play 要件。本プロジェクトは 4096 bit を採用 |
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

> TimerUtility は初回 AAB アップロード時に Play App Signing へ加入済み。2026-07-24
> 時点の公式仕様では、新規アプリは Google 生成鍵へ自動 enroll される。現行運用は
> §5 と Play Console の「アプリの署名」を正とする。

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
- `-keysize 4096`: 本プロジェクトの採用値。Play の Upload Key 要件は RSA 2048 bit 以上
- `-validity 9125`: 本プロジェクトの採用値。9125 日は約 25 年。生成後に実際の失効日を確認する
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
- `android/key.properties.template` は placeholder 版としてコミット済み。fork 開発者は
  これを参照し、実値を含む `android/key.properties` はコミットしない

---

## 4. `build.gradle.kts` 配線 (Phase 11.9-T14)

現行実装は `android/key.properties` が存在する場合に upload keystore を読み、release
署名へ使用する。ファイルがない開発環境ではローカル実行性を保つため debug keystoreへ
フォールバックする。

```kotlin
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    // 既存 namespace / compileSdk / kotlinOptions / defaultConfig ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}
```

GitHub Actions の `release.yml` は Secrets から keystore と `key.properties` を
ビルド直前に生成するため、公開AABがdebug署名へフォールバックすることはない。

### 4.1 ローカル動作確認 (Phase 11.9-T17)

```sh
flutter build appbundle --release
```

成功すれば `build/app/outputs/bundle/release/app-release.aab` が生成される。v1.1.5 (9) は
`jarsigner -verify` 成功後に GitHub Release へ添付され、Play Console の Closed Testing へ
アップロード済み。

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

> 2026-07-24 に公式ドキュメントで確認済み (詳細は §8): **新規アプリは aab 初回
> アップロード時に「quantum-ready hybrid signing (Google 生成鍵)」へ自動 enroll
> される**。以下の Option A/B のような能動的な「加入」選択操作は現行 UI には
> 存在しない前提で読み替える (Option B 相当の「既存鍵の持ち込み」だけ明示操作が
> 必要)。

1. Play Console にログイン → 「アプリを作成」で新規アプリを登録 (パッケージ名 =
   `io.github.bonkoturyu.timer_utility`、初回はあらゆる項目が空欄)
2. 「設定」→「アプリの署名」(または「Play App Signing」) を開く
3. 加入オプション:
   - **Option A (採用、実質デフォルト)**: aab 初回アップロードで自動 enroll。
     Upload Key だけ開発者が管理 (本書 §2 で生成した `upload-keystore.jks` を
     そのまま使用)
   - Option B: 既存の App Signing Key をアップロードする (Play App Signing
     に乗せる)。古典的な keystore 運用からの移行用、新規アプリでは不要
4. Upload Key を Play Console に登録:
   - `keytool -export -rfc -keystore upload-keystore.jks -alias upload -file upload_certificate.pem`
     で証明書 (.pem) を export
   - Play Console の「アプリの署名」画面でアップロード
5. 以降は aab を作って Play Console に upload するたびに、Play 側が Upload Key
   署名を検証 → App Signing Key で再署名 → ユーザーに配信

### 5.1 紛失時の復旧

Upload Key を紛失または侵害した場合は、新しい Upload Key を作成して証明書を PEM 形式で
export し、Play Console の `Protected with Play` → `Play Store protection` →
`Manage Play app signing` → `Upload key certificate` からリセットを申請する。
App Signing Key 自体は Play 側に残るため、Upload Key の交換後も同じアプリを更新できる。
公式手順: <https://support.google.com/googleplay/android-developer/answer/9842756>

---

## 6. GitHub Actions の手動リリース運用

`.github/workflows/release.yml` はタグ push では起動せず、GitHub Actions の
`workflow_dispatch` からリポジトリ所有者が明示的に実行する。GitHub の
「Run workflow」ボタンは対象 Workflow がデフォルトブランチに存在するときに
利用できる。公式手順:
<https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow>

実行手順:

1. GitHub の `Actions` → `Release` → `Run workflow` を開く
2. Branch に `main` を選び、`release_tag` に `vMAJOR.MINOR.PATCH` 形式のタグを入力する
   （現行リリースの実績: `v1.1.5`）
3. `Run workflow` を押す
4. Workflow が成功すると、実行対象の `main` commit にタグを作り、署名済み AAB を
  添付した GitHub Release を公開する

Workflow はビルド前に次を検証する。

- 実行者がリポジトリ所有者であること
- 実行ブランチが `main` であること
- `release_tag` が `vMAJOR.MINOR.PATCH` 形式であること
- `pubspec.yaml` の `version: MAJOR.MINOR.PATCH+BUILD` とタグが一致すること
- 同名のリモートタグが未作成であること
- 次の署名用 GitHub Secrets 4 件が未登録または空でないこと

署名に必要な情報は GitHub Secrets として登録する:

| Secret 名 | 内容 |
| --- | --- |
| `UPLOAD_KEYSTORE_BASE64` | `upload-keystore.jks` を base64 エンコードしたもの |
| `UPLOAD_KEY_ALIAS` | `upload` (本書 §2.1) |
| `UPLOAD_KEY_PASSWORD` | key alias パスワード |
| `UPLOAD_STORE_PASSWORD` | keystore パスワード |

手動リリースジョブ内で:

1. Google 公式の Flutter 3.44.8 Linux SDK archive を取得し、固定 SHA-256
   (`672089e001571a9fbb209a495c583580c0c6c73ef98999264ba07fa93ace332d`)
   と照合してから展開
2. `flutter analyze --fatal-infos` と `flutter test` を実行
3. `UPLOAD_KEYSTORE_BASE64` を decode して一時 `.jks` ファイルを生成
4. 動的に `android/key.properties` を生成
5. `flutter build appbundle --release` を実行
6. 署名情報を runner から削除
7. 指定タグを実行対象 commit に作成し、生成 AAB を GitHub Release へ添付
8. fastlane supply 連携で Play Console に自動 upload — これは本 Phase 完了後の
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

## 8. 外部仕様の確認状況

[CLAUDE.md](../CLAUDE.md) のソース信用原則に従い確認:

1. ✅ (2026-08-03 再確認) Play App Signing は新規アプリで **自動 enroll** (aab
   初回アップロード時に quantum-ready hybrid signing へ自動加入、能動的な
   「強制/任意」の選択操作は不要)。
   参照: <https://support.google.com/googleplay/android-developer/answer/9842756>
2. ✅ (2026-08-03 公式ヘルプ確認) Upload Key Reset は新しい鍵と PEM 証明書を作成し、
   `Manage Play app signing` の `Upload key certificate` から申請する。
3. ✅ (2026-08-03 公式ヘルプ確認) Upload Key は RSA 2048 bit 以上が要件。本プロジェクトの
   `4096 bit / 9125 日` はこの要件を満たす採用値であり、Google の指定推奨値とは表記しない。
4. 未確認: `fastlane supply` ベースの自動 upload と Play Developer API の
   現行制約 (Phase 11.10-T9 着手時に確認する方針で保留のまま)
