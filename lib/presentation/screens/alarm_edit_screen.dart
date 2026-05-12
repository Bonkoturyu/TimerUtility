import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/alarm_collection_notifier.dart';
import '../../application/settings_notifier.dart';
import '../../application/user_preferences_provider.dart';
import '../../domain/alarm/alarm_entity.dart';
import '../../domain/alarm/alarm_repeat.dart';
import '../../domain/alarm/day_of_week.dart';
import '../../domain/alarm/exceptions.dart';
import '../../domain/alarm/time_of_day_value.dart';
import '../../domain/ports/user_preferences.dart';
import '../../domain/timer/alarm_sound.dart';
import '../../domain/timer/alarm_sound_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/alarm_delete_confirm_dialog.dart';
import '../widgets/duration_picker.dart' show soundDisplayName;
import '../widgets/sound_select_sheet.dart';
import '../widgets/weekday_selector.dart';

/// Phase 9.5 のアラーム編集画面。新規作成 / 既存編集の両用。
///
/// `alarmId == null` のときは新規作成モード。AppBar タイトルは
/// `alarmEditTitleNew`、削除ボタン非表示。enabled デフォルト true。
///
/// `alarmId` を指定すると既存アラーム編集モード。`AlarmCollectionNotifier`
/// から該当エンティティを引いて初期値とする。AppBar に削除ボタン (ゴミ箱)
/// + 確認ダイアログ。
///
/// 主な要素 (ADR 0005 / docs/domain-model.md L362 準拠):
/// - 上部: enabled の Switch (Google Clock 流)
/// - 時刻: `showTimePicker` モーダル経由
/// - 繰り返し: SegmentedButton (単発 / 曜日指定)
///   weekly 選択時は `WeekdaySelector` 表示、デフォルトは全曜日選択済み
/// - ラベル: TextField (maxLength 50)
/// - 音源: 既存 `SoundSelectSheet` を流用
/// - スヌーズ分: SegmentedButton (5 / 10 / 15)
/// - 保存: AppBar の保存ボタン → `AlarmCollectionNotifier.create` or `update`
class AlarmEditScreen extends ConsumerStatefulWidget {
  const AlarmEditScreen({super.key, this.alarmId});

  final String? alarmId;

