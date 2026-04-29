# ADR 0003: フルスクリーン Intent + AlarmManager 方式を採用、Foreground Service は使用しない

- 状態: Accepted
- 日付: 2026-04-29
- 関連: `docs/android-constraints.md`, `docs/permissions.md`, `docs/platform-channels.md`

---

## Context（背景・制約）

タイマーアプリの中核要件:

- **裏で動いている時もアラームを鳴らす**
- **アプリ強制終了後でもアラームを鳴らす**
- **端末スリープ中でもアラームを鳴らす**
- **ロック画面上にアラーム画面を表示する**（要件で確定）
- **複数タイマー同時稼働**

加えて Android 16（API 36）が主ターゲットであり、以下の制約がある:

- Foreground Service の型指定が厳格化、`dataSync` / `mediaProcessing` 型は時間制限付き
- `specialUse` 型は Play Store 審査で正当性説明が必要
- `USE_FULL_SCREEN_INTENT` 権限が Android 14+ で制限（カテゴリ承認 or ユーザー手動許可）
- Doze Mode / App Standby Buckets により長時間バックグラウンド実行は困難
- メーカー独自省電力（Xiaomi / OPPO / Huawei 等）でさらに制約強化

---

## Decision（決定事項）

### 採用方針

**AlarmManager 経由の通知スケジュール + フルスクリーン Intent 通知** 方式を採用する。
**Foreground Service は使用しない**。

### 具体的な実装方針

1. **タイマー Start 時**:
   - 終了絶対時刻（endAt）を計算
   - `flutter_local_notifications` 経由で `setExactAndAllowWhileIdle` 相当のアラームを予約
   - 通知に `fullScreenIntent` フラグを設定
   - DB に endAt を永続化

2. **アプリ起動中**:
   - UI 上で残り時間をリアルタイム表示（`Stream.periodic` 100ms 周期）
   - 表示は揮発、ドメイン状態は離散イベント（start / pause / ringing 化）でしか変わらない

3. **アプリ背景 / 終了時**:
   - アプリは何もしない、OS が予約を保持
   - バッテリー消費ほぼゼロ

4. **アラーム発火時**:
   - OS が通知を発火
   - フルスクリーン Intent で MainActivity を起動（権限あり時）
   - Native → Flutter にイベント送信、AlarmRingingScreen に遷移
   - audioplayers でカスタム音源再生

5. **権限なし時のフォールバック**:
   - `Importance.max` のヘッドアップ通知で代替
   - 通知タップでアラーム画面に遷移

6. **端末再起動後**:
   - `RECEIVE_BOOT_COMPLETED` で Native が起動 → Flutter 経由で再予約

---

## Consequences（結果・トレードオフ）

### 利点

- **Android 16 の Foreground Service 制約を完全回避**
- **Play Store の `specialUse` 型 FGS 審査が不要**
- **バッテリー消費が最小**（裏でアプリが動いていない）
- **端末スリープ中も時計は止まらないため、絶対時刻ベースで正確**
- **実装がシンプル**（FGS 起動・更新ロジック不要）
- **テストが書きやすい**（NotificationScheduler 抽象を通じてロジックが Pure Dart で完結）
- **複数タイマー同時稼働が自然に実現**（各タイマーが独立した OS 予約を持つ）

### 欠点・トレードオフ

- **通知のリアルタイム秒数表示ができない**（OS から見るとアプリは寝ている）
  - 緩和策: アプリ起動中のみ UI で表示。通知は「タイマー実行中」程度の静的表示か非表示で OK
- **フルスクリーン Intent 権限の取得 UX が必要**（Android 14+）
  - 緩和策: Play Store カテゴリ承認で自動付与を狙う、ダメならフォールバックで動作
- **メーカー独自省電力で発火しない端末の存在**
  - 緩和策: バッテリー最適化除外の設定誘導、ただし完全解決は不可
- **`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` 権限の扱いが必要**
  - 緩和策: USE_EXACT_ALARM 優先、ダメなら SCHEDULE_EXACT_ALARM 設定誘導、最終フォールバック `setAndAllowWhileIdle`

### 制約として受け入れる点

- **完全な保証はできない**: Doze Mode やメーカー独自省電力により、極稀に発火しない / 遅延するケースがある
- これは OS の物理的制約であり、どの実装方式を採っても完全解決は不可能
- アプリ側でできるのは、OS の機構を最も適切に使うことと、ユーザーに状況を説明すること

---

## Alternatives Considered（検討した代替案）

### Foreground Service（specialUse 型）

- 利点: 通知に秒数リアルタイム表示が可能、自前で全制御できる
- 欠点:
  - Play Store で specialUse の正当性説明が必要、審査リスク
  - バッテリー消費大
  - メーカー独自省電力でも完全には防げない
  - Android 16 でさらなる制約が予想される
- 却下理由: 「秒数リアルタイム表示」の利益がコストに見合わない。AlarmManager 方式で要件を満たせる

### Foreground Service（dataSync / mediaProcessing 型）

- 利点: Play Store 審査の特別対応が不要
- 欠点: Android 15 で 6h/24h 制限、Android 16 でさらに厳格化
- 却下理由: 長時間タイマー（数時間後のアラーム）で破綻する

### WorkManager + 通知

- 利点: バッテリー優しい
- 欠点: WorkManager の遅延保証が「最低限」レベル、正確なアラーム時刻に発火しない
- 却下理由: タイマー要件と合わない

### 自前 BroadcastReceiver + AlarmManager（flutter_local_notifications を使わず）

- 利点: 完全な制御が可能
- 欠点: 実装量大、テスト困難、`flutter_local_notifications` で十分な要件
- 却下理由: 車輪の再発明、メンテコスト高

### Push 通知（FCM）

- 利点: サーバー側で時刻管理
- 欠点:
  - サーバーインフラが必要（コスト）
  - ネットワーク必須（オフラインで動かない）
  - 通知の遅延がある
- 却下理由: タイマーアプリの本質的要件（オフライン動作）と合わない

---

## 移行可能性

将来「秒数リアルタイム表示」の要件が出た場合、以下の段階的移行が可能:

1. 現方式を維持 + Phase 11 等で Foreground Service `specialUse` 型のオプション機能を追加
2. ユーザー設定で「リアルタイム表示モード」を ON にしたときだけ FGS 起動
3. Play Store 審査用に正当性説明を準備

ただし**現行要件ではこの拡張は不要**。

---

## 関連ドキュメント

- `docs/android-constraints.md`: OS 制約の詳細
- `docs/permissions.md`: 権限取得フロー
- `docs/platform-channels.md`: Native 連携の詳細
