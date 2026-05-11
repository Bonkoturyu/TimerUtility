import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/timezone_resolver_provider.dart';
import 'package:timer_utility/domain/clock/clock_entry.dart';
import 'package:timer_utility/domain/clock/clock_time.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/widgets/clock_design_a.dart';

class _FixedResolver implements TimezoneResolver {
  _FixedResolver(this._returns);
  final DateTime _returns;
  @override
  DateTime computeAt(DateTime now, String timezoneId) => _returns;
}

ClockEntry _entry(int order, String name) => ClockEntry(
  id: 'id-$order',
  displayName: name,
  timezoneId: 'Etc/UTC',
  isCurrentLocation: order == 0,
  displayOrder: order,
  createdAt: DateTime.utc(2026, 1, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required List<ClockEntry> entries,
}) async {
  // GridView.count の 3 行目までを 1 画面で確実に layout させるため
  // テスト surface を縦長に拡大しておく (デフォルト 800x600 では下段が
  // viewport 外で findsOneWidget が安定しない場合がある)。
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        timezoneResolverProvider.overrideWithValue(
          _FixedResolver(DateTime.utc(2026, 1, 15, 12)),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const <Locale>[Locale('ja'), Locale('en')],
        home: Scaffold(
          body: ClockDesignA(
            entries: entries,
            now: DateTime.utc(2026, 1, 15, 12),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ClockDesignA', () {
    testWidgets('6 件のエントリ displayName がすべて表示される', (WidgetTester tester) async {
      final List<ClockEntry> entries = <ClockEntry>[
        _entry(0, 'Tokyo'),
        _entry(1, 'New York'),
        _entry(2, 'London'),
        _entry(3, 'Paris'),
        _entry(4, 'Sydney'),
        _entry(5, 'Dubai'),
      ];
      await _pump(tester, entries: entries);
      for (final ClockEntry entry in entries) {
        expect(find.text(entry.displayName), findsOneWidget);
      }
    });

    testWidgets('entries 空のとき empty hint が key で見つかる', (
      WidgetTester tester,
    ) async {
      await _pump(tester, entries: const <ClockEntry>[]);
      expect(find.byKey(const Key('clock_design_a_empty')), findsOneWidget);
    });
  });
}
