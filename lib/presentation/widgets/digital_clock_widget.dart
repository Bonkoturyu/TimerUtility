import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timezone_resolver_provider.dart';

/// Low-level digital clock readout (`HH:mm:ss` or `HH:mm`).
///
/// Hand-rolls the format to stay consistent with the rest of the
/// presentation layer (see `preset_label_formatter.dart`) and avoid a
/// new direct `intl` import when zero-padded HH:mm:ss is the only
/// requirement.
///
/// `tabularFigures()` is enabled so the digits keep a fixed advance
/// width and the readout doesn't visibly jitter between ticks.
class DigitalClockWidget extends ConsumerWidget {
  const DigitalClockWidget({
    super.key,
    required this.time,
    required this.timezoneId,
    this.showSeconds = true,
    this.fontSize = 24,
  });

  final DateTime time;
  final String timezoneId;
  final bool showSeconds;
  final double fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime wall = ref
        .read(timezoneResolverProvider)
        .computeAt(time, timezoneId);
    final String hh = wall.hour.toString().padLeft(2, '0');
    final String mm = wall.minute.toString().padLeft(2, '0');
    final String formatted = showSeconds
        ? '$hh:$mm:${wall.second.toString().padLeft(2, '0')}'
        : '$hh:$mm';
    return Text(
      formatted,
      style: TextStyle(
        fontSize: fontSize,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}
