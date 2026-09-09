import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/admin_contact.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/admin_repository.dart';

/// Bottom sheet: report / complaint / problem → save to admin inbox + external chat.
Future<void> showContactAdminSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(),
    builder: (context) => const _ContactAdminSheet(),
  );
}

class _ContactAdminSheet extends StatelessWidget {
  const _ContactAdminSheet();

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      final c = context.colors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.text,
          content: Text(
            'تعذر فتح رابط التواصل',
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w400,
              color: c.onPrimary,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onKind(BuildContext context, AdminContactKind kind) async {
    final details = TextEditingController();
    final contact = TextEditingController();

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        return AlertDialog(
          title: Text(
            kind.label,
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kind.subtitle,
                  style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: details,
                  maxLines: 3,
                  style: GoogleFonts.ibmPlexSansArabic(),
                  decoration: InputDecoration(
                    labelText: 'التفاصيل',
                    labelStyle: GoogleFonts.ibmPlexSansArabic(),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contact,
                  style: GoogleFonts.ibmPlexSansArabic(),
                  decoration: InputDecoration(
                    labelText: 'رقم أو تلغرام للتواصل (اختياري)',
                    labelStyle: GoogleFonts.ibmPlexSansArabic(),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'متابعة',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w600,
                  color: c.primary,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (proceed != true || !context.mounted) {
      details.dispose();
      contact.dispose();
      return;
    }

    final detailText = details.text.trim();
    final base = AdminContact.messageFor(kind);
    final message = detailText.isEmpty ? base : '$base\n\n$detailText';

    await AdminRepository.shared.submitReport(
      kind: kind,
      message: message,
      contactHint:
          contact.text.trim().isEmpty ? null : contact.text.trim(),
    );

    details.dispose();
    contact.dispose();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        final c = ctx.colors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تم استلام ${kind.label} في لوحة التحكم',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'يمكنك أيضاً متابعة التواصل مباشرة:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    color: c.text.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                _ChannelTile(
                  title: 'واتساب',
                  subtitle: 'إرسال رسالة جاهزة للإدارة',
                  icon: Icons.chat_outlined,
                  onTap: () async {
                    await _open(
                      ctx,
                      Uri.parse(AdminContact.whatsappUrl(message)),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                _ChannelTile(
                  title: 'تلغرام',
                  subtitle: 'فتح محادثة الإدارة',
                  icon: Icons.send_outlined,
                  onTap: () async {
                    await _open(ctx, Uri.parse(AdminContact.telegram));
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'إغلاق',
                    style: GoogleFonts.ibmPlexSansArabic(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'التواصل مع الإدارة',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: c.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'يُسجَّل البلاغ في لوحة التحكم ويمكن متابعته عبر واتساب أو تلغرام',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: c.text.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            for (final kind in AdminContactKind.values) ...[
              _ChannelTile(
                title: kind.label,
                subtitle: kind.subtitle,
                icon: switch (kind) {
                  AdminContactKind.report => Icons.flag_outlined,
                  AdminContactKind.complaint => Icons.report_problem_outlined,
                  AdminContactKind.problem => Icons.support_agent_outlined,
                },
                onTap: () => _onKind(context, kind),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: c.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: c.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: c.text.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
