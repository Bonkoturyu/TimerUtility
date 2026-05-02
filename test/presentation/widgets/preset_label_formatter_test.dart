import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/widgets/preset_label_formatter.dart';

/// Loads `AppLocalizations` for the given locale via the gen-l10n
/// delegate. Cleaner than spinning up a full `MaterialApp` just to grab
/// `AppLocalizations.of(context)`.
Future<AppLocalizations> _localizationsFor(Locale locale) {
  return AppLocalizations.delegate.load(locale);
}

void main() {
  group('formatPresetDurationOnly (ja)', () {
    late AppLocalizations l;
    setUpAll(() async {
      l = await _localizationsFor(const Locale('ja'));
    });

    test('30 seconds → "30秒"', () {
      expect(
        formatPresetDurationOnly(duration: const Duration(seconds: 30), l: l),
        '30秒',
      );
    });

    test('5 minutes → "5分"', () {
      expect(
        formatPresetDurationOnly(duration: const Duration(minutes: 5), l: l),
        '5分',
      );
    });

    test('2 hours → "2時間"', () {
      expect(
        formatPresetDurationOnly(duration: const Duration(hours: 2), l: l),
        '2時間',
      );
    });

    test('1h 30m falls back to HH:MM:SS', () {
      expect(
        formatPresetDurationOnly(
          duration: const Duration(hours: 1, minutes: 30),
          l: l,
        ),
        '01:30:00',
      );
    });

    test('5m 20s falls back to HH:MM:SS', () {
      expect(
        formatPresetDurationOnly(
          duration: const Duration(minutes: 5, seconds: 20),
          l: l,
        ),
        '05:20',
      );
    });
  });

  group('formatPresetDurationOnly (en) handles plural forms', () {
    late AppLocalizations l;
    setUpAll(() async {
      l = await _localizationsFor(const Locale('en'));
    });

    test('1 second → "1 second"', () {
      expect(
        formatPresetDurationOnly(duration: const Duration(seconds: 1), l: l),
        '1 second',
      );
    });

    test('30 seconds → "30 seconds"', () {
      expect(
        formatPresetDurationOnly(duration: const Duration(seconds: 30), l: l),
        '30 seconds',
      );
    });

    test('1 minute → "1 minute"', () {
      expect(
        formatPresetDurationOnly(duration: const Duration(minutes: 1), l: l),
        '1 minute',
      );
    });

    test('5 minutes → "5 minutes"', () {
      expect(
        formatPresetDurationOnly(duration: const Duration(minutes: 5), l: l),
        '5 minutes',
      );
    });

    test('1 hour → "1 hour"', () {
      expect(
        formatPresetDurationOnly(duration: const Duration(hours: 1), l: l),
        '1 hour',
      );
    });
  });

  group('formatPresetLabel', () {
    late AppLocalizations l;
    setUpAll(() async {
      l = await _localizationsFor(const Locale('ja'));
    });

    test('non-empty userLabel wins over duration', () {
      expect(
        formatPresetLabel(
          duration: const Duration(seconds: 30),
          l: l,
          userLabel: 'コーヒー',
        ),
        'コーヒー',
      );
    });

    test('empty userLabel falls back to duration formatting', () {
      expect(
        formatPresetLabel(duration: const Duration(minutes: 5), l: l),
        '5分',
      );
    });
  });
}
