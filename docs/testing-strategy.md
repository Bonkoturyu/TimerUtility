# Testing Strategy

本プロジェクトのテスト戦略・自動化範囲・実装方針を定義する。
Claude Code は新規ロジック追加時に必ず本ドキュメントを参照し、適切なテストを同時作成すること。

---

## 基本原則

1. **ロジックは 100% 自動テスト可能な設計にする**
2. **OS / 実機依存部分のみ手動 or Integration Test に逃がす**
3. **時間制御を伴うテストで実時間 sleep 禁止**（fake_async / withClock を使用）
4. **テストは振る舞い駆動で書く**（実装詳細ではなく、外部から観測可能な振る舞いを検証）

---

## テストレイヤー

```
┌──────────────────────────────────────────────┐
│  Manual Test (実機)                          │
│  - OS が約束を守るか                          │
│  - 通知 / 音 / 画面遷移の最終確認             │
└──────────────────────────────────────────────┘
              ▲ 自動化境界
              │
┌──────────────────────────────────────────────┐
│  Integration Test (integration_test/)        │
│  - 実機 / エミュレータで E2E                  │
│  - Platform Channel を含む動作                │
└──────────────────────────────────────────────┘
              ▲
┌──────────────────────────────────────────────┐
│  Widget Test (test/presentation/)            │
│  - Screen / Widget 単体                      │
│  - Riverpod の override で Notifier 差し替え │
└──────────────────────────────────────────────┘
              ▲
┌──────────────────────────────────────────────┐
│  Notifier Test (test/application/)           │
│  - ProviderContainer で Notifier を隔離      │
│  - fake_async で時間制御                      │
└──────────────────────────────────────────────┘
              ▲
┌──────────────────────────────────────────────┐
│  Domain Unit Test (test/domain/)             │
│  - Pure Dart テスト (package:test)            │
│  - withClock で時間制御                       │
│  - 最も高速・最も多く書く                      │
└──────────────────────────────────────────────┘
```

---

## 自動化範囲マトリクス

| 対象 | テスト種別 | 自動化 | 備考 |
|---|---|---|---|
| **ドメイン層** | | | |
| StopwatchService の状態遷移 | Domain Unit | ◎ | withClock |
| TimerService の残り時間計算 | Domain Unit | ◎ | withClock |
| TimerCollection の上限制約 | Domain Unit | ◎ | |
| SnoozeCalculator | Domain Unit | ◎ | |
| DurationFormatter | Domain Unit | ◎ | |
| Entity の不変条件 | Domain Unit | ◎ | factory での例外 throw |
| **Application 層** | | | |
| StopwatchNotifier 状態遷移 | Notifier Test | ◎ | fake_async |
| TimerNotifier の予約呼び出し | Notifier Test | ◎ | Mock NotificationScheduler |
| TimerCollectionNotifier の DB 復元 | Notifier Test | ◎ | Mock Repository |
| AlarmRingingNotifier の音再生制御 | Notifier Test | ◎ | Mock Player |
| AppLifecycle 対応 | Notifier Test | ○ | 手動でイベント送信 |
| **Infrastructure 層** | | | |
| Drift Repository | Infra Test | ◎ | in-memory DB |
| NotificationIdGenerator | Infra Test | ◎ | |
| Adapter（Platform Channel ラッパ） | Infra Test | ○ | Channel mock |
| **Presentation 層** | | | |
| Screen の描画 | Widget Test | ◎ | |
| ボタン操作 → Notifier 呼び出し | Widget Test | ◎ | Riverpod override |
| Lap リスト表示 | Widget Test | ◎ | |
| カウントダウン表示更新 | Widget Test | ◎ | pump(Duration) |
| 権限ダイアログ | Widget Test | ○ | Mock PermissionManager |
| **OS 連携** | | | |
| 通知の実表示 | Integration / 実機 | △ | |
| カスタム音源の再生 | Integration / 実機 | △ | |
| フルスクリーン Intent | 実機 | × | |
| ロック画面表示 | 実機 | × | |
| 端末再起動後の復元 | 実機 | × | |
| Doze 中の精度 | 実機 | × | |
| メーカー独自省電力 | 実機 | × | |

---

## ライブラリ

### test 用パッケージ

| パッケージ | 用途 |
|---|---|
| `package:test` | Pure Dart のユニットテスト（domain 層） |
| `flutter_test` | Widget Test、Flutter 依存テスト |
| `fake_async` | 仮想時間制御 |
| `mocktail` | モック生成（**mockito ではない**） |
| `clock` | `withClock()` での時刻固定 |
| `riverpod` の `ProviderContainer` | Provider テスト |
| `drift` の `NativeDatabase.memory()` | in-memory DB テスト |
| `integration_test` | E2E テスト |

