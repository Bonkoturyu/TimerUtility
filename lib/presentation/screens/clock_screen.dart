import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'home/clock_page.dart';

/// Deep-link entry point for `/clock`. Phase 11 promoted the body to
/// a reusable [ClockPage] widget so HomeScreen's PageView and the
/// deep-link route can share rendering. Edit-locations is surfaced via
/// the AppBar overflow (kept here so HomeScreen reuses the same menu
/// definition by referencing the shared 'edit_locations' value).
class ClockScreen extends StatelessWidget {
  const ClockScreen({super.key});

  static const String routeLocation = '/clock';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.clockAppBarTitle),
        actions: <Widget>[
          PopupMenuButton<String>(
            key: const Key('clock_menu'),
            onSelected: (String value) {
              if (value == 'edit_locations') {
                context.push('/clock/locations');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit_locations',
                child: Text(l.clockMenuEditLocations),
              ),
            ],
          ),
        ],
      ),
      body: const ClockPage(),
    );
  }
}