  @override
  ConsumerState<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends ConsumerState<AlarmEditScreen> {
  bool _enabled = true;
  TimeOfDayValue _targetTime = const TimeOfDayValue.unsafe(hour: 7, minute: 0);
  bool _isWeekly = false;
  Set<DayOfWeek> _weekdays = DayOfWeek.values.toSet();
  String _label = '';
  String? _soundId;
  int _snoozeMinutes = 5;
  bool _initialized = false;
  // Phase 11 設定画面: 新規作成モードでユーザ設定のデフォルト
  // (defaultSnoozeMinutes / defaultAlarmSoundId) を 1 度だけ反映する。
  // didChangeDependencies が複数回呼ばれてもユーザ入力を上書きしないよう
  // フラグで二重実行を防ぐ。編集モードでは既存値が優先なのでこのパスを
  // 通らない (else 分岐に依存しない: ガードは _isEditMode で十分)。
  bool _appliedDefaults = false;

  late final TextEditingController _labelController;

  bool get _isEditMode => widget.alarmId != null;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isEditMode) {
      if (_initialized) return;
      // Notifier の state が既に populated されているケース (warm load)
      // で即時初期化。空のときは build の ref.listen で microtask 完了を
      // 待つ。
      final List<AlarmEntity> all = ref.read(alarmCollectionNotifierProvider);
      final AlarmEntity? entity = _findById(all, widget.alarmId!);
      if (entity != null) _applyEntity(entity);
      return;
    }
    // 新規作成モード: 設定画面のデフォルトを 1 度だけシードする。
    if (_appliedDefaults) return;
    final SettingsState settings = ref.read(settingsNotifierProvider);
    _snoozeMinutes = settings.defaultSnoozeMinutes;
    _soundId = settings.defaultAlarmSoundId;
    _appliedDefaults = true;
  }

  void _applyEntity(AlarmEntity entity) {
    _enabled = entity.enabled;
    _targetTime = entity.targetTime;
    switch (entity.repeat) {
      case AlarmRepeatOnce():
        _isWeekly = false;
      case AlarmRepeatWeekly(days: final Set<DayOfWeek> days):
        _isWeekly = true;
        _weekdays = Set<DayOfWeek>.from(days);
    }
    _label = entity.label;
    _labelController.text = _label;
    _soundId = entity.soundId;
    _snoozeMinutes = entity.snoozeMinutes;
    _initialized = true;
  }

  AlarmEntity? _findById(List<AlarmEntity> all, String id) {
    for (final AlarmEntity a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _onTimeTap() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _targetTime.hour,
        minute: _targetTime.minute,
      ),
    );
    if (picked == null) return;
    setState(() {
      _targetTime = TimeOfDayValue(hour: picked.hour, minute: picked.minute);
    });
  }

  Future<void> _onSoundTap() async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) =>
          SoundSelectSheet(initialSoundId: _soundId),
    );
    if (picked == null) return;
    setState(() => _soundId = picked);
  }

  Future<void> _onSave() async {
    final AppLocalizations l = AppLocalizations.of(context);
    if (_isWeekly && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.alarmEditValidationWeekdaysEmpty)),
      );
      return;
    }
    final AlarmRepeat repeat = _isWeekly
        ? AlarmRepeatWeekly.create(_weekdays)
        : const AlarmRepeatOnce();
    final notifier = ref.read(alarmCollectionNotifierProvider.notifier);

    try {
      if (_isEditMode) {
        // 既存: notificationId / createdAt は notifier 側で merge される。
        final List<AlarmEntity> all = ref.read(alarmCollectionNotifierProvider);
        final AlarmEntity? current = _findById(all, widget.alarmId!);
        if (current == null) {
          // 通常は build の ref.listen 経由で _initialized = true になる
          // ため到達しないが、対象 alarmId が削除されていた等の race で
          // 対象が見つからない場合は保存を諦めて通知する。
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.alarmEditNotFound)));
          return;
        }
        await notifier.update(
          current.copyWith(
            label: _label,
            targetTime: _targetTime,
            repeat: repeat,
            snoozeMinutes: _snoozeMinutes,
            enabled: _enabled,
            soundId: _soundId,
          ),
        );
      } else {
        await notifier.create(
          label: _label,
          targetTime: _targetTime,
          repeat: repeat,
          snoozeMinutes: _snoozeMinutes,
          enabled: _enabled,
          soundId: _soundId,
        );
      }
    } on MaxAlarmCountExceededException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.timerListLimitReached(e.maxSize))),
      );
      return;
    }
    if (!mounted) return;
    context.pop();
  }

  Future<void> _onDelete() async {
    if (!_isEditMode) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final UserPreferences prefs = ref.read(userPreferencesProvider);
    final bool? skip = await prefs.getBool(
      UserPreferenceKeys.skipAlarmDeleteConfirm,
    );

    bool confirmed = skip ?? false;
    if (!confirmed) {
      if (!mounted) return;
      final r = await showAlarmDeleteConfirmDialog(
        context,
        title: l.alarmDeleteConfirmTitle,
        dontAskLabel: l.alarmDeleteConfirmDontAsk,
        cancelLabel: l.alarmDeleteConfirmCancel,
        deleteLabel: l.alarmDeleteConfirmDelete,
      );
      confirmed = r.confirmed;
      if (r.dontAskAgain) {
        await prefs.setBool(UserPreferenceKeys.skipAlarmDeleteConfirm, true);
      }
    }
    if (!confirmed) return;
    if (!mounted) return;
    await ref
        .read(alarmCollectionNotifierProvider.notifier)
        .delete(widget.alarmId!);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    // 編集モードで notifier 経由 load を microtask で待っているケース。
    // state が更新されたら初期値を入れ直す (1 度だけ)。
    ref.listen<List<AlarmEntity>>(alarmCollectionNotifierProvider, (
      List<AlarmEntity>? prev,
      List<AlarmEntity> next,
    ) {
      if (!_isEditMode || _initialized) return;
      final AlarmEntity? entity = _findById(next, widget.alarmId!);
      if (entity != null) {
        setState(() => _applyEntity(entity));
        return;
      }
      // PR #11 review (Copilot) 反映: deep link / 古いブックマーク経由
      // で stale id を踏んだ際にローディング表示が永続する問題への対処。
      //
      // `prev == null` は build 直後の初回発火 = まだ load 走ってない。
      // `prev != null` かつ entity が見つからない = AlarmCollectionNotifier
      // の load が完了した上で対象が居ない (= 削除済 / 不正な id) と
      // 確定するため、SnackBar で通知して画面を閉じる。再発火防止のため
      // `_initialized` を立てておく (フォーム値は使わずに pop するので OK)。
      if (prev != null) {
        _initialized = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.alarmEditNotFound)));
          context.pop();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l.alarmEditTitleEdit : l.alarmEditTitleNew),
        actions: <Widget>[
          // Google Clock 流: 右上に enabled の Switch を出す。
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                Text(l.alarmEditEnabledLabel),
                const SizedBox(width: 4),
                Switch(
                  key: const Key('alarm_edit_enabled_switch'),
                  value: _enabled,
                  onChanged: (bool v) => setState(() => _enabled = v),
                ),
              ],
            ),
          ),
          if (_isEditMode)
            IconButton(
              key: const Key('alarm_edit_delete_button'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _onDelete,
              tooltip: l.alarmEditDelete,
            ),
          IconButton(
            key: const Key('alarm_edit_save_button'),
            icon: const Icon(Icons.check),
            // 編集モードかつ初期化前は保存を無効化。新規モードは初期化を
            // 待つ必要が無いので常に有効。
            onPressed: (_isEditMode && !_initialized) ? null : _onSave,
            tooltip: l.alarmEditSave,
          ),
        ],
      ),
      body: (_isEditMode && !_initialized)
          ? Center(
              key: const Key('alarm_edit_loading'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l.alarmEditLoading),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _Section(
                  label: l.alarmEditTimeLabel,
                  child: InkWell(
                    key: const Key('alarm_edit_time_field'),
                    onTap: _onTimeTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Text(
                        _formatTime(_targetTime),
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
                _Section(
                  label: l.alarmEditRepeatLabel,
                  child: SegmentedButton<bool>(
                    key: const Key('alarm_edit_repeat_segmented'),
                    segments: <ButtonSegment<bool>>[
                      ButtonSegment<bool>(
                        value: false,
                        label: Text(l.alarmEditRepeatOnce),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text(l.alarmEditRepeatWeekly),
                      ),
                    ],
                    selected: <bool>{_isWeekly},
                    onSelectionChanged: (Set<bool> v) =>
                        setState(() => _isWeekly = v.first),
                  ),
                ),
                if (_isWeekly)
                  _Section(
                    label: l.alarmEditWeekdaysLabel,
                    child: WeekdaySelector(
                      value: _weekdays,
                      labels: _weekdayLabels(l),
                      onChanged: (Set<DayOfWeek> v) =>
                          setState(() => _weekdays = v),
                    ),
                  ),
                _Section(
                  label: l.alarmEditLabelHint,
                  child: TextField(
                    key: const Key('alarm_edit_label_field'),
                    controller: _labelController,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String v) => _label = v,
                  ),
                ),
                _Section(
                  label: l.alarmEditSoundLabel,
                  child: InkWell(
                    key: const Key('alarm_edit_sound_field'),
                    onTap: _onSoundTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Text(soundDisplayName(l, _resolvedSoundId)),
                    ),
                  ),
                ),
                _Section(
                  label: l.alarmEditSnoozeLabel,
                  child: SegmentedButton<int>(
                    key: const Key('alarm_edit_snooze_segmented'),
                    segments: <ButtonSegment<int>>[
                      for (final int m in <int>[5, 10, 15])
                        ButtonSegment<int>(
                          value: m,
                          label: Text(l.alarmEditSnoozeMinutes(m)),
                        ),
                    ],
                    selected: <int>{_snoozeMinutes},
                    onSelectionChanged: (Set<int> v) =>
                        setState(() => _snoozeMinutes = v.first),
                  ),
                ),
              ],
            ),
    );
  }

  String get _resolvedSoundId =>
      (_soundId != null &&
          AlarmSoundCatalog.all.any((AlarmSound s) => s.id == _soundId))
      ? _soundId!
      : AlarmSoundCatalog.defaultSound.id;

  String _formatTime(TimeOfDayValue v) {
    final String hh = v.hour.toString().padLeft(2, '0');
    final String mm = v.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Map<DayOfWeek, String> _weekdayLabels(AppLocalizations l) {
    return <DayOfWeek, String>{
      DayOfWeek.monday: l.weekdayMon,
      DayOfWeek.tuesday: l.weekdayTue,
      DayOfWeek.wednesday: l.weekdayWed,
      DayOfWeek.thursday: l.weekdayThu,
      DayOfWeek.friday: l.weekdayFri,
      DayOfWeek.saturday: l.weekdaySat,
      DayOfWeek.sunday: l.weekdaySun,
    };
  }
}

/// 各セクションのラベル + コンテンツを並べる薄いラッパ。
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(label, style: tt.labelLarge),
          ),
          child,
        ],
      ),
    );
  }
}
