import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timezone_resolver_provider.dart';
import '../../domain/clock/clock_location.dart';
import '../../domain/clock/clock_time.dart';
import 'digital_clock_widget.dart';

/// Design B: list of digital-prominent rows with secondary metadata
/// (date `M/d` + UTC offset) on the trailing edge.
///
/// Picks `ListView.separated` to keep the dividers cheap (no per-row
/// Card/Decoration cost) — the row layout itself carries the visual
/// hierarchy via font sizing.
class ClockDesignB extends ConsumerWidget {
  const ClockDesignB({super.key, required this.locations, required this.now});

  final List<ClockLocation> locations;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (locations.isEmpty) {
      return const Center(
        child: Text(
          'No cities yet — tap menu to add',
          key: Key('clock_design_b_empty'),
        ),
      );
    }
    final TimezoneResolver resolver = ref.watch(timezoneResolverProvider);
    final Color subColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView.separated(
      itemCount: locations.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final ClockLocation loc = locations[index];
        final DateTime wall = resolver.computeAt(now, loc.timezoneId);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      loc.displayName,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    DigitalClockWidget(
                      time: now,
                      timezoneId: loc.timezoneId,
                      fontSize: 36,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${wall.month}/${wall.day}',
                    style: TextStyle(fontSize: 14, color: subColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatUtcOffset(wall.timeZoneOffset),
                    style: TextStyle(fontSize: 14, color: subColor),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

String _formatUtcOffset(Duration offset) {
  final bool negative = offset.isNegative;
  final int h = offset.inHours.abs();
  final int m = offset.inMinutes.abs() % 60;
  final String sign = negative ? '-' : '+';
  return m == 0 ? 'UTC$sign$h' : 'UTC$sign$h:${m.toString().padLeft(2, '0')}';
}
