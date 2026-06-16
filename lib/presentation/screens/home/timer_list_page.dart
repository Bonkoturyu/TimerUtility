import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/home_active_page_index_provider.dart';
import '../../../application/permission_notifier.dart';
import '../../../application/timer_collection_notifier.dart';
import '../../../application/timer_service_provider.dart';
import '../../../domain/shared/duration_formatter.dart';
import '../../../domain/timer/exceptions.dart';
import '../../../domain/timer/preset.dart';
import '../../../domain/timer/timer_collection.dart';
import '../../../domain/timer/timer_entity.dart';
import '../../../domain/timer/timer_status.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/duration_picker.dart';
import '../../widgets/permission_banners.dart';
import '../../widgets/preset_select_sheet.dart';
import '../preset_manage_screen.dart';
import '../../widgets/sound_select_sheet.dart';

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

/// Phase 11 Page widget. Body-only counterpart of the legacy
/// `TimerListScreen`. Owns the 200ms ticker that rebuilds running rows
/// and the `WidgetsBindingObserver` that re-checks permissions when
/// the app resumes from system Settings.
///
/// Ringing → `/alarm-ringing` push **does not live here**: PR #29 G1
/// moved it up to [HomeScreen] because this Page can be dispose()d by
/// the parent PageView when the user swipes two tabs away, which would
/// have lost the listener. See `HomeScreen.build` for the current
/// `ref.listen<TimerCollection>` site.
///
/// FAB construction is exposed via [TimerListPage.buildFab] and the add
/// flow via [TimerListPage.handleAddTap] so that both the deep-link
/// Screen wrapper and the new HomeScreen can share the same logic.
class TimerListPage extends ConsumerStatefulWidget {
  const TimerListPage({super.key});

  /// Logical HomeScreen tab index this Page occupies. Used by
  /// `homeActivePageIndexProvider`-driven ticker gating (PR #29
  /// follow-up #4) so the 200ms `Timer.periodic` pauses while the
  /// user is looking at another tab.
  static const int homeTabIndex = 1;

  /// FAB shared between the deep-link `TimerListScreen` wrapper and the
  /// HomeScreen's dynamic FAB slot. PR #29 follow-up #3: icon-only to
  /// match the Alarm / Clock FAB silhouette across all four tabs — the
  /// previous `FloatingActionButton.extended` morphed the button shape
  /// during PageView swipes. The "タイマーを追加" / "Add Timer" label
  /// survives as a tooltip (long-press / screen-reader).
  static FloatingActionButton buildFab(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    return FloatingActionButton(
      key: const Key('timer_list_add_fab'),
      tooltip: l.timerListAddFab,
      onPressed: () => handleAddTap(context, ref),
      child: const Icon(Icons.add),
    );
  }

  /// Add-timer flow (preset sheet → optional duration picker → create).
  /// Public so HomeScreen can wire its dynamic FAB to the same handler
  /// without copying the limit-reached SnackBar logic.
  static Future<void> handleAddTap(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l = AppLocalizations.of(context);
    await ref
        .read(permissionNotifierProvider.notifier)
        .ensureNotificationPermissionForScheduling();
    if (!context.mounted) return;
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

    final PresetSelectResult? selection =
        await showModalBottomSheet<PresetSelectResult>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const PresetSelectSheet(),
        );
    if (selection == null) return;
    if (!context.mounted) return;

    if (selection.preset != null) {
      _createTimerFrom(context, ref, selection.preset!);
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
      _createTimer(context, ref, label: '', duration: chosen, soundId: null);
      return;
    }
    if (selection.manageRequested) {
      unawaited(context.push(PresetManageScreen.routeLocation));
    }
  }

  static void _createTimerFrom(
    BuildContext context,
    WidgetRef ref,
    Preset preset,
  ) {
    _createTimer(
      context,
      ref,
      label: preset.label,
      duration: preset.duration,
      soundId: preset.soundId,
    );
  }

  static void _createTimer(
    BuildContext context,
    WidgetRef ref, {
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

  @override
  ConsumerState<TimerListPage> createState() => _TimerListPageState();
}

class _TimerListPageState extends ConsumerState<TimerListPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  Timer? _ticker;

  // PR #29 G2: keep timer-card scroll position and the running ticker
  // alive across HomeScreen tab swipes.
  @override
  bool get wantKeepAlive => true;

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
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionNotifierProvider.notifier).refresh();
    }
  }

  void _ensureTickerForState(TimerCollection collection, bool isVisible) {
    // PR #29 follow-up #4 (Copilot C3): gate the running-timer ticker
    // by visibility so a Timer kept alive across HomeScreen tab swipes
    // (via `AutomaticKeepAliveClientMixin`) does not burn CPU
    // repainting elapsed-time rows the user can't see. The
    // `endAt`-based elapsed calculation stays accurate during the
    // pause and catches up as soon as `isVisible` flips back to true.
    final bool shouldRun = collection.runningCount > 0 && isVisible;
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
    super.build(context); // AutomaticKeepAliveClientMixin contract.
    final TimerCollection collection = ref.watch(
      timerCollectionNotifierProvider,
    );
    // PR #29 follow-up #4: `null` = deep-link Screen mount (HomeScreen
    // absent → only Page on screen, run ticker); 0..3 = HomeScreen
    // hosted, compare to this Page's tab index.
    final int? active = ref.watch(homeActivePageIndexProvider);
    final bool isVisible =
        active == null || active == TimerListPage.homeTabIndex;
    _ensureTickerForState(collection, isVisible);

    // Phase 11 follow-up (PR #29 G1): the ringing→/alarm-ringing push
    // used to live here, but `TimerListPage` is dispose()d whenever the
    // user swipes to a non-adjacent tab in HomeScreen's PageView, which
    // would silently break the auto-push when a timer fires while
    // Stopwatch or Clock is on screen. The listener moved up to
    // `HomeScreen`, which is mounted for the whole HomeScreen lifetime.

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PermissionBanners(),
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
    );
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
