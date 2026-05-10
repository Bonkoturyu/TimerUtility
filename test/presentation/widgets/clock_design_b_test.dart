import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/timezone_resolver_provider.dart';
import 'package:timer_utility/domain/clock/clock_location.dart';
import 'package:timer_utility/domain/clock/clock_time.dart';
import 'package:timer_utility/l10n/app_localizations.dart';
import 'package:timer_utility/presentation/widgets/clock_design_b.dart';

class _FixedResolver implements TimezoneResolver {
  _FixedResolver(this._returns);
  final DateTime _returns;
  @override
  DateTime computeAt(DateTime now, String timezoneId) => _returns;
}

ClockLocation _loc(int order, String name) => ClockLocation(
  id: 'id-$order',
  displayName: name,
  timezoneId: 'Etc/UTC',
  isCurrentLocation: order == 0,
  displayOrder: order,
  createdAt: DateTime.utc(2026, 1, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required List<ClockLocation> locations,
}) async {
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
          body: ClockDesignB(
            locations: locations,
            now: DateTime.utc(2026, 1, 15, 12),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ClockDesignB', () {
    testWidgets('6 件のロケーション displayName がすべて表示される', (
      WidgetTester tester,
    ) async {
      final List<ClockLocation> locations = <ClockLocation>[
        _loc(0, 'Tokyo'),
        _loc(1, 'New York'),
        _loc(2, 'London'),
        _loc(3, 'Paris'),
        _loc(4, 'Sydney'),
        _loc(5, 'Dubai'),
      ];
      await _pump(tester, locations: locations);
      for (final ClockLocation loc in locations) {
        expect(find.text(loc.displayName), findsOneWidget);
      }
    });

    testWidgets('locations 空のとき empty hint が key で見つかる', (
      WidgetTester tester,
    ) async {
      await _pump(tester, locations: const <ClockLocation>[]);
      expect(find.byKey(const Key('clock_design_b_empty')), findsOneWidget);
    });
  });
}
