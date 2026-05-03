import 'package:flutter/material.dart';

/// PageView ベースの MainShell で、各タブの AppBar 左右に置く
/// 「次/前のページに何があるか」のヒント表示 (Phase 9.5)。
///
/// 例: Timer タブの AppBar
///   leading  : `< ⏱ ストップウォッチ` (前のタブ = Stopwatch)
///   trailing : `アラーム ⏰ >`         (次のタブ = Alarm)
///
/// タップすると親が `PageController.animateToPage` を発火する想定で、
/// 本 widget は `onTap` コールバックを受け取るだけ。Pure UI 部品。
///
/// 注意: AppBar の `leading` スロットはデフォルト幅 56dp で、
/// 本 widget の「アイコン + 短ラベル」は overflow する。
/// `direction: left` で利用するときは AppBar 側で `leadingWidth: 200`
/// 程度を設定すること (実機 / テスト共に 144dp では不足、
/// 200dp で 9〜10 文字程度の短ラベルが収まる)。
class PageNavigationHint extends StatelessWidget {
  const PageNavigationHint({
    super.key,
    required this.icon,
    required this.label,
    required this.direction,
    required this.onTap,
  });

  /// 隣接タブを象徴するアイコン (例: Icons.timer / Icons.alarm)。
  final IconData icon;

  /// 隣接タブの短いラベル (例: "ストップウォッチ" / "アラーム")。
  final String label;

  /// 矢印の向き。`left` = leading に置く前向きヒント、
  /// `right` = trailing に置く後向きヒント。
  final PageHintDirection direction;

  /// タップ時のコールバック (通常は PageController.animateToPage 呼び出し)。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color color = cs.onSurfaceVariant;
    final TextStyle? labelStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: color);

    final Widget chevron = Icon(
      direction == PageHintDirection.left
          ? Icons.chevron_left
          : Icons.chevron_right,
      size: 20,
      color: color,
    );
    final Widget icn = Icon(icon, size: 18, color: color);
    final Widget lbl = Text(label, style: labelStyle);

    final List<Widget> children = direction == PageHintDirection.left
        ? <Widget>[
            chevron,
            const SizedBox(width: 4),
            icn,
            const SizedBox(width: 4),
            lbl,
          ]
        : <Widget>[
            lbl,
            const SizedBox(width: 4),
            icn,
            const SizedBox(width: 4),
            chevron,
          ];

    return InkWell(
      key: Key(
        'page_nav_hint_${direction == PageHintDirection.left ? "left" : "right"}',
      ),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// `PageNavigationHint` の向き。
enum PageHintDirection { left, right }
