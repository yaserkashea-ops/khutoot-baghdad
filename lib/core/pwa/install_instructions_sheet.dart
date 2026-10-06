import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/pwa/pwa_install.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

Future<void> showInstallInstructionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radius)),
    ),
    builder: (ctx) => const InstallInstructionsSheet(),
  );
}

class InstallInstructionsSheet extends StatelessWidget {
  const InstallInstructionsSheet({super.key});

  List<String> get _steps {
    if (PwaInstall.isIos) {
      return const [
        'اضغط زر المشاركة في Safari',
        'اختر «إضافة إلى الشاشة الرئيسية»',
        'اضغط «إضافة»',
      ];
    }
    if (PwaInstall.isMobile) {
      return const [
        'اضغط قائمة المتصفح ⋮',
        'اختر «إضافة إلى الشاشة الرئيسية» أو «تثبيت التطبيق»',
        'اضغط «إضافة»',
      ];
    }
    return const [
      'افتح قائمة المتصفح',
      'ابحث عن «تثبيت التطبيق» أو «إضافة إلى الشاشة الرئيسية»',
      'أكّد الإضافة',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final steps = _steps;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Icon(Icons.app_shortcut_outlined, size: 40, color: c.primary),
            const SizedBox(height: 10),
            Text(
              'ثبّت دليل خطوط بغداد',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ثبّت دليل خطوط بغداد على الشاشة الرئيسية للوصول السريع كل يوم.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                height: 1.45,
                color: c.text.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${i + 1}. ${steps[i]}',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: AppTokens.minTap,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('فهمت'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
