import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/app_version_reader.dart';
import '../infrastructure/platform/package_info_app_version_reader.dart';

part 'app_version_provider.g.dart';

/// Default-bound [AppVersionReader]. Override in tests via
/// `appVersionReaderProvider.overrideWithValue(StubAppVersionReader(...))`.
@Riverpod(keepAlive: true)
AppVersionReader appVersionReader(Ref ref) =>
    const PackageInfoAppVersionReader();

/// The running build's version, shown in the settings "About" section.
///
/// `keepAlive` because the value is immutable for the process lifetime —
/// re-reading it on every settings screen open would hit the platform
/// channel for nothing.
@Riverpod(keepAlive: true)
Future<AppVersion> appVersion(Ref ref) =>
    ref.watch(appVersionReaderProvider).read();
