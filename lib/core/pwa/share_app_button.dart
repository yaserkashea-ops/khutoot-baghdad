import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_hosts.dart';
import '../theme/app_colors.dart';
import 'native_share.dart';

/// Opens the system share sheet immediately (like professional apps).
/// Falls back to a multi-destination «مشاركة عبر» sheet only when the OS
/// share API is unavailable (common on some desktop browsers).
Future<void> shareAppLink(BuildContext context) async {
  final link = AppHosts.publicUrl;
  const title = 'خطوط بغداد';
  const text = 'خطوط بغداد — نظّم وابحث عن خطوط النقل المشترك في بغداد';
  final payload = '$text\n$link';

  // 1) Browser Web Share API → full OS sheet (WhatsApp, Messages, Copy, …)
  final native = await NativeShare.share(
    title: title,
    text: text,
    url: link,
  );
  if (native != NativeShareOutcome.unavailable) return;
  if (!context.mounted) return;

  // 2) Native mobile/desktop plugins (non-web embeds)
  if (!kIsWeb) {
    Rect? origin;
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          title: title,
          subject: title,
          text: payload,
          sharePositionOrigin: origin,
          mailToFallbackEnabled: false,
          downloadFallbackEnabled: false,
        ),
      );
      if (result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed) {
        return;
      }
    } catch (_) {
      // Continue to multi-app fallback.
    }
  }

  // 3) Desktop / unsupported browsers: multi-destination chooser
  if (!context.mounted) return;
  await _showShareViaSheet(
    context,
    link: link,
    title: title,
    text: text,
    payload: payload,
  );
}

Future<void> _showShareViaSheet(
  BuildContext context, {
  required String link,
  required String title,
  required String text,
  required String payload,
}) async {
  if (!context.mounted) return;
  final c = context.colors;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      Future<void> open(Uri uri) async {
        if (ctx.mounted) Navigator.pop(ctx);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      Widget tile({
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
                  child: Icon(icon, color: c.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'مشاركة عبر',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'اختر التطبيق الذي تريد المشاركة من خلاله',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: c.text.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.85,
                children: [
                  tile(
                    icon: Icons.copy_rounded,
                    label: 'نسخ',
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: c.primary,
                          content: Text(
                            'تم نسخ رابط التطبيق',
                            style: TextStyle(color: c.onPrimary),
                          ),
                        ),
                      );
                    },
                  ),
                  tile(
                    icon: Icons.chat_rounded,
                    label: 'واتساب',
                    onTap: () => open(
                      Uri.parse(
                        'https://wa.me/?text=${Uri.encodeComponent(payload)}',
                      ),
                    ),
                  ),
                  tile(
                    icon: Icons.send_rounded,
                    label: 'تيليجرام',
                    onTap: () => open(
                      Uri.parse(
                        'https://t.me/share/url?url=${Uri.encodeComponent(link)}&text=${Uri.encodeComponent(text)}',
                      ),
                    ),
                  ),
                  tile(
                    icon: Icons.sms_rounded,
                    label: 'رسائل',
                    onTap: () => open(
                      Uri(
                        scheme: 'sms',
                        queryParameters: {'body': payload},
                      ),
                    ),
                  ),
                  tile(
                    icon: Icons.email_outlined,
                    label: 'بريد',
                    onTap: () => open(
                      Uri(
                        scheme: 'mailto',
                        query:
                            'subject=${Uri.encodeComponent(title)}&body=${Uri.encodeComponent(payload)}',
                      ),
                    ),
                  ),
                  tile(
                    icon: Icons.facebook_rounded,
                    label: 'فيسبوك',
                    onTap: () => open(
                      Uri.parse(
                        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}',
                      ),
                    ),
                  ),
                  tile(
                    icon: Icons.alternate_email_rounded,
                    label: 'إكس',
                    onTap: () => open(
                      Uri.parse(
                        'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(link)}',
                      ),
                    ),
                  ),
                  tile(
                    icon: Icons.ios_share_rounded,
                    label: 'المزيد',
                    onTap: () async {
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!context.mounted) return;
                      final again = await NativeShare.share(
                        title: title,
                        text: text,
                        url: link,
                      );
                      if (again != NativeShareOutcome.unavailable) return;
                      try {
                        await SharePlus.instance.share(
                          ShareParams(
                            title: title,
                            subject: title,
                            text: payload,
                            mailToFallbackEnabled: false,
                            downloadFallbackEnabled: false,
                          ),
                        );
                      } catch (_) {
                        await Clipboard.setData(ClipboardData(text: link));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: c.primary,
                            content: Text(
                              'تم نسخ رابط التطبيق',
                              style: TextStyle(color: c.onPrimary),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Classic share mark — opens native / multi-app share on tap.
class ShareAppIconButton extends StatelessWidget {
  const ShareAppIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'مشاركة التطبيق',
      child: Builder(
        builder: (buttonContext) {
          return IconButton(
            tooltip: 'مشاركة التطبيق',
            onPressed: () => shareAppLink(buttonContext),
            icon: const Icon(Icons.share_rounded),
          );
        },
      ),
    );
  }
}
