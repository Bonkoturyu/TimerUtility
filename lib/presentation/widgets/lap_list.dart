import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/stopwatch_notifier.dart';
import '../../domain/shared/duration_formatter.dart';
import '../../domain/stopwatch/stopwatch_state.dart';

/// Vertical list of recorded laps. Newest at the top.
class LapList extends ConsumerWidget {
  const LapList({super.key, this.formatter = const DurationFormatter()});

  final DurationFormatter formatter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stopwatchNotifierProvider);
    final laps = switch (state) {
      StopwatchIdle() => const <LapRecord>[],
      StopwatchRunning(:final laps) => laps,
      StopwatchPaused(:final laps) => laps,
    };

    if (laps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No laps recorded'),
        ),
      );
    }

    final reversed = laps.reversed.toList();
    return ListView.separated(
      key: const Key('lap_list'),
      itemCount: reversed.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final lap = reversed[index];
        return ListTile(
          dense: true,
          leading: Text(
            'Lap ${lap.index}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          title: Text('Split ${formatter.formatStopwatch(lap.splitTime)}'),
          trailing: Text('Total ${formatter.formatStopwatch(lap.totalTime)}'),
        );
      },
    );
  }
}
