# Assets Specification

本プロジェクトに同梱する音源・画像等のアセットの仕様を定義する。
Phase 5 着手前に音源を準備すること。

---

## ディレクトリ構成

```
assets/
├── sounds/
│   ├── alarm_default.mp3
│   ├── alarm_gentle.mp3
│   ├── alarm_urgent.mp3
│   ├── alarm_chime.mp3
│   └── ...
├── images/
│   └── (アプリ内画像、Phase 11 で追加)
└── icons/
    └── (アプリアイコン関連、Phase 11 で追加)
```

---

## 音源仕様

### 共通要件

| 項目 | 要件 |
|---|---|
| フォーマット | MP3（推奨）または WAV |
| サンプリングレート | 44.1 kHz |
| ビットレート | 128 kbps 以上（MP3 の場合） |
| チャンネル | ステレオ |
| 長さ | **8〜15 秒**（ループ再生前提） |
| ファイルサイズ | 1 ファイル 500 KB 以下 |
| 音量 | -3 dB ピーク以下（クリッピング回避） |
| フェードイン / アウト | 推奨（ブツ切り音は避ける） |

### ループ再生

`audioplayers` の `ReleaseMode.loop` で繰り返し再生する。
ループ境界が滑らかになるよう、音源の最初と最後の波形を合わせる。

### 音量正規化

すべての音源を同じピーク音量に揃える（-3 dB 推奨）。
ユーザーが音源を切り替えても音量が大きく変わらないようにする。

---

## 同梱音源リスト（仮）

具体的な音源は Phase 5 着手時に最終決定。仮の構成例:

| ファイル名 | ID | 表示名（日本語） | 表示名（英語） | 特徴 |
|---|---|---|---|---|
| `alarm_default.mp3` | `default` | デフォルト | Default | 標準的なアラーム音 |
| `alarm_gentle.mp3` | `gentle` | やさしい | Gentle | 穏やかな起床向け |
| `alarm_urgent.mp3` | `urgent` | 急ぎ | Urgent | 強めの注意喚起 |
| `alarm_chime.mp3` | `chime` | チャイム | Chime | 学校チャイム風 |
| `alarm_bell.mp3` | `bell` | ベル | Bell | 単音ベル |
| `alarm_digital.mp3` | `digital` | デジタル | Digital | 電子音 |

最低 5 種類、最大 10 種類程度を目安に同梱。

---

## ライセンス管理

### 採用方針

以下のいずれかから取得:

1. **Royalty Free / CC0 サイト**
   - Pixabay: https://pixabay.com/sound-effects/
   - freesound.org（CC0 限定で絞り込み）
   - Mixkit: https://mixkit.co/free-sound-effects/

2. **自作**

3. **商用利用可能なライセンス購入**

### ライセンス情報の記録

`assets/sounds/LICENSES.md` を作成し、各音源について以下を記録:

- ファイル名
- 出典（URL）
- 作者
- ライセンス名（CC0, CC BY 4.0 等）
- 取得日
- 加工有無

例:

```
## alarm_default.mp3
- 出典: https://pixabay.com/sound-effects/xxx/
- 作者: 〇〇
- ライセンス: Pixabay Content License (Royalty Free)
- 取得日: 2026-05-XX
- 加工: 8 秒にトリミング、フェードイン / アウト追加
```

### Play Store 提出時の注意

- CC BY 等の表示義務があるライセンスは、アプリ内クレジット表示が必要
- 設定画面に「使用ライセンス」セクションを設置（Phase 11）

---

## AlarmSoundCatalog の実装

`lib/domain/timer/alarm_sound_catalog.dart`:

ドメイン層に同梱音源のリストを定義。

