import 'package:flutter/material.dart';

import '../../domain/alarm/day_of_week.dart';

/// 7 つの `FilterChip` を `Wrap` で並べた多重選択ウィジェット。
///
/// Phase 9.5 の AlarmEditScreen で「繰り返し: 曜日指定」を選んだ時に
/// 表示する。曜日の略称ラベルは presentation 層から (AppLocalizations
/// 経由で) 注入する想定で、本 widget は Pure な UI 部品として
/// `labels` を受け取るだけにする。
///
/// 状態は親が `Set<DayOfWeek>` で保持。チップタップ時に新しい Set を
/// `onChanged` に渡す (元の Set は immutable に扱う)。
///
/// 空集合の許容判定は呼び出し側 (AlarmEditScreen の保存時バリデーション)
/// に委ねる。本 widget は「全曜日チップを未選択にもできる」という UI
/// 動作だけを保証する。
class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  /// 現在の選択状態。
  final Set<DayOfWeek> value;

  /// 各曜日の表示用略称 (例: 月 / 火 / Mon / Tue)。
  /// 7 件すべてを含むことを呼び出し側が保証する。
  final Map<DayOfWeek, String> labels;

  /// 選択トグル時のコールバック。引数は新しい Set (defensive copy 済)。
  final ValueChanged<Set<DayOfWeek>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final DayOfWeek d in DayOfWeek.values)
          FilterChip(
            key: Key('weekday_chip_${d.name}'),
            label: Text(labels[d] ?? d.name),
            selected: value.contains(d),
            onSelected: (bool selected) {
              final Set<DayOfWeek> next = <DayOfWeek>{...value};
              if (selected) {
                next.add(d);
              } else {
                next.remove(d);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}
