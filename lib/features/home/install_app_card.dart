import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/pwa/install_app_button.dart';
import '../../../core/pwa/install_instructions_sheet.dart';
import '../../../core/pwa/pwa_install.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

class InstallAppCard extends StatelessWidget {
  const InstallAppCard({
    super.key,
    this.onInstalled,
    this.onDismiss,
  });

  final VoidCallback? onInstalled;
  final VoidCallback? onDismiss;

  Future<void> _open(BuildContext context) async {
    if (PwaInstall.canNativeInstall) {
      await runInstallAppFlow(context);
    } else {
      if (!context.mounted) return;
      await showInstallInstructionsSheet(context);
    }
    onInstalled?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      borderRadius: AppTokens.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppTokens.borderRadius,
            color: Color.lerp(c.background, c.surface, 0.2),
            border: Border.all(color: c.accent.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_to_home_screen_rounded,
                    color: c.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ثبّت خطوط بغداد على شاشة هاتفك',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        'وصول أسرع إلى الإعلانات كل يوم',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          color: c.text.withValues(alpha: 0.62),
                        ),
                      ),
                      Text(
                        'طريقة التثبيت',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          color: c.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      color: c.text.withValues(alpha: 0.45),
                    ),
                  )
                else
                  Icon(Icons.chevron_left, color: c.primary.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
