import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/screens/licenses_screen.dart';

void main() {
  const String packageName = 'App icon / Hoshino v2 (bundled)';

  setUpAll(() {
    LicenseRegistry.addLicense(
      () => Stream<LicenseEntry>.value(
        const LicenseEntryWithLineBreaks(
          <String>[packageName],
          '''
- 生成サービス: PixAI
- 使用モデル: Hoshino v2
- モデルページ: https://pixai.art/ja/model/1954632827019711809
''',
        ),
      ),
    );
  });

  testWidgets('PixAIモデル情報を同梱アセットとして表示する', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: <Locale>[Locale('ja')],
        home: LicensesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('同梱アセット'), findsOneWidget);
    expect(find.text('App icon / Hoshino v2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('license_entry_$packageName')));
    await tester.pumpAndSettle();

    expect(find.textContaining('生成サービス: PixAI'), findsOneWidget);
    expect(find.textContaining('使用モデル: Hoshino v2'), findsOneWidget);
    expect(
      find.textContaining('https://pixai.art/ja/model/1954632827019711809'),
      findsOneWidget,
    );
  });
}
