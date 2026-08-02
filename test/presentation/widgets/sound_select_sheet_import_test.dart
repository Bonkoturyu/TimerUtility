import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/alarm_sound_player_provider.dart';
import 'package:timer_utility/application/imported_sound_import_service.dart';
import 'package:timer_utility/application/imported_sound_management_controller.dart';
import 'package:timer_utility/domain/ports/alarm_sound_player.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/domain/sound/imported_sound_format.dart';
import 'package:timer_utility/domain/timer/alarm_sound.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/widgets/sound_select_sheet.dart';

class _PreparedSound extends Fake implements PreparedImportedSound {
  _PreparedSound(this.candidate);

  @override
  final ImportedSound candidate;
}

class _ImportController extends ImportedSoundManagementController {
  _ImportController(this.prepareResult, {this.confirmGate});

  final PrepareImportedSoundResult? prepareResult;
  final Completer<void>? confirmGate;
  int confirmCalls = 0;
  int cancelCalls = 0;

  @override
  Future<List<ImportedSound>> build() async => const <ImportedSound>[];

  @override
  Future<PrepareImportedSoundResult?> prepareImport() async => prepareResult;

  @override
  Future<ImportedSound> confirmImport(PreparedImportedSound prepared) async {
    confirmCalls++;
    await confirmGate?.future;
    return prepared.candidate;
  }

  @override
  Future<void> cancelImport(PreparedImportedSound prepared) async {
    cancelCalls++;
  }

  @override
  String stagingTokenOf(PreparedImportedSound prepared) => 'stage-1';
}

class _PreviewPlayer
    implements AlarmSoundPlayer, StagedImportedSoundPreviewPlayer {
  String? stagedToken;
  String? bundledSoundId;
  int stopCalls = 0;

  @override
  bool get isPlaying => stagedToken != null || bundledSoundId != null;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> play(AlarmSound sound) async {
    bundledSoundId = sound.id;
  }

  @override
  Future<void> playStaged(String stagingToken) async {
    stagedToken = stagingToken;
  }

  @override
  Future<void> prepare(AlarmSound sound) async {}

  @override
  Future<void> stop() async {
    stopCalls++;
    stagedToken = null;
    bundledSoundId = null;
  }
}

class _SheetHost extends StatefulWidget {
  const _SheetHost({this.importOnly = false});

  final bool importOnly;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  String? selected;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: <Widget>[
        ElevatedButton(
          key: const Key('open_sound_sheet'),
          onPressed: () async {
            final String? result = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              builder: (_) => SoundSelectSheet(
                initialSoundId: null,
                importOnly: widget.importOnly,
                startImport: widget.importOnly,
              ),
            );
            if (mounted) setState(() => selected = result);
          },
          child: const Text('open'),
        ),
        if (selected != null)
          Text(selected!, key: const Key('selected_sound_id')),
      ],
    ),
  );
}

ImportedSound _sound({String id = 'candidate', String name = 'My alarm'}) =>
    ImportedSound.create(
      id: id,
      displayName: name,
      format: ImportedSoundFormat.mp3,
      byteLength: 100,
      duration: const Duration(seconds: 3),
      contentHash: List<String>.filled(64, 'a').join(),
      createdAt: DateTime.utc(2026, 7, 17),
    );

