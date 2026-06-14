import 'package:flutter/foundation.dart' show LicenseEntry, LicenseRegistry;
import 'package:flutter/material.dart';

import '../../infrastructure/licenses/bundled_asset_licenses.dart';
import '../../l10n/app_localizations.dart';

/// Custom licenses screen replacing Flutter's stock `showLicensePage`.
///
/// Reasons we don't reuse the stock page:
///   - The stock page lists every entry in a flat alphabetical list,
///     mixing app-bundled assets with pub packages. Users
///     can't tell at a glance "what does this app ship vs. depend on".
///   - Asset license entries embed line-broken bullet lists; the stock
///     detail view centers paragraphs which makes bullets hard to read.
///
/// We group entries into two ExpansionTile sections:
///   - "Bundled assets": entries whose primary package name ends with
///     [bundledAssetPackageNameSuffix]. Initially expanded — small set,
///     immediately useful.
///   - "Software licenses": every other entry (i.e. pub packages).
///     Collapsed by default since the list is long.
///
/// Tapping an entry pushes a left-aligned detail screen rendering each
/// `LicenseParagraph` on its own line.
class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  static const String routeLocation = '/licenses';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.licenseMenuOverflow)),
      body: FutureBuilder<List<LicenseEntry>>(
        future: LicenseRegistry.licenses.toList(),
        builder:
            (BuildContext context, AsyncSnapshot<List<LicenseEntry>> snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final List<LicenseEntry> bundled = <LicenseEntry>[];
              final List<LicenseEntry> software = <LicenseEntry>[];
              for (final LicenseEntry entry in snapshot.data!) {
                final String first = entry.packages.first;
                if (first.endsWith(bundledAssetPackageNameSuffix)) {
                  bundled.add(entry);
                } else {
                  software.add(entry);
                }
              }
              bundled.sort(
                (LicenseEntry a, LicenseEntry b) =>
                    a.packages.first.compareTo(b.packages.first),
              );
              software.sort(
                (LicenseEntry a, LicenseEntry b) =>
                    a.packages.first.compareTo(b.packages.first),
              );

              return ListView(
                children: <Widget>[
                  ExpansionTile(
                    key: const Key('licenses_group_bundled'),
                    title: Text(l.licenseGroupBundledAssets),
                    initiallyExpanded: true,
                    children: <Widget>[
                      for (final LicenseEntry entry in bundled)
                        _LicenseEntryTile(
                          entry: entry,
                          stripSuffix: bundledAssetPackageNameSuffix,
                        ),
                    ],
                  ),
                  ExpansionTile(
                    key: const Key('licenses_group_software'),
                    title: Text(l.licenseGroupSoftware),
                    children: <Widget>[
                      for (final LicenseEntry entry in software)
                        _LicenseEntryTile(entry: entry),
                    ],
                  ),
                ],
              );
            },
      ),
    );
  }
}

class _LicenseEntryTile extends StatelessWidget {
  const _LicenseEntryTile({required this.entry, this.stripSuffix});
  final LicenseEntry entry;
  final String? stripSuffix;

  @override
  Widget build(BuildContext context) {
    final String raw = entry.packages.first;
    final String display = stripSuffix != null && raw.endsWith(stripSuffix!)
        ? raw.substring(0, raw.length - stripSuffix!.length)
        : raw;
    return ListTile(
      key: Key('license_entry_$raw'),
      title: Text(display),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _LicenseDetailScreen(entry: entry, title: display),
        ),
      ),
    );
  }
}

class _LicenseDetailScreen extends StatelessWidget {
  const _LicenseDetailScreen({required this.entry, required this.title});
  final LicenseEntry entry;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final paragraph in entry.paragraphs)
              Padding(
                padding: EdgeInsets.only(
                  // Negative indent (== centeredIndent sentinel) → no
                  // left padding. Positive levels are scaled at 16dp.
                  left: paragraph.indent <= 0 ? 0 : paragraph.indent * 16.0,
                  bottom: 8,
                ),
                child: Text(paragraph.text),
              ),
          ],
        ),
      ),
    );
  }
}
