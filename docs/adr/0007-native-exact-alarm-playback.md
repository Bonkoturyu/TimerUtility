# ADR 0007: Exact Alarm の音源再生を Native Foreground Service が所有する

- 状態: Accepted
- 日付: 2026-08-02
- 関連: `docs/android-constraints.md`, `docs/platform-channels.md`, `docs/assets-spec.md`

---

## Context（背景・制約）

通知 Channel の音量は作成後にアプリから変更できず、ユーザーが選択した同梱／取り込み
音源も通知 Channel から直接再生できない。従来は固定通知音を鳴らし、Flutter画面起動後に
3200 ms待って `audioplayers` のループへ切り替えていた。この経路ではExact予約が利用可能でも、
最初の音だけはアプリ内音量と選択音源を反映できない。

一方、長時間のループ再生を `BroadcastReceiver` が所有することはできない。Androidの
バックグラウンド起動制限を考慮すると、任意のinexact発火からForeground Serviceを確実に
開始できる前提も置けない。

## Decision（決定事項）

1. Exact Alarmが利用可能な予約は、Native `AlarmManager` と
   `mediaPlayback` Foreground Serviceを使用する。
2. Serviceは無音の高重要度通知を `startForeground` で表示し、選択音源を予約時刻から
   ループ再生する。音量はアプリ設定の10〜100%を使用し、端末のグローバル音量は変更しない。
3. Exact権限が予約時または再起動後に利用できなければinexact予約へ落とし、固定Channel音と
   3200 ms後のFlutterループという従来経路を維持する。
4. Flutterが前面で満了を先に検知した場合は `ensurePlayback` でNative予約を即時発火させる。
   Nativeセッションがactiveなら `AlarmRingingNotifier` はFlutter再生を開始しない。
5. Stop / SnoozeはNative ServiceとFlutter playerの両方を停止する。
6. BOOT_COMPLETED receiverは未来の予約の再登録だけを行い、Serviceを直接開始しない。

## Consequences（結果・トレードオフ）

- Exact経路は選択音源とアプリ内音量を最初から適用でき、Flutterプロセス停止中も鳴動する。
- inexactフォールバックの最初の固定Channel音はOS所有なので、アプリ内音量の対象外である。
- Native側にも同梱5音源を `res/raw` として配置するため、APK容量と二重管理が増える。
- Manifestに `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_MEDIA_PLAYBACK` とService宣言が必要になる。
- 実機ではExact / inexact、ロック状態、プロセス停止、再起動、取り込み音源を個別に検証する。

## Supersedes

ADR 0003の「Foreground Serviceは使わない」は、カウントダウン表示や常駐処理には引き続き適用する。
ただしExact Alarm発火後のユーザー選択音源ループに限り、本ADRが優先される。

## References

- Exact alarmとForeground Service起動の例外:
  https://developer.android.com/develop/background-work/services/alarms
- Foreground Serviceのバックグラウンド起動制限:
  https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start
- `mediaPlayback` service type:
  https://developer.android.com/develop/background-work/services/fgs/service-types
- Notification Channelのユーザー所有設定:
  https://developer.android.com/develop/ui/compose/notifications/channels
