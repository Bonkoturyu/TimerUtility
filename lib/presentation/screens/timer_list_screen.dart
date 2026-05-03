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
import '../../domain/timer/preset.dart';
import '../../domain/timer/timer_collection.dart';
import '../../domain/timer/timer_entity.dart';
import '../../domain/timer/timer_status.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/duration_picker.dart';
import '../widgets/preset_select_sheet.dart';
import '../widgets/sound_select_sheet.dart';
import 'alarm_ringing_screen.dart' show AlarmRingingScreen;

/// Maps a [TimerStatus] enum value to the localized string used in the
/// status badge / chip on each timer card.
String _localizedStatus(AppLocalizations l, TimerStatus status) {
  return switch (status) {
    TimerStatus.idle => l.timerStatusIdle,
    TimerStatus.running => l.timerStatusRunning,
    TimerStatus.paused => l.timerStatusPaused,
    TimerStatus.ringing => l.timerStatusRinging,
    TimerStatus.completed => l.timerStatusCompleted,
    TimerStatus.cancelled => l.timerStatusCancelled,
  };
}

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

class _TimerListScreenState extends ConsumerState<TimerListScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(
      () => ref.read(permissionNotifierProvider.notifier).refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns from the system Settings page (granted /
    // revoked a permission), Android sends `resumed`. Re-query so the
    // permission banners reflect the new state without requiring the
    // user to navigate away and back.
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionNotifierProvider.notifier).refresh();
    }
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
    WidgetsBinding.instance.removeObserver(this);
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
          // matchedLocation is best-effort and can race with the
          // notification-tap push when both fire in the same frame.
          // Defer to the synchronous reservation flag — only one path
          // actually pushes.
          if (!AlarmRingingScreen.tryReservePush()) return;
          context.push('/alarm-ringing');
        });
      }
    });

    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.timerListAppBarTitle),
        actions: <Widget>[
          PopupMenuButton<String>(
            key: const Key('timer_list_menu'),
            onSelected: (String value) {
              if (value == 'manage_presets') {
                context.push('/presets');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                key: const Key('timer_list_menu_manage_presets'),
                value: 'manage_presets',
                child: Text(l.presetManageMenuOverflow),
              ),
            ],
          ),
        ],
      ),
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
        label: Text(l.timerListAddFab),
      ),
    );
  }

  Future<void> _onAddTap(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context);
    // Surface the limit before opening the picker so the user doesn't
    // configure a duration only to have it rejected on confirm.
    final TimerCollection current = ref.read(timerCollectionNotifierProvider);
    if (current.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.timerListLimitReached(TimerCollection.maxSize)),
        ),
      );
      return;
    }

    // Phase 9: bottom sheet first — pick a saved preset, or fall back
    // to the existing custom-time DurationPicker via the explicit
    // "Create with custom time" button.
    final PresetSelectResult? selection =
        await showModalBottomSheet<PresetSelectResult>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const PresetSelectSheet(),
        );
    if (selection == null) return;
    if (!context.mounted) return;

    if (selection.preset != null) {
      _createTimerFrom(context, selection.preset!);
      return;
    }
    if (selection.customRequested) {
      final Duration? chosen = await showModalBottomSheet<Duration>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const DurationPicker(),
      );
      if (chosen == null) return;
      if (!context.mounted) return;
      // Custom-time creation uses the catalog default sound; the
      // user can swap it from the timer card's sound icon afterwards.
      _createTimer(context, label: '', duration: chosen, soundId: null);
    }
  }

  void _createTimerFrom(BuildContext context, Preset preset) {
    _createTimer(
      context,
      label: preset.label,
      duration: preset.duration,
      soundId: preset.soundId,
    );
  }

  void _createTimer(
    BuildContext context, {
    required String label,
    required Duration duration,
    required String? soundId,
  }) {
    final AppLocalizations l = AppLocalizations.of(context);
    try {
      ref
          .read(timerCollectionNotifierProvider.notifier)
          .create(label: label, duration: duration, soundId: soundId);
    } on MaxTimerCountExceededException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.timerListLimitReached(e.maxSize))),
      );
    }
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l.timerListEmptyHint,
          key: const Key('timer_list_empty_hint'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
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
    final AppLocalizations l = AppLocalizations.of(context);
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
            // When the source preset had a user label (or the user typed
            // one), keep it visible above the big duration so a list of
            // multiple cards is still distinguishable at a glance.
            if (entity.label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  entity.label,
                  key: Key('timer_label_${entity.id}'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    entity.status == TimerStatus.ringing
                        ? l.timerCardTimesUp
                        : formatter.formatTimer(display),
                    key: Key('timer_display_${entity.id}'),
                    style: const TextStyle(
                      fontSize: 32,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Chip(label: Text(_localizedStatus(l, entity.status))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildPrimaryButton(notifier, l),
                IconButton(
                  key: Key('timer_card_${entity.id}_sound'),
                  tooltip: l.timerCardSoundChange,
                  icon: const Icon(Icons.music_note),
                  onPressed: () => _onChangeSound(context, ref),
                ),
                OutlinedButton(
                  key: Key('timer_card_${entity.id}_delete'),
                  onPressed: () => notifier.delete(entity.id),
                  child: Text(l.timerCardActionDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onChangeSound(BuildContext context, WidgetRef ref) async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SoundSelectSheet(initialSoundId: entity.soundId),
    );
    if (picked == null) return;
    ref
        .read(timerCollectionNotifierProvider.notifier)
        .changeSound(entity.id, picked);
  }

  Widget _buildPrimaryButton(
    TimerCollectionNotifier notifier,
    AppLocalizations l,
  ) {
    return switch (entity.status) {
      TimerStatus.idle => FilledButton(
        key: Key('timer_card_${entity.id}_start'),
        onPressed: () => notifier.start(entity.id),
        child: Text(l.timerCardActionStart),
      ),
      TimerStatus.running => FilledButton(
        key: Key('timer_card_${entity.id}_pause'),
        onPressed: () => notifier.pause(entity.id),
        child: Text(l.timerCardActionPause),
      ),
      TimerStatus.paused => FilledButton(
        key: Key('timer_card_${entity.id}_resume'),
        onPressed: () => notifier.resume(entity.id),
        child: Text(l.timerCardActionResume),
      ),
      TimerStatus.ringing => FilledButton(
        key: Key('timer_card_${entity.id}_dismiss'),
        onPressed: () => notifier.cancel(entity.id),
        child: Text(l.timerCardActionDismiss),
      ),
      TimerStatus.completed || TimerStatus.cancelled => FilledButton(
        key: Key('timer_card_${entity.id}_reset'),
        onPressed: () => notifier.reset(entity.id),
        child: Text(l.timerCardActionReset),
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
    final AppLocalizations l = AppLocalizations.of(context);

    final List<Widget> banners = <Widget>[];

    if (state.postNotifications == DomainPermissionStatus.denied ||
        state.postNotifications == DomainPermissionStatus.permanentlyDenied) {
      banners.add(
        _PermissionBanner(
          key: const Key('banner_post_notifications'),
          icon: Icons.notifications_off_outlined,
          color: Colors.red.shade100,
          title: l.permissionBannerNotificationsTitle,
          description: l.permissionBannerNotificationsDescription,
          actionLabel:
              state.postNotifications ==
                  DomainPermissionStatus.permanentlyDenied
              ? l.permissionBannerActionOpenSettings
              : l.permissionBannerActionAllow,
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
          title: l.permissionBannerExactAlarmTitle,
          description: l.permissionBannerExactAlarmDescription,
          actionLabel:
              state.scheduleExactAlarm ==
                  DomainPermissionStatus.permanentlyDenied
              ? l.permissionBannerActionOpenSettings
              : l.permissionBannerActionAllow,
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
          title: l.permissionBannerFullScreenIntentTitle,
          description: l.permissionBannerFullScreenIntentDescription,
          actionLabel: l.permissionBannerActionOpenSettings,
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
