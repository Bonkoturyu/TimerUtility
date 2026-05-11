import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/clock_collection_notifier.dart';
import '../../../application/clock_provider.dart';
import '../../../application/clock_tick/current_time_stream_provider.dart';
import '../../../domain/clock/clock_location.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/clock_design_a.dart';
import '../../widgets/clock_design_b.dart';
import '../../widgets/clock_design_c.dart';

/// Phase 11 Page widget. Body-only counterpart of the Phase 10.5
/// `ClockScreen`. Hosts the three design variants (`ClockDesignA/B/C`)
/// and lets the user switch between them via a `SegmentedButton`.
///
/// Tick ownership: this widget `watch`es `currentTimeProvider` exactly
/// once and passes the resulting `DateTime` down to the active design
/// child as a prop. Centralising the stream subscription keeps each
/// `ClockDesign*` stateless instead of independently subscribing to the
/// same 1 Hz source.
class ClockPage extends ConsumerStatefulWidget {
  const ClockPage({super.key});

  /// FAB shared between the deep-link `ClockScreen` wrapper and the
  /// HomeScreen's dynamic FAB slot. Mirrors the Timer / Alarm tabs'
  /// "right-bottom + → edit screen" pattern so the Clock tab no longer
  /// hides the entry-point inside the AppBar overflow (PR #29 follow-up
  /// #2). The destination `/clock/locations` is the existing add /
  /// edit / reorder screen — only the entry-point UX changes.
  static FloatingActionButton buildFab(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return FloatingActionButton(
      key: const Key('clock_list_add_fab'),
      tooltip: l.clockListAddFab,
      onPressed: () => context.push('/clock/locations'),
      child: const Icon(Icons.add),
    );
  }

  @override
  ConsumerState<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends ConsumerState<ClockPage>
    with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;

  // PR #29 G2: keep the selected design segment (analog / digital /
  // compact) alive across HomeScreen tab swipes — without this the
  // SegmentedButton resets to Analog every time the user comes back.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin contract.
    final AppLocalizations l = AppLocalizations.of(context);
    final AsyncValue<DateTime> nowAsync = ref.watch(currentTimeProvider);
    final List<ClockLocation> locations = ref
        .watch(clockCollectionNotifierProvider)
        .all;
    // `currentTimeProvider` is backed by `Stream.multi` which emits the
    // initial value synchronously, so the loading branch is essentially
    // unreachable in steady state. We still need a fallback for the
    // first frame on a cold rebuild — `clockProvider` is the project's
    // `DateTime.now()` seam (CLAUDE.md bans direct `DateTime.now()`
    // calls), so the fallback goes through it.
    final DateTime now = nowAsync.when(
      data: (DateTime n) => n,
      loading: () => ref.read(clockProvider).now(),
      error: (_, _) => ref.read(clockProvider).now(),
    );

    final List<Widget> pages = <Widget>[
      ClockDesignA(locations: locations, now: now),
      ClockDesignB(locations: locations, now: now),
      ClockDesignC(locations: locations, now: now),
    ];

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SegmentedButton<int>(
            key: const Key('clock_design_segmented'),
            segments: <ButtonSegment<int>>[
              ButtonSegment<int>(
                value: 0,
                label: Text(l.clockDesignSegmentAnalog),
                icon: const Icon(Icons.access_time),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text(l.clockDesignSegmentDigital),
                icon: const Icon(Icons.numbers),
              ),
              ButtonSegment<int>(
                value: 2,
                label: Text(l.clockDesignSegmentCompact),
                icon: const Icon(Icons.grid_view),
              ),
            ],
            selected: <int>{_selectedIndex},
            onSelectionChanged: (Set<int> selection) {
              setState(() => _selectedIndex = selection.first);
            },
          ),
        ),
        Expanded(child: pages[_selectedIndex]),
      ],
    );
  }
}
