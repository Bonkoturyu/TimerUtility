import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../widgets/sound_select_sheet.dart';
import '../alarm_ringing_screen.dart' show AlarmRingingScreen;

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
/// `TimerListScreen`. Owns the 200ms ticker, the `WidgetsBindingObserver`
/// for permission refresh on resume, and the `ref.listen` that pushes
/// `/alarm-ringing` when a timer flips to ringing.
///
/// FAB construction is exposed via [TimerListPage.buildFab] and the add
/// flow via [TimerListPage.handleAddTap] so that both the deep-link
/// Screen wrapper and the new HomeScreen can share the same logic.
class TimerListPage extends ConsumerStatefulWidget {
  const TimerListPage({super.key});

  /// FAB shared between the deep-link `TimerListScreen` wrapper and the
  /// HomeScreen's dynamic FAB slot.
  static FloatingActionButton buildFab(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    return FloatingActionButton.extended(
      key: const Key('timer_list_add_fab'),
      onPressed: () => handleAddTap(context, ref),
      icon: const Icon(Icons.add),
      label: Text(l.timerListAddFab),
    );
  }

  /// Add-timer flow (preset sheet → optional duration picker → create).
  /// Public so HomeScreen can wire its dynamic FAB to the same handler
  /// without copying the limit-reached SnackBar logic.
  static Future<void> handleAddTap(BuildContext context, WidgetRef ref) async {
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
          if (!AlarmRingingScreen.tryReservePush()) return;
          context.push('/alarm-ringing');
        });
      }
    });

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
