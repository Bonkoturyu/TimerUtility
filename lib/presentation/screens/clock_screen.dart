import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/clock_collection_notifier.dart';
import '../../application/clock_provider.dart';
import '../../application/clock_tick/current_time_stream_provider.dart';
import '../../domain/clock/clock_location.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/clock_design_a.dart';
import '../widgets/clock_design_b.dart';
import '../widgets/clock_design_c.dart';

/// Phase 10.5 world-clock hub screen. Hosts the three design variants
/// (`ClockDesignA/B/C`) and lets the user switch between them via a
/// `SegmentedButton`.
///
/// The earlier Phase 10.5 implementation used a horizontal `PageView`
/// for design switching. Phase 11 wraps the home screen itself in a
/// horizontal `PageView` (Stopwatch / Timer / Alarm / Clock tabs), so a
/// nested horizontal swipe inside Clock would fight the outer tab swipe
/// for gesture ownership. SegmentedButton sidesteps the conflict by
/// making the design switch tap-only.
///
/// Tick ownership: this screen `watch`es `currentTimeProvider` exactly
/// once and passes the resulting `DateTime` down to the active design
/// child as a prop. Centralising the stream subscription keeps each
/// `ClockDesign*` stateless instead of independently subscribing to the
/// same 1 Hz source.
///
/// Editing locations is intentionally pulled out to a separate route
/// (`/clock/locations`) and surfaced via the AppBar overflow only —
/// there is no FAB on this screen because all three designs are dense
/// viewing layouts and a FAB would compete with the SegmentedButton
/// visually.
class ClockScreen extends ConsumerStatefulWidget {
  const ClockScreen({super.key});

  static const String routeLocation = '/clock';

  @override
  ConsumerState<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends ConsumerState<ClockScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l.clockAppBarTitle),
        actions: <Widget>[
          PopupMenuButton<String>(
            key: const Key('clock_menu'),
            onSelected: (String value) {
              if (value == 'edit_locations') {
                context.push('/clock/locations');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit_locations',
                child: Text(l.clockMenuEditLocations),
              ),
            ],
          ),
        ],
      ),
      body: Column(
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
      ),
    );
  }
}
