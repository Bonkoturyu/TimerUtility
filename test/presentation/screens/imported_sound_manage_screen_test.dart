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
import 'package:timer_utility/presentation/screens/imported_sound_manage_screen.dart';

class _MemorySoundController extends ImportedSoundManagementController {
  _MemorySoundController(
    this._sounds, {
    this.prepareResult,
    this.isPlayingLookup,
  });

  List<ImportedSound> _sounds;
  final PrepareImportedSoundResult? prepareResult;
  final bool Function()? isPlayingLookup;
  bool? wasPlayingWhenPrepareCalled;
  bool? wasPlayingWhenDeleteCalled;
  int prepareCalls = 0;
  int confirmCalls = 0;
  int deleteCalls = 0;

  @override
  Future<List<ImportedSound>> build() async => _sounds;

  @override
  Future<PrepareImportedSoundResult?> prepareImport() async {
    prepareCalls++;
    wasPlayingWhenPrepareCalled = isPlayingLookup?.call();
    return prepareResult;
  }

  @override
  Future<ImportedSound> confirmImport(PreparedImportedSound prepared) async {
    confirmCalls++;
    final ImportedSound imported = prepared.candidate;
    _sounds = <ImportedSound>[..._sounds, imported];
    state = AsyncData<List<ImportedSound>>(_sounds);
    return imported;
  }

  @override
  Future<void> cancelImport(PreparedImportedSound prepared) async {}

  @override
  String stagingTokenOf(PreparedImportedSound prepared) => 'stage-1';

  @override
  Future<void> rename(ImportedSound sound, String displayName) async {
    _sounds = _sounds
        .map(
          (ImportedSound current) =>
              current.id == sound.id ? current.rename(displayName) : current,
        )
        .toList(growable: false);
    state = AsyncData<List<ImportedSound>>(_sounds);
  }

  @override
  Future<void> delete(String soundId) async {
    deleteCalls++;
    wasPlayingWhenDeleteCalled = isPlayingLookup?.call();
    _sounds = _sounds
        .where((ImportedSound sound) => sound.id != soundId)
        .toList(growable: false);
    state = AsyncData<List<ImportedSound>>(_sounds);
  }
}

class _PreviewPlayer
    implements
        AlarmSoundPlayer,
        ImportedSoundPreviewPlayer,
        StagedImportedSoundPreviewPlayer {
  String? previewedId;
  String? stagedToken;
  int stopCalls = 0;

  @override
  bool get isPlaying => previewedId != null || stagedToken != null;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> play(AlarmSound sound) async {}

  @override
  Future<void> playImported(String soundId) async => previewedId = soundId;

  @override
  Future<void> playStaged(String stagingToken) async {
    stagedToken = stagingToken;
  }

  @override
  Future<void> prepare(AlarmSound sound) async {}

  @override
  Future<void> stop() async {
    stopCalls++;
    previewedId = null;
    stagedToken = null;
  }
}

class _PreparedSound extends Fake implements PreparedImportedSound {
  _PreparedSound(this.candidate);

  @override
  final ImportedSound candidate;
}

ImportedSound _sound({String id = 'sound-1', String name = 'Kitchen'}) =>
    ImportedSound.create(
      id: id,
      displayName: name,
      format: ImportedSoundFormat.mp3,
      byteLength: 1000,
      duration: const Duration(seconds: 5),
      contentHash: List<String>.filled(64, 'a').join(),
      createdAt: DateTime.utc(2026, 7, 17),
    );

Widget _harness(_MemorySoundController controller, _PreviewPlayer player) =>
    ProviderScope(
      overrides: <Override>[
        importedSoundManagementControllerProvider.overrideWith(
          () => controller,
        ),
        alarmSoundPlayerProvider.overrideWithValue(player),
      ],
      child: const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: <Locale>[Locale('ja'), Locale('en')],
        home: ImportedSoundManageScreen(),
      ),
    );

