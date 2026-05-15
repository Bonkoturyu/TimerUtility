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
          accentKey: const Key('banner_post_notifications_accent'),
          icon: Icons.notifications_off_outlined,
          color: scheme.errorContainer,
          onColor: scheme.onErrorContainer,
          severity: _PermissionBannerSeverity.critical,
          title: l.permissionBannerNotificationsTitle,
          description: l.permissionBannerNotificationsDescription,
          hint:
              state.postNotifications ==
                  DomainPermissionStatus.permanentlyDenied
              ? l.permissionBannerHintTapToOpenSettings
              : l.permissionBannerHintTapToAllow,
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
          accentKey: const Key('banner_exact_alarm_accent'),
          icon: Icons.alarm_off_outlined,
          color: scheme.tertiaryContainer,
          onColor: scheme.onTertiaryContainer,
          severity: _PermissionBannerSeverity.recommended,
          title: l.permissionBannerExactAlarmTitle,
          description: l.permissionBannerExactAlarmDescription,
          hint:
              state.scheduleExactAlarm ==
                  DomainPermissionStatus.permanentlyDenied
              ? l.permissionBannerHintTapToOpenSettings
              : l.permissionBannerHintTapToAllow,
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
          accentKey: const Key('banner_full_screen_intent_accent'),
          icon: Icons.lock_outline,
          color: scheme.secondaryContainer,
          onColor: scheme.onSecondaryContainer,
          severity: _PermissionBannerSeverity.supplementary,
          title: l.permissionBannerFullScreenIntentTitle,
          description: l.permissionBannerFullScreenIntentDescription,
          hint: l.permissionBannerHintTapToOpenSettings,
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

/// Phase 11 CVD 冗長表示用の重大度。色相に依存しない 3 種の冗長情報
/// (ラベル / FontWeight / 左端色帯幅) を一括で決定するためのキー。
enum _PermissionBannerSeverity { critical, recommended, supplementary }

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required super.key,
    required this.accentKey,
    required this.icon,
    required this.color,
    required this.onColor,
    required this.severity,
    required this.title,
    required this.description,
    required this.hint,
    required this.onAction,
  });

  final Key accentKey;
  final IconData icon;
  final Color color;
  final Color onColor;
  final _PermissionBannerSeverity severity;
  final String title;
  final String description;
  final String hint;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String severityLabel = switch (severity) {
      _PermissionBannerSeverity.critical => l.permissionBannerSeverityCritical,
      _PermissionBannerSeverity.recommended =>
        l.permissionBannerSeverityRecommended,
      _PermissionBannerSeverity.supplementary =>
        l.permissionBannerSeveritySupplementary,
    };
    final FontWeight titleWeight = switch (severity) {
      _PermissionBannerSeverity.critical => FontWeight.w900,
      _PermissionBannerSeverity.recommended => FontWeight.w700,
      _PermissionBannerSeverity.supplementary => FontWeight.w600,
    };
    final double accentWidth = switch (severity) {
      _PermissionBannerSeverity.critical => 8.0,
      _PermissionBannerSeverity.recommended => 5.0,
      _PermissionBannerSeverity.supplementary => 3.0,
    };

    final BorderRadius radius = BorderRadius.circular(8);
    final TextStyle? hintStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: onColor.withValues(alpha: 0.85));

    // container: true で独立した SemanticsNode を確保し (これが無いと
    // props が祖先ノードへ合流し、兄弟の Text と同じノードに吸収されて
    // 画面全体が 1 ボタンとして読まれる)、
    // excludeSemantics: true で descendant の semantics を全遮断し
    // (Text.rich の TextSpan が「テキスト N」と読まれる回帰防止)、
    // 親 Semantics の label のみを TalkBack に届ける。InkWell も
    // excludeFromSemantics: true で暗黙の button ノード生成を抑止し、
    // 親の button role と競合させない。
    return Semantics(
      button: true,
      container: true,
      onTap: onAction,
      // セパレータは半角スペースのみ。日本語の句点「。」をハードコードすると
      // 英語ロケールで「Notifications disabled。Timer-end...」のように
      // ロケール非依存の記号が読み上げに混入するため、区切りはスペースで
      // 統一し、句読点は description / hint の ARB 訳側に任せる。
      label: '$severityLabel $title $description $hint',
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: radius,
        child: InkWell(
          onTap: onAction,
          borderRadius: radius,
          excludeFromSemantics: true,
          child: ClipRRect(
            borderRadius: radius,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    key: accentKey,
                    width: accentWidth,
                    color: onColor.withValues(alpha: 0.6),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: onColor),
                        child: IconTheme.merge(
                          data: IconThemeData(color: onColor),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(icon),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                          fontWeight: titleWeight,
                                        ),
                                        children: <InlineSpan>[
                                          TextSpan(text: '$severityLabel '),
                                          TextSpan(text: title),
                                        ],
                                      ),
                                    ),
                                    Text(description),
                                    Text(hint, style: hintStyle),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
