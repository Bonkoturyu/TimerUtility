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

    // Resolver-only contract: this test verifies that when a caller
    // includes zh-Hant in `supported`, the resolver returns it
    // unchanged. It does NOT assert that `AppLocalizations.delegate`
    // can load zh-Hant — at the time of this PR (F-9), only en/ja ARB
    // files are generated under `lib/l10n/`. Loading zh-Hant is the
    // responsibility of the upcoming zh/ko translation task tracked in
    // BACKLOG.md L694, not of this resolver's unit tests.
    test(
      'zh-Hant resolves to itself when listed in supported (experimental)',
      () {
        const List<Locale> experimentalSupported = <Locale>[
          Locale('ja'),
          Locale('en'),
          Locale('zh', 'Hant'),
        ];
        expect(
          resolveSupportedLocale(
            const Locale('zh', 'Hant'),
            experimentalSupported,
          ),
          const Locale('zh', 'Hant'),
        );
      },
    );
  });
}
