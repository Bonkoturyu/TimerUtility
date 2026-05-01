import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/permission_notifier.dart';
import '../../application/timer_collection_notifier.dart';
import '../../application/timer_service_provider.dart';
import '../../domain/ports/permission_manager.dart';
import '../../domain/shared/duration_formatter.dart';
import '../../domain/timer/exceptions.dart';
import '../../domain/timer/timer_collection.dart';
import '../../domain/timer/timer_entity.dart';
import '../../domain/timer/timer_status.dart';
import '../widgets/duration_picker.dart';

/// Phase 8 multi-timer screen. Replaces the Phase 3 single-timer
/// screen; reads the entire [TimerCollection] from
/// [TimerCollectionNotifier] and exposes per-timer controls in a card
/// list.
///
/// FAB opens the existing [DurationPicker]; when the collection is at
/// the 10-timer cap, tapping the FAB instead surfaces a SnackBar telling
/// the user to delete an existing timer first (rather than disabling
/// the button, which is visually too subtle on FloatingActionButton).
class TimerListScreen extends ConsumerStatefulWidget {
  const TimerListScreen({super.key});

  @override
  ConsumerState<TimerListScreen> createState() => _TimerListScreenState();
}

class _TimerListScreenState extends ConsumerState<TimerListScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(permissionNotifierProvider.notifier).refresh(),
    );
  }

  void _ensureTickerForState(TimerCollection collection) {
    final bool shouldRun = collection.runningCount > 0;
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
    final TimerCollection collection = ref.watch(
      timerCollectionNotifierProvider,
    );
    _ensureTickerForState(collection);

    // When any timer flips to `ringing` for the first time, push the
    // dedicated alarm screen. We compare the previous ringing-count to
    // the next one to decide whether to navigate so re-renders during
    // the alarm screen don't re-push.
    ref.listen<TimerCollection>(timerCollectionNotifierProvider, (
      TimerCollection? prev,
      TimerCollection next,
    ) {
      final int prevRinging =
          prev?.all
              .where((TimerEntity t) => t.status == TimerStatus.ringing)
              .length ??
          0;
      final int nextRinging = next.all
          .where((TimerEntity t) => t.status == TimerStatus.ringing)
          .length;
      if (nextRinging > prevRinging) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final String here = GoRouterState.of(context).matchedLocation;
          if (here == '/alarm-ringing') return;
          context.push('/alarm-ringing');
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Timers')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _PermissionBanners(),
            Expanded(
              child: collection.isEmpty
                  ? const _EmptyHint()
                  : ListView.separated(
                      itemCount: collection.size,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) =>
                          _TimerCard(entity: collection.all[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('timer_list_add_fab'),
        // Always tappable. We could pass `null` when full to disable
        // the button, but FloatingActionButton.extended's disabled
        // state is visually subtle (no obvious greyout) so users see
        // a "broken" button rather than a meaningful "limit reached"
        // signal. Instead we keep it active and route the limit case
        // through a SnackBar in `_onAddTap` below.
        onPressed: () => _onAddTap(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Timer'),
      ),
    );
  }

  Future<void> _onAddTap(BuildContext context) async {
    // Surface the limit before opening the picker so the user doesn't
    // configure a duration only to have it rejected on confirm.
    final TimerCollection current = ref.read(timerCollectionNotifierProvider);
    if (current.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('上限 ${TimerCollection.maxSize} 件に達しています')),
      );
      return;
    }

    final Duration? chosen = await showModalBottomSheet<Duration>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const DurationPicker(),
    );
    if (chosen == null) return;
    if (!context.mounted) return;
    try {
      ref
          .read(timerCollectionNotifierProvider.notifier)
          .create(label: '', duration: chosen);
    } on MaxTimerCountExceededException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('上限 ${e.maxSize} 件に達しています')));
    }
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'タイマーがありません。\n右下の「Add Timer」から追加できます。',
          key: Key('timer_list_empty_hint'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _TimerCard extends ConsumerWidget {
  const _TimerCard({required this.entity});

  final TimerEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timerCollectionNotifierProvider.notifier);
    final liveRemaining = ref.read(timerServiceProvider).remaining(entity);
    final Duration display = switch (entity.status) {
      TimerStatus.running || TimerStatus.paused => liveRemaining,
      TimerStatus.idle ||
      TimerStatus.completed ||
      TimerStatus.cancelled => entity.duration,
      TimerStatus.ringing => Duration.zero,
    };
    const DurationFormatter formatter = DurationFormatter();

    return Card(
      key: Key('timer_card_${entity.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    entity.status == TimerStatus.ringing
                        ? "Time's up!"
                        : formatter.formatTimer(display),
                    key: Key('timer_display_${entity.id}'),
                    style: const TextStyle(
                      fontSize: 32,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Chip(label: Text(entity.status.name)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildPrimaryButton(notifier),
                OutlinedButton(
                  key: Key('timer_card_${entity.id}_delete'),
                  onPressed: () => notifier.delete(entity.id),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(TimerCollectionNotifier notifier) {
    return switch (entity.status) {
      TimerStatus.idle => FilledButton(
        key: Key('timer_card_${entity.id}_start'),
        onPressed: () => notifier.start(entity.id),
        child: const Text('Start'),
      ),
      TimerStatus.running => FilledButton(
        key: Key('timer_card_${entity.id}_pause'),
        onPressed: () => notifier.pause(entity.id),
        child: const Text('Pause'),
      ),
      TimerStatus.paused => FilledButton(
        key: Key('timer_card_${entity.id}_resume'),
        onPressed: () => notifier.resume(entity.id),
        child: const Text('Resume'),
      ),
      TimerStatus.ringing => FilledButton(
        key: Key('timer_card_${entity.id}_dismiss'),
        onPressed: () => notifier.cancel(entity.id),
        child: const Text('Dismiss'),
      ),
      TimerStatus.completed || TimerStatus.cancelled => FilledButton(
        key: Key('timer_card_${entity.id}_reset'),
        onPressed: () => notifier.reset(entity.id),
        child: const Text('Reset'),
      ),
    };
  }
}

/// Same banner stack as the Phase 3 screen, copied because the Phase 3
/// screen is being deleted as part of Phase 8 cleanup. Future home is
/// a shared `presentation/widgets/permission_banners.dart` whenever a
/// third caller appears.
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

    if (state.fullScreenIntent == DomainPermissionStatus.denied ||
        state.fullScreenIntent == DomainPermissionStatus.permanentlyDenied) {
      banners.add(
        _PermissionBanner(
          key: const Key('banner_full_screen_intent'),
          icon: Icons.lock_outline,
          color: Colors.amber.shade100,
          title: 'ロック画面でのアラームが無効です',
          description: '権限がない場合は通知バナーで代わりにお知らせします。',
          actionLabel: '設定を開く',
          onAction: () => notifier.openFullScreenIntentSettings(),
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
