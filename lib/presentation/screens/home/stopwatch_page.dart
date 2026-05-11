import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/home_active_page_index_provider.dart';
import '../../../application/stopwatch_notifier.dart';
import '../../../domain/shared/duration_formatter.dart';
import '../../../domain/stopwatch/stopwatch_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/lap_list.dart';

/// Phase 11 Page widget. Body-only counterpart of the legacy
/// `StopwatchScreen` — owns the 100ms ticker that re-paints the
/// elapsed-time readout while running. Carries no FAB and no AppBar
/// overflow, so HomeScreen / the deep-link Screen wrapper supply only
/// the chrome around it.
class StopwatchPage extends ConsumerStatefulWidget {
  const StopwatchPage({super.key});

  /// Logical HomeScreen tab index this Page occupies. Used by
  /// `homeActivePageIndexProvider`-driven ticker gating (PR #29
  /// follow-up #4) so the 100ms `Timer.periodic` pauses while the
  /// user is looking at another tab.
  static const int homeTabIndex = 0;

  @override
  ConsumerState<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends ConsumerState<StopwatchPage>
    with AutomaticKeepAliveClientMixin {
  static const DurationFormatter _formatter = DurationFormatter();

  Timer? _ticker;

  // PR #29 G2: keep the running stopwatch state alive even when the
  // user swipes to another HomeScreen tab — without this the page is
  // dispose()d on tab change and the elapsed-time readout resets.
  @override
  bool get wantKeepAlive => true;

  void _ensureTickerForState(StopwatchState state, bool isVisible) {
    // PR #29 follow-up #4 (Copilot C4): gate the running-stopwatch
    // ticker by visibility so a Stopwatch kept alive across HomeScreen
    // tab swipes (via `AutomaticKeepAliveClientMixin`) does not burn
    // CPU repainting elapsed time the user can't see. The state-
    // machine `elapsed` calculation stays accurate during the pause
    // and catches up as soon as `isVisible` flips back to true.
    final bool shouldRun = state is StopwatchRunning && isVisible;
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
    super.build(context); // AutomaticKeepAliveClientMixin contract.
    final state = ref.watch(stopwatchNotifierProvider);
    // PR #29 follow-up #4: `null` = deep-link Screen mount (HomeScreen
    // absent → only Page on screen, run ticker); 0..3 = HomeScreen
    // hosted, compare to this Page's tab index.
    final int? active = ref.watch(homeActivePageIndexProvider);
    final bool isVisible =
        active == null || active == StopwatchPage.homeTabIndex;
    _ensureTickerForState(state, isVisible);

    final elapsed = ref.read(stopwatchServiceProvider).elapsed(state);

    return Column(
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
    );
  }
}

class _ControlBar extends ConsumerWidget {
  const _ControlBar({required this.state});

  final StopwatchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(stopwatchNotifierProvider.notifier);
    final AppLocalizations l = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        switch (state) {
          StopwatchIdle() => FilledButton(
            key: const Key('stopwatch_start_button'),
            onPressed: notifier.start,
            child: Text(l.stopwatchStart),
          ),
          StopwatchRunning() => FilledButton(
            key: const Key('stopwatch_pause_button'),
            onPressed: notifier.pause,
            child: Text(l.stopwatchPause),
          ),
          StopwatchPaused() => FilledButton(
            key: const Key('stopwatch_resume_button'),
            onPressed: notifier.resume,
            child: Text(l.stopwatchResume),
          ),
        },
        OutlinedButton(
          key: const Key('stopwatch_lap_button'),
          onPressed: state is StopwatchRunning ? notifier.lap : null,
          child: Text(l.stopwatchLap),
        ),
        OutlinedButton(
          key: const Key('stopwatch_reset_button'),
          onPressed: state is StopwatchIdle ? null : notifier.reset,
          child: Text(l.stopwatchReset),
        ),
      ],
    );
  }
}
