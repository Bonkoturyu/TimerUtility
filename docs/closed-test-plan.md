# Closed Test Plan (TimerUtility)

作成日: 2026-06-17
対象: Google Play の新規 Personal developer account 向け Production access 申請準備

## 目的

TimerUtility を Production 公開する前に、Google Play Console の closed testing
要件を満たしつつ、Production access 申請で説明できる検証記録を残す。

公式 Help の 2026-06-17 確認結果:

- 対象: 2023-11-13 より後に作成された Personal developer account
- 条件: closed test で最低 12 testers が 14 日連続 opt-in
- 申請時: closed test の内容、テスターの利用状況、得られた feedback、修正内容、
  production readiness を回答する

参照: <https://support.google.com/googleplay/android-developer/answer/14151465>

## 方針

- まず Internal testing でユーザー本人の端末に配信し、AAB / Play App Signing /
  インストール経路を検証する。
- Internal testing が通った AAB を closed testing track に上げる。
- 12 人以上に opt-in URL を配布し、14 日間 opt-out しないよう依頼する。
- 実使用 feedback は全員から必須にしないが、Production access 申請に備え、
  主要機能の確認ログと数件の具体的 feedback を残す。
- テスト中に重要 bug を直した場合は、修正版 AAB を closed testing に再配布し、
  変更内容と確認結果を記録する。

## テスター募集文

```text
TimerUtility の Google Play closed test に協力していただける方を募集しています。

お願いしたいこと:
- Google アカウントで closed test に参加登録する
- 参加後 14 日間はテスト参加を解除しない
- 可能ならアプリを数回起動し、タイマー / アラーム / 世界時計のいずれかを試す
- 気付いた不具合や分かりにくい点があれば GitHub Issues
  (<https://github.com/Bonkoturyu/TimerUtility/issues>) に送る

注意:
- テスト版は Google Play 経由で配布されます
- 個人情報の送信は不要です
- アプリは無料、広告なし、アプリ内課金なしです
```

## テスター向け手順

1. テスター登録に使う Google アカウントを決める。
2. 開発者から受け取った opt-in URL を開く。
3. closed test への参加を承認する。
4. Google Play から TimerUtility をインストールする。
5. 14 日間、closed test 参加を解除しない。
6. 可能な範囲で以下のテスト項目を実施する。
7. feedback がある場合は、スクリーンショットまたは短い文章で報告する。

## 14 日テスト項目

最低限、全項目を全テスターが実施する必要はない。Production access 申請時に
「どの機能をどの程度確認したか」を説明できるよう、担当を分散する。

| 項目 | 内容 | 優先度 |
| --- | --- | --- |
| Install / launch | Play 経由でインストールし、初回起動できる | 必須 |
| Timer | 1 分以内のタイマーを作成し、通知 / 鳴動を確認する | 必須 |
| Alarm | 数分後の指定時刻アラームを作成し、鳴動を確認する | 必須 |
| Lock screen alarm | 可能なら画面ロック中にアラーム画面が出るか確認する | 高 |
| Stopwatch | start / pause / lap / reset を試す | 中 |
| World clock | 都市追加、表示切替を試す | 中 |
| Presets | プリセット選択、管理画面を開く | 中 |
| Settings | テーマ、言語、診断ログトグルを確認する | 中 |
| Reboot restore | 可能なら端末再起動後の timer / alarm 復元を確認する | 高 |
| Accessibility | 文字切れ、見づらい色、操作しづらい箇所を確認する | 中 |

## フィードバック記録テンプレ

| 日付 | テスター | 端末 / Android | 確認項目 | 結果 | 対応 |
| --- | --- | --- | --- | --- | --- |
| YYYY-MM-DD | tester-01 | Pixel 6a / Android 16 | Timer / Alarm | 問題なし | なし |

## Production access 申請用メモ

### About your closed test

- 募集方法:
  - 個人の知人 / 開発者コミュニティ / SNS / GitHub 経由で募集
- テスター数:
  - 12 人以上
- テスト期間:
  - YYYY-MM-DD から YYYY-MM-DD まで
- 14 日連続 opt-in:
  - Play Console 上で条件達成後に Production access を申請

### Tester engagement

- 全テスターに install / launch を依頼した。
- 複数人に Timer / Alarm / Lock screen alarm / World clock の担当を分散した。
- Feedback は GitHub Issue、メール、またはメッセージで収集した。

### Feedback summary

- 重大 crash:
  - なし / あり (詳細)
- Alarm / notification 回帰:
  - なし / あり (詳細)
- UI / wording feedback:
  - なし / あり (詳細)
- 修正した内容:
  - なし / あり (commit / versionCode / 内容)

### Production readiness

- `flutter analyze` / `flutter test` が成功している。
- Play 経由の install と起動を確認している。
- Timer / Alarm / Lock screen alarm / World clock の主要シナリオを確認している。
- Privacy Policy / Data Safety / Content Rating がアプリ挙動と整合している。

## 注意点

- テスターが途中で opt-out すると、そのテスターは 14 日連続条件にカウントされない。
- 一度抜けて再参加しても、合計 14 日ではなく連続 14 日が必要。
- テスターは Google アカウントまたは Google Workspace アカウントが必要。
- Internal testing は closed testing 要件の代替にはならない。
- Production access 承認後の通常アップデートで、同じ 12 人 14 日を毎回やり直す
  要件ではない。ただし別アプリを Production 公開する場合は、そのアプリで再度
  closed test 要件が発生する可能性が高い。
