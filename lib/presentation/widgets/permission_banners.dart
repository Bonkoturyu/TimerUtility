import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/permission_notifier.dart';
import '../../domain/ports/permission_manager.dart';
import '../../l10n/app_localizations.dart';

/// Phase 9.5 で TimerListScreen の private クラスから切り出した
/// 共通権限バナー widget。
///
/// 元は [TimerListScreen] (Phase 6b) のみが表示していたが、Phase 9.5 で
/// AlarmListScreen も同じ permission state (`POST_NOTIFICATIONS` /
/// `SCHEDULE_EXACT_ALARM` / `USE_FULL_SCREEN_INTENT`) に依存するため、
/// 一覧画面間で表示の一貫性を担保すべく widget 化した。
///
/// `permissionNotifierProvider` を `watch` するため、画面側で
/// `refresh()` を呼ぶ責務は呼び出し画面 (initState の microtask +
/// `didChangeAppLifecycleState(resumed)`) にある。
class PermissionBanners extends ConsumerWidget {
  const PermissionBanners({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(permissionNotifierProvider);
    final notifier = ref.read(permissionNotifierProvider.notifier);
    final AppLocalizations l = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final List<Widget> banners = <Widget>[];

    if (state.postNotifications == DomainPermissionStatus.denied ||
        state.postNotifications == DomainPermissionStatus.permanentlyDenied) {
      banners.add(
        _PermissionBanner(
          key: const Key('banner_post_notifications'),
          icon: Icons.notifications_off_outlined,
          color: scheme.errorContainer,
          onColor: scheme.onErrorContainer,
          title: l.permissionBannerNotificationsTitle,
          description: l.permissionBannerNotificationsDescription,
          actionLabel:
              state.postNotifications ==
                  DomainPermissionStatus.permanentlyDenied
              ? l.permissionBannerActionOpenSettings
              : l.permissionBannerActionAllow,
          onAction:
              state.postNotifications ==
                  DomainPermissionStatus.permanentlyDenied
              ? () => notifier.openSettings()
              : () => notifier.requestNotification(),
        ),
      );
    }

    if (state.scheduleExactAlarm == DomainPermissionStatus.denied ||
        state.scheduleExactAlarm == DomainPermissionStatus.permanentlyDenied) {
      banners.add(
        _PermissionBanner(
          key: const Key('banner_exact_alarm'),
          icon: Icons.alarm_off_outlined,
          color: scheme.tertiaryContainer,
          onColor: scheme.onTertiaryContainer,
          title: l.permissionBannerExactAlarmTitle,
          description: l.permissionBannerExactAlarmDescription,
          actionLabel:
              state.scheduleExactAlarm ==
                  DomainPermissionStatus.permanentlyDenied
              ? l.permissionBannerActionOpenSettings
              : l.permissionBannerActionAllow,
          onAction:
              state.scheduleExactAlarm ==
                  DomainPermissionStatus.permanentlyDenied
              ? () => notifier.openSettings()
              : () => notifier.requestScheduleExactAlarm(),
        ),
      );
    }

    if (state.fullScreenIntent == DomainPermissionStatus.denied ||
        state.fullScreenIntent == DomainPermissionStatus.permanentlyDenied) {
      banners.add(
        _PermissionBanner(
          key: const Key('banner_full_screen_intent'),
          icon: Icons.lock_outline,
          color: scheme.secondaryContainer,
          onColor: scheme.onSecondaryContainer,
          title: l.permissionBannerFullScreenIntentTitle,
          description: l.permissionBannerFullScreenIntentDescription,
          actionLabel: l.permissionBannerActionOpenSettings,
          onAction: () => notifier.openFullScreenIntentSettings(),
        ),
      );
    }

    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final banner in banners) ...<Widget>[
          banner,
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required super.key,
    required this.icon,
    required this.color,
    required this.onColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final Color onColor;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: onColor),
          child: IconTheme.merge(
            data: IconThemeData(color: onColor),
            child: Row(
              children: <Widget>[
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(description),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(foregroundColor: onColor),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
