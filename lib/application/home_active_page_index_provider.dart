import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently visible HomeScreen tab logical index (0..3), or `null`
/// when no HomeScreen is mounted.
///
/// PR #29 follow-up #4 (Copilot C3/C4): each HomeScreen-hosted Page
/// (TimerListPage / StopwatchPage) reads this to gate its 100-200ms
/// `Timer.periodic` so a running timer / stopwatch does not keep
/// burning CPU on tabs the user has swiped away from. Other Pages
/// (`AlarmListPage` / `ClockPage`) do not maintain a Dart-side ticker
/// — Alarm relies on system notifications and Clock subscribes to a
/// 1-Hz autoDispose stream — so the optimisation is targeted only
/// where it pays off.
///
/// State transitions:
/// - `null` initially. Deep-link Screens like `/timer` `/stopwatch`
///   open the Page widgets directly without a HomeScreen, so Pages
///   treat `null` as "I'm the only thing on screen — run the ticker".
/// - `0..3` while a HomeScreen is mounted. Each Page compares to its
///   own logical index and pauses its ticker if they differ.
/// - back to `null` automatically when HomeScreen unmounts: marked
///   `autoDispose`, the provider tears down as soon as the last
///   watcher leaves the tree, so any subsequent deep-link mount
///   sees a fresh `null`. (We can't reset from HomeScreen.dispose /
///   .deactivate because the still-mounted child Pages are watching
///   it — flipping the value during the parent's teardown phase
///   triggers `setState() during build`.)
final homeActivePageIndexProvider = StateProvider.autoDispose<int?>(
  (ref) => null,
);
