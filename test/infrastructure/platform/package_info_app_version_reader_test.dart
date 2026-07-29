import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timer_utility/domain/ports/app_version_reader.dart';
import 'package:timer_utility/infrastructure/platform/package_info_app_version_reader.dart';

void main() {
  group('PackageInfoAppVersionReader', () {
    test('PackageInfoのversionとbuildNumberをAppVersionへ変換する', () async {
      final reader = PackageInfoAppVersionReader(
        loadPackageInfo: () async => PackageInfo(
          appName: 'TimerUtility',
          packageName: 'io.github.bonkoturyu.timer_utility',
          version: '1.2.3',
          buildNumber: '45',
        ),
      );

      final AppVersion result = await reader.read();

      expect(result, const AppVersion(version: '1.2.3', buildNumber: '45'));
    });

    test('PackageInfo取得が例外なら空のAppVersionへフォールバックする', () async {
      final reader = PackageInfoAppVersionReader(
        loadPackageInfo: () async => throw StateError('platform unavailable'),
      );

      final AppVersion result = await reader.read();

      expect(result, const AppVersion(version: '', buildNumber: ''));
    });
  });
}
