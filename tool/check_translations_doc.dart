// ARB ファイル (lib/l10n/app_ja.arb / app_en.arb) と
// docs/translations.md のキー集合がズレていないか検証する CI スクリプト。
//
// 実行: `dart run tool/check_translations_doc.dart`
// 終了コード: 0=一致 / 1=不一致 / 2=I/O エラー
//
// 対象は ja / en のみ (translations.md は ja / en 2 列ミラーという A-3 方針)。
// zh / zh_Hant / ko ARB のキー集合検査は本スクリプトの対象外。

import 'dart:convert';
import 'dart:io';

const _arbJaPath = 'lib/l10n/app_ja.arb';
const _arbEnPath = 'lib/l10n/app_en.arb';
const _docPath = 'docs/translations.md';

// translations.md のテーブル行先頭からキーを拾う:
//   | `keyName` | ja訳 | en訳 | 用途 |
final _docKeyPattern = RegExp(r'^\|\s*`([a-zA-Z_][a-zA-Z0-9_]*)`\s*\|');

Future<void> main() async {
  try {
    final jaKeys = _extractArbKeys(await _readJson(_arbJaPath));
    final enKeys = _extractArbKeys(await _readJson(_arbEnPath));
    final docKeys = _extractDocKeys(await File(_docPath).readAsString());

    final issues = <String>[];

    final jaOnly = jaKeys.difference(enKeys);
    final enOnly = enKeys.difference(jaKeys);
    if (jaOnly.isNotEmpty || enOnly.isNotEmpty) {
      issues.add(
        _formatSection('ARB key set mismatch between ja and en', {
          '$_arbJaPath only': jaOnly,
          '$_arbEnPath only': enOnly,
        }),
      );
    }

    final arbUnion = {...jaKeys, ...enKeys};
    final missingInDoc = arbUnion.difference(docKeys);
    final staleInDoc = docKeys.difference(arbUnion);
    if (missingInDoc.isNotEmpty || staleInDoc.isNotEmpty) {
      issues.add(
        _formatSection('ARB <-> $_docPath drift', {
          'in ARB but missing from $_docPath': missingInDoc,
          'in $_docPath but no longer in ARB (stale)': staleInDoc,
        }),
      );
    }

    if (issues.isEmpty) {
      stdout.writeln(
        'OK: ARB (ja=${jaKeys.length}, en=${enKeys.length}) and '
        '$_docPath (${docKeys.length}) key sets are aligned.',
      );
      exit(0);
    }

    stderr.writeln('Translations doc drift detected:\n');
    for (final block in issues) {
      stderr.writeln(block);
    }
    stderr.writeln(
      'Fix: update $_docPath so its table rows match the ARB key set, '
      'or revert the ARB change.',
    );
    exit(1);
  } on FileSystemException catch (e) {
    stderr.writeln('I/O error: ${e.message} (${e.path})');
    exit(2);
  } on FormatException catch (e) {
    stderr.writeln('Parse error: ${e.message}');
    exit(2);
  }
}

Future<Map<String, dynamic>> _readJson(String path) async {
  final raw = await File(path).readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('$path is not a JSON object');
  }
  return decoded;
}

Set<String> _extractArbKeys(Map<String, dynamic> arb) {
  return arb.keys.where((k) => k != '@@locale' && !k.startsWith('@')).toSet();
}

Set<String> _extractDocKeys(String markdown) {
  final keys = <String>{};
  for (final line in const LineSplitter().convert(markdown)) {
    final match = _docKeyPattern.firstMatch(line);
    if (match != null) {
      keys.add(match.group(1)!);
    }
  }
  return keys;
}

String _formatSection(String title, Map<String, Set<String>> groups) {
  final buf = StringBuffer('== $title ==\n');
  groups.forEach((label, keys) {
    if (keys.isEmpty) return;
    final sorted = keys.toList()..sort();
    buf.writeln('  $label (${sorted.length}):');
    for (final k in sorted) {
      buf.writeln('    - $k');
    }
  });
  return buf.toString();
}
