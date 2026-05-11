import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'home/clock_page.dart';

/// Deep-link entry point for `/clock`. Phase 11 promoted the body to
/// a reusable [ClockPage] widget so HomeScreen's PageView and the
/// deep-link route can share rendering. PR #29 follow-up #2 replaced
/// the AppBar overflow "都市を編集" entry with a right-bottom FAB
/// (`ClockPage.buildFab`) so this Screen now mirrors the Timer / Alarm
/// "+ FAB → edit screen" UX pattern. Same FAB widget is reused by
/// HomeScreen so swiping to the Clock tab and arriving via deep link
/// look identical.
class ClockScreen extends StatelessWidget {
  const ClockScreen({super.key});

  static const String routeLocation = '/clock';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.clockAppBarTitle)),
      body: const ClockPage(),
      floatingActionButton: ClockPage.buildFab(context),
    );
  }
}
