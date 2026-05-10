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
  // Pseudo-infinite PageView so swiping past Design C loops back to A
  // (and vice versa). PageView itself can't wrap, so we offer a very
  // large itemCount and start from the centre — the user would have
  // to swipe 1000+ times to hit either edge. `index % pages.length`
  // maps the raw page back to the actual design index.
  // The initial value must be a multiple of `pages.length` (3) so the
  // first frame shows Design A, not B/C.
  static const int _initialRawPage = 3000;

  final PageController _controller = PageController(
    initialPage: _initialRawPage,
  );
  int _rawPage = _initialRawPage;

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
          PageView.builder(
            controller: _controller,
            onPageChanged: (int i) => setState(() => _rawPage = i),
            // null itemCount = unbounded scrolling in both directions.
            itemBuilder: (BuildContext context, int index) =>
                pages[index % pages.length],
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: _DotIndicator(
              count: pages.length,
              current: _rawPage % pages.length,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page indicator pinned to the bottom of [ClockScreen]. Kept as a
/// private class because it has no reuse target outside this file —
/// pulling it out to its own widget file would just add an indirection.
///
/// Visual: active dot is a 24×10 pill (Material 3 "expressive" page
/// indicator pattern), inactive dots are 10×10 circles. The whole row
/// sits on a translucent `surfaceContainerHigh` capsule so it stays
/// legible over Design B/C content. The earlier 8 px dots without a
/// background were missed entirely in real-device review.
class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < count; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                // Container (not AnimatedContainer) to keep the existing
                // widget-test harness — it reads `Container.decoration`
                // synchronously and an animated swap would race with
                // `pumpAndSettle`.
                child: Container(
                  key: Key('clock_dot_$i'),
                  width: i == current ? 24 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: i == current
                        ? scheme.primary
                        : scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
