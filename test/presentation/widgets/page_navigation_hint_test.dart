import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/presentation/widgets/page_navigation_hint.dart';

void main() {
  group('PageNavigationHint', () {
    testWidgets('left 向き: chevron_left + アイコン + ラベル の順で並ぶ', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leadingWidth: 200,
              leading: PageNavigationHint(
                icon: Icons.timer,
                label: 'Stopwatch',
                direction: PageHintDirection.left,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('page_nav_hint_left')), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.text('Stopwatch'), findsOneWidget);
    });

    testWidgets('right 向き: ラベル + アイコン + chevron_right の順', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: <Widget>[
                PageNavigationHint(
                  icon: Icons.alarm,
                  label: 'Alarm',
                  direction: PageHintDirection.right,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('page_nav_hint_right')), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.alarm), findsOneWidget);
      expect(find.text('Alarm'), findsOneWidget);
    });

    testWidgets('タップで onTap callback が発火する', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leadingWidth: 200,
              leading: PageNavigationHint(
                icon: Icons.timer,
                label: 'Stopwatch',
                direction: PageHintDirection.left,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('page_nav_hint_left')));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });
}
