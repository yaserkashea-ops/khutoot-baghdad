import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// `true` = rider, `false` = driver, `null` = cancelled.
Future<bool?> showPublishRoleSheet(BuildContext context) {
  final c = context.colors;
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: c.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ماذا تريد أن تنشر؟',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'اختر بدقة: كل طرف ينشر في تبويبه فقط. سيظهر تنبيه تأكيد قبل فتح النموذج.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  height: 1.4,
                  color: c.text.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 16),
              _RoleChoiceTile(
                icon: Icons.directions_car_filled_rounded,
                title: 'أنا سائق',
                subtitle: 'أريد نشر خطي ليبحث عني الراكبون',
                color: c.primary,
                filled: true,
                onTap: () => Navigator.pop(ctx, false),
              ),
              const SizedBox(height: 10),
              _RoleChoiceTile(
                icon: Icons.person_search_rounded,
                title: 'أنا طالب/موظف',
                subtitle: 'أريد نشر طلبي ليبحث عني السائقين',
                color: c.opportunity,
                filled: false,
                onTap: () => Navigator.pop(ctx, true),
              ),
              const SizedBox(height: 12),
              Text(
                'يمكنك متابعة التصفح بدون حساب. التسجيل مطلوب فقط لإدارة منشورك لاحقاً.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12.5,
                  height: 1.4,
                  color: c.text.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RoleChoiceTile extends StatelessWidget {
  const _RoleChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: filled ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: filled ? Colors.white : color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: filled ? Colors.white : c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12.5,
                        height: 1.35,
                        color: filled
                            ? Colors.white.withValues(alpha: 0.88)
                            : c.text.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirms the chosen publish lane so drivers do not post rider requests.
Future<bool> confirmPublishLane(
  BuildContext context, {
  required bool asRider,
}) async {
  final c = context.colors;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Text(
          asRider ? 'انتبه — طلبات الركاب' : 'انتبه — خطوط السائقين',
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w800),
        ),
        content: Text(
          asRider
              ? 'هنا يقوم الركاب بنشر طلباتهم ليبحث عنهم السائقون.\n\n'
                  'إذا كنت سائقاً وتريد نشر خطك، اضغط إلغاء ثم اختر خطوط السائقين.'
              : 'هنا يقوم السائقون بنشر خطوطهم ليبحث عنها الركاب.\n\n'
                  'إذا كنت راكباً وتريد نشر طلب مقعد، اضغط إلغاء ثم اختر طلبات الركاب.',
          style: GoogleFonts.ibmPlexSansArabic(height: 1.5, fontSize: 14.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w600,
                color: c.text.withValues(alpha: 0.7),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: asRider ? c.opportunity : c.primary,
            ),
            child: Text(
              asRider ? 'نعم، أنا راكب' : 'نعم، أنا سائق',
              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    },
  );
  return ok == true;
}
