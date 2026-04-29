import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/stopwatch_notifier.dart';
import '../../domain/shared/duration_formatter.dart';
import '../../domain/stopwatch/stopwatch_state.dart';
import '../widgets/lap_list.dart';

class StopwatchScreen extends ConsumerStatefulWidget {
  const StopwatchScreen({super.key});

  @override
  ConsumerState<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends ConsumerState<StopwatchScreen> {
  static const DurationFormatter _formatter = DurationFormatter();

  Timer? _ticker;

  void _ensureTickerForState(StopwatchState state) {
    final shouldRun = state is StopwatchRunning;
    if (shouldRun && _ticker == null) {
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) setState(() {});
      });
    } else if (!shouldRun && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stopwatchNotifierProvider);
    _ensureTickerForState(state);

    final elapsed = ref.read(stopwatchServiceProvider).elapsed(state);

    return Scaffold(
      appBar: AppBar(title: const Text('Stopwatch')),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 24),
          Center(
            child: Text(
              _formatter.formatStopwatch(elapsed),
              key: const Key('stopwatch_display'),
              style: const TextStyle(
                fontSize: 56,
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ControlBar(state: state),
          const SizedBox(height: 16),
          const Expanded(child: LapList()),
        ],
      ),
    );
  }
}

class _ControlBar extends ConsumerWidget {
  const _ControlBar({required this.state});

  final StopwatchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(stopwatchNotifierProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        switch (state) {
          StopwatchIdle() => FilledButton(
            key: const Key('stopwatch_start_button'),
            onPressed: notifier.start,
            child: const Text('Start'),
          ),
          StopwatchRunning() => FilledButton(
            key: const Key('stopwatch_pause_button'),
            onPressed: notifier.pause,
            child: const Text('Pause'),
          ),
          StopwatchPaused() => FilledButton(
            key: const Key('stopwatch_resume_button'),
            onPressed: notifier.resume,
            child: const Text('Resume'),
          ),
        },
        OutlinedButton(
          key: const Key('stopwatch_lap_button'),
          onPressed: state is StopwatchRunning ? notifier.lap : null,
          child: const Text('Lap'),
        ),
        OutlinedButton(
          key: const Key('stopwatch_reset_button'),
          onPressed: state is StopwatchIdle ? null : notifier.reset,
          child: const Text('Reset'),
        ),
      ],
    );
  }
}
