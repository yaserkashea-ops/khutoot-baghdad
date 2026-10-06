import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(AppTokens.minTap, AppTokens.minTap),
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return ok == true;
}
