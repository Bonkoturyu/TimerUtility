import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/domain/ports/app_version_reader.dart';

void main() {
  group('AppVersion.display', () {
    test('version と buildNumber を "1.0.0 (2)" 形式で結合する', () {
      const AppVersion v = AppVersion(version: '1.0.0', buildNumber: '2');
      expect(v.display, '1.0.0 (2)');
    });

    // buildNumber を報告しないプラットフォームで "1.0.0 ()" にならないこと。
    test('buildNumber が空なら version のみを返す', () {
      const AppVersion v = AppVersion(version: '1.0.0', buildNumber: '');
      expect(v.display, '1.0.0');
    });

    // Reader が例外時に返す空値。UI 側は em dash へ落とす。
    test('両方空なら空文字を返す', () {
      const AppVersion v = AppVersion(version: '', buildNumber: '');
      expect(v.display, isEmpty);
    });

    test('値が同じインスタンスは等価', () {
      expect(
        const AppVersion(version: '1.0.0', buildNumber: '2'),
        const AppVersion(version: '1.0.0', buildNumber: '2'),
      );
      expect(
        const AppVersion(version: '1.0.0', buildNumber: '2'),
        isNot(const AppVersion(version: '1.0.0', buildNumber: '3')),
      );
    });
  });
}
