import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timer_notifier.dart';
import '../../domain/shared/duration_formatter.dart';
import '../../domain/timer/timer_entity.dart';
import '../../domain/timer/timer_status.dart';

/// Phase 3 single-timer screen. No notifications, no sound — those land in
/// Phase 4 / 5. The screen has two visual modes:
///   1. Setup: no timer configured (notifier state = null) — shows duration
///      preset chips. Picking one creates an idle timer.
///   2. Active: timer present (idle/running/paused/ringing/completed/cancelled)
///      — shows countdown, primary action button, and Cancel.
class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  static const DurationFormatter _formatter = DurationFormatter();
  static const List<Duration> _presets = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 3),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];

  Timer? _ticker;

  void _ensureTickerForState(TimerEntity? entity) {
    final shouldRun = entity?.status == TimerStatus.running;
    if (shouldRun && _ticker == null) {
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
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
    final entity = ref.watch(timerNotifierProvider);
    _ensureTickerForState(entity);

    return Scaffold(
      appBar: AppBar(title: const Text('Timer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: entity == null
            ? _buildSetup(context, ref)
            : _buildActive(context, ref, entity),
      ),
    );
  }

  Widget _buildSetup(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timerNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'Choose a duration',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (final d in _presets)
              FilledButton(
                key: Key('timer_preset_${d.inSeconds}s'),
                onPressed: () => notifier.create(label: '', duration: d),
                child: Text(_formatter.formatTimer(d)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActive(BuildContext context, WidgetRef ref, TimerEntity entity) {
    final notifier = ref.read(timerNotifierProvider.notifier);
    final liveRemaining = ref.read(timerServiceProvider).remaining(entity);
    // For non-active statuses, show the configured duration instead of zero.
    final displayDuration = switch (entity.status) {
      TimerStatus.running || TimerStatus.paused => liveRemaining,
      TimerStatus.idle ||
      TimerStatus.completed ||
      TimerStatus.cancelled => entity.duration,
      TimerStatus.ringing => Duration.zero,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 24),
        Center(
          child: Text(
            entity.status == TimerStatus.ringing
                ? "Time's up!"
                : _formatter.formatTimer(displayDuration),
            key: const Key('timer_display'),
            style: const TextStyle(
              fontSize: 56,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Status: ${entity.status.name}',
            key: const Key('timer_status_label'),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _buildPrimaryButton(entity, notifier),
            OutlinedButton(
              key: const Key('timer_cancel_button'),
              onPressed: notifier.clear,
              child: const Text('Back'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(TimerEntity entity, TimerNotifier notifier) {
    return switch (entity.status) {
      TimerStatus.idle => FilledButton(
        key: const Key('timer_start_button'),
        onPressed: notifier.start,
        child: const Text('Start'),
      ),
      TimerStatus.running => FilledButton(
        key: const Key('timer_pause_button'),
        onPressed: notifier.pause,
        child: const Text('Pause'),
      ),
      TimerStatus.paused => FilledButton(
        key: const Key('timer_resume_button'),
        onPressed: notifier.resume,
        child: const Text('Resume'),
      ),
      TimerStatus.ringing => FilledButton(
        key: const Key('timer_dismiss_button'),
        onPressed: notifier.cancel,
        child: const Text('Dismiss'),
      ),
      TimerStatus.completed || TimerStatus.cancelled => FilledButton(
        key: const Key('timer_reset_button'),
        onPressed: notifier.reset,
        child: const Text('Reset'),
      ),
    };
  }
}