### 採用しないライブラリ

- ❌ `mockito`（コード生成必須、`mocktail` の方がシンプル）
- ❌ `bloc_test`（本プロジェクトは Riverpod 採用）

---

## テスト実装パターン

### Domain Unit Test

`package:test` のみを使用。Flutter には依存しない。

```
import 'package:test/test.dart';
import 'package:clock/clock.dart';
// import 'package:flutter_test/flutter_test.dart';  ← 使わない

void main() {
  group('StopwatchService', () {
    test('Start から 5 秒後の elapsed が 5 秒を返す', () {
      final fixedStart = DateTime(2026, 1, 1, 12, 0, 0);
      withClock(Clock.fixed(fixedStart), () {
        final service = StopwatchService(clock: clock);
        final running = service.start();
        // 5 秒進める
        withClock(Clock.fixed(fixedStart.add(Duration(seconds: 5))), () {
          expect(service.elapsed(running), Duration(seconds: 5));
        });
      });
    });
  });
}
```

### fake_async によるテスト

`Timer.periodic` / `Stream.periodic` / `Future.delayed` を含むコードのテスト。

```
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  test('Timer は 60 秒後に ringing になる', () {
    fakeAsync((async) {
      final notifier = TimerNotifier(...);
      notifier.start(Duration(seconds: 60));

      async.elapse(Duration(seconds: 30));
      expect(notifier.state.status, TimerStatus.running);

      async.elapse(Duration(seconds: 31));
      expect(notifier.state.status, TimerStatus.ringing);
    });
  });
}
```

### Notifier Test (Riverpod)

```
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('start() で running 状態に遷移する', () {
    final fakeScheduler = FakeNotificationScheduler();
    final container = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(Clock.fixed(DateTime(2026,1,1))),
      notificationSchedulerProvider.overrideWithValue(fakeScheduler),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(timerNotifierProvider(testId).notifier);
    notifier.start();

    expect(container.read(timerNotifierProvider(testId)).status,
           TimerStatus.running);
    expect(fakeScheduler.scheduledIds, contains(any));
  });
}
```

### Mock 戦略

#### Fake と Mock の使い分け

- **Fake**: 状態を持つ単純な実装（FakeNotificationScheduler など）
- **Mock**: 呼び出し検証が主目的の場合（mocktail）

ドメイン層の port 実装は **Fake を優先**、呼び出し回数や引数の検証が必要な場合のみ **Mock** を使う。

#### mocktail の基本

```
import 'package:mocktail/mocktail.dart';

class MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

void main() {
  late MockNotificationScheduler scheduler;

  setUp(() {
    scheduler = MockNotificationScheduler();
    when(() => scheduler.schedule(any(), any(), any()))
        .thenAnswer((_) async {});
  });

  test('schedule が正しい時刻で呼ばれる', () async {
    // ...
    verify(() => scheduler.schedule(
      notificationId,
      DateTime(2026, 1, 1, 12, 0, 30),
      any(),
    )).called(1);
  });
}
```

### Widget Test

```
testWidgets('ストップウォッチ画面で Start ボタンを押すと表示が動き出す',
    (tester) async {
  final container = ProviderContainer(overrides: [
    clockProvider.overrideWithValue(Clock.fixed(DateTime(2026,1,1))),
  ]);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: StopwatchScreen()),
    ),
  );

  expect(find.text('00:00.00'), findsOneWidget);

  await tester.tap(find.byKey(Key('start_button')));
  await tester.pump();
  await tester.pump(Duration(seconds: 1));

  expect(find.textContaining('00:01'), findsOneWidget);
});
```

### Drift Repository Test

```
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;
  late DriftTimerRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftTimerRepository(db);
  });

  tearDown(() async => await db.close());

  test('保存したタイマーが取得できる', () async {
    final entity = TimerEntity.create(...);
    await repo.save(entity);

    final fetched = await repo.findById(entity.id);
    expect(fetched, equals(entity));
  });
}
```

---

## カバレッジ目標

| 層 | 目標 | 測定方法 |
|---|---|---|
| Domain | 90% 以上 | `flutter test --coverage` |
| Application（Notifier） | 80% 以上 | 同上 |
| Infrastructure | 70% 以上 | 同上（Adapter は実機テスト併用） |
| Presentation（Widget） | 60% 以上 | 同上 |