void main() {
  testWidgets('一覧表示、試聴、改名、削除確認を操作できる', (WidgetTester tester) async {
    final _PreviewPlayer player = _PreviewPlayer();
    final _MemorySoundController controller = _MemorySoundController(
      <ImportedSound>[_sound()],
      isPlayingLookup: () => player.isPlaying,
    );

    await tester.pumpWidget(_harness(controller, player));
    await tester.pumpAndSettle();

    expect(find.text('Kitchen'), findsOneWidget);

    await tester.tap(find.byKey(const Key('imported_sound_preview_sound-1')));
    await tester.pump();
    expect(player.previewedId, 'sound-1');
    expect(find.byIcon(Icons.stop), findsOneWidget);

    await tester.tap(find.byKey(const Key('imported_sound_rename_sound-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('imported_sound_rename_field')),
      'Tea timer',
    );
    await tester.tap(find.byKey(const Key('imported_sound_rename_confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Tea timer'), findsOneWidget);

    await tester.tap(find.byKey(const Key('imported_sound_delete_sound-1')));
    await tester.pumpAndSettle();
    expect(find.text('この音源を削除しますか？'), findsOneWidget);
    await tester.tap(find.byKey(const Key('imported_sound_delete_confirm')));
    await tester.pumpAndSettle();

    expect(controller.deleteCalls, 1);
    expect(controller.wasPlayingWhenDeleteCalled, isFalse);
    expect(player.previewedId, isNull);
    expect(find.text('取り込み音源はありません。\n右下のボタンから追加できます。'), findsOneWidget);
  });

  testWidgets('同じ音源の試聴ボタンを再タップすると停止する', (WidgetTester tester) async {
    final _MemorySoundController controller = _MemorySoundController(
      <ImportedSound>[_sound()],
    );
    final _PreviewPlayer player = _PreviewPlayer();

    await tester.pumpWidget(_harness(controller, player));
    await tester.pumpAndSettle();
    final Finder preview = find.byKey(
      const Key('imported_sound_preview_sound-1'),
    );
    await tester.tap(preview);
    await tester.pump();
    await tester.tap(preview);
    await tester.pump();

    expect(player.previewedId, isNull);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('別音源を試聴すると再生中の音源を停止して切り替える', (WidgetTester tester) async {
    final _MemorySoundController controller = _MemorySoundController(
      <ImportedSound>[_sound(), _sound(id: 'sound-2', name: 'Bedroom')],
    );
    final _PreviewPlayer player = _PreviewPlayer();

    await tester.pumpWidget(_harness(controller, player));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('imported_sound_preview_sound-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('imported_sound_preview_sound-2')));
    await tester.pump();

    expect(player.previewedId, 'sound-2');
    expect(player.stopCalls, 2);
  });

  testWidgets('追加開始前に試聴を停止する', (WidgetTester tester) async {
    final _PreviewPlayer player = _PreviewPlayer();
    final _MemorySoundController controller = _MemorySoundController(
      <ImportedSound>[_sound()],
      prepareResult: _PreparedSound(_sound(id: 'sound-2', name: 'Bedroom')),
      isPlayingLookup: () => player.isPlaying,
    );

    await tester.pumpWidget(_harness(controller, player));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('imported_sound_preview_sound-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('imported_sound_add_button')));
    await tester.pumpAndSettle();

    expect(controller.prepareCalls, 1);
    expect(controller.wasPlayingWhenPrepareCalled, isFalse);
    expect(player.previewedId, isNull);

    expect(find.text('Bedroom'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sound_import_candidate_preview')));
    await tester.pump();
    expect(player.stagedToken, 'stage-1');

    await tester.tap(find.byKey(const Key('sound_import_candidate_confirm')));
    await tester.pumpAndSettle();

    expect(controller.confirmCalls, 1);
    expect(player.stagedToken, isNull);
    expect(
      find.byKey(const Key('imported_sound_tile_sound-2')),
      findsOneWidget,
    );
  });

  testWidgets('画面を閉じると試聴を停止する', (WidgetTester tester) async {
    final _MemorySoundController controller = _MemorySoundController(
      <ImportedSound>[_sound()],
    );
    final _PreviewPlayer player = _PreviewPlayer();

    await tester.pumpWidget(_harness(controller, player));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('imported_sound_preview_sound-1')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());

    expect(player.stopCalls, greaterThanOrEqualTo(1));
  });
}
