import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin action confirmation. Use [show] for a single extra click
/// (action + confirm = two taps). [showDouble] keeps two dialogs
/// for irreversible subscription/delete flows.
abstract final class AdminDoubleConfirm {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String detail,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
          ),
          content: Text(
            detail,
            style: GoogleFonts.ibmPlexSansArabic(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: c.error,
                      foregroundColor: c.onError,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return ok == true;
  }

  static Future<bool> showDouble(
    BuildContext context, {
    required String title,
    required String detail,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
          ),
          content: Text(
            detail,
            style: GoogleFonts.ibmPlexSansArabic(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: c.error,
                      foregroundColor: c.onError,
                    )
                  : null,
              child: Text('متابعة — $confirmLabel'),
            ),
          ],
        );
      },
    );
    if (first != true || !context.mounted) return false;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            'تأكيد نهائي',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'هذه الخطوة لا تُلغى بسهولة.\nهل تؤكد: $confirmLabel؟',
            style: GoogleFonts.ibmPlexSansArabic(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: c.error,
                      foregroundColor: c.onError,
                    )
                  : null,
              child: Text('تأكيد نهائي: $confirmLabel'),
            ),
          ],
        );
      },
    );
    return second == true;
  }
}
