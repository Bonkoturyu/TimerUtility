import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'home/timer_list_page.dart';

/// Deep-link entry point for `/timer`. Phase 11 promoted the body to a
/// reusable [TimerListPage] widget so HomeScreen's PageView and the
/// deep-link route can share rendering. The Screen wrapper retains the
/// AppBar overflow (manage presets) and the FAB; both delegate to the
/// shared static helpers on `TimerListPage` so HomeScreen reuses the
/// same logic without duplication.
class TimerListScreen extends ConsumerWidget {
  const TimerListScreen({super.key});

  static const String routeLocation = '/timer';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.timerListAppBarTitle),
        actions: <Widget>[
          PopupMenuButton<String>(
            key: const Key('timer_list_menu'),
            onSelected: (String value) {
              if (value == 'manage_presets') {
                context.push('/presets');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                key: const Key('timer_list_menu_manage_presets'),
                value: 'manage_presets',
                child: Text(l.presetManageMenuOverflow),
              ),
            ],
          ),
        ],
      ),
      body: const TimerListPage(),
      floatingActionButton: TimerListPage.buildFab(context, ref),
    );
  }
}
