import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/user_preferences_provider.dart';
import '../../../domain/ports/user_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/home_dot_indicator.dart';
import '../../widgets/page_navigation_hint.dart';
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
/// (`UserPreferenceKeys.lastHomePageIndex`). On cold start we read it in
/// the post-frame microtask and `jumpToPage` to the stored index;
/// missing key falls back to Timer (index 1) which we judged the most
/// frequent landing page (Phase 11 settings session). Ranges are
/// clamped to [0..3] so a stale persisted value from a future tab
/// reordering doesn't crash the controller.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  /// Default landing tab when no `lastHomePageIndex` is stored. Timer
  /// is the everyday workflow; Stopwatch / Alarm / Clock are
  /// secondary surfaces.
  static const int defaultPageIndex = 1;

  /// Total page count. Kept here (not on a hardcoded 4) so the
  /// indicator and clamp logic stay in lockstep should a fifth tab
  /// arrive in a later phase.
  static const int pageCount = 4;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _controller;
  int _currentPage = HomeScreen.defaultPageIndex;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _currentPage);
    // Defer to a microtask so we can `await` the prefs read; the first
    // frame still paints with `defaultPageIndex` if the user happens to
    // glance at the screen during the first ~1ms.
    Future<void>.microtask(_restoreLastPage);
  }

  Future<void> _restoreLastPage() async {
    final UserPreferences prefs = ref.read(userPreferencesProvider);
    final int? stored = await prefs.getInt(
      UserPreferenceKeys.lastHomePageIndex,
    );
    if (!mounted) return;
    if (stored == null) return;
    final int clamped = stored.clamp(0, HomeScreen.pageCount - 1);
    if (clamped == _currentPage) return;
    setState(() => _currentPage = clamped);
    _controller.jumpToPage(clamped);
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    // Fire-and-forget persistence. A single write per swipe is fine —
    // `shared_preferences` debounces internally and a missed write is
    // self-correcting on the next swipe / app exit.
    ref
        .read(userPreferencesProvider)
        .setInt(UserPreferenceKeys.lastHomePageIndex, index);
  }

  void _animateTo(int index) {
    _controller.animateToPage(
      index,
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
    return Scaffold(
      appBar: _buildAppBar(context, l),
      body: PageView(
        key: const Key('home_page_view'),
        controller: _controller,
        onPageChanged: _onPageChanged,
        children: const <Widget>[
          StopwatchPage(),
          TimerListPage(),
          AlarmListPage(),
          ClockPage(),
        ],
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
    final bool hasPrev = _currentPage > 0;
    final bool hasNext = _currentPage < HomeScreen.pageCount - 1;

    return AppBar(
      // 80dp = chevron (20) + icon (18) + 2× inter-spacing (8) + outer
      // padding (16) ≈ 62dp + a slack for ripple bounds. Both leading
      // and trailing hints are label-less; the ja short labels
      // (e.g. "ストップウォッチ" ≈ 7 chars) do not fit any AppBar slot
      // on a 412dp-class device without crowding out the title. The
      // current-tab name lives in `title`, the adjacent tabs are
      // signalled by chevron + tab icon — the DotIndicator tells
      // absolute position.
      leadingWidth: hasPrev ? 80 : null,
      // Force left-aligned title so the Material 3 platform default
      // (Android centers titles) doesn't carve additional padding out
      // of the already-tight title slot when a leading is present.
      centerTitle: false,
      leading: hasPrev
          ? PageNavigationHint(
              icon: _iconForPage(_currentPage - 1),
              label: '',
              direction: PageHintDirection.left,
              onTap: () => _animateTo(_currentPage - 1),
            )
          : null,
      title: Text(_titleForPage(l, _currentPage)),
      actions: <Widget>[
        if (hasNext)
          PageNavigationHint(
            icon: _iconForPage(_currentPage + 1),
            label: '',
            direction: PageHintDirection.right,
            onTap: () => _animateTo(_currentPage + 1),
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
          case 'edit_locations':
            context.push('/clock/locations');
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
        if (_currentPage == 3) {
          items.add(
            PopupMenuItem<String>(
              key: const Key('home_menu_edit_locations'),
              value: 'edit_locations',
              child: Text(l.clockMenuEditLocations),
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

  IconData _iconForPage(int index) => switch (index) {
    0 => Icons.timer_outlined,
    1 => Icons.hourglass_top,
    2 => Icons.alarm,
    3 => Icons.public,
    _ => Icons.help_outline,
  };
}
