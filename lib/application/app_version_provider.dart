import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/app_version_reader.dart';

part 'app_version_provider.g.dart';

/// 本番では `main()` で Infrastructure 実装へ overrideし、
/// テストでは stub へ差し替える。
///
/// 未override時にApplicationからInfrastructureへ依存しないよう、
/// repository provider群と同じthrow-on-defaultとする。
@Riverpod(keepAlive: true)
AppVersionReader appVersionReader(Ref ref) {
  throw UnimplementedError(
    'appVersionReaderProvider must be overridden in main() with the '
    'package-info adapter (or in tests with a stub).',
  );
}

/// The running build's version, shown in the settings "About" section.
///
/// `keepAlive` because the value is immutable for the process lifetime —
/// re-reading it on every settings screen open would hit the platform
/// channel for nothing.
@Riverpod(keepAlive: true)
Future<AppVersion> appVersion(Ref ref) =>
    ref.watch(appVersionReaderProvider).read();
