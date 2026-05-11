import 'package:flutter/material.dart';

/// Material-style page indicator for the Phase 11 HomeScreen PageView.
///
/// Originally lived as `_DotIndicator` inside the Phase 10.5 ClockScreen,
/// where it visualised the inner clock-design PageView. Phase 11
/// promoted it to a public widget under `presentation/widgets/` because
/// the new HomeScreen tab PageView (Stopwatch / Timer / Alarm / Clock)
/// needs the same affordance and the inner ClockScreen PageView was
/// replaced by a SegmentedButton (gesture-conflict resolution — see
/// `home/clock_page.dart`).
///
/// The widget is intentionally a plain `Container` rather than an
/// `AnimatedContainer`: the existing widget-test harness reads
/// `Container.decoration` synchronously to assert the active dot, and
/// an animated swap would race with `pumpAndSettle`.
///
/// Per-dot keys (`home_dot_<i>`) are stable across rebuilds so tests
/// can target a specific position regardless of render order.
class HomeDotIndicator extends StatelessWidget {
  /// PR #29 C2: fail fast on out-of-range inputs. A silent miss (no
  /// active dot) is hard to debug, so make the contract explicit at
  /// the call site.
  const HomeDotIndicator({
    super.key,
    required this.count,
    required this.current,
  }) : assert(count > 0, 'HomeDotIndicator.count must be > 0'),
       assert(
         current >= 0 && current < count,
         'HomeDotIndicator.current must satisfy 0 <= current < count',
       );

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
                child: Container(
                  key: Key('home_dot_$i'),
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
