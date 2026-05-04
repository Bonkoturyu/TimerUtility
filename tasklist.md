# tasklist.md

短期タスク（直近の作業項目）を管理するファイル。
中長期の Phase 管理は `BACKLOG.md` を参照すること。

本ファイルは「今日〜数日以内に着手するもの」「進行中のもの」のみを扱う。
完了タスクは適宜削除し、肥大化させない。

---

## 凡例

- `[ ]` 未着手
- `[~]` 進行中
- `[x]` 完了（次回更新時に削除候補）
- `[!]` ブロック中（理由を併記）

---

## 進行中

なし。Phase 9.5 は実機検証完了 (2026-05-04、Pixel 6a / Android 16 で
4 シナリオ確認済、F-1 = PR #12 / F-3 = PR #11 / F-4 = PR #13 で fix
反映済、F-1 セクションは PR #12 マージ時に削除済)。次は Phase 10
(端末再起動後の復元) に着手予定。

---

## Follow-up タスク (Phase 9.5 派生)

### F-4. cold-start FSI 後の戻るキーでアプリ終了 + Recent 二重起動 ✅ 完了

#### F-4 修正内容 (B + C 案併用、2026-05-04)

実機検証 (Pixel 6a / Android 16、2026-05-04) シナリオ 4 で観測した
2 種類の症状 (戻るキー押下でアプリ終了 / Recent に task 2 つ並ぶ) に
Native 側 + Flutter 側の両面で対処:

- **B 案 (Native)**: [`AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml)
  の MainActivity を `launchMode="singleTop"` → `"singleTask"` に強化、
  併せて `taskAffinity=""` 属性を削除。`taskAffinity=""` は Phase 1
  雛形に紛れ込んだまま放置されており、同一パッケージの Activity を
  別 task root として扱わせる副作用 (Recent 二重表示の主因) があった。
  デフォルト affinity (`com.bonkotu.timer.timer_utility`) に戻し、
  ランチャー起動 / 通知 cold-start / FSI のいずれの経路でも 1 task に
  収束させる。
- **C 案 (Flutter)**: [`alarm_ringing_screen.dart`](lib/presentation/screens/alarm_ringing_screen.dart)
  `_leaveAlarmScreen` の cold-start fallback (`!context.canPop()`) を
  `context.go('/alarms' or '/timer')` 1 段スタックから、`router.go('/')` →
  `router.push(dest)` の Home → list の 2 段スタックに変更。これで
  list 画面で戻るキーを押すと Home → アプリ終了の順に正しく辿れる。
- **回帰テスト**: [`alarm_ringing_screen_test.dart`](test/presentation/screens/alarm_ringing_screen_test.dart)
  に「cold-start: Stop rebuilds Home → list 2-stack so back returns to home」
  テスト 1 件追加。`initialLocation = '/alarm-ringing'` の cold-start 状態で
  起動 → Stop → `GoRouter.pop()` で home-stub に戻れることを検証 (PR #13
  Copilot review 反映)。

#### F-4 実機検証 (Pixel 6a / Android 16、2026-05-04 完了)

- [x] シナリオ 4 再現確認: cold-start FSI → AlarmRingingScreen → 停止 →
      list 表示 → 戻るキー → **Home に戻る** (アプリ終了しない)
- [x] Recent (□) 表示が 1 task のみ (2 つ並ばない)
- [x] 副作用なし確認:
  - 通常起動 (ランチャー) → 動作不変
  - warm-launch FSI (アプリ前面/背景) → 既存フロー通り
  - lock-screen FSI → keyguard override が引き続き効く
  - 通知タップ (warm) → AlarmRingingScreen → 停止 → 元画面に戻る
    (`context.canPop()` パス、Home 経由しない)

### F-3. permission UX バグ修正 (実機検証で発覚) ✅ 完了

実機検証 (Pixel 6a / Android 16、2026-05-04) でシナリオ 1 が再現せず、
原因調査の結果以下 2 段の問題が判明 → PR #11 に追加 commit で対応:

- (a) AlarmListScreen が `permissionNotifierProvider.refresh()` を呼ばず
  state が `unknown` のまま → `_scheduleAt` で `useExact = false` →
  `inexactAllowWhileIdle` schedule で発火が大幅遅延 (1 分後の発火が
  起きない実機事象の主因)
- (b) AlarmListScreen に permission banner が無く、ユーザは権限不足を
  画面上で気付けない (TimerListScreen にしか banner が無かった)

#### F-3 修正内容

- [PermissionBanners](lib/presentation/widgets/permission_banners.dart)
  を共通 widget として切り出し (元は TimerListScreen の private クラス)
- [AlarmListScreen](lib/presentation/screens/alarm_list_screen.dart) を
  `ConsumerStatefulWidget` 化、`initState` の microtask + `didChangeAppLifecycleState(resumed)` で
  `permissionNotifierProvider.refresh()` を呼ぶ TimerListScreen と
  同じパターンを移植、`PermissionBanners` を body 上部に配置
- [AlarmCollectionNotifier._scheduleAt](lib/application/alarm_collection_notifier.dart)
  を内部で `_scheduleAtAsync` に分離し、`unknown` のとき先に `await
  refresh()` してから exact/inexact 判定 (画面遷移が高速な場合の race 対策)
- alarm_list_screen_test.dart に banner 表示 / 非表示の Widget Test
  2 件追加 (denied 状態 + 全 granted 状態)

### F-2. auto-request-copilot-review.yml の silent fail 対策 → workflow 廃止 ✅ 完了

優先度: 低 (手動で `gh pr edit N --add-reviewer @copilot` 実行で復旧可能)

#### F-2 背景

PR #11 で Action (`auto-request-copilot-review.yml`) が exit 0 success
で完了したものの、`gh api repos/.../pulls/11/requested_reviewers` 結果は
`{users: [], teams: []}` で **silent fail** していた。手動で同じコマンドを
実行すると正常に追加された。

#### F-2 調査結果 (PR #15 で実施、2026-05-04)

第 1 段で silent fail 検出ロジック (`set -euo pipefail` + API 読み返し
による exit 1) を入れて PR #15 で再現確認した結果:

- `gh pr edit --add-reviewer @copilot` は内部で REST `POST /pulls/N/requested_reviewers`
  を叩く。このエンドポイントは **user / team のみ受け付け、bot (Copilot) は
  silently 無視される** (GitHub maintainer 公式回答:
  [community#157751](https://github.com/orgs/community/discussions/157751))
- 手動 (個人 PAT) で動くのは `gh` CLI が PAT 認証時に Copilot 専用の
  GraphQL `requestReviews(input: { botIds: [...] })` 経路を使うため
  ([community#186152](https://github.com/orgs/community/discussions/186152))
- `secrets.GITHUB_TOKEN` でこの GraphQL 経路を叩くには追加の特別スコープが
  必要で、`pull-requests: write` だけでは不足。公式 docs にも
  「`pull-requests: write` で reviewer 追加可」の明記なし
- 公式の推奨自動化経路は **Settings → Copilot → Code review → 自動レビュー
  有効化** ([Configure automatic review](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/configure-automatic-review))

#### F-2 最終対応 (2026-05-04)

PAT 管理コスト + GraphQL 経路の複雑さに対し、公式 Settings 自動レビュー
機能の方が運用コストゼロなため後者に切替:

- `.github/workflows/auto-request-copilot-review.yml` を **削除**
- ユーザ手動作業: GitHub Settings → Copilot → Code review で
  「Automatic code review」を有効化 (PR open 時に Copilot が自動 reviewer
  として付く公式機能)
- 過去 PR #14 等で実際に Copilot review が走っていたのは、自動レビュー
  機能が裏で部分的に効いていたため (workflow 経由ではなかった可能性高)

#### F-2 リリース時 caveats

- Free private repo の Settings 自動レビューがどこまで動くかは要実機確認。
  もし無効化されていた場合は、F-2 を再オープンして PAT 化 or GraphQL
  経路への書き換えを再検討

---

## Phase 9.5 実装ログ (2026-05-03 着手 → 2026-05-04 実装完了)

ブランチ: `feat/phase-9-5-scheduled-alarm` (PR #10) → 残作業を main に直接 commit
参照: BACKLOG.md L359-437 / docs/adr/0005-alarm-vs-timer-separation.md /
docs/domain-model.md L355-436 / docs/state-management.md L84/198-215

### Plan (Phase 8/9 のレイヤー単位 commit パターン踏襲)

各レイヤー完了で `flutter analyze` + `flutter test` 緑を確認 → commit。

1. **Domain 層** (lib/domain/alarm/)
   - `day_of_week.dart` (Pure Dart enum、`DateTime.weekday` と互換マッピング)
   - `alarm_repeat.dart` (sealed: `AlarmRepeatOnce` / `AlarmRepeatWeekly(Set<DayOfWeek>)`) + Unit Test
   - `alarm_entity.dart` (freezed、domain-model.md L362-373 の定義に従う)
   - `alarm_service.dart` (`Clock` 注入、`nextFireAt` / `advanceAfterFire` / `snoozeUntil`) + Unit Test
   - `exceptions.dart` (`AlarmNotFoundException` / `MaxAlarmCountExceededException`
     / `InvalidAlarmRepeatException` / `InvalidSnoozeMinutesException`)
   - `lib/domain/ports/alarm_repository.dart` (`add` / `update` / `delete` / `findById` / `findAll`)

2. **Infrastructure 層**
   - `app_database.dart` に `Alarms` テーブル追加 (schemaVersion 2 → 3 + onUpgrade)
   - `alarm_mapper.dart` (`AlarmEntity ⇔ AlarmRow / AlarmsCompanion`、
     `AlarmRepeat` は専用列 `repeatKind` (text) + `repeatDaysBitmask` (int) で永続化)
   - `drift_alarm_repository.dart` + Unit Test (in-memory)

3. **Application 層**
   - `alarm_repository_provider.dart` (override-required、main.dart で wire)
   - `alarm_service_provider.dart`
   - `alarm_collection_notifier.dart` + Unit Test
     - `load` / `create` / `update` / `toggle(id)` / `delete(id)` /
       `onFiredStop(id)` / `onFiredSnooze(id)`
     - enabled 化 / 編集時 → `nextFireAt` → `NotificationScheduler.schedule(payload: 'alarm:<id>')`
     - disabled / 削除時 → `cancel`
     - 鳴動 → 停止 → `advanceAfterFire` + 永続化 + 次回 schedule
     - 鳴動 → スヌーズ → `snoozeUntil` + schedule

4. **AlarmRingingNotifier 両用化 + main.dart payload 分岐**
   - `AlarmRingingNotifier.start` の `timerId` パラメータを `sourceId` 概念で扱い、
     payload prefix `timer:<id>` / `alarm:<id>` で起動元判別
   - `main.dart` の `onNotificationTap` で payload prefix を解析、
     alarm の場合は AlarmRingingScreen に alarm モードで遷移
   - `AlarmRingingScreen` の Stop / Snooze ハンドラで Timer / Alarm 分岐
   - 既存 Timer 由来のテストは全パス維持 (regression)

5. **Presentation 層**
   - `alarm_list_screen.dart` (一覧 + ON/OFF トグル + FAB) + Widget Test
   - `alarm_edit_screen.dart` (TimePicker + 曜日チップ + ラベル + 音源 + スヌーズ分) + Widget Test
   - `weekday_selector.dart` (multi-select 曜日チップ) + Widget Test
   - go_router に `/alarms` / `/alarms/edit/:id?` 追加
   - HomeScreen に Alarm 導線を追加 (Stopwatch / Timer / Alarm の 3 本柱)

6. **l10n**
   - `app_ja.arb` / `app_en.arb` に必要キー追加 (画面名、ラベル、空表示、曜日略称等)
   - `docs/translations.md` に新規キーをミラー

7. **docs 更新**
   - `docs/architecture.md` のディレクトリ構造図に `lib/domain/alarm/` 追記
   - 実装で乖離が出た部分があれば `docs/domain-model.md` に追記

### 自動停止ポイント

- pubspec.yaml / AndroidManifest / Native の編集が必要と判断したとき
- Drift schemaVersion bump で migration ロジックに不安が残るとき
- 100 行超の新規生成タイミング (節目で設計レビュー)
- 各レイヤー commit 完了時 (進捗報告)
- 全 7 ステップ完了 → 実機検証 (BACKLOG L420-424、4 シナリオ) 直前で停止

### 着手前 status check (2026-05-04, PR #10 マージ後)

PR #10 (b90c819) で Step 1〜5d までマージ済。実装ファイル直接確認の結果:

- **Step 1 Domain**: ✅ alarm_entity / alarm_repeat / alarm_service / day_of_week /
  time_of_day_value / exceptions すべて実装済 + Unit Test 完備
- **Step 2 Infrastructure**: ✅ drift_alarm_repository.dart + Drift schema migration 済
- **Step 3 Application**: ✅ alarm_collection_notifier.dart (create/update/toggle/delete/
  onFiredStop/onFiredSnooze) + alarm_repository_provider + alarm_service_provider
- **Step 4 AlarmRingingNotifier 両用化 + payload 分岐**: ✅ 完全実装済
  - [alarm_ringing_notifier.dart](lib/application/alarm_ringing_notifier.dart) に
    `AlarmSource` enum + `currentSource` フィールド追加済
  - [alarm_ringing_screen.dart](lib/presentation/screens/alarm_ringing_screen.dart) で
    `_parsePayload` (`timer:` / `alarm:` プレフィックス) + Stop / Snooze の
    AlarmCollectionNotifier 委譲済 (`onFiredStop` / `onFiredSnooze`)
  - [main.dart](lib/main.dart) の `onNotificationTap` / cold-launch 両 path で
    payload を queryParameter に詰めて遷移する配線済
- **Step 5 Presentation**: 一部済
  - ✅ alarm_edit_screen.dart / weekday_selector.dart / alarm_delete_confirm_dialog.dart
  - ❌ **alarm_list_screen.dart** 未実装
  - ❌ **go_router の `/alarms` / `/alarms/edit/:id?` ルート未配線** (main.dart で
    `/alarms` の grep 0 ヒット確認)
  - ❌ **HomeScreen の Alarm 導線未追加** (現状 Stopwatch / Timer の 2 ボタンのみ)
- **Step 6 l10n**: 編集画面用キー (alarmEdit*) は追加済、一覧画面用 (alarmList*) は未追加
- **Step 7 docs 更新**: docs/architecture.md のディレクトリ構造図に
  `lib/domain/alarm/` 未追記

### 残作業の commit 計画 (実施結果)

Step 4 が既に完了済なため、当初 3 commit 計画を 2 commit に圧縮:

1. **Commit 1** (86f8847): AlarmListScreen + go_router 配線 + HomeScreen 導線 +
   ARB (alarmList* / homeOpenAlarm) + Widget Test 8 件追加 → 384 テストパス
2. **Commit 2**: docs 更新 (architecture.md ディレクトリ構造図) +
   tasklist/BACKLOG の Phase 9.5 完了マーク (実機検証だけ未完で残す)

Commit 2 完了後に停止し、実機検証 4 シナリオ (BACKLOG L420-424) はユーザに依頼。

---

## Phase 9 完了内容（2026-05-02）

プリセット機能 + テンプレート差し替え（Plan A / Plan P / Plan Y）+ 削除確認ダイアログ +
音源変更 UI を実装。Phase 8 のレイヤー単位コミットパターンを踏襲して 5 commits でレイヤーを
積み上げ、その後フィードバック反映 4 commits で UX 微調整した。

### 実装サマリ

- Domain: Preset / PresetCollection / PresetService / PresetTemplates（3 プロファイル）/
  preset_exceptions / PresetRepository / UserPreferences ports
- Infrastructure: Drift schemaVersion 1 → 2、Presets テーブル + onCreate/onUpgrade で
  general profile を atomic seed、PresetMapper、DriftPresetRepository、
  SharedPreferencesUserPreferences
- Application: PresetCollectionNotifier（keepAlive、`replaceFromTemplate(profileId, mode)`、
  ReplaceTemplateResult で discardedCount 返却）、TimerCollectionNotifier に
  `changeSound(id, soundId)` 追加
- Presentation: PresetSelectSheet（FAB 経由 2x3 GridView）/ PresetEditSheet /
  PresetDeleteConfirmDialog / SoundSelectSheet / PresetManageScreen / TimerListScreen 編集
- ARB: 約 27 キー追加（plural ラベル + 音源 sheet + テンプレート差し替え）
- 実機検証 (Pixel 6a / Android 16): 10 シナリオすべて OK
- 計 275 テストパス、analyze 緑

### 実機検証フィードバック反映（合計 6 件、4 commits）

1. **テンプレート差し替えダイアログ**: 追加 = FilledButton、上書き = error 色 TextButton に
   強調入れ替え。実機で「追加」意図のタップが「上書き」に流れた事故への対処
2. **プリセット管理 リスト下端 padding 96 → 128 dp**: FAB と最下カードの右端 Delete
   ボタンが至近で被っていた件
3. **各プリセットカードに ♪ IconButton 追加**: TimerCard と同位置（Edit と Delete の間）、
   右上の音源 Chip は表示専用として維持
4. **音源 Chip の Material ink 起因の AppBar チラつき**: `IgnorePointer` で囲んで
   gesture を ListView に流す
5. **ラベル指定時に時間が見えない件**: プリセット管理カードはサブタイトル併記、
   タイマー一覧カードは duration の上に小さくラベル
6. **soundId 'urgent' → 'warning' に統一**: pre-release 段階のため互換性配慮なしで
   i18n キー / soundId / アセットファイル名 / Pomodoro テンプレート / テスト 全て更新

### 仕様変更ログ

- DurationPicker 内に音源 dropdown を統合する当初プランは取り下げ。
  CupertinoPicker と Dropdown の hit-test 干渉が発生したため、カスタム時間作成時は
  カタログ既定音 → カードの ♪ ボタンで後から変更、という UX に変更。実機で
  こちらの方が直感的との確認済

### 関連 docs 追加・更新

- `docs/translations.md` 新規（ARB 全キー × ja / en の対訳ミラー）
- `docs/assets-spec.md` / `docs/oss-publishing-notes.md` /
  `assets/sounds/LICENSES.md` を `alarm_warning.mp3` に追従

---

## Phase 9 Plan（着手前確認用、2026-05-02）

### 事前確定事項（ユーザ確認済、再確認不要）

| # | 項目 | 決定 |
| --- | --- | --- |
| 1 | Preset Entity フィールド | id (uuid) / label / duration / soundId / createdAt |
| 2 | Drift schema migration | schemaVersion 1 → 2、Presets 新設、既存 Timers 不変、migration 内で seed 6 件 atomic insert（案 X） |
| 3 | プリセット選択 UI 配置 | 案 A: FAB → bottom sheet（6 チップ + 区切り + カスタムボタン） |
| 4-1 | 削除確認 dialog | ON、「次から確認しない」チェック + SharedPreferences 保存 |
| 4-2 | 空状態表示 | 案 a: テキスト「プリセットがありません。+ ボタンから追加するか、テンプレートから差し替えてください」 |
| 4-3 | 管理画面導線 | 案 P: TimerListScreen AppBar overflow メニューに「プリセット管理」 |
| 4-4 | テンプレート差し替えラベル | 候補 1: "テンプレートから差し替え" / "Replace from template" |
| 5 | 件数上限 | 10 件（TimerCollection と同じ） |
| 7 | 切替 UX | 案 Y: 管理画面 overflow メニューから 3 プロファイル切替、3 択 dialog |
| 7 | 初期 seed | a) 一般用: 30s / 1m / 3m / 5m / 10m / 30m |
| 7 | label ローカライズ | ARB plural 3 キー + presentation 層フォーマッタ |
| 7 | 定数配置 | `lib/domain/timer/preset_templates.dart`（Pure Dart） |
| 7 | プロファイル | 一般用 (default), 料理向け (gentle), Pomodoro (urgent) |

### 着手前に必要な依存追加（ユーザ承認必須）

- [ ] `flutter pub add shared_preferences`（または `pubspec.yaml` 手動編集）を**ユーザに実行してもらう**
  - 理由: 削除確認 dialog の「次から確認しない」状態を端末ローカルに保存するため
  - **Auto 側からは pubspec.yaml を編集しない**
  - 完了後、その旨を Auto セッションで通知してもらえれば実装着手する

### A. 管理画面の細かい UI レイアウト案

#### A-1. プリセット bottom sheet（FAB タップで開く）

```text
┌──────────────────────┐
│ プリセットから選択   │  ← presetSheetTitle
├──────────────────────┤
│ [30秒] [1分] [3分]   │
│ [5分] [10分] [30分]  │  ← 2x3 GridView、各タップで
│                      │     即タイマー作成（音源は
│                      │     プリセットの soundId 使用）
├──────────────────────┤
│ [カスタム時間で作成] │  ← FilledButton.tonal、タップで
└──────────────────────┘     既存 DurationPicker（音源
                             選択付き）モーダルへ遷移
```

実装: `lib/presentation/widgets/preset_select_sheet.dart`

#### A-2. プリセット編集モーダル（管理画面の追加 / 編集）

縦並びのフォーム、`showModalBottomSheet<Preset>` で開いて結果を pop:

```text
┌──────────────────────┐
│ プリセットを追加 / 編集 │
├──────────────────────┤
│ ラベル (任意)        │
│ [TextField]          │
├──────────────────────┤
│ 時間                 │
│ [HH:MM:SS ホイール]  │  ← DurationPicker のホイール部分を
│                      │     再利用（StatelessWidget 化して
│                      │     ピッカー部分を切り出す）
├──────────────────────┤
│ 音源                 │
│ [Dropdown ▼]         │  ← AlarmSoundCatalog.all から動的生成
│                      │     項目数に応じて自動スクロール
├──────────────────────┤
│ [キャンセル] [保存]  │
└──────────────────────┘
```

実装: `lib/presentation/screens/preset_edit_sheet.dart`

#### A-3. プリセット管理画面

```text
┌──────────────────────┐
│ プリセット管理   [⋮] │  ← overflow に「テンプレートから差し替え」
├──────────────────────┤
│ ┌──────────────────┐ │
│ │ 30秒 [標準]      │ │  ← Card、タップで編集モーダル、
│ │ [編集] [削除]    │ │     右下に編集 / 削除アイコン
│ └──────────────────┘ │
│ ┌──────────────────┐ │
│ │ 1分 [標準]       │ │
│ │ [編集] [削除]    │ │
│ └──────────────────┘ │
│ ...                  │
│                  [+] │  ← 追加 FAB
└──────────────────────┘
```

実装: `lib/presentation/screens/preset_manage_screen.dart`

#### A-4. DurationPicker への音源ドロップダウン追加

ホイール 3 本の**下**、Cancel / Confirm ボタンの**上**に音源選択 Dropdown を追加。

```text
┌──────────────────────┐
│ カスタム時間で作成   │
├──────────────────────┤
│ [HH] [MM] [SS] ホイール│
├──────────────────────┤
│ 音源: [Dropdown ▼]   │  ← New
├──────────────────────┤
│ [キャンセル] [決定]  │
└──────────────────────┘
```

戻り値を `Duration` から `({Duration duration, String soundId})` の record に変更（呼び出し側の `_onAddTap` も追従）。

#### A-5. タイマーカードに音源変更アイコン

既存カードの「Delete」ボタンの**前**に `IconButton(icon: Icons.music_note)` を追加。タップで音源選択 bottom sheet（RadioListTile ベース）を開く。選択結果は `TimerCollectionNotifier.changeSound(id, soundId)`（新メソッド）で適用。

#### A-6. 音源選択 UI のスケーラビリティ

- DurationPicker / 編集モーダル: `DropdownButton<String>` で `AlarmSoundCatalog.all` を `map((s) => DropdownMenuItem(value: s.id, child: Text(...)))` で動的生成
- 既存カードの音源変更 sheet: `ListView.builder` + `RadioListTile`、項目数に応じて自動スクロール
- ハードコード 3 件は禁止、すべて `AlarmSoundCatalog.all.map(...)` 経由

### B. ARB キー一覧（推定 27 キー、ja / en 両方追加予定）

| key | ja | en | 用途 |
| --- | --- | --- | --- |
| presetSheetTitle | プリセットから選択 | Choose preset | bottom sheet タイトル |
| presetSheetCustomButton | カスタム時間で作成 | Create with custom time | bottom sheet 内のカスタムボタン |
| presetManageAppBarTitle | プリセット管理 | Manage presets | 管理画面 AppBar |
| presetManageMenuOverflow | プリセット管理 | Manage presets | TimerList の overflow メニュー項目 |
| presetManageEmptyHint | プリセットがありません。+ ボタンから追加するか、テンプレートから差し替えてください。 | No presets yet. Tap + to add one or replace from a template. | 管理画面の空状態 |
| presetManageReplaceTemplate | テンプレートから差し替え | Replace from template | 管理画面 overflow メニュー項目 |
| presetEditTitleNew | プリセットを追加 | Add preset | 編集モーダル（新規時） |
| presetEditTitleEdit | プリセットを編集 | Edit preset | 編集モーダル（編集時） |
| presetEditLabelHint | ラベル（任意） | Label (optional) | TextField placeholder |
| presetEditDurationLabel | 時間 | Duration | section header |
| presetEditSoundLabel | 音源 | Sound | section header |
| presetEditCancel | キャンセル | Cancel | モーダルボタン |
| presetEditSave | 保存 | Save | モーダルボタン |
| presetDeleteConfirmTitle | このプリセットを削除しますか？ | Delete this preset? | 確認 dialog タイトル |
| presetDeleteConfirmDontAsk | 次から確認しない | Don't ask again | チェックボックスラベル |
| presetDeleteConfirmDelete | 削除 | Delete | dialog 削除アクション |
| presetDeleteConfirmCancel | キャンセル | Cancel | dialog キャンセルアクション |
| presetTemplateReplaceTitle | テンプレートから差し替え | Replace from template | プロファイル選択 dialog タイトル |
| presetTemplateReplaceProfileGeneral | 一般用 | General | プロファイル名 |
| presetTemplateReplaceProfileCooking | 料理向け | Cooking | プロファイル名 |
| presetTemplateReplaceProfilePomodoro | Pomodoro | Pomodoro | プロファイル名 |
| presetTemplateReplaceMode | 既存のプリセットがあります。どうしますか？ | You already have presets. What would you like to do? | 3 択 dialog 説明 |
| presetTemplateReplaceModeOverwrite | 上書き | Overwrite | 3 択 dialog アクション |
| presetTemplateReplaceModeAppend | 追加 | Append | 3 択 dialog アクション |
| presetTemplateReplaceModeCancel | キャンセル | Cancel | 3 択 dialog アクション |
| presetTemplateReplaceLimitWarning (plural) | プリセット件数の上限（{max} 件）を超えたため、{discarded} 件が追加されませんでした | {discarded, plural, one{1 preset was skipped} other{{discarded} presets were skipped}} because the limit ({max}) was reached | SnackBar 警告（appendで上限超過時） |
| presetLabelSeconds (plural) | {count}秒 | {count, plural, =1{1 second} other{{count} seconds}} | seed プリセット表示 |
| presetLabelMinutes (plural) | {count}分 | {count, plural, =1{1 minute} other{{count} minutes}} | seed プリセット表示 |
| presetLabelHours (plural) | {count}時間 | {count, plural, =1{1 hour} other{{count} hours}} | seed プリセット表示 |
| timerCardSoundChange | 音源を変更 | Change sound | カード音源アイコンの tooltip |
| timerSoundSheetTitle | 音源を選択 | Choose sound | 音源選択 bottom sheet タイトル |
| timerSoundDefault | 標準 | Default | 音源表示名（'default'） |
| timerSoundGentle | やさしい | Gentle | 音源表示名（'gentle'） |
| timerSoundUrgent | 緊急 | Urgent | 音源表示名（'urgent'） |

### C. 新規ファイル予定

#### Domain 層

- `lib/domain/timer/preset.dart`（Entity, freezed）
- `lib/domain/timer/preset_collection.dart`（集約ルート、最大 10 件、add/update/remove）
- `lib/domain/timer/preset_templates.dart`（3 プロファイル定数 Pure Dart）
- `lib/domain/timer/preset_exceptions.dart`（`MaxPresetCountExceededException` / `PresetNotFoundException`）
- `lib/domain/ports/preset_repository.dart`
- `lib/domain/ports/user_preferences.dart`（`shared_preferences` の抽象、`getBool` / `setBool`）

#### Infrastructure 層

- `lib/infrastructure/database/app_database.dart` 編集（Presets テーブル追加 + schemaVersion 2 + onUpgrade）
- `lib/infrastructure/database/mappers/preset_mapper.dart`
- `lib/infrastructure/database/drift_preset_repository.dart`
- `lib/infrastructure/preferences/shared_preferences_user_preferences.dart`（adapter）

#### Application 層

- `lib/application/preset_repository_provider.dart`
- `lib/application/preset_collection_notifier.dart`
- `lib/application/user_preferences_provider.dart`

#### Presentation 層

- `lib/presentation/screens/preset_manage_screen.dart`
- `lib/presentation/widgets/preset_select_sheet.dart`
- `lib/presentation/widgets/preset_edit_sheet.dart`
- `lib/presentation/widgets/preset_delete_confirm_dialog.dart`
- `lib/presentation/widgets/preset_label_formatter.dart`（formatPresetLabel）
- `lib/presentation/widgets/sound_select_sheet.dart`
- `lib/presentation/widgets/duration_picker.dart` 編集（音源 dropdown 追加 + 戻り値変更）
- `lib/presentation/screens/timer_list_screen.dart` 編集（FAB の挙動変更 / overflow メニュー / カード音源アイコン）

#### ルーティング

- `lib/main.dart` 編集（`/presets` ルート追加）

#### ARB

- `lib/l10n/app_ja.arb` / `app_en.arb` 編集（27 キー追加）

### 進め方

Phase 8 のパターンを踏襲、層単位でコミット:
1. domain 層（Preset / PresetCollection / preset_templates / preset_exceptions / ports）+ Unit Test
2. infrastructure 層（Drift schema bump + migration + mapper + repository + shared_preferences adapter）+ Unit Test
3. application 層（PresetCollectionNotifier + UserPreferences provider）+ Unit Test
4. presentation 層（管理画面 + bottom sheet + 編集モーダル + DurationPicker 拡張 + カード変更）+ Widget Test
5. main.dart 配線
6. flutter analyze + flutter test 緑、層単位コミット

### Plan 承認のお願い

- A 案（UI レイアウト 6 種）: OK / 修正案
- B 案（ARB 27 キー）: OK / 訳の修正
- shared_preferences 追加: ユーザ側で `flutter pub add shared_preferences` を実行 → 完了通知をお願いします

---

## Phase 8.5 follow-up: アラーム再鳴動時の二重音修正（2026-05-02）

スヌーズ後の再鳴動時、heads-up 通知 → タップで AlarmRingingScreen に遷移する経路で、
OS チャンネル音 (alarm-stream の `RawResourceAndroidNotificationSound`) と
audioplayers のループ再生が重なって聞こえる問題を修正。

### 経緯

1. **Option A 試行**: [AlarmRingingNotifier.start()](lib/application/alarm_ringing_notifier.dart) の `unawaited` を `await` 化して cancel→play の順序を保証。実機では二重音残留 (Pixel 6a / Android 16)。
2. **Option B 試行**: チャンネルの `playSound: false` でチャンネル音を切り audioplayers に一本化。FSI 経由は OK だが、heads-up 経路 (画面 ON で他アプリ操作中 / ホーム画面待機 / スヌーズ後再鳴動) で OS が FSI を抑制するため**音なし**になる UX 劣化が判明。
3. **Option C 採用**: チャンネルは `playSound: true` に戻し、`start()` で `cancel → 500ms 遅延 → play` の 3 段順序にして OS 通知音が完全に止まってから audioplayers が引き継ぐ動作に。

### 変更内容

- [x] [alarm_ringing_notifier.dart](lib/application/alarm_ringing_notifier.dart): `start()` を `await cancel → await Future.delayed(500ms) → await play` に変更。why コメント追記
- [x] [flutter_local_notification_adapter.dart](lib/infrastructure/notification/flutter_local_notification_adapter.dart): Channel id を `timer_alarm_v4` → `timer_alarm_v6` にバンプ (途中で v5 に下げて Option B を試したため)、`_legacyTimerAlarmChannelIds` に v4/v5 を追加。`playSound: true` + `RawResourceAndroidNotificationSound('alarm_default')` + `audioAttributesUsage: alarm` の v4 構成を維持。クラスドキュメントに Option B 試行と Option C 着地の経緯を記録
- [x] [alarm_ringing_screen_test.dart](test/presentation/screens/alarm_ringing_screen_test.dart): 全 7 シナリオに `await tester.pump(Duration(milliseconds: 600))` を挿入して 500ms 遅延の Future を完了させる
- [x] flutter analyze: No issues found
- [x] flutter test: 180 / 180 passed
- [x] 実機検証 (Pixel 6a / Android 16、2026-05-02): 6 シナリオすべて単音、二重音解消
  - 初回 foreground (自動遷移) / 初回 background (heads-up タップ) / 初回 FSI (ロック画面) /
    強制終了 → ロック画面 / 強制終了 → ホーム画面待機 / **スヌーズ後再鳴動 (heads-up タップ)**

### 残タスク

- [x] [docs/android-constraints.md](docs/android-constraints.md) の「Phase 6 実機検証で見つかって修正した問題」セクションに本件を追記 (Phase 8.5 follow-up サブセクション追加)

---

## ローカライズ土台導入完了内容（2026-05-02）

中国語簡体字 / 繁体字 / 韓国語までの拡張可能性を担保する設計を採用。

- [x] `pubspec.yaml`: `flutter_localizations` (SDK) + `intl` 追加、
  `flutter:` 配下に `generate: true` 追加
- [x] `l10n.yaml` 新規 (テンプレート ja、出力先 lib/l10n)
- [x] `lib/l10n/app_ja.arb` / `app_en.arb` 新規 (約 50 キー、ICU plural
  含む)
- [x] `lib/main.dart`: `localizationsDelegates` / `supportedLocales` 設定。
  `kEnableExperimentalLocales` (compile-time flag) で zh / zh-Hant / ko
  を社内ビルドのみ有効化可能
- [x] `lib/domain/timer/alarm_sound.dart`: `displayName` フィールドを削除
  (Pure Dart 制約遵守)。表示名は presentation 層で `AppLocalizations`
  経由で解決
- [x] `lib/domain/timer/alarm_sound_catalog.dart`: 同上、id + assetPath のみに
- [x] `lib/presentation/screens/timer_list_screen.dart`: AppBar / FAB /
  empty hint / カード内の表示・状態 chip・各ボタン / 上限 SnackBar /
  権限バナー 3 種すべて ARB 経由に置換
- [x] `lib/presentation/screens/alarm_ringing_screen.dart`: AppBar /
  Time's up! / Stop / Snooze / モーダル内タイトル + 分単位 + キャンセル
  すべて ARB 経由に置換
- [x] `lib/presentation/screens/stopwatch_screen.dart`: AppBar / Start /
  Pause / Resume / Lap / Reset すべて ARB 経由に置換
- [x] `lib/presentation/widgets/duration_picker.dart`: タイトル / 時 /
  分 / 秒 / キャンセル / 決定すべて ARB 経由に置換
- [x] `lib/presentation/widgets/lap_list.dart`: 空表示 / Lap N / Split /
  Total すべて ARB 経由に置換
- [x] `lib/main.dart` HomeScreen: appTitle / Open Stopwatch /
  Open Timer すべて ARB 経由に置換
- [x] テストハーネスに `localizationsDelegates` + 固定 Locale を追加
  (lap_list_test / stopwatch_screen_test は en、duration_picker_test /
  alarm_ringing_screen_test / timer_list_screen_test は ja)
- [x] `test/domain/timer/alarm_sound_catalog_test.dart`: displayName
  削除に追従
- [x] flutter analyze: No issues found
- [x] flutter test: 180 / 180 passed
- [x] dart format で整形済み
- [x] 通知本文の i18n 対応 (2026-05-03、PR #5): NotificationStringsNotifier +
      WidgetsBindingObserver.didChangeLocales で locale 切替追従、
      rescheduleAllRunning で in-flight banner も上書き
- [ ] 通知 channel 名の i18n 対応 (Phase 11)
- [ ] 設定画面での手動切替 UI (Phase 11)
- [ ] 中韓 ARB の本格翻訳 (Phase 11)

`docs/oss-publishing-notes.md` のローカライズ言語ポリシー記載は今後 Phase 11
着手時にまとめて更新する。

---

## Phase 8 Plan（着手前確認用、2026-05-01）

### 事前確定事項（ユーザー確認済）

| # | 項目 | 決定 |
| --- | --- | --- |
| 1 | 同時稼働上限 | **10 本**（`MaxTimerCountExceededException`） |
| 2 | `/timer` ルート | **一覧画面に置換**、単一画面 (`TimerScreen`) は廃止 |
| 3 | Provider 構造 | `timerNotifierProvider`（単一）廃止、`timerCollectionNotifierProvider` に統一。docs/state-management.md の `timerNotifierProvider(TimerId)` family 案も廃止（docs 反映時に削除提案） |
| 4 | 復元時の過去タイマー | `endAt < now` の running は **completed 扱い + `NotificationScheduler.show()` で 1 度だけ通知**。AlarmRingingScreen は起動しない、音も鳴らさない |

### 削除予定ファイル

- `lib/application/timer_notifier.dart` + `.g.dart`
- `lib/presentation/screens/timer_screen.dart`
- `test/application/timer_notifier_test.dart`
- `test/presentation/screens/timer_screen_test.dart`

### 新規作成ファイル

- `lib/infrastructure/database/app_database.dart` (+ `.g.dart`)
- `lib/infrastructure/database/mappers/timer_mapper.dart`
- `lib/infrastructure/database/drift_timer_repository.dart`
- `lib/domain/ports/timer_repository.dart`
- `lib/domain/timer/timer_collection.dart`
- `lib/domain/timer/exceptions.dart` (`MaxTimerCountExceededException`, `TimerNotFoundException`)
- `lib/application/timer_collection_notifier.dart` (+ `.g.dart`)
- `lib/application/timer_repository_provider.dart`
- `lib/presentation/screens/timer_list_screen.dart`
- 各レイヤーに対応する `test/`

### 編集予定ファイル

- `lib/domain/ports/notification_scheduler.dart`: `show(notificationId, title, body, payload)` メソッド追加
- `lib/infrastructure/notification/flutter_local_notification_adapter.dart`: `show()` 実装
- `lib/presentation/screens/alarm_ringing_screen.dart`: `_bootstrapRingingIfNeeded` / `_onSnoozeTap` を Collection 参照に書き換え、`Stop` ボタンも Collection.cancel + clear に書き換え
- `lib/main.dart`: `/timer` を `TimerListScreen` に差し替え、HomeScreen ボタン文言は維持
- `test/application/alarm_ringing_notifier_test.dart`: 必要に応じて regression 追加

### 影響を受ける既存テスト

- `test/presentation/screens/alarm_ringing_screen_test.dart` の `_SeededTimerNotifier` を `_SeededTimerCollectionNotifier` に置換
- `test/widget_test.dart`（HomeScreen スモーク）

---

## 直近の予定

### Phase 8「複数タイマー管理 + Drift 永続化」完了内容（2026-05-01）

- [x] `lib/domain/ports/timer_repository.dart` 新規（findAll / findById / upsert / delete）
- [x] `lib/domain/timer/timer_collection.dart` 新規（集約ルート、最大 10 件、add/update/remove）+ 13 テスト
- [x] `lib/domain/timer/exceptions.dart` 新規（`MaxTimerCountExceededException` / `TimerNotFoundException`）
- [x] `lib/domain/ports/notification_scheduler.dart` に `show()` 追加（復元時の即時通知用）
- [x] `lib/infrastructure/database/app_database.dart` 新規（Drift スキーマ、`Timers` テーブル + `forTesting` factory）
- [x] `lib/infrastructure/database/mappers/timer_mapper.dart` 新規（TimerEntity ⇔ TimerRow / TimersCompanion）+ 8 テスト
- [x] `lib/infrastructure/database/drift_timer_repository.dart` 新規（in-memory 対応）+ 8 テスト
- [x] `lib/infrastructure/notification/flutter_local_notification_adapter.dart` に `show()` 実装
- [x] `lib/application/timer_service_provider.dart` 新規（旧 timer_notifier.dart から TimerService Provider を分離）
- [x] `lib/application/timer_repository_provider.dart` 新規（main.dart で override）
- [x] `lib/application/timer_collection_notifier.dart` 新規 + 10 テスト（CRUD / 起動時 DB 復元 / 過去到達タイマーの completed 化 + show 通知 / 200ms ticker）
- [x] `lib/presentation/screens/timer_list_screen.dart` 新規 + 5 Widget テスト（empty hint / FAB / Start / Delete / FAB disabled at cap 10）
- [x] `lib/presentation/screens/alarm_ringing_screen.dart` を Collection ベースに書き換え（`findRinging` で対象選択、Stop で `cancel`、snooze で `snooze` 呼び出し）
- [x] `test/presentation/screens/alarm_ringing_screen_test.dart` を Collection 対応に全面書き換え（in-memory repo 経由でリンギング状態を seed）
- [x] `lib/main.dart`: AppDatabase + DriftTimerRepository を生成して `timerRepositoryProvider` に override、`/timer` を `TimerListScreen` に差し替え
- [x] **削除**: `lib/application/timer_notifier.dart` + `.g.dart` / `lib/presentation/screens/timer_screen.dart` / `test/application/timer_notifier_test.dart` / `test/presentation/screens/timer_screen_test.dart`
- [x] flutter analyze: No issues found
- [x] flutter test: 180 / 180 passed（既存 162 - 削除分 + 新規 50 強）
- [x] dart format で整形済み
- [x] docs/architecture.md / docs/domain-model.md / docs/state-management.md / docs/adr/0002-use-drift.md への Phase 8 反映 (1c585db)
- [x] 実機検証フィードバックでの 2 件修正 (62add6a): show() 用無音チャンネル timer_completed_v1 新設 / FAB は disable せず SnackBar 方式に変更
- [x] 実機検証 (Pixel 6a / Android 16、2026-05-02): 6 シナリオすべて想定通り
  - 検証 1: 複数タイマー (3 本) 同時稼働
  - 検証 2: アプリ強制終了 → 再起動で状態保持で復元
  - 検証 3: 過去到達 running が completed + 無音ヘッドアップ通知 1 回
  - 検証 4: 上限 10 本到達後の FAB タップで SnackBar
  - 検証 5: 各カードの個別操作 (Start/Pause/Resume/Delete/Reset/Stop) が独立
  - 検証 6: 通知タップ → AlarmRingingScreen → Stop で該当タイマー cancelled

### Phase 7「スヌーズ機能本体」完了内容（2026-05-01）

- [x] `lib/domain/timer/snooze_calculator.dart` 新規（Pure Dart、Clock 注入、3/5/10 分プリセット限定 + ArgumentError、Set 定数 `allowedMinutes`）
- [x] `test/domain/timer/snooze_calculator_test.dart` 新規（8 シナリオ: 3/5/10 分の正常 + 日付跨ぎ + プリセット外 3 種 + allowedMinutes 検証）
- [x] `lib/domain/timer/timer_service.dart` に `snooze(entity, snoozeMinutes)` 追加（ringing → running、endAt = now + N 分、duration 不変）
- [x] `test/domain/timer/timer_service_test.dart` にスヌーズ 9 シナリオ追加
- [x] `lib/application/timer_notifier.dart` に `snooze(int)` 追加（state 更新 + ticker 再開 + NotificationScheduler.schedule + AlarmRingingNotifier.stop で audioplayers 停止）
- [x] `test/application/timer_notifier_test.dart` にスヌーズ 3 シナリオ追加（5 分 re-arm + scheduler verify + StateError）
- [x] `lib/presentation/screens/alarm_ringing_screen.dart` のスヌーズボタンをモーダル + 3/5/10 分選択 + `TimerNotifier.snooze` 呼び出しに置き換え（snooze_calculator import）
- [x] `test/presentation/screens/alarm_ringing_screen_test.dart` 旧スヌーズテストを 3 つの新シナリオに置き換え（チョイスシート表示 / 5 分選択で running + 画面遷移 / キャンセルで現状維持）。`_SeededTimerNotifier` で ringing 状態をシード、`super.build()` で _ticker dispose を継承
- [x] flutter analyze: No issues found
- [x] flutter test: 162 / 162 passed（既存 140 + 新規 22）
- [x] dart format 整形済み
- [x] 実機検証: ringing → snooze 5 分 → 5 分後に再鳴動 + 通知音 + AlarmRingingScreen（heads-up タップで遷移）→ 単音化（Pixel 6a / Android 16、2026-05-02、Phase 8.5 follow-up で audioplayers と OS 通知音の二重音問題を修正後に確認済）

### カスタム時間タイマー UI 完了内容（2026-05-01）

- [x] `lib/presentation/widgets/duration_picker.dart` 新規（CupertinoPicker × 3 のホイール、確定/キャンセル）
- [x] `test/presentation/widgets/duration_picker_test.dart` 新規（7 シナリオ: 初期値表示 / 0:00:00 disabled / positive enabled / 99:00:00 確定 OK + 戻り値検証 / 99h+1s で disabled / Cancel で null pop / drag で値変化）
- [x] `lib/presentation/screens/timer_screen.dart` 編集: プリセット行末尾に「カスタム」FilledButton.tonal を追加 → `showModalBottomSheet<Duration>` 経由で DurationPicker 表示 → 確定値で `TimerNotifier.create` 呼び出し
- [x] `test/presentation/screens/timer_screen_test.dart` 編集: setup mode に 3 シナリオ追加（カスタムボタン表示 / モーダル表示 / 確定で active 遷移）+ 1 シナリオ（キャンセルで setup 維持）
- [x] flutter analyze: No issues found
- [x] flutter test: 136 / 136 passed（既存 126 + 新規 10）
- [x] dart format で整形済み
- [x] 実機で「カスタム時間（例: 1h 30m）→ Start → カウントダウン → 鳴動」の動作確認（Pixel 6a / Android 16、2026-05-02、初期表示 01:30:00 + Start 後の秒単位カウントダウン + Pause/Resume すべて想定通り）

### Phase 6 実機検証結果（2026-04-30、Pixel 6a / Android 16）

- [x] パターン 1（前面）: AlarmRingingScreen 遷移 + カスタム音再生 + Stop 動作
- [x] パターン 2（背景）: ロック画面上に AlarmRingingScreen + バンドル音源再生 + Stop 1 回で setup mode
- [x] パターン 3（強制終了）: コールドスタート deep link + バンドル音源がアラーム音量で再生 + Stop で setup mode
- [x] 権限なし時のヘッドアップ通知フォールバック（adapter の動的判定で動作）
- [x] 設定画面誘導の往復動作

検証中に発見した問題と修正は docs/android-constraints.md の「Phase 6 実機検証で
見つかって修正した問題（再発防止メモ）」に集約。

### Phase 6c 完了内容（2026-04-30）

- [x] FlutterLocalNotificationAdapter に PermissionChannel を注入
- [x] schedule 内で `canUseFullScreenIntent()` を毎回検査し、false 時は `fullScreenIntent: false` でヘッドアップ通知化
- [x] `MissingPluginException` / `PlatformException` 時は安全側（false）にフォールバック
- [x] docs/permissions.md / docs/architecture.md / docs/android-constraints.md を Phase 6 完了範囲で更新
- [x] 実機検証フォロー修正:
  - MainActivity.onCreate で `setShowWhenLocked(true)` / `setTurnScreenOn(true)` のランタイム呼び出し
  - main() の通知タップ callback と TimerScreen の ringing listener に重複ガード、`_leaveAlarmScreen` は `context.go('/timer')` で全置換
  - コールドスタート deep link（`getNotificationAppLaunchDetails()` で `initialLocation` 切替）
  - TimerNotifier.clear() で notification cancel
  - `assets/sounds/alarm_default.mp3` を `android/app/src/main/res/raw/` にもコピー、Channel に `RawResourceAndroidNotificationSound` + `AudioAttributesUsage.alarm` を明示。Channel id を v4 までバンプ（旧 id は init 時に削除）
- [x] flutter analyze: No issues found
- [x] flutter test: 126 / 126 passed

### Phase 6b 完了内容（2026-04-30）

- [x] `domain/ports/permission_manager.dart` に `checkFullScreenIntent` / `openFullScreenIntentSettings` 追加
- [x] `lib/infrastructure/platform/permission_channel.dart` 新規（`com.bonkotu.timer/permission` Channel ラッパ）
- [x] `lib/infrastructure/permission/permission_handler_adapter.dart` を const 解除し PermissionChannel 注入対応
- [x] Native `MainActivity.kt`: `com.bonkotu.timer/permission` Channel ハンドラ登録、`canUseFullScreenIntent()` (API 34+) と `ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT` Intent 発行を実装。古い API では true 返却 + アプリ詳細画面フォールバック
- [x] `application/permission_notifier.dart`: `PermissionState` に `fullScreenIntent` 追加（freezed 再生成）、`openFullScreenIntentSettings` メソッド追加、`refresh` で 3 軸読み込み
- [x] `presentation/screens/timer_screen.dart`: FSI 拒否時のバナー追加（'banner_full_screen_intent'）
- [x] `test/infrastructure/platform/permission_channel_test.dart` 新規 + 4 テスト
- [x] `test/application/permission_notifier_test.dart` を 3 軸対応 + FSI delegate テスト追加
- [x] `test/presentation/screens/timer_screen_test.dart` に FSI バナー Widget テスト追加 + 既存 banner テストを 3 軸対応
- [x] flutter analyze: No issues found
- [x] flutter test: 126 / 126 passed

### Phase 6a 完了内容（2026-04-30）

- [x] AndroidManifest に `USE_EXACT_ALARM` / `USE_FULL_SCREEN_INTENT` 追加
- [x] `<activity>` に `android:showOnLockScreen="true"` / `android:turnScreenOn="true"` 追加
- [x] FlutterLocalNotificationAdapter:
  - 通知 Channel の `importance: high` → `max`、`playSound: false` 追加
  - `AndroidNotificationDetails` を `importance: max` / `priority: max` / `fullScreenIntent: true` /
    `visibility: NotificationVisibility.public` / `playSound: false` に更新
- [x] flutter analyze: No issues found
- [x] flutter test: 120 / 120 passed

### Phase 5 完了内容（2026-04-30）

- [x] `assets/sounds/` に default / gentle / urgent の 3 音源を配置 + LICENSES.md
- [x] `pubspec.yaml` の `flutter:` セクションに `assets/sounds/` 登録
- [x] `lib/domain/timer/alarm_sound.dart`（freezed ValueObject、`AlarmSound.create` でバリデーション）
- [x] `lib/domain/timer/alarm_sound_catalog.dart`（all / defaultSound / findById）+ 6 ユニットテスト
- [x] `lib/domain/timer/timer_entity.dart` に `String? soundId` 追加（freezed 再生成）
- [x] `lib/domain/timer/timer_service.dart` の `createIdle` に `soundId` 引数追加
- [x] `lib/domain/ports/alarm_sound_player.dart`（play / stop / isPlaying / dispose）
- [x] `lib/infrastructure/audio/audioplayers_adapter.dart`（`ReleaseMode.loop` + `AssetSource`）
- [x] `lib/application/alarm_sound_player_provider.dart`
- [x] `lib/application/alarm_ringing_notifier.dart`（`AlarmRingingState` freezed + start / stop / snoozeRequested）+ 4 ユニットテスト
- [x] `lib/application/timer_notifier.dart` に ringing 連携: tick で ringing 化を検知して AlarmRingingNotifier.start を発火、cancel/reset で stop を発火
- [x] `lib/presentation/screens/alarm_ringing_screen.dart`（Stop / Snooze ボタン）+ 3 Widget テスト
- [x] `lib/main.dart`: `/alarm-ringing` ルート追加 + `onNotificationTap` callback で payload 経由 deep link
- [x] `lib/presentation/screens/timer_screen.dart`: ringing 遷移時に `context.push('/alarm-ringing')` で自動遷移
- [x] `lib/domain/ports/notification_scheduler.dart` の schedule に `payload` 引数追加（既存テストを更新）
- [x] flutter analyze: No issues found
- [x] flutter test: 120 / 120 passed
- [x] dart format で全体整形済み
- [x] 実機で 5s タイマー → カスタム音再生 → Stop で止まる動作確認（Phase 6 実機検証 2026-04-30 のパターン 1〜3 + Phase 8 検証 6 で実質カバー済）
- [ ] CI が緑になることを確認（push 後に GitHub Actions で確認）

### Phase 4 完了内容（2026-04-29）

- [x] `lib/domain/timer/notification_id_generator.dart`（Pure Dart、`timerId.hashCode & 0x7FFFFFFF`）+ 4 ユニットテスト
- [x] `lib/domain/ports/notification_scheduler.dart`（schedule / cancel / cancelAll）
- [x] `lib/domain/ports/permission_manager.dart`（DomainPermissionStatus enum + 5 メソッド）
- [x] `lib/domain/timer/timer_entity.dart` 拡張: `notificationId` フィールド追加
- [x] `lib/domain/timer/timer_service.dart` 更新: NotificationIdGenerator 注入で createIdle 時に id を発番
- [x] `lib/infrastructure/notification/flutter_local_notification_adapter.dart`（`zonedSchedule` + AndroidScheduleMode 切替）
- [x] `lib/infrastructure/permission/permission_handler_adapter.dart`
- [x] `lib/application/notification_scheduler_provider.dart`
- [x] `lib/application/permission_notifier.dart`（PermissionState freezed + Notifier）+ 5 ユニットテスト
- [x] `lib/application/timer_notifier.dart` に通知連携: start/resume で schedule、pause/cancel/reset で cancel
- [x] `lib/main.dart` で `WidgetsFlutterBinding.ensureInitialized()` + `Adapter.initialize()`
- [x] `lib/presentation/screens/timer_screen.dart` に権限拒否時バナー（POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM）+ 3 Widget テスト
- [x] AndroidManifest.xml に POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / WAKE_LOCK / VIBRATE 追加
- [x] android/app/build.gradle.kts: minSdk=26、coreLibraryDesugaring 有効化
- [x] pubspec.yaml に `flutter_local_notifications: ^19.0.0` `permission_handler: ^11.3.1` `timezone: ^0.10.1` `flutter_timezone: ^5.0.2` 追加
- [x] adapter で `tz.setLocalLocation` を実行（zonedSchedule の前提条件）
- [x] android/app/build.gradle.kts: desugar_jdk_libs を 2.1.4 へ更新（flutter_local_notifications 19 が要求）
- [x] flutter analyze: No issues found
- [x] flutter test: 106 / 106 passed
- [x] Emulator (Pixel 6a API 33) での権限フロー / バナー UI 動作確認済み
- [x] Emulator で `_plugin.show()` 経由の即時通知が表示できることを確認（チャンネル / 権限 / プラグイン初期化が正常）
- [x] AndroidManifest に `flutter_local_notifications` の `<receiver>` 2 つ + `RECEIVE_BOOT_COMPLETED` 権限を追加（プラグイン README で必須宣言）
- [x] **実機 (Pixel 6a / Android 16) で 5 秒タイマー → 通知発火 + バイブ動作確認**
- [x] docs/domain-model.md（TimerEntity に notificationId、NotificationIdGenerator 章）反映済み
- [x] docs/architecture.md（ports/permission_manager 追加 + ディレクトリ構造の Phase 4/5 実装状況反映）更新（2026-04-30）
- [ ] CI が緑になることを確認（push 後に GitHub Actions で確認）

### ドキュメント整備の仕上げ（Phase 0 完了済み）

- [x] ルート直下の `*.md` を `docs/` および `docs/adr/` へ移動
- [x] `CLAUDE.md` を最低限の制約集に圧縮
- [x] `tasklist.md` を新規作成
- [x] `BACKLOG.md` の Phase 0 チェック項目を更新（ドキュメント整備完了を反映）
- [x] `README.md` を最低限のプロジェクト説明に更新

### Phase 1 完了内容（2026-04-29）

- [x] `flutter create --org com.bonkotu.timer --project-name timer_utility --platforms=android .` 実行
- [x] レイヤー別ディレクトリ構造を作成（`lib/{domain,application,infrastructure,presentation}/`）
- [x] `pubspec.yaml` に Phase 1 依存パッケージ追加（115 依存解決済み）
- [x] `analysis_options.yaml` を厳格化（strict-casts/inference/raw-types、freezed 除外、custom_lint）
- [x] `.github/workflows/ci.yml` を新規作成（format / analyze / test ジョブ）
- [x] `lib/main.dart` を ProviderScope + GoRouter の最小構成に書き換え
- [x] `test/widget_test.dart` を新 main.dart に対応するスモークテストに書き換え
- [x] Kotlin パッケージパス差異を `docs/architecture.md` で実態に合わせて修正
- [x] CLAUDE.md のテストポリシーを `flutter_test` 経由に修正（`test` 直接依存はエコシステム制約で断念）
- [x] `flutter analyze` → No issues found
- [x] `flutter test` → All tests passed
- [x] CI が緑になることを確認（push 後の GitHub Actions 実行で確認済み）

### Phase 3 完了内容（2026-04-29）

- [x] `lib/domain/timer/timer_status.dart` (enum 6 状態)
- [x] `lib/domain/timer/timer_entity.dart` (freezed クラス、Phase 3 最小フィールド)
- [x] `lib/domain/timer/timer_service.dart` (Clock + idGenerator 注入) + 31 ユニットテスト
- [x] `lib/application/timer_notifier.dart` (`@Riverpod` Notifier、Timer.periodic 200ms) + 10 fake_async テスト
- [x] `lib/presentation/screens/timer_screen.dart` (Setup/Active 2 モード) + 5 Widget テスト
- [x] `lib/main.dart` 更新: `/timer` ルート追加、HomeScreen に導線
- [x] flutter analyze: No issues found
- [x] flutter test: 93 / 93 passed (Phase 2 の 47 + Phase 3 の 46)
- [x] domain 層カバレッジ: timer_service 100%、stopwatch_service 100%、duration_formatter 100%
- [x] バックグラウンド復帰時に endAt 過ぎていれば即 ringing（Notifier テストで検証）
- [ ] CI が緑になることを確認（push 後に GitHub Actions で確認）

### Phase 2 完了内容（2026-04-29）

- [x] エコシステム互換性: `dependency_overrides: analyzer_plugin: ^0.13.0` で build_runner を解決
- [x] `lib/domain/shared/duration_formatter.dart` (Pure Dart) + 13 ユニットテスト
- [x] `lib/domain/stopwatch/stopwatch_state.dart` (freezed sealed class: Idle / Running / Paused + LapRecord)
- [x] `lib/domain/stopwatch/stopwatch_service.dart` (Clock 注入、Pure Dart) + 16 ユニットテスト
- [x] `lib/application/clock_provider.dart` (`@Riverpod(keepAlive: true)`)
- [x] `lib/application/stopwatch_notifier.dart` (`@Riverpod` Notifier + stopwatchServiceProvider) + 8 Notifier テスト
- [x] `lib/presentation/widgets/lap_list.dart` + 4 Widget テスト
- [x] `lib/presentation/screens/stopwatch_screen.dart` (ConsumerStatefulWidget + Timer.periodic in dispose) + 4 Widget テスト
- [x] `lib/main.dart` 更新: `/stopwatch` ルート追加、HomeScreen に導線
- [x] BACKLOG / docs/architecture.md の clock_provider 配置場所修正（ADR 0004 整合）
- [x] flutter analyze: No issues found
- [x] flutter test: 47 / 47 passed
- [x] domain 層カバレッジ: stopwatch_service 100%、duration_formatter 100%（DoD 90% を大幅クリア）
- [ ] CI が緑になることを確認（push 後に GitHub Actions で確認）

### Phase 1 着手準備

- [x] `flutter create` 実行時の org / projectName を確定
  - org: `com.bonkotu.timer`
  - projectName: `timer_utility`
- [x] `pubspec.yaml` で追加する依存パッケージリストを最終確認
  - `freezed` / `freezed_annotation` を追加（Entity の copyWith / sealed class の網羅性検証用途）
  - `intl` は Phase 1 では追加せず、Phase 11（ローカライズ）着手時に `flutter_localizations` とセットで追加
  - `json_serializable` は Drift 永続化のため不要（外部 API 連携が出てきたら再検討）
- [x] Auto 運用ポリシーを CLAUDE.md に明文化
  - 自動実行範囲: コード生成 + テスト実行 + ローカルコミットまで（push は手動）
  - 停止条件: テスト 3 回連続失敗 / 同一ファイル 5 回以上連続編集 / 100 行超の新規生成 / Phase DoD 達成
- [x] `flutter create` の実行環境を確定: HP ProDesk（本マシン）
- [x] Flutter SDK 環境の Warning / NG 解消
  - Android SDK Command-line Tools をインストール
  - `flutter doctor --android-licenses` で全ライセンス承認
  - `flutter config --no-enable-windows-desktop` で Windows desktop 無効化
  - `flutter doctor` で `• No issues found!` を確認

### Auto 運用開始前のユーザー側作業

- [x] GitHub リポジトリ作成済み（`https://github.com/Bonkoturyu/TimerUtility.git`）
- [x] `git remote -v` で push 先 URL 設定済み
- [x] `git ls-remote` で認証確認済み
- [x] Phase 0 ドキュメント push 完了
- [ ] GitHub Settings → Actions → 有効化されていることを確認（Web UI で要確認）
- [x] 上記まで完了したら Auto 起動可能（Actions 確認のみ残）

詳細は `BACKLOG.md` の Phase 1 を参照。

---

## ブロック中

<!-- ブロック要因と解消条件をここに記載 -->
- なし

---

## メモ

- タスクの粒度: 1 タスク = 30 分〜半日程度を目安
- 1 日以上かかるタスクは `BACKLOG.md` の Phase に格上げを検討

---

最終更新日: 2026-05-04（Phase 9.5 実機検証完了、Pixel 6a / Android 16 で 4 シナリオ確認済、F-1 = PR #12 / F-3 = PR #11 / F-4 = PR #13 で fix 反映済）