Widget _harness(
  _ImportController controller,
  _PreviewPlayer player, {
  bool importOnly = false,
}) => ProviderScope(
  overrides: <Override>[
    importedSoundManagementControllerProvider.overrideWith(() => controller),
    alarmSoundPlayerProvider.overrideWithValue(player),
  ],
  child: MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
    home: _SheetHost(importOnly: importOnly),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open_sound_sheet')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('sound_select_add_imported')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('同梱音源の試聴は選択を変えず再タップで停止する', (WidgetTester tester) async {
    final _ImportController controller = _ImportController(null);
    final _PreviewPlayer player = _PreviewPlayer();
    await tester.pumpWidget(_harness(controller, player));

    await tester.tap(find.byKey(const Key('open_sound_sheet')));
    await tester.pumpAndSettle();
    final Finder preview = find.byKey(const Key('sound_select_gentle_preview'));
    await tester.tap(preview);
    await tester.pump();

    expect(player.bundledSoundId, 'gentle');
    expect(find.byType(SoundSelectSheet), findsOneWidget);
    expect(find.byKey(const Key('selected_sound_id')), findsNothing);

    await tester.tap(preview);
    await tester.pump();
    expect(player.bundledSoundId, isNull);
  });

  testWidgets('同梱音源を試聴後に行を選ぶと停止して選択値を返す', (WidgetTester tester) async {
    final _ImportController controller = _ImportController(null);
    final _PreviewPlayer player = _PreviewPlayer();
    await tester.pumpWidget(_harness(controller, player));

    await tester.tap(find.byKey(const Key('open_sound_sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sound_select_warning_preview')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sound_select_warning')));
    await tester.pumpAndSettle();

    expect(player.bundledSoundId, isNull);
    expect(find.text('warning'), findsOneWidget);
  });

  testWidgets('候補名を表示してstagingを試聴後に確定できる', (WidgetTester tester) async {
    final _PreparedSound prepared = _PreparedSound(_sound());
    final _ImportController controller = _ImportController(prepared);
    final _PreviewPlayer player = _PreviewPlayer();
    await tester.pumpWidget(_harness(controller, player));

    await _open(tester);
    expect(
      find.byKey(const Key('sound_import_candidate_name')),
      findsOneWidget,
    );
    expect(find.text('My alarm'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sound_import_candidate_preview')));
    await tester.pump();
    expect(player.stagedToken, 'stage-1');

    await tester.tap(find.byKey(const Key('sound_import_candidate_confirm')));
    await tester.pumpAndSettle();

    expect(controller.confirmCalls, 1);
    expect(player.stopCalls, greaterThanOrEqualTo(1));
    expect(find.text('candidate'), findsOneWidget);
  });

  testWidgets('確定処理中にsheetを閉じてもstagingを取消しない', (WidgetTester tester) async {
    final Completer<void> confirmGate = Completer<void>();
    final _ImportController controller = _ImportController(
      _PreparedSound(_sound()),
      confirmGate: confirmGate,
    );
    final _PreviewPlayer player = _PreviewPlayer();
    await tester.pumpWidget(_harness(controller, player));
    await _open(tester);

    await tester.tap(find.byKey(const Key('sound_import_candidate_confirm')));
    await tester.pump();
    Navigator.of(tester.element(find.byType(SoundSelectSheet))).pop();
    await tester.pumpAndSettle();

    expect(controller.confirmCalls, 1);
    expect(controller.cancelCalls, 0);
    confirmGate.complete();
    await tester.pump();
  });

  testWidgets('候補のキャンセルは試聴を停止してstagingを破棄する', (WidgetTester tester) async {
    final _ImportController controller = _ImportController(
      _PreparedSound(_sound()),
    );
    final _PreviewPlayer player = _PreviewPlayer();
    await tester.pumpWidget(_harness(controller, player));

    await _open(tester);
    await tester.tap(find.byKey(const Key('sound_import_candidate_preview')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sound_import_candidate_cancel')));
    await tester.pumpAndSettle();

    expect(controller.cancelCalls, 1);
    expect(player.stagedToken, isNull);
    expect(find.byKey(const Key('sound_import_candidate_name')), findsNothing);
  });

  testWidgets('重複内容は既存名を案内して既存IDを選択する', (WidgetTester tester) async {
    final ImportedSound existing = _sound(id: 'existing', name: 'Kitchen');
    final _ImportController controller = _ImportController(
      DuplicateImportedSound(existing),
    );
    final _PreviewPlayer player = _PreviewPlayer();
    await tester.pumpWidget(_harness(controller, player));

    await _open(tester);

    expect(find.text('Kitchen は追加済みです。既存の音源を選択しました。'), findsOneWidget);
    expect(find.text('existing'), findsOneWidget);
    expect(controller.confirmCalls, 0);
  });

  testWidgets('管理画面用導線は自動で候補を準備し取消時に閉じる', (WidgetTester tester) async {
    final _ImportController controller = _ImportController(
      _PreparedSound(_sound()),
    );
    final _PreviewPlayer player = _PreviewPlayer();
    await tester.pumpWidget(_harness(controller, player, importOnly: true));

    await tester.tap(find.byKey(const Key('open_sound_sheet')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('sound_import_candidate_name')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('sound_select_manage_imported')), findsNothing);

    await tester.tap(find.byKey(const Key('sound_import_candidate_cancel')));
    await tester.pumpAndSettle();

    expect(controller.cancelCalls, 1);
    expect(find.byKey(const Key('sound_import_candidate_name')), findsNothing);
  });
}
