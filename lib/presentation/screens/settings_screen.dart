import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/settings_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/duration_picker.dart' show soundDisplayName;
import '../widgets/sound_select_sheet.dart';
import 'licenses_screen.dart';

/// Phase 11 settings screen.
///
/// Hosts the manual theme override, the seed values applied when
/// creating new alarms / presets (default snooze minutes / default
/// alarm sound), and the licenses entry. The Phase 10 license link in
/// the HomeScreen overflow menu was migrated here in the same PR.
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
