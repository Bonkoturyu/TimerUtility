import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timezone_resolver_provider.dart';

/// Low-level analog clock face. Renders a circular dial with 12 minute
/// ticks, plus hour / minute / second hands at the wall-clock time of
/// [time] in [timezoneId].
///
/// The conversion from absolute [time] to the target zone's wall clock
/// is delegated to [timezoneResolverProvider] — tests inject a fake
/// resolver with `overrideWithValue` to keep the widget hermetic.
///
/// `time` is expected to be the same `DateTime` instance shared across
/// all clocks driven by `currentTimeStreamProvider`; rebuilds happen at
/// the stream's tick rate (1 Hz), so the second hand advances in
/// discrete steps rather than continuously.
class AnalogClockWidget extends ConsumerWidget {
  const AnalogClockWidget({
    super.key,
    required this.time,
    required this.timezoneId,
    this.size = 120,
  });

  final DateTime time;
  final String timezoneId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime wall = ref
        .read(timezoneResolverProvider)
        .computeAt(time, timezoneId);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.square(size),
      painter: _AnalogClockPainter(wall: wall, scheme: scheme),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  _AnalogClockPainter({required this.wall, required this.scheme});

  final DateTime wall;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2;

    final Paint dial = Paint()
      ..color = scheme.onSurface.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 2, dial);

    final Paint tickPaint = Paint()
      ..color = scheme.onSurface.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final double angle = i * (math.pi * 2 / 12) - math.pi / 2;
      final Offset outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 2);
      final Offset inner =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 8);
      canvas.drawLine(inner, outer, tickPaint);
    }

    final double hourDeg = (wall.hour % 12) * 30 + wall.minute * 0.5;
    final double minuteDeg = wall.minute * 6 + wall.second * 0.1;
    final double secondDeg = wall.second * 6.0;

    final Paint hourHand = Paint()
      ..color = scheme.onSurface
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    _drawHand(canvas, center, hourDeg, radius * 0.5, hourHand);

    final Paint minuteHand = Paint()
      ..color = scheme.onSurface
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    _drawHand(canvas, center, minuteDeg, radius * 0.7, minuteHand);

    final Paint secondHand = Paint()
      ..color = Colors.red
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    _drawHand(canvas, center, secondDeg, radius * 0.8, secondHand);

    final Paint hub = Paint()..color = scheme.onSurface;
    canvas.drawCircle(center, 3, hub);
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    double degrees,
    double length,
    Paint paint,
  ) {
    final double rad = degrees * math.pi / 180 - math.pi / 2;
    final Offset tip = center + Offset(math.cos(rad), math.sin(rad)) * length;
    canvas.drawLine(center, tip, paint);
  }

  @override
  bool shouldRepaint(_AnalogClockPainter old) =>
      old.wall != wall || old.scheme != scheme;
}
