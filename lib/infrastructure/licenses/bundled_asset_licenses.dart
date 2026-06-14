import 'package:flutter/foundation.dart';

const String bundledAssetLicensesPath = 'assets/sounds/LICENSES.md';
const String bundledAssetPackageNameSuffix = ' (bundled)';

List<LicenseEntry> parseBundledAssetLicenses(String content) {
  final List<LicenseEntry> entries = <LicenseEntry>[];
  String? currentName;
  final List<String> currentLines = <String>[];

  void flush() {
    if (currentName == null) return;
    entries.add(
      BundledAssetLicenseEntry(
        packageName: '$currentName$bundledAssetPackageNameSuffix',
        lines: List<String>.unmodifiable(currentLines),
      ),
    );
  }

  for (final String raw in content.split('\n')) {
    final String line = raw.trimRight();
    if (line.startsWith('## ')) {
      flush();
      currentName = line.substring(3).trim();
      currentLines.clear();
    } else if (currentName != null) {
      currentLines.add(line);
    }
  }
  flush();
  return List<LicenseEntry>.unmodifiable(entries);
}

class BundledAssetLicenseEntry extends LicenseEntry {
  BundledAssetLicenseEntry({required this.packageName, required this.lines});

  final String packageName;
  final List<String> lines;

  @override
  Iterable<String> get packages => <String>[packageName];

  @override
  Iterable<LicenseParagraph> get paragraphs =>
      lines.map((String line) => LicenseParagraph(line, 0));
}
