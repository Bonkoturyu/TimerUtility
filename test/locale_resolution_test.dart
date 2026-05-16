import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/main.dart';

void main() {
  group('resolveSupportedLocale', () {
    const List<Locale> publicSupported = <Locale>[Locale('ja'), Locale('en')];

    test('exact match for ja returns ja', () {
      expect(
        resolveSupportedLocale(const Locale('ja'), publicSupported),
        const Locale('ja'),
      );
    });

    test('exact match for en returns en', () {
      expect(
        resolveSupportedLocale(const Locale('en'), publicSupported),
        const Locale('en'),
      );
    });

    test('unsupported zh falls back to en', () {
      expect(
        resolveSupportedLocale(const Locale('zh'), publicSupported),
        const Locale('en'),
      );
    });

    test('unsupported zh-Hant falls back to en when zh is not supported', () {
      expect(
        resolveSupportedLocale(const Locale('zh', 'Hant'), publicSupported),
        const Locale('en'),
      );
    });

    test('unsupported fr falls back to en', () {
      expect(
        resolveSupportedLocale(const Locale('fr'), publicSupported),
        const Locale('en'),
      );
    });

    test('unsupported de falls back to en', () {
      expect(
        resolveSupportedLocale(const Locale('de'), publicSupported),
        const Locale('en'),
      );
    });

    test('null deviceLocale falls back to en', () {
      expect(resolveSupportedLocale(null, publicSupported), const Locale('en'));
    });

    test('language match with country variant resolves to supported entry', () {
      expect(
        resolveSupportedLocale(const Locale('en', 'US'), publicSupported),
        const Locale('en'),
      );
    });

    // Resolver-only contract: when a caller includes zh-Hant in `supported`,
    // the resolver returns it unchanged. A-3 (PR #61) updated the production
    // list to `Locale.fromSubtags(scriptCode: 'Hant')` so it matches both
    // gen-l10n's lookup (`switch (locale.scriptCode) case 'Hant'`) and
    // `parseLocaleTag('zh-Hant')` in `settings_notifier.dart`. The pre-A-3
    // form `Locale('zh', 'Hant')` set countryCode='Hant' / scriptCode=null,
    // which silently fell back to Simplified Chinese on manual selection.
    test(
      'zh-Hant (scriptCode form) resolves to itself when listed in supported',
      () {
        final List<Locale> experimentalSupported = <Locale>[
          const Locale('ja'),
          const Locale('en'),
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ];
        expect(
          resolveSupportedLocale(
            const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
            experimentalSupported,
          ),
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        );
      },
    );

    // Production list (`_experimentalSupportedLocales` in main.dart) must
    // declare zh-Hant via `Locale.fromSubtags(scriptCode: 'Hant')` — not
    // `Locale('zh', 'Hant')` (countryCode form) — so the manual-override
    // path (parseLocaleTag → MaterialApp.locale) and the gen-l10n
    // `lookupAppLocalizations` script-code switch line up.
    //
    // Tested via the @visibleForTesting `debugExperimentalSupportedLocales`
    // export so the assertion runs unconditionally — the public
    // `supportedLocales` getter is gated on the `kEnableExperimentalLocales`
    // compile-time flag (default false in `flutter test` and CI), which
    // would otherwise let a regression slip through silently.
    test(
      'debugExperimentalSupportedLocales declares zh_Hant in scriptCode form',
      () {
        final Iterable<Locale> zhHant = debugExperimentalSupportedLocales.where(
          (Locale l) => l.languageCode == 'zh' && l != const Locale('zh'),
        );
        expect(
          zhHant.length,
          1,
          reason: 'expected exactly one zh variant beyond Locale("zh")',
        );
        final Locale entry = zhHant.first;
        expect(entry.scriptCode, 'Hant');
        expect(entry.countryCode, isNull);
      },
    );
  });
}
