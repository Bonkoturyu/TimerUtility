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
/// (`ClockDesignA/B/C`) inside a `PageView` so the user can horizontally
/// swipe between them; the active page is signalled by a dot indicator
/// pinned to the bottom of the body.
///
/// Tick ownership: this screen `watch`es `currentTimeProvider` exactly
/// once and passes the resulting `DateTime` down to all three design
/// children as a prop. The benefit isn't avoiding the construction of
/// off-page children — it's keeping the stream subscription centralised
/// here so each `ClockDesign*` stays stateless instead of independently
/// subscribing to the same 1 Hz source.
///
/// Editing locations is intentionally pulled out to a separate route
/// (`/clock/locations`, wired in Session 5) and surfaced via the AppBar
/// overflow only — there is no FAB on this screen because all three
/// designs are dense viewing layouts and a FAB would compete with the
/// dot indicator visually.
class ClockScreen extends ConsumerStatefulWidget {
  const ClockScreen({super.key});

  static const String routeLocation = '/clock';

  @override
  ConsumerState<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends ConsumerState<ClockScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

    // Single source of truth for "how many design pages exist". The
    // `_DotIndicator` reads its count off this list rather than holding
    // a duplicate literal `3`, so adding/removing a design touches one
    // place.
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
      body: Stack(
        children: <Widget>[
          PageView(
            controller: _controller,
            onPageChanged: (int i) => setState(() => _page = i),
            children: pages,
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _DotIndicator(count: pages.length, current: _page),
          ),
        ],
      ),
    );
  }
}

/// 3-dot page indicator pinned to the bottom of [ClockScreen]. Kept as
/// a private class because it has no reuse target outside this file —
/// pulling it out to its own widget file would just add an indirection.
class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
            child: Container(
              key: Key('clock_dot_$i'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == current
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
      ],
    );
  }
}
