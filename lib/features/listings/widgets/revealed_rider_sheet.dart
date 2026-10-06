import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/listing.dart';
import '../../../core/config/directory_launch.dart';
import '../../../core/utils/listing_contact.dart';
import 'listing_card.dart';

Future<void> showListingContactChooser(
  BuildContext context,
  Listing listing,
) async {
  final options = ListingContact.optionsFor(listing);
  if (options.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'لا توجد وسيلة تواصل محفوظة',
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
      ),
    );
    return;
  }
  final c = context.colors;
  final chosen = await showModalBottomSheet<ContactOption>(
    context: context,
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
                listing.isDriver ? 'تواصل مع السائق' : 'تواصل مع الراكب',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              for (final option in options) ...[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: c.border),
                  ),
                  title: Row(
                    children: [
                      Text(option.label),
                      if (option.detail != null &&
                          option.detail!.trim().isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: SelectableText(
                            option.detail!,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: c.text.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.pop(ctx, option),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      );
    },
  );
  if (chosen == null) return;
  await ListingContact.openUrl(chosen.url);
}

/// Same rider card as the public directory, with WhatsApp / Telegram on تواصل.
Future<void> showRevealedRiderSheet(
  BuildContext context,
  Listing listing,
) async {
  final c = context.colors;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListingCard(
                listing: DirectoryLaunch.freeRiderContacts
                    ? listing
                    : listing.withoutPublicContacts(),
                contactLabel: 'تواصل مع الراكب',
                onContact: () => showListingContactChooser(ctx, listing),
              ),
            ],
          ),
        ),
      );
    },
  );
}
