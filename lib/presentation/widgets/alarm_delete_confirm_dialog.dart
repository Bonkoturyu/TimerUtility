import 'package:flutter/material.dart';

/// `showAlarmDeleteConfirmDialog` の戻り値。
///
/// - `confirmed`: ユーザが Delete をタップしたか
/// - `dontAskAgain`: 「次から確認しない」のチェックが入っていたか。
///   呼び出し側が `UserPreferences` に
///   [UserPreferenceKeys.skipAlarmDeleteConfirm] (Phase 9.5 で追加)
///   として保存し、true のときは以降のダイアログをスキップする。
class AlarmDeleteConfirmResult {
  const AlarmDeleteConfirmResult({
    required this.confirmed,
    required this.dontAskAgain,
  });
  final bool confirmed;
  final bool dontAskAgain;

  static const AlarmDeleteConfirmResult cancelled = AlarmDeleteConfirmResult(
    confirmed: false,
    dontAskAgain: false,
  );
}

/// アラーム削除の確認ダイアログを表示する (Phase 9.5)。
///
/// Preset 側の `showPresetDeleteConfirmDialog` と同じ流儀で、
/// l10n は呼び出し側 (AlarmListScreen) が `AppLocalizations` 経由で
/// 解決した文字列を渡す形にする。本 widget は Pure UI で
/// `AppLocalizations` を直接 import しない (Step 5c と Step 6 の
/// 順序依存を切り離すため)。
///
/// ダイアログの外側タップで dismiss された場合は
/// [AlarmDeleteConfirmResult.cancelled] を返す。
Future<AlarmDeleteConfirmResult> showAlarmDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String dontAskLabel,
  required String cancelLabel,
  required String deleteLabel,
}) async {
  final AlarmDeleteConfirmResult? result =
      await showDialog<AlarmDeleteConfirmResult>(
        context: context,
        builder: (BuildContext context) => _AlarmDeleteConfirmDialog(
          title: title,
          dontAskLabel: dontAskLabel,
          cancelLabel: cancelLabel,
          deleteLabel: deleteLabel,
        ),
      );
  return result ?? AlarmDeleteConfirmResult.cancelled;
}

class _AlarmDeleteConfirmDialog extends StatefulWidget {
  const _AlarmDeleteConfirmDialog({
    required this.title,
    required this.dontAskLabel,
    required this.cancelLabel,
    required this.deleteLabel,
  });
  final String title;
  final String dontAskLabel;
  final String cancelLabel;
  final String deleteLabel;

  @override
  State<_AlarmDeleteConfirmDialog> createState() =>
      _AlarmDeleteConfirmDialogState();
}

class _AlarmDeleteConfirmDialogState extends State<_AlarmDeleteConfirmDialog> {
  bool _dontAskAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Row(
        children: <Widget>[
          Checkbox(
            key: const Key('alarm_delete_dont_ask'),
            value: _dontAskAgain,
            onChanged: (bool? v) => setState(() => _dontAskAgain = v ?? false),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(widget.dontAskLabel)),
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('alarm_delete_cancel'),
          onPressed: () => Navigator.of(context).pop(
            AlarmDeleteConfirmResult(
              confirmed: false,
              dontAskAgain: _dontAskAgain,
            ),
          ),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          key: const Key('alarm_delete_confirm'),
          onPressed: () => Navigator.of(context).pop(
            AlarmDeleteConfirmResult(
              confirmed: true,
              dontAskAgain: _dontAskAgain,
            ),
          ),
          child: Text(widget.deleteLabel),
        ),
      ],
    );
  }
}
