import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/alarm_collection_notifier.dart';
import '../../application/permission_notifier.dart';
import '../../domain/alarm/alarm_entity.dart';
import '../../domain/alarm/alarm_repeat.dart';
import '../../domain/alarm/day_of_week.dart';
import '../../domain/alarm/time_of_day_value.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/permission_banners.dart';

/// Phase 9.5 のアラーム一覧画面。`AlarmCollectionNotifier` から
/// 全アラームを読み出してカード表示する。
///
/// UI 方針:
/// - 各カード: 時刻 (HH:mm) + 繰り返し / ラベルのサブタイトル + ON/OFF Switch
/// - カードタップで `/alarms/edit/<id>` に push (編集画面へ)
/// - FAB で `/alarms/edit` (新規作成モード)
/// - **削除導線は AlarmEditScreen の AppBar 削除ボタンに集約** している
///   ため一覧側からは削除できない。Preset 一覧 (PresetManageScreen) は
///   カードに直接 Delete を持つが、Alarm はソフト削除に近い「OFF」操作
///   (Switch) と区別を強調するためこの設計とした。誤タップで貴重な
///   目覚ましアラームが消える事故を避ける意図もある。
/// - 件数上限 (50 件) チェックは `AlarmCollectionNotifier.create` 側で
///   例外送出。一覧画面では FAB を常時有効にし、edit screen 側の
///   保存時にハンドリングする (本 commit 範囲外、別タスク)。
///
/// Phase 9.5 follow-up (2026-05-04): TimerListScreen 同様に
/// `permissionNotifierProvider.refresh()` を initState の microtask と
/// `didChangeAppLifecycleState(resumed)` で呼ぶ。これがないと state が
/// `unknown` のままで `_scheduleAt` の `useExact` が false になり、
/// `inexactAllowWhileIdle` schedule で発火が大幅遅延する (実機検証で
/// 1 分後の発火が起きなかった件の主因)。同時に [PermissionBanners] を
/// 表示し、権限不足の状態をユーザが画面上で気付けるようにする。
class AlarmListScreen extends ConsumerStatefulWidget {
  const AlarmListScreen({super.key});

  static const String routeLocation = '/alarms';

  @override
  ConsumerState<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends ConsumerState<AlarmListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(
      () => ref.read(permissionNotifierProvider.notifier).refresh(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ユーザが OS 設定から戻ってきた時 (resumed) に再評価して banner /
    // exact alarm decision を最新に保つ。TimerListScreen と同じ流儀。
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionNotifierProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<AlarmEntity> alarms = ref.watch(alarmCollectionNotifierProvider);
    // 表示順は時刻昇順 → 同時刻なら createdAt 昇順で安定化。
    // notifier 側は永続化順 (id 採番順) に近いため、UI 側で並び替え。
    final List<AlarmEntity> sorted = List<AlarmEntity>.from(alarms)
      ..sort((AlarmEntity a, AlarmEntity b) {
        final int byTime = a.targetTime.toMinutesFromMidnight().compareTo(
          b.targetTime.toMinutesFromMidnight(),
        );
        if (byTime != 0) return byTime;
        return a.createdAt.compareTo(b.createdAt);
      });

    return Scaffold(
      appBar: AppBar(title: Text(l.alarmListAppBarTitle)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const PermissionBanners(),
            Expanded(
              child: sorted.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l.alarmListEmptyHint,
                          key: const Key('alarm_list_empty_hint'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : ListView.separated(
                      // PresetManageScreen と同じ理屈: 56+16 ≒ 72dp の
                      // FAB 領域に tap target が被らないよう余裕を取る。
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: sorted.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final AlarmEntity entity = sorted[index];
                        return _AlarmCard(entity: entity);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('alarm_list_add_fab'),
        tooltip: l.alarmListAddFab,
        onPressed: () => context.push('/alarms/edit'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AlarmCard extends ConsumerWidget {
  const _AlarmCard({required this.entity});

  final AlarmEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool enabled = entity.enabled;
    // 無効状態は Material のテキスト色を弱める。Google Clock 流。
    final Color timeColor = enabled
        ? theme.colorScheme.onSurface
        : theme.disabledColor;
    final Color subtitleColor = enabled
        ? theme.colorScheme.onSurfaceVariant
        : theme.disabledColor;

    return Card(
      key: Key('alarm_card_${entity.id}'),
      child: InkWell(
        onTap: () => context.push('/alarms/edit/${entity.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _formatTime(entity.targetTime),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: timeColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatSubtitle(l, entity),
                      // 長いラベルでカードの高さが膨らむのを防ぐため
                      // 1 行省略表示。PR #11 review (gemini) 反映。
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: Key('alarm_card_switch_${entity.id}'),
                value: enabled,
                // toggle は新値を見ずに反転する。Switch の onChanged は
                // 「ユーザがタップした事実」のシグナルとして使う。
                onChanged: (_) => ref
                    .read(alarmCollectionNotifierProvider.notifier)
                    .toggle(entity.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDayValue v) {
    final String hh = v.hour.toString().padLeft(2, '0');
    final String mm = v.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// サブタイトル: 繰り返し情報 + (ラベル非空なら " · ラベル")
  ///
  /// - `Once` → "単発" / "Once"
  /// - `Weekly(全 7 曜日)` → "毎日" / "Every day"
  /// - `Weekly(部分集合)` → "月 火 水" / "Mon Tue Wed" (曜日順、空白区切り)
  String _formatSubtitle(AppLocalizations l, AlarmEntity entity) {
    final String repeatText = switch (entity.repeat) {
      AlarmRepeatOnce() => l.alarmEditRepeatOnce,
      AlarmRepeatWeekly(days: final Set<DayOfWeek> days) =>
        days.length == DayOfWeek.values.length
            ? l.alarmListRepeatEveryday
            : _formatWeekdays(l, days),
    };
    if (entity.label.isEmpty) return repeatText;
    return '$repeatText · ${entity.label}';
  }

  String _formatWeekdays(AppLocalizations l, Set<DayOfWeek> days) {
    // `DayOfWeek.values` は月→日の定義順。`where` で残せば即定義順の
    // List になり、別途 sort が不要 (PR #11 review (gemini) 反映)。
    final List<DayOfWeek> sorted = DayOfWeek.values
        .where(days.contains)
        .toList();
    final Map<DayOfWeek, String> labels = <DayOfWeek, String>{
      DayOfWeek.monday: l.weekdayMon,
      DayOfWeek.tuesday: l.weekdayTue,
      DayOfWeek.wednesday: l.weekdayWed,
      DayOfWeek.thursday: l.weekdayThu,
      DayOfWeek.friday: l.weekdayFri,
      DayOfWeek.saturday: l.weekdaySat,
      DayOfWeek.sunday: l.weekdaySun,
    };
    return sorted.map((DayOfWeek d) => labels[d] ?? d.name).join(' ');
  }
}
