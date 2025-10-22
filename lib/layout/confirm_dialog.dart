import 'package:fling/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

showConfirmDialog(
    {required BuildContext context,
    void Function()? yesAction,
    String? yesText,
    Widget? content}) {
  var l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.action_sure),
      content: content,
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(l10n.action_cancel)),
        TextButton(
            onPressed: yesAction, child: Text(yesText ?? l10n.action_done)),
      ],
    ),
  );
}
