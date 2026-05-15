import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/duration_picker.dart' show soundDisplayName;
import '../widgets/sound_select_sheet.dart';
import 'licenses_screen.dart';

/// 言語名は **そのロケール自身の表記** で出すのが多言語アプリの慣習
/// (現在の UI ロケールに依存させない)。ARB に入れず、ここに固定 Map
/// として保持する。`null` キーは「システムに合わせる」用で、表示は
/// ARB の `settingsLanguageSystem` で取る。
const Map<String, String> _languageDisplayNames = <String, String>{
  'ja': '日本語',
  'en': 'English',
  'zh': '简体中文',
  'zh-Hant': '繁體中文',
  'ko': '한국어',
};

const List<String> _publicLanguageTagOrder = <String>['ja', 'en'];
const List<String> _experimentalLanguageTagOrder = <String>[
  'zh',
  'zh-Hant',
  'ko',
];

/// Phase 11 settings screen.
///
/// Hosts the manual theme override, the manual language override
/// (Phase 11 language toggle), the seed values applied when creating
/// new alarms / presets (default snooze minutes / default alarm sound),
/// and the licenses entry. The Phase 10 license link in the HomeScreen
/// overflow menu was migrated here in the same PR.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String routeLocation = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    final SettingsNotifier notifier = ref.read(
      settingsNotifierProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAppBarTitle)),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            _SectionHeader(label: l.settingsSectionDisplay),
            ListTile(
              key: const Key('settings_theme_tile'),
              leading: const Icon(Icons.brightness_6_outlined),
              isThreeLine: true,
              title: Text(l.settingsThemeLabel),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SegmentedButton<ThemeMode>(
                  key: const Key('settings_theme_segmented'),
                  segments: <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text(l.settingsThemeSystem),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(l.settingsThemeLight),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(l.settingsThemeDark),
                    ),
                  ],
                  selected: <ThemeMode>{settings.themeMode},
                  onSelectionChanged: (Set<ThemeMode> v) =>
                      notifier.setThemeMode(v.first),
                ),
              ),
            ),
            ListTile(
              key: const Key('settings_language_tile'),
              leading: const Icon(Icons.language_outlined),
              title: Text(l.settingsLanguageLabel),
              subtitle: Text(_languageSubtitle(l, settings.localeOverride)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _onLanguageTap(context, ref, settings),
            ),
            _SectionHeader(label: l.settingsSectionDefaults),
            ListTile(
              key: const Key('settings_snooze_tile'),
              leading: const Icon(Icons.snooze_outlined),
              isThreeLine: true,
              title: Text(l.settingsDefaultSnoozeLabel),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SegmentedButton<int>(
                  key: const Key('settings_snooze_segmented'),
                  segments: <ButtonSegment<int>>[
                    for (final int m in kAllowedDefaultSnoozeMinutes)
                      ButtonSegment<int>(
                        value: m,
                        label: Text(l.settingsDefaultSnoozeOption(m)),
                      ),
                  ],
                  selected: <int>{settings.defaultSnoozeMinutes},
                  onSelectionChanged: (Set<int> v) =>
                      notifier.setDefaultSnoozeMinutes(v.first),
                ),
              ),
            ),
            ListTile(
              key: const Key('settings_sound_tile'),
              leading: const Icon(Icons.music_note_outlined),
              title: Text(l.settingsDefaultAlarmSoundLabel),
              subtitle: Text(soundDisplayName(l, settings.defaultAlarmSoundId)),
              onTap: () => _onSoundTap(context, ref, settings),
            ),
            _SectionHeader(label: l.settingsSectionAbout),
            ListTile(
              key: const Key('settings_licenses_tile'),
              leading: const Icon(Icons.description_outlined),
              title: Text(l.licenseMenuOverflow),
              onTap: () => context.push(LicensesScreen.routeLocation),
            ),
          ],
        ),
      ),
    );
  }

  String _languageSubtitle(AppLocalizations l, Locale? override) {
    if (override == null) return l.settingsLanguageSystem;
    final String tag = override.toLanguageTag();
    return _languageDisplayNames[tag] ?? l.settingsLanguageSystem;
  }

  Future<void> _onLanguageTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) async {
    final AppLocalizations l = AppLocalizations.of(context);
    // null = follow-system, otherwise the BCP-47 tag.
    final String? picked = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => _LanguagePickerSheet(
        title: l.settingsLanguageDialogTitle,
        systemLabel: l.settingsLanguageSystem,
        // 現在の選択を Sheet に渡す。null は「システムに合わせる」相当。
        initialTag: settings.localeOverride?.toLanguageTag(),
      ),
    );
    // showModalBottomSheet は dismiss 時 (背景 tap / pop) に null を返す。
    // 「システムに合わせる」を選んだ場合は本シート内で sentinel を渡してから
    // pop している (`_followSystemSentinel`)。null 戻り = 変更なし。
    if (picked == null) return;
    final String? pickedTag = picked == _followSystemSentinel ? null : picked;
    await ref
        .read(settingsNotifierProvider.notifier)
        .setLocaleOverride(pickedTag);
  }

  Future<void> _onSoundTap(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) async {
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          SoundSelectSheet(initialSoundId: settings.defaultAlarmSoundId),
    );
    if (picked == null) return;
    await ref
        .read(settingsNotifierProvider.notifier)
        .setDefaultAlarmSoundId(picked);
  }
}

/// シートを `null` で pop すると「変更キャンセル」と区別がつかないため
/// 「システムに合わせる」用の sentinel 文字列を内部 API として使う。
const String _followSystemSentinel = '__system__';

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({
    required this.title,
    required this.systemLabel,
    required this.initialTag,
  });

  final String title;
  final String systemLabel;
  final String? initialTag;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String effective = initialTag ?? _followSystemSentinel;
    final List<String> tags = <String>[
      ..._publicLanguageTagOrder,
      if (kEnableExperimentalLocales) ..._experimentalLanguageTagOrder,
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          // RadioListTile.groupValue/onChanged は Flutter 3.32 以降で
          // deprecated。`SoundSelectSheet` と同じく ListTile + radio
          // アイコンで描画し、deprecation を回避しつつスタイルを揃える。
          _LanguageOptionTile(
            key: const Key('settings_language_option_system'),
            label: systemLabel,
            value: _followSystemSentinel,
            selected: effective == _followSystemSentinel,
          ),
          for (final String tag in tags)
            _LanguageOptionTile(
              key: Key('settings_language_option_$tag'),
              label: _languageDisplayNames[tag] ?? tag,
              value: tag,
              selected: effective == tag,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.value,
    required this.selected,
    super.key,
  });

  final String label;
  final String value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(label),
      onTap: () => Navigator.of(context).pop(value),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
