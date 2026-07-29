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

    // Production list (`supportedLocales` in main.dart) must declare the
    // generic zh-Hant via `Locale.fromSubtags(scriptCode: 'Hant')` — not
    // `Locale('zh', 'Hant')` (countryCode form) — so the manual-override
    // path (parseLocaleTag → MaterialApp.locale) and the gen-l10n
    // `lookupAppLocalizations` script-code switch line up.
    test('supportedLocales declares a script-form generic zh_Hant', () {
      final Iterable<Locale> generic = supportedLocales.where(
        (Locale l) =>
            l.languageCode == 'zh' &&
            l != const Locale('zh') &&
            l.countryCode == null,
      );
      expect(
        generic.length,
        1,
        reason: 'expected exactly one generic zh variant beyond Locale("zh")',
      );
      expect(generic.first.scriptCode, 'Hant');
    });

    // Every zh entry beyond `Locale('zh')` must carry scriptCode 'Hant',
    // because `lookupAppLocalizations` switches on scriptCode alone —
    // a countryCode-only entry would silently load Simplified.
    test('all non-generic zh entries carry scriptCode Hant', () {
      final Iterable<Locale> zhVariants = supportedLocales.where(
        (Locale l) => l.languageCode == 'zh' && l != const Locale('zh'),
      );
      expect(zhVariants, isNotEmpty);
      for (final Locale l in zhVariants) {
        expect(l.scriptCode, 'Hant', reason: '$l must declare scriptCode');
      }
    });

    // `Locale('zh')` must precede the Hant entries: the SDK's
    // language-only fallback returns the first languageCode match, so a
    // bare `zh` device has to land on Simplified.
    test('Locale("zh") precedes every zh_Hant entry', () {
      final int simplified = supportedLocales.indexOf(const Locale('zh'));
      final int firstHant = supportedLocales.indexWhere(
        (Locale l) => l.scriptCode == 'Hant',
      );
      expect(simplified, isNonNegative);
      expect(firstHant, isNonNegative);
      expect(simplified, lessThan(firstHant));
    });
  });

  // The public build ships all five languages; these cases pin the
  // device-locale → UI-locale resolution against the production list.
  group('resolveSupportedLocale against the production supportedLocales', () {
    test('zh (no script/country) resolves to Simplified', () {
      expect(
        resolveSupportedLocale(const Locale('zh'), supportedLocales),
        const Locale('zh'),
      );
    });

    test('zh_Hans_CN resolves to Simplified', () {
      expect(
        resolveSupportedLocale(
          const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
            countryCode: 'CN',
          ),
          supportedLocales,
        ),
        const Locale('zh'),
      );
    });

    // Android may report `zh_TW` without a scriptCode. Without the
    // explicit zh_Hant_TW entry this would fall through to the
    // language-only match and render Simplified.
    test('zh_TW (no scriptCode) resolves to a Hant entry', () {
      final Locale resolved = resolveSupportedLocale(
        const Locale('zh', 'TW'),
        supportedLocales,
      );
      expect(resolved.scriptCode, 'Hant');
    });

    test('zh_HK (no scriptCode) resolves to a Hant entry', () {
      final Locale resolved = resolveSupportedLocale(
        const Locale('zh', 'HK'),
        supportedLocales,
      );
      expect(resolved.scriptCode, 'Hant');
    });

    test('zh_MO (no scriptCode) resolves to a Hant entry', () {
      final Locale resolved = resolveSupportedLocale(
        const Locale('zh', 'MO'),
        supportedLocales,
      );
      expect(resolved.scriptCode, 'Hant');
    });

    test('zh_Hant_TW resolves to a Hant entry', () {
      final Locale resolved = resolveSupportedLocale(
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
        supportedLocales,
      );
      expect(resolved.scriptCode, 'Hant');
    });

    // scriptCodeなしのzh_MOを繁体字へ解決するため追加した専用entryへ、
    // scriptCode付きの端末報告もexact matchする。
    test('zh_Hant_MO resolves to the dedicated zh_Hant_MO entry', () {
      expect(
        resolveSupportedLocale(
          const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
            countryCode: 'MO',
          ),
          supportedLocales,
        ),
        const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'MO',
        ),
      );
    });

    test('ko resolves to ko', () {
      expect(
        resolveSupportedLocale(const Locale('ko'), supportedLocales),
        const Locale('ko'),
      );
    });

    test('ko_KR resolves to ko', () {
      expect(
        resolveSupportedLocale(const Locale('ko', 'KR'), supportedLocales),
        const Locale('ko'),
      );
    });

    test('unsupported fr still falls back to en', () {
      expect(
        resolveSupportedLocale(const Locale('fr'), supportedLocales),
        const Locale('en'),
      );
    });
  });
}
