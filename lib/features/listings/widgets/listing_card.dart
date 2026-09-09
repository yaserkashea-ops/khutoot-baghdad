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
            border: BorderDirectional(
              start: BorderSide(color: stripe, width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _TypeBadge(listing: listing),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        listing.scheduleLabel,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: c.text.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${listing.area} ← ${listing.destination}',
                  softWrap: true,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: c.text,
                    height: 1.3,
                  ),
                ),
                if (listing.hasRouteSubs) ...[
                  const SizedBox(height: 4),
                  _SubRouteRow(listing: listing),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
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
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: onContact,
                    style: TextButton.styleFrom(
                      foregroundColor: c.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      textStyle: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Text(
        listing.typeLabel,
        style: GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}

class _SubRouteRow extends StatelessWidget {
  const _SubRouteRow({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final from =
        listing.originSubs.isEmpty ? '—' : listing.originSubsLabel;
    final to = listing.destinationSubs.isEmpty
        ? '—'
        : listing.destinationSubsLabel;

    return Text(
      '$from  ←  $to',
      softWrap: true,
      style: GoogleFonts.ibmPlexSansArabic(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.35,
        color: c.text.withValues(alpha: 0.58),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.border.withValues(alpha: 0.85)),
      ),
      child: Text(
        label,
        style: useManropeDigits
            ? AppTheme.manrope(
                fontSize: 11,
                color: c.text.withValues(alpha: 0.8),
              )
            : GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: c.text.withValues(alpha: 0.8),
              ),
      ),
    );
  }
}
