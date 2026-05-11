import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'home/alarm_list_page.dart';

/// Deep-link entry point for `/alarms`. Phase 11 promoted the body to
/// a reusable [AlarmListPage] widget so HomeScreen's PageView and the
/// deep-link route can share rendering. Add-flow FAB is supplied by
/// `AlarmListPage.buildFab(context)` so HomeScreen reuses the same
/// logic without duplication.
class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  static const String routeLocation = '/alarms';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.alarmListAppBarTitle)),
      body: const AlarmListPage(),
      floatingActionButton: AlarmListPage.buildFab(context),
    );
  }
}