ただしカバレッジは目安。**振る舞いが網羅されているか**を最優先。

---

## CI 設定

`.github/workflows/ci.yml` で以下を実行:

1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter analyze`
4. `dart format --set-exit-if-changed .`
5. `flutter test --coverage`
6. カバレッジレポートのアーティファクト保存

PR ごとに必須実行。失敗すればマージ不可。

---

## 命名規則

### テストファイル

- 対象ファイルと 1:1 対応
- 例: `lib/domain/timer/timer_service.dart` → `test/domain/timer/timer_service_test.dart`

### テスト記述

- `group` でクラス名を指定
- `test` / `testWidgets` の説明は **日本語で振る舞いを記述**
- 「〜する場合〜になる」「〜のとき〜を返す」の形式

例:
```
group('TimerService', () {
  test('start 時に endAt が duration 後の時刻になる', () {...});
  test('duration が 0 のとき InvalidDurationException を throw する', () {...});
});
```

---

## アンチパターン

❌ **`Future.delayed(Duration(seconds: 5))` で実時間待機**
→ `fake_async` または `tester.pump(Duration)` を使う

❌ **`DateTime.now()` を直接使うコードのテスト**
→ そもそもコード側を `Clock` 注入に変更する

❌ **テスト内で実 DB / 実ファイルシステムを使う**
→ in-memory DB / モックファイルシステムを使う

❌ **テストが実装詳細に依存する**
→ private メソッドを直接テストせず、public API 経由で検証

❌ **複数のテストが順序依存する**
→ 各テストは独立、`setUp` / `tearDown` で初期化

❌ **巨大な setUp**
→ ヘルパー関数 / Builder パターンで簡潔に

---

## 手動テスト項目（自動化不可領域）

Phase 完了時にチェックリスト形式で実施。`docs/manual-test-checklist.md`（Phase 6 着手前に作成）に記録。

主な項目:
- [ ] アプリ起動状態でのアラーム鳴動（前面 / 背面）
- [ ] アプリ強制終了状態でのアラーム鳴動
- [ ] ロック画面でのアラーム画面表示
- [ ] サイレントモード時の挙動
- [ ] バッテリー最適化 ON / OFF それぞれでの動作
- [ ] 端末再起動後のタイマー復元
- [ ] 複数タイマー同時鳴動
- [ ] スヌーズ後の再鳴動
- [ ] カスタム音源の再生確認

---

## テスト実行コマンド

| 用途 | コマンド |
| --- | --- |
| Pure Dart テスト | `dart test test/domain/` |
| 全テスト | `flutter test` |
| カバレッジ付き | `flutter test --coverage` |
| 特定ファイル | `flutter test test/domain/timer/timer_service_test.dart` |
| Integration Test | `flutter test integration_test/` |
| ウォッチモード | `flutter test --watch`（dev 時） |

---

## IDE からのテスト実行（必須要件）

本プロジェクトのテストはすべて Flutter 標準のテストフレームワーク（`package:test` / `package:flutter_test` / `package:integration_test`）で記述すること。
これにより Android Studio / IntelliJ IDEA の Run/Debug 設定からテストを直接実行・デバッグできる状態を必須要件とする。

### Android Studio / IntelliJ での実行方法

- **個別テスト**: テストファイルを開き、関数横の緑の三角アイコンから実行
- **ファイル単位**: ファイルツリーでテストファイルを右クリック → `Run 'tests in xxx_test.dart'`
- **ディレクトリ単位**: `test/` ディレクトリを右クリック → `Run 'tests in test'`
- **Integration Test**: 実機または Emulator を選択した状態で `integration_test/` 配下を実行

### テストランナーの選定根拠

- `flutter test` 単体で Pure Dart / Widget / Integration Test を統一実行できる
- AndroidStudio の Flutter プラグインが `flutter test` をネイティブにサポート
- CI（`.github/workflows/ci.yml`）と IDE 実行で同一コマンドが使えるため、ローカルと CI の挙動が一致する

### 禁止事項

- AndroidStudio から実行できない独自スクリプトのみで完結するテスト構成は不可
- Native（Kotlin）側のテストを書く場合も、Flutter 側からの結合検証を `integration_test/` で同等に再現すること

---

## 関連ドキュメント

- `docs/architecture.md`: レイヤー構造とテスタビリティ
- `docs/state-management.md`: Provider テストの override 方法
- `docs/domain-model.md`: テスト対象のドメインモデル

---

最終更新日: 2026-04-29
