import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'home/stopwatch_page.dart';

/// Deep-link entry point for `/stopwatch`. Phase 11 promoted the body
/// to a reusable [StopwatchPage] widget so HomeScreen's PageView and
/// the deep-link route can share rendering. This Screen now only owns
/// the Scaffold + AppBar chrome that the deep-link surface needs.
class StopwatchScreen extends StatelessWidget {
  const StopwatchScreen({super.key});

  static const String routeLocation = '/stopwatch';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.stopwatchAppBarTitle)),
      body: const StopwatchPage(),
    );
  }
}
