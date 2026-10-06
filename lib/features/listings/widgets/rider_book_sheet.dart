import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/publisher_auth_controller.dart';
import '../../../core/config/admin_contact.dart';
import '../../../core/config/unlock_payment.dart';
import '../../../core/models/contact_unlock.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/contact_unlocks_repository.dart';
import '../publisher_auth_sheet.dart';
import 'revealed_rider_sheet.dart';

/// Driver books an open rider request (fee notice + WhatsApp to admin).
Future<ContactUnlock?> openRiderBooking(
  BuildContext context, {
  required Listing listing,
  ContactUnlock? existing,
}) async {
  if (listing.isBooked &&
      existing?.isPending != true &&
      existing?.isApproved != true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          UnlockPayment.bookedNotice,
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
      ),
    );
    return existing;
  }

  if (existing != null && existing.isApproved) {
    await showListingContactChooser(context, listing);
    return existing;
  }

  final auth = PublisherAuthController.shared;
  if (!auth.isLoaded) await auth.load();
  if (!context.mounted) return existing;
  if (!auth.isLoggedIn) {
    final ok = await showPublisherAuthSheet(
      context,
      title: 'سجّل الدخول لحجز الطلب',
    );
    if (!context.mounted) return existing;
    if (!ok || !PublisherAuthController.shared.isLoggedIn) return existing;
  }

  final payMsg = UnlockPayment.adminBriefMessage(
    code: listing.displayCode,
    origin: listing.area,
    destination: listing.destination,
  );
  final c = context.colors;
  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
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
                existing != null && existing.isPending
                    ? 'طلب الحجز قيد التأكيد'
                    : 'احجز الطلب وتواصل مع الراكب',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                UnlockPayment.availableInvite,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  height: 1.45,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.text.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                UnlockPayment.notice,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  height: 1.5,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, 'whatsapp'),
                icon: const Icon(Icons.chat_outlined),
                label: Text(
                  existing != null && existing.isPending
                      ? 'إعادة إرسال الرسالة للإدارة'
                      : 'تواصل مع الإدارة',
                ),
              ),
              if (existing != null && existing.isPending) ...[
                const SizedBox(height: 8),
                Text(
                  'بانتظار تأكيد الدفع',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12.5,
                    color: c.text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
  if (!context.mounted || action != 'whatsapp') return existing;

  ContactUnlock? created = existing;
  try {
    if (existing == null || existing.isRejected) {
      created = await ContactUnlocksRepository.shared.requestUnlock(
        riderRequest: listing,
      );
    }
  } on RequestAlreadyBooked {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            UnlockPayment.bookedNotice,
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    }
    return existing;
  } catch (_) {}
  if (!context.mounted) return created;
  final url = Uri.parse(AdminContact.whatsappUrl(payMsg));
  await launchUrl(url, mode: LaunchMode.externalApplication);
  return created;
}
