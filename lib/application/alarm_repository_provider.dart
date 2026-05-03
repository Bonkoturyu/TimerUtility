import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ports/alarm_repository.dart';

part 'alarm_repository_provider.g.dart';

/// [AlarmCollectionNotifier] が依存する [AlarmRepository] を提供する
/// プロバイダ (Phase 9.5)。
///
/// 本番では `main()` で `DriftAlarmRepository` に override、
/// テストでは in-memory fake に override する想定。
/// override し忘れた場合に挙動が黙って壊れないよう、
/// `timerRepositoryProvider` と同じく throw-on-default とする。
@Riverpod(keepAlive: true)
AlarmRepository alarmRepository(Ref ref) {
  throw UnimplementedError(
    'alarmRepositoryProvider must be overridden in main() with the '
    'Drift-backed adapter (or in tests with an in-memory fake).',
  );
}
