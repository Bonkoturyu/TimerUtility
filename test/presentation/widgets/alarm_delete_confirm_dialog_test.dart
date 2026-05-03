import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/presentation/widgets/alarm_delete_confirm_dialog.dart';

/// ダイアログを開いて、Completer 経由で「閉じた後の結果」を Future
/// として呼び出し側に返す。
/// 呼び出し側のフロー:
///   1. final fut = await _open(tester);   // ダイアログが画面に出た状態
///   2. await tester.tap(find.byKey(...));  // Cancel / Confirm をタップ
///   3. await tester.pumpAndSettle();
///   4. final r = await fut;                // ここで結果を受け取る
Future<Future<AlarmDeleteConfirmResult>> _open(WidgetTester tester) async {
  final Completer<AlarmDeleteConfirmResult> completer =
      Completer<AlarmDeleteConfirmResult>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => ElevatedButton(
            key: const Key('open'),
            onPressed: () async {
              final AlarmDeleteConfirmResult r =
                  await showAlarmDeleteConfirmDialog(
                    context,
                    title: 'このアラームを削除しますか？',
                    dontAskLabel: '次から確認しない',
                    cancelLabel: 'キャンセル',
                    deleteLabel: '削除',
                  );
              completer.complete(r);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return completer.future;
}

void main() {
  group('showAlarmDeleteConfirmDialog', () {
    testWidgets('Cancel タップ → confirmed:false / dontAskAgain:false', (
      WidgetTester tester,
    ) async {
      final Future<AlarmDeleteConfirmResult> futureResult = await _open(tester);
      await tester.tap(find.byKey(const Key('alarm_delete_cancel')));
      await tester.pumpAndSettle();
      final r = await futureResult;
      expect(r.confirmed, isFalse);
      expect(r.dontAskAgain, isFalse);
    });

    testWidgets('Delete タップ → confirmed:true', (WidgetTester tester) async {
      final Future<AlarmDeleteConfirmResult> futureResult = await _open(tester);
      await tester.tap(find.byKey(const Key('alarm_delete_confirm')));
      await tester.pumpAndSettle();
      final r = await futureResult;
      expect(r.confirmed, isTrue);
      expect(r.dontAskAgain, isFalse);
    });

    testWidgets('Don\'t-ask チェックを入れて Delete → dontAskAgain:true', (
      WidgetTester tester,
    ) async {
      final Future<AlarmDeleteConfirmResult> futureResult = await _open(tester);
      await tester.tap(find.byKey(const Key('alarm_delete_dont_ask')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('alarm_delete_confirm')));
      await tester.pumpAndSettle();
      final r = await futureResult;
      expect(r.confirmed, isTrue);
      expect(r.dontAskAgain, isTrue);
    });

    testWidgets('外側タップで dismiss → cancelled (confirmed:false)', (
      WidgetTester tester,
    ) async {
      final Future<AlarmDeleteConfirmResult> futureResult = await _open(tester);
      // barrier を tap (showDialog は barrierDismissible=true デフォルト)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      final r = await futureResult;
      expect(r.confirmed, isFalse);
      expect(r.dontAskAgain, isFalse);
    });

    testWidgets('渡したラベルが描画される', (WidgetTester tester) async {
      // _open の返り値 (Future<...>) は使わずに破棄。Cancel タップで
      // dialog を閉じることで Completer は中断するが、テスト終了時の
      // リーク検出には引っかからない (showDialog 経由の Future は
      // Navigator.pop で resolved されるため)。
      unawaited(await _open(tester));
      expect(find.text('このアラームを削除しますか？'), findsOneWidget);
      expect(find.text('次から確認しない'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
      await tester.tap(find.byKey(const Key('alarm_delete_cancel')));
      await tester.pumpAndSettle();
    });
  });
}
