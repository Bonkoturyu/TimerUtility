import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timezone_resolver_provider.dart';
import '../../domain/clock/clock_entry.dart';
import '../../domain/clock/clock_time.dart';
import '../../l10n/app_localizations.dart';
import 'digital_clock_widget.dart';
import 'utc_offset_formatter.dart';

/// Design B: list of digital-prominent rows with secondary metadata
/// (date `M/d` + UTC offset) on the trailing edge.
///
/// Picks `ListView.separated` to keep the dividers cheap (no per-row
/// Card/Decoration cost) — the row layout itself carries the visual
/// hierarchy via font sizing.
class ClockDesignB extends ConsumerWidget {
  const ClockDesignB({super.key, required this.entries, required this.now});

  final List<ClockEntry> entries;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      final AppLocalizations l = AppLocalizations.of(context);
      return Center(
        child: Text(l.clockEmptyHint, key: const Key('clock_design_b_empty')),
      );
    }
    final TimezoneResolver resolver = ref.watch(timezoneResolverProvider);
    final Color subColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final ClockEntry entry = entries[index];
        final DateTime wall = resolver.computeAt(now, entry.timezoneId);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.displayName,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    DigitalClockWidget(
                      time: now,
                      timezoneId: entry.timezoneId,
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
                    formatUtcOffset(wall.timeZoneOffset),
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
