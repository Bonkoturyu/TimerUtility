import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer_utility/application/diagnostic_export_controller.dart';
import 'package:timer_utility/application/diagnostic_log_exporter_provider.dart';
import 'package:timer_utility/domain/ports/diagnostic_log_exporter.dart';

/// Test double for the exporter port. Records every call so the test
/// can assert ordering (createArchive → share) and can be configured
/// to throw on either step to drive the error branch.
class _FakeExporter implements DiagnosticLogExporter {
  _FakeExporter({
    this.archivePath = '/tmp/fake.zip',
    this.throwOnCreate = false,
    this.throwOnShare = false,
  });

  String archivePath;
  bool throwOnCreate;
  bool throwOnShare;
  int createCalls = 0;
  int shareCalls = 0;
  String? lastSharedPath;

  @override
  Future<String> createArchive() async {
    createCalls++;
    if (throwOnCreate) throw StateError('create boom');
    return archivePath;
  }

  @override
  Future<void> share(String path) async {
    shareCalls++;
    lastSharedPath = path;
    if (throwOnShare) throw StateError('share boom');
  }
}

ProviderContainer _container(DiagnosticLogExporter exporter) {
  final ProviderContainer c = ProviderContainer(
    overrides: <Override>[
      diagnosticLogExporterProvider.overrideWithValue(exporter),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('DiagnosticExportController', () {
    test('初期 state は idle', () {
      final _FakeExporter exporter = _FakeExporter();
      final ProviderContainer c = _container(exporter);
      expect(
        c.read(diagnosticExportControllerProvider),
        isA<DiagnosticExportIdle>(),
      );
    });

    test('export 成功時: idle → done(path) で path を返す', () async {
      final _FakeExporter exporter = _FakeExporter(
        archivePath: '/tmp/diag.zip',
      );
      final ProviderContainer c = _container(exporter);
      await c.read(diagnosticExportControllerProvider.notifier).export();

      final DiagnosticExportState s = c.read(
        diagnosticExportControllerProvider,
      );
      expect(s, isA<DiagnosticExportDone>());
      expect((s as DiagnosticExportDone).archivePath, '/tmp/diag.zip');
      expect(exporter.createCalls, 1);
      expect(exporter.shareCalls, 1);
      expect(exporter.lastSharedPath, '/tmp/diag.zip');
    });

    test('createArchive 失敗時: idle → error(message)', () async {
      final _FakeExporter exporter = _FakeExporter(throwOnCreate: true);
      final ProviderContainer c = _container(exporter);
      await c.read(diagnosticExportControllerProvider.notifier).export();

      final DiagnosticExportState s = c.read(
        diagnosticExportControllerProvider,
      );
      expect(s, isA<DiagnosticExportError>());
      expect((s as DiagnosticExportError).message, contains('create boom'));
      expect(exporter.shareCalls, 0, reason: 'create が落ちたら share は呼ばない');
    });

    test('share 失敗時: idle → error(message)', () async {
      final _FakeExporter exporter = _FakeExporter(throwOnShare: true);
      final ProviderContainer c = _container(exporter);
      await c.read(diagnosticExportControllerProvider.notifier).export();

      final DiagnosticExportState s = c.read(
        diagnosticExportControllerProvider,
      );
      expect(s, isA<DiagnosticExportError>());
      expect((s as DiagnosticExportError).message, contains('share boom'));
    });

    test('reset() で done / error から idle に戻る', () async {
      final _FakeExporter exporter = _FakeExporter();
      final ProviderContainer c = _container(exporter);
      await c.read(diagnosticExportControllerProvider.notifier).export();
      expect(
        c.read(diagnosticExportControllerProvider),
        isA<DiagnosticExportDone>(),
      );

      c.read(diagnosticExportControllerProvider.notifier).reset();
      expect(
        c.read(diagnosticExportControllerProvider),
        isA<DiagnosticExportIdle>(),
      );
    });

    test('state value equality (sealed class)', () {
      expect(
        const DiagnosticExportIdle(),
        equals(const DiagnosticExportIdle()),
      );
      expect(
        const DiagnosticExportDone('/a'),
        equals(const DiagnosticExportDone('/a')),
      );
      expect(
        const DiagnosticExportDone('/a'),
        isNot(equals(const DiagnosticExportDone('/b'))),
      );
      expect(
        const DiagnosticExportError('e'),
        equals(const DiagnosticExportError('e')),
      );
    });
  });
}
