import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/imported_sound_management_controller.dart';
import 'package:timer_utility/domain/sound/imported_sound.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/widgets/alarm_sound_name.dart';

class _LoadingImportedSoundController
    extends ImportedSoundManagementController {
  final Completer<List<ImportedSound>> gate = Completer<List<ImportedSound>>();

  @override
  Future<List<ImportedSound>> build() => gate.future;
}

void main() {
  testWidgets('取り込み音源のロード中はプレースホルダーを表示する', (WidgetTester tester) async {
    final _LoadingImportedSoundController controller =
        _LoadingImportedSoundController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          importedSoundManagementControllerProvider.overrideWith(
            () => controller,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: <Locale>[Locale('ja'), Locale('en')],
          home: Scaffold(body: AlarmSoundName(soundId: 'imported-loading')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('...'), findsOneWidget);
  });
}