```
class AlarmSoundCatalog {
  static const List<AlarmSound> all = [
    AlarmSound(
      id: 'default',
      displayName: 'デフォルト',
      assetPath: 'assets/sounds/alarm_default.mp3',
    ),
    AlarmSound(
      id: 'gentle',
      displayName: 'やさしい',
      assetPath: 'assets/sounds/alarm_gentle.mp3',
    ),
    // ...
  ];

  static AlarmSound get defaultSound => all.first;

  static AlarmSound? findById(String id) =>
      all.firstWhereOrNull((s) => s.id == id);
}
```

### 永続化との関係

- TimerEntity / Preset には `AlarmSound` ではなく **`String soundId`** で保存
- 表示時に `AlarmSoundCatalog.findById(soundId)` で解決
- 将来音源を追加・削除しても DB スキーマ変更不要

### ローカライズ

`displayName` は `application/` 層で `AppLocalizations` を使って多言語化することも可能。
ただし Phase 11 までは日本語固定で OK。

---

## pubspec.yaml への登録

```yaml
flutter:
  assets:
    - assets/sounds/
    - assets/images/
    - assets/icons/
```

ディレクトリ単位で登録すると、ファイル追加時に毎回 yaml 編集する必要がない。

---

## 通知音との関係

### Android の通知音

通知 Channel に設定した音は `assets/` から直接読めない。
代替案:

1. **`android/app/src/main/res/raw/` に配置**
   - 通知 Channel の `setSound()` で参照可能
   - ただし assets と二重管理になる

2. **通知音は標準 + アラーム画面起動後にカスタム音再生**（採用）
   - 通知 Channel: 標準音 or 短い通知音
   - アラーム画面表示後: `audioplayers` で `assets/sounds/` の音源を再生

3. **通知音なし + バイブ + フルスクリーン Intent**
   - 通知時点では音を鳴らさず、画面遷移後に鳴らす
   - フルスクリーン Intent 失敗時は無音になるリスク

### 採用方針

**案 2** を採用。理由:
- assets 一元管理
- アラーム画面のスヌーズ / 停止操作と音再生のライフサイクルが一致
- 通知音は短い「タンッ」程度で OK（あくまで存在通知）

ただし通知のみで気付かせたいケース（ロック画面に出ない場合）があるため、`res/raw/` にも軽い通知音 `notification_chime.mp3` を 1 つ配置。

```
android/app/src/main/res/raw/
└── notification_chime.mp3  // 通知 Channel 用、1〜2 秒
```

---

## ファイル命名規則

### 音源

- 形式: `<category>_<name>.<ext>`
- 例: `alarm_gentle.mp3`, `notification_chime.mp3`
- すべて小文字、スネークケース

### カテゴリ

| カテゴリ | 用途 |
|---|---|
| `alarm_` | タイマー鳴動用（ループ再生） |
| `notification_` | 通知音（短時間、単発） |

---

## バリデーションスクリプト（任意）

CI で以下を自動チェックする想定:

- 全音源のフォーマット確認（`ffprobe` 等）
- ファイルサイズ上限チェック
- `AlarmSoundCatalog` のエントリと実ファイルの整合性チェック

スクリプトは `tool/validate_assets.dart` 等に配置（Phase 5 以降に検討）。

---

## アセット追加・削除のフロー

新規音源追加時:

1. ファイルを `assets/sounds/` に配置
2. `assets/sounds/LICENSES.md` にライセンス情報を記載
3. `lib/domain/timer/alarm_sound_catalog.dart` に追加
4. ユニットテスト（catalog のエントリが正しく取得できるか）
5. 実機でループ再生確認

削除時:

1. **DB 上に該当 soundId を持つレコードがある可能性**を考慮
2. `AlarmSoundCatalog.findById()` が null を返した場合、デフォルト音にフォールバック
3. ファイルと catalog エントリを削除
4. マイグレーションスクリプトは不要（findById のフォールバックで対応）

---

## 関連ドキュメント

- `docs/domain-model.md`: AlarmSound ValueObject の定義
- `docs/android-constraints.md`: 通知音の OS 制約
- `docs/architecture.md`: assets の配置ルール

---

最終更新日: 2026-04-29
