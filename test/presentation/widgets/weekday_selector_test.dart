import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/alarm/day_of_week.dart';
import 'package:timer_utility/presentation/widgets/weekday_selector.dart';

const Map<DayOfWeek, String> _testLabels = <DayOfWeek, String>{
  DayOfWeek.monday: '月',
  DayOfWeek.tuesday: '火',
  DayOfWeek.wednesday: '水',
  DayOfWeek.thursday: '木',
  DayOfWeek.friday: '金',
  DayOfWeek.saturday: '土',
  DayOfWeek.sunday: '日',
};

/// 親側の Set 保持を rebuild で失わない harness。
class _Harness extends StatefulWidget {
  const _Harness({required this.initial, required this.onChanged});
  final Set<DayOfWeek> initial;
  final ValueChanged<Set<DayOfWeek>> onChanged;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late Set<DayOfWeek> _current = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: WeekdaySelector(
          value: _current,
          labels: _testLabels,
          onChanged: (Set<DayOfWeek> next) {
            setState(() => _current = next);
            widget.onChanged(next);
          },
        ),
      ),
    );
  }
}

Widget _harness({
  required Set<DayOfWeek> initial,
  required ValueChanged<Set<DayOfWeek>> onChanged,
}) => _Harness(initial: initial, onChanged: onChanged);

void main() {
  group('WeekdaySelector', () {
    testWidgets('全 7 曜日のチップが描画される', (WidgetTester tester) async {
      await tester.pumpWidget(
        _harness(initial: <DayOfWeek>{}, onChanged: (_) {}),
      );
      for (final DayOfWeek d in DayOfWeek.values) {
        expect(find.byKey(Key('weekday_chip_${d.name}')), findsOneWidget);
      }
      expect(find.text('月'), findsOneWidget);
      expect(find.text('日'), findsOneWidget);
    });

    testWidgets('未選択のチップをタップすると onChanged で追加される', (WidgetTester tester) async {
      Set<DayOfWeek>? lastEmitted;
      await tester.pumpWidget(
        _harness(
          initial: <DayOfWeek>{},
          onChanged: (Set<DayOfWeek> v) => lastEmitted = v,
        ),
      );
      await tester.tap(find.byKey(const Key('weekday_chip_monday')));
      await tester.pumpAndSettle();

      expect(lastEmitted, <DayOfWeek>{DayOfWeek.monday});
    });

    testWidgets('既選択のチップをタップすると onChanged で削除される', (WidgetTester tester) async {
      Set<DayOfWeek>? lastEmitted;
      await tester.pumpWidget(
        _harness(
          initial: <DayOfWeek>{DayOfWeek.monday, DayOfWeek.friday},
          onChanged: (Set<DayOfWeek> v) => lastEmitted = v,
        ),
      );
      await tester.tap(find.byKey(const Key('weekday_chip_monday')));
      await tester.pumpAndSettle();

      expect(lastEmitted, <DayOfWeek>{DayOfWeek.friday});
    });

    testWidgets('複数曜日を順次タップすると累積する', (WidgetTester tester) async {
      final List<Set<DayOfWeek>> emissions = <Set<DayOfWeek>>[];
      await tester.pumpWidget(
        _harness(initial: <DayOfWeek>{}, onChanged: emissions.add),
      );
      await tester.tap(find.byKey(const Key('weekday_chip_monday')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('weekday_chip_wednesday')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('weekday_chip_friday')));
      await tester.pumpAndSettle();

      expect(emissions.last, <DayOfWeek>{
        DayOfWeek.monday,
        DayOfWeek.wednesday,
        DayOfWeek.friday,
      });
    });

    testWidgets('FilterChip の selected 状態が value と一致する', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          initial: <DayOfWeek>{DayOfWeek.tuesday, DayOfWeek.thursday},
          onChanged: (_) {},
        ),
      );
      // FilterChip の selected プロパティは描画から直接読み取れないため、
      // チェックマークアイコン (Material 3 では `Icons.done`) の有無で
      // 代用する。
      final FilterChip chipMon = tester.widget<FilterChip>(
        find.byKey(const Key('weekday_chip_monday')),
      );
      final FilterChip chipTue = tester.widget<FilterChip>(
        find.byKey(const Key('weekday_chip_tuesday')),
      );
      expect(chipMon.selected, isFalse);
      expect(chipTue.selected, isTrue);
    });
  });
}
