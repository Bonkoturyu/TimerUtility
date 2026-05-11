import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/alarm_collection_notifier.dart';
import '../../../application/permission_notifier.dart';
import '../../../domain/alarm/alarm_entity.dart';
import '../../../domain/alarm/alarm_repeat.dart';
import '../../../domain/alarm/day_of_week.dart';
import '../../../domain/alarm/time_of_day_value.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/permission_banners.dart';

/// Phase 11 Page widget. Body-only counterpart of the legacy
/// `AlarmListScreen`. Owns the `WidgetsBindingObserver` so the
/// permission banners refresh when the user comes back from system
/// Settings (Phase 9.5 follow-up — without this the `unknown` permission
/// state would force `inexactAllowWhileIdle` scheduling and miss the
/// 1-minute exact-alarm wake).
class AlarmListPage extends ConsumerStatefulWidget {
  const AlarmListPage({super.key});

  /// FAB shared between the deep-link `AlarmListScreen` wrapper and the
  /// HomeScreen's dynamic FAB slot.
  static FloatingActionButton buildFab(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return FloatingActionButton(
      key: const Key('alarm_list_add_fab'),
      tooltip: l.alarmListAddFab,
      onPressed: () => context.push('/alarms/edit'),
      child: const Icon(Icons.add),
    );
  }

  @override
  ConsumerState<AlarmListPage> createState() => _AlarmListPageState();
}

class _AlarmListPageState extends ConsumerState<AlarmListPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // PR #29 G2: keep alarm-card scroll position alive across HomeScreen
  // tab swipes.
  @override
  bool get wantKeepAlive => true;

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
    super.build(context); // AutomaticKeepAliveClientMixin contract.
    final AppLocalizations l = AppLocalizations.of(context);
    final List<AlarmEntity> alarms = ref.watch(alarmCollectionNotifierProvider);
    final List<AlarmEntity> sorted = List<AlarmEntity>.from(alarms)
      ..sort((AlarmEntity a, AlarmEntity b) {
        final int byTime = a.targetTime.toMinutesFromMidnight().compareTo(
          b.targetTime.toMinutesFromMidnight(),
        );
        if (byTime != 0) return byTime;
        return a.createdAt.compareTo(b.createdAt);
      });

    return Padding(
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
