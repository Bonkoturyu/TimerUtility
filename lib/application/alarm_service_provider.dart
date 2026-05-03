import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/alarm/alarm_service.dart';
import 'clock_provider.dart';

part 'alarm_service_provider.g.dart';

/// アプリ用 [Clock] を注入した [AlarmService] を提供するプロバイダ
/// (Phase 9.5)。
///
/// `timerServiceProvider` と同形の `keepAlive` 関数 Provider。
/// Notifier 側 (`AlarmCollectionNotifier`) は
/// `ref.read(alarmServiceProvider)` 経由で参照し、テストは
/// `clockProvider` を override すれば現在時刻を任意の値に固定できる。
@Riverpod(keepAlive: true)
AlarmService alarmService(Ref ref) => AlarmService(ref.watch(clockProvider));
