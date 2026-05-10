import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/clock/clock_location.dart';
import 'analog_clock_widget.dart';
import 'digital_clock_widget.dart';

/// Design C: 3 x 2 compact grid — analog 64 px + truncated label +
/// HH:mm digital. UTC offset is intentionally dropped (the smaller
/// cell budget can't carry a fourth line legibly); users who need the
/// offset pick Design A or B.
class ClockDesignC extends ConsumerWidget {
  const ClockDesignC({super.key, required this.locations, required this.now});

  final List<ClockLocation> locations;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (locations.isEmpty) {
      return const Center(
        child: Text(
          'No cities yet — tap menu to add',
          key: Key('clock_design_c_empty'),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 0.9,
      padding: const EdgeInsets.all(12),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: <Widget>[
        for (final ClockLocation loc in locations)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AnalogClockWidget(
                    time: now,
                    timezoneId: loc.timezoneId,
                    size: 64,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.displayName,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  DigitalClockWidget(
                    time: now,
                    timezoneId: loc.timezoneId,
                    showSeconds: false,
                    fontSize: 18,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
