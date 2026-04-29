import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/permission_notifier.dart';
import '../../application/timer_notifier.dart';
import '../../domain/ports/permission_manager.dart';
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

  @override
  void initState() {
    super.initState();
    // Refresh permission state once when entering the screen.
    Future<void>.microtask(
      () => ref.read(permissionNotifierProvider.notifier).refresh(),
    );
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _PermissionBanners(),
            Expanded(
              child: entity == null
                  ? _buildSetup(context, ref)
                  : _buildActive(context, ref, entity),
            ),
          ],
        ),
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

/// Renders up to two stacked banners depending on permission state:
///   - POST_NOTIFICATIONS denied → warning (timer cannot show notifications)
///   - SCHEDULE_EXACT_ALARM denied → info (alarm may fire late under Doze)
///
/// Each banner offers a primary action (request) and, when the OS marks the
/// permission permanently denied, an "Open settings" fallback.
class _PermissionBanners extends ConsumerWidget {
  const _PermissionBanners();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(permissionNotifierProvider);
    final notifier = ref.read(permissionNotifierProvider.notifier);

    final List<Widget> banners = <Widget>[];

    if (state.postNotifications == DomainPermissionStatus.denied ||
        state.postNotifications == DomainPermissionStatus.permanentlyDenied) {
      banners.add(
        _PermissionBanner(
          key: const Key('banner_post_notifications'),
          icon: Icons.notifications_off_outlined,
          color: Colors.red.shade100,
          title: '通知が無効です',
          description: 'タイマーが終了したときに通知が表示されません。',
          actionLabel:
              state.postNotifications ==
                  DomainPermissionStatus.permanentlyDenied
              ? '設定を開く'
              : '許可する',
          onAction:
              state.postNotifications ==
                  DomainPermissionStatus.permanentlyDenied
              ? () => notifier.openSettings()
              : () => notifier.requestNotification(),
        ),
      );
    }

    if (state.scheduleExactAlarm == DomainPermissionStatus.denied ||
        state.scheduleExactAlarm == DomainPermissionStatus.permanentlyDenied) {
      banners.add(
        _PermissionBanner(
          key: const Key('banner_exact_alarm'),
          icon: Icons.alarm_off_outlined,
          color: Colors.orange.shade100,
          title: '正確なアラームが無効です',
          description: '省電力モード時にアラームが数分遅れる場合があります。',
          actionLabel:
              state.scheduleExactAlarm ==
                  DomainPermissionStatus.permanentlyDenied
              ? '設定を開く'
              : '許可する',
          onAction:
              state.scheduleExactAlarm ==
                  DomainPermissionStatus.permanentlyDenied
              ? () => notifier.openSettings()
              : () => notifier.requestScheduleExactAlarm(),
        ),
      );
    }

    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final banner in banners) ...<Widget>[
          banner,
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(description),
                ],
              ),
            ),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
