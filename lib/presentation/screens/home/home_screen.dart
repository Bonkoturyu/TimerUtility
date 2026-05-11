import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/timer_collection_notifier.dart';
import '../../../application/user_preferences_provider.dart';
import '../../../domain/ports/user_preferences.dart';
import '../../../domain/timer/timer_collection.dart';
import '../../../domain/timer/timer_entity.dart';
import '../../../domain/timer/timer_status.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/home_dot_indicator.dart';
import '../../widgets/page_navigation_hint.dart';
import '../alarm_ringing_screen.dart' show AlarmRingingScreen;
import '../licenses_screen.dart';
import 'alarm_list_page.dart';
import 'clock_page.dart';
import 'stopwatch_page.dart';
import 'timer_list_page.dart';

/// Phase 11 HomeScreen. Replaces the four-button vertical menu of Phase
/// 10.5 with a horizontal `PageView` whose tabs are the four feature
/// screens (Stopwatch / Timer / Alarm / Clock).
///
/// AppBar / FAB are owned by this Scaffold and switched dynamically on
/// `_currentPage`; the PageView only renders Page widgets (body-only)
/// imported from `presentation/screens/home/`. Each deep-link Screen
/// (`StopwatchScreen` etc.) is now a thin wrapper that reuses the same
/// Page widget, which is why the same FAB / overflow code lives both
/// here and in the wrappers — they delegate to static helpers on the
/// Page class.
///
/// The 4-page progress indicator (`HomeDotIndicator`) lives in the
/// Scaffold's `bottomNavigationBar` slot — not as a `Positioned`
/// overlay inside a `Stack`, which collided with the FAB on a
/// Pixel 6a. The indicator is tap-disabled, so this is purely a
/// position cue and does not turn into a tab bar (design decision #1
/// keeps tab-switch UI off the bottom).
///
/// Page restore: the user's last tab is persisted via `UserPreferences`
/// (`UserPreferenceKeys.lastHomePageIndex`). On cold start `main()`
/// awaits the prefs read **before** building the widget tree and passes
/// the resolved index down through `HomeScreen(initialPageIndex:)`,
/// which `initState` then hands to the `PageController` synchronously —
/// so the very first frame paints at the right tab (PR #29 G3 removed
/// the previous `initState` microtask that caused a Timer→stored-tab
/// flash on Pixel 6a). A missing key falls back to Timer (index 1) and
/// stale values are clamped to [0..3] so a future tab reordering can't
/// crash the controller.
///
/// PageView is wrap-around: swiping past Clock loops back to Stopwatch
/// (and Stopwatch swiped right loops to Clock). Implemented via
/// `PageView.builder` with `itemCount: null` and a large
/// `_initialRawPage` (2520, LCM of 1..7 — divisible by any future tab
/// count up to 7). The persisted index is always the **logical** value
/// (`raw % pageCount` ∈ [0..3]); raw values are session-local so a kill
/// → restart cycle never carries a thousand-page offset.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialPageIndex = defaultPageIndex});

  /// Resolved landing tab passed in from `main()` after it has read
  /// `lastHomePageIndex` from `SharedPreferences`. Doing the read in
  /// `main()` (instead of an `initState` microtask) lets the very
  /// first frame paint at the right tab and avoids the previous
  /// "flash of Timer then jump" behaviour reported on Pixel 6a
  /// (PR #29 G3). Tests that pump HomeScreen directly fall back to
  /// the default; the harness can pass `initialPageIndex` explicitly
  /// when it wants to exercise the restore path.
  final int initialPageIndex;

  /// Default landing tab when no `lastHomePageIndex` is stored. Timer
  /// is the everyday workflow; Stopwatch / Alarm / Clock are
  /// secondary surfaces.
  static const int defaultPageIndex = 1;

  /// Total page count. Kept here (not on a hardcoded 4) so the
  /// indicator and clamp logic stay in lockstep should a fifth tab
  /// arrive in a later phase.
  static const int pageCount = 4;

  /// Anchor raw page index for the wrap-around `PageView.builder`.
  /// 2520 = LCM(1..7) so it is divisible by any plausible `pageCount`
  /// in [1..7]. `_initialRawPage % pageCount == 0`, so adding the
  /// logical default index gives a clean starting position with
  /// thousands of swipes of headroom in either direction (effectively
  /// infinite for human use).
  static const int _initialRawPage = 2520;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _controller;

  /// Raw page index (potentially many thousands). The on-screen
  /// indicator and persistence layer translate this through
  /// `% HomeScreen.pageCount` to get the logical 0..3 page.
  late int _rawPage;

  int get _currentPage => _rawPage % HomeScreen.pageCount;

  @override
  void initState() {
    super.initState();
    final int logical = widget.initialPageIndex.clamp(
      0,
      HomeScreen.pageCount - 1,
    );
    _rawPage = HomeScreen._initialRawPage + logical;
    _controller = PageController(initialPage: _rawPage);
  }

  void _onPageChanged(int rawIndex) {
    setState(() => _rawPage = rawIndex);
    // Fire-and-forget persistence. Save the **logical** index so we
    // don't carry the raw offset across launches. shared_preferences
    // debounces internally and a missed write is self-correcting on
    // the next swipe / app exit.
    ref
        .read(userPreferencesProvider)
        .setInt(
          UserPreferenceKeys.lastHomePageIndex,
          rawIndex % HomeScreen.pageCount,
        );
  }

  /// Animate by ±1 raw page. Wrap-around is automatic because the
  /// builder accepts arbitrarily large indices.
  void _animateBy(int delta) {
    _controller.animateToPage(
      _rawPage + delta,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    // Phase 11 follow-up (PR #29 G1): pushing `/alarm-ringing` when a
    // timer flips to `ringing` lives at the HomeScreen level so it
    // keeps firing regardless of which PageView tab is on screen.
    // PageView dispose()s non-adjacent pages — when `TimerListPage`
    // owned this listener it stopped working as soon as the user
    // swiped two tabs away.
    ref.listen<TimerCollection>(timerCollectionNotifierProvider, (
      TimerCollection? prev,
      TimerCollection next,
    ) {
      final int prevRinging =
          prev?.all
              .where((TimerEntity t) => t.status == TimerStatus.ringing)
              .length ??
          0;
      final int nextRinging = next.all
          .where((TimerEntity t) => t.status == TimerStatus.ringing)
          .length;
      if (nextRinging > prevRinging) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final String here = GoRouterState.of(context).matchedLocation;
          if (here == '/alarm-ringing') return;
          if (!AlarmRingingScreen.tryReservePush()) return;
          context.push('/alarm-ringing');
        });
      }
    });

    return Scaffold(
      appBar: _buildAppBar(context, l),
      body: PageView.builder(
        key: const Key('home_page_view'),
        controller: _controller,
        onPageChanged: _onPageChanged,
        // No itemCount — `PageView.builder` then accepts arbitrarily
        // large indices, which is what gives us the wrap-around. The
        // `_initialRawPage = 2520` anchor leaves thousands of pages of
        // headroom in either direction (LCM(1..7) so any future
        // pageCount up to 7 stays divisible).
        itemBuilder: (BuildContext context, int rawIndex) {
          switch (rawIndex % HomeScreen.pageCount) {
            case 0:
              return const StopwatchPage();
            case 1:
              return const TimerListPage();
            case 2:
              return const AlarmListPage();
            case 3:
              return const ClockPage();
            default:
              // Unreachable — `% pageCount` is always in [0, pageCount).
              return const SizedBox.shrink();
          }
        },
      ),
      // Pin the dot indicator to the Scaffold's bottomNavigationBar
      // slot rather than overlaying it inside the PageView via a
      // `Positioned`. The previous overlay collided with the FAB on
      // Pixel 6a (Y axis ~14dp overlap) and made the dot pill hard to
      // read. The widget itself is tap-disabled so this does not
      // promote to a real BottomNavigationBar — design decision #1
      // (no bottom-tab UI) is preserved.
      //
      // The fixed 38dp wraps `HomeDotIndicator`'s inner `Center` so the
      // bottomNavigationBar slot does not let the indicator expand
      // vertically (which would steal the body / PageView's height
      // and break swipe hit-testing in tests).
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 38,
          child: HomeDotIndicator(
            count: HomeScreen.pageCount,
            current: _currentPage,
          ),
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppLocalizations l) {
    // PageView is wrap-around (Step 3 of the Phase 11 follow-up), so
    // both prev / next hints are always rendered.
    final int prevLogical =
        (_currentPage - 1 + HomeScreen.pageCount) % HomeScreen.pageCount;
    final int nextLogical = (_currentPage + 1) % HomeScreen.pageCount;

    return AppBar(
      // 80dp = chevron (20) + icon (18) + 2× inter-spacing (8) + outer
      // padding (16) ≈ 62dp + a slack for ripple bounds. Both leading
      // and trailing hints are label-less; the ja short labels
      // (e.g. "ストップウォッチ" ≈ 7 chars) do not fit any AppBar slot
      // on a 412dp-class device without crowding out the title. The
      // current-tab name lives in `title`, the adjacent tabs are
      // signalled by chevron + tab icon — the DotIndicator tells
      // absolute position.
      leadingWidth: 80,
      // Force left-aligned title so the Material 3 platform default
      // (Android centers titles) doesn't carve additional padding out
      // of the already-tight title slot when a leading is present.
      centerTitle: false,
      // PR #29 C1: the hints are visually label-less to keep the
      // AppBar layout compact, but screen readers still need to know
      // where the tap leads. Wrap in `Semantics(label:)` with the ja
      // short label of the adjacent tab; `excludeSemantics: true` on
      // the inner widget stops TalkBack from also reading the
      // chevron / icon as separate nodes.
      leading: Semantics(
        button: true,
        label: _labelForPage(l, prevLogical),
        excludeSemantics: true,
        child: PageNavigationHint(
          icon: _iconForPage(prevLogical),
          label: '',
          direction: PageHintDirection.left,
          onTap: () => _animateBy(-1),
        ),
      ),
      title: Text(_titleForPage(l, _currentPage)),
      actions: <Widget>[
        Semantics(
          button: true,
          label: _labelForPage(l, nextLogical),
          excludeSemantics: true,
          child: PageNavigationHint(
            icon: _iconForPage(nextLogical),
            label: '',
            direction: PageHintDirection.right,
            onTap: () => _animateBy(1),
          ),
        ),
        _buildOverflow(context, l),
      ],
    );
  }

  Widget _buildOverflow(BuildContext context, AppLocalizations l) {
    return PopupMenuButton<String>(
      key: const Key('home_menu'),
      onSelected: (String value) {
        switch (value) {
          case 'licenses':
            context.push(LicensesScreen.routeLocation);
            break;
          case 'manage_presets':
            context.push('/presets');
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[];
        if (_currentPage == 1) {
          items.add(
            PopupMenuItem<String>(
              key: const Key('home_menu_manage_presets'),
              value: 'manage_presets',
              child: Text(l.presetManageMenuOverflow),
            ),
          );
        }
        items.add(
          PopupMenuItem<String>(
            key: const Key('home_menu_licenses'),
            value: 'licenses',
            child: Text(l.licenseMenuOverflow),
          ),
        );
        return items;
      },
    );
  }

  Widget? _buildFab(BuildContext context) {
    return switch (_currentPage) {
      1 => TimerListPage.buildFab(context, ref),
      2 => AlarmListPage.buildFab(context),
      3 => ClockPage.buildFab(context),
      _ => null,
    };
  }

  String _titleForPage(AppLocalizations l, int index) => switch (index) {
    0 => l.stopwatchAppBarTitle,
    1 => l.timerListAppBarTitle,
    2 => l.alarmListAppBarTitle,
    3 => l.clockAppBarTitle,
    _ => '',
  };

  /// Short tab name used only as a `Semantics.label` for the
  /// label-less PageNavigationHint chips — keeps the AppBar visually
  /// compact while still announcing "前のタブ: ストップウォッチ" etc.
  /// in TalkBack / VoiceOver (PR #29 C1).
  String _labelForPage(AppLocalizations l, int index) => switch (index) {
    0 => l.homeOpenStopwatch,
    1 => l.homeOpenTimer,
    2 => l.homeOpenAlarm,
    3 => l.homeOpenClock,
    _ => '',
  };

  IconData _iconForPage(int index) => switch (index) {
    0 => Icons.timer_outlined,
    1 => Icons.hourglass_top,
    2 => Icons.alarm,
    3 => Icons.public,
    _ => Icons.help_outline,
  };
}
