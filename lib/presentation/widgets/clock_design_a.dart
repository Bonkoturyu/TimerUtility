import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timezone_resolver_provider.dart';
import '../../domain/clock/clock_location.dart';
import '../../domain/clock/clock_time.dart';
import 'analog_clock_widget.dart';
import 'digital_clock_widget.dart';
import 'utc_offset_formatter.dart';

/// Design A: 2 x 3 grid of analog-prominent clock cards.
///
/// `ClockCollection.maxSize == 6` keeps the grid within 3 rows even at
/// max population. Empty state returns a single hint Text — l10n is
/// deferred to Session 5 (English literal here, key is stable).
///
/// Stateless: `now` is owned by the parent screen which `watch`es
/// `currentTimeStreamProvider` exactly once and props it down, so a
/// 1 Hz tick rebuilds this subtree (not the whole screen).
class ClockDesignA extends ConsumerWidget {
  const ClockDesignA({super.key, required this.locations, required this.now});

  final List<ClockLocation> locations;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (locations.isEmpty) {
      return const Center(
        child: Text(
          'No cities yet — tap menu to add',
          key: Key('clock_design_a_empty'),
        ),
      );
    }
    final TimezoneResolver resolver = ref.watch(timezoneResolverProvider);
    final Color subColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 0.85,
      padding: const EdgeInsets.all(16),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: <Widget>[
        for (final ClockLocation loc in locations)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnalogClockWidget(
                    time: now,
                    timezoneId: loc.timezoneId,
                    size: 96,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.displayName,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  DigitalClockWidget(
                    time: now,
                    timezoneId: loc.timezoneId,
                    showSeconds: false,
                    fontSize: 14,
                  ),
                  Text(
                    formatUtcOffset(
                      resolver.computeAt(now, loc.timezoneId).timeZoneOffset,
                    ),
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
