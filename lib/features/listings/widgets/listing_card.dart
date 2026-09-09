import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onContact,
  });

  final Listing listing;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stripe = listing.isDriver ? c.accent : c.riderAccent;

    return Material(
      color: c.surface,
      child: InkWell(
        onTap: onContact,
        child: DecoratedBox(
          decoration: BoxDecoration(
            // RTL: BorderDirectional.start paints on the right edge.
            border: BorderDirectional(
              start: BorderSide(color: stripe, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _TypeBadge(listing: listing),
                    const Spacer(),
                    Text(
                      listing.scheduleLabel,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: c.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${listing.area} ← ${listing.destination}',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: c.text,
                    height: 1.35,
                  ),
                ),
                if (listing.hasRouteSubs) ...[
                  const SizedBox(height: 6),
                  _SubRouteRow(listing: listing),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaChip(label: listing.genderLabel),
                    if (listing.isDriver && listing.vehicleType != null)
                      _MetaChip(label: listing.vehicleType!),
                    if (listing.isDriver && listing.seatsCount != null)
                      _MetaChip(
                        label: '${listing.seatsCount} مقاعد',
                        useManropeDigits: true,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: onContact,
                    style: TextButton.styleFrom(
                      foregroundColor: c.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('تواصل'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = listing.isDriver ? c.accent : c.riderAccent;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.45)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Text(
        listing.typeLabel,
        style: GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }
}

/// Shows secondary from/to points: «نقاط من» ← «نقاط إلى»
class _SubRouteRow extends StatelessWidget {
  const _SubRouteRow({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = GoogleFonts.ibmPlexSansArabic(
      fontWeight: FontWeight.w400,
      fontSize: 13,
      height: 1.45,
      color: c.text.withValues(alpha: 0.62),
    );
    final arrowStyle = GoogleFonts.ibmPlexSansArabic(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: c.primary.withValues(alpha: 0.55),
    );

    final from = listing.originSubs.isEmpty
        ? '—'
        : listing.originSubsLabel;
    final to = listing.destinationSubs.isEmpty
        ? '—'
        : listing.destinationSubsLabel;

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: from),
          TextSpan(text: '  ←  ', style: arrowStyle),
          TextSpan(text: to),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    this.useManropeDigits = false,
  });

  final String label;
  final bool useManropeDigits;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
      ),
      child: Text(
        label,
        style: useManropeDigits
            ? AppTheme.manrope(fontSize: 12, color: c.text.withValues(alpha: 0.8))
            : GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: c.text.withValues(alpha: 0.8),
              ),
      ),
    );
  }
}
