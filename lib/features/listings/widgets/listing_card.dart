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

  String get _typeTitle => listing.isDriver
      ? 'سائق لديه مقاعد'
      : 'راكب يبحث عن مقعد';

  String get _contactLabel =>
      listing.isDriver ? 'تواصل مع السائق' : 'تواصل مع الراكب';

  String get _subsLine {
    final from =
        listing.originSubs.isEmpty ? '—' : listing.originSubsLabel;
    final to =
        listing.destinationSubs.isEmpty ? '—' : listing.destinationSubsLabel;
    return '$from ← $to';
  }

  String? get _publishedLabel {
    final at = listing.createdAt?.toLocal();
    if (at == null) return null;
    final diff = DateTime.now().difference(at);
    if (diff.isNegative || diff.inSeconds < 45) {
      return 'نشر منذ لحظات';
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return 'نشر منذ ${_countLabel(m, 'دقيقة', 'دقيقتين', 'دقائق')}';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours.clamp(1, 23);
      return 'نشر منذ ${_countLabel(h, 'ساعة', 'ساعتين', 'ساعات')}';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays.clamp(1, 6);
      return 'نشر منذ ${_countLabel(d, 'يوم', 'يومين', 'أيام')}';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor().clamp(1, 4);
      return 'نشر منذ ${_countLabel(w, 'أسبوع', 'أسبوعين', 'أسابيع')}';
    }
    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor().clamp(1, 11);
      return 'نشر منذ ${_countLabel(mo, 'شهر', 'شهرين', 'أشهر')}';
    }
    final y = (diff.inDays / 365).floor().clamp(1, 99);
    return 'نشر منذ ${_countLabel(y, 'سنة', 'سنتين', 'سنوات')}';
  }

  /// Instagram-like Arabic plural forms for relative time.
  String _countLabel(int n, String one, String two, String many) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n >= 3 && n <= 10) return '$n $many';
    return '$n $one';
  }

  List<String> get _footerChips {
    final chips = <String>[
      listing.timePeriodLabel,
      listing.genderLabel,
    ];
    final dep = listing.departureTime?.trim();
    final ret = listing.returnTime?.trim();
    if (dep != null && dep.isNotEmpty) chips.add('انطلاق $dep');
    if (ret != null && ret.isNotEmpty) chips.add('عودة $ret');
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final badgeColor = listing.isDriver ? c.accent : c.riderAccent;

    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: badgeColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      listing.isDriver
                          ? Icons.directions_car_outlined
                          : Icons.person_search_outlined,
                      size: 14,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _typeTitle,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${listing.area} ← ${listing.destination}',
              softWrap: true,
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: c.text,
                height: 1.35,
              ),
            ),
            if (listing.hasRouteSubs) ...[
              const SizedBox(height: 4),
              Text(
                _subsLine,
                softWrap: true,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                  height: 1.35,
                  color: c.primary,
                ),
              ),
            ],
            if (listing.isDriver && listing.seatsCount != null) ...[
              const SizedBox(height: 8),
              Text(
                '${listing.seatsCount} مقاعد متاحة',
                style: AppTheme.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.text.withValues(alpha: 0.8),
                ),
              ),
            ],
            if (listing.isDriver &&
                listing.vehicleType != null &&
                listing.vehicleType!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'نوع السيارة: ${listing.vehicleType!.trim()}',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12,
                  color: c.text.withValues(alpha: 0.65),
                ),
              ),
            ],
            if (_publishedLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                _publishedLabel!,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w400,
                  fontSize: 11,
                  color: c.text.withValues(alpha: 0.5),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onContact,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.primary,
                    side: BorderSide(color: c.primary.withValues(alpha: 0.35)),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    visualDensity: VisualDensity.compact,
                    textStyle: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  child: Text(_contactLabel),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final label in _footerChips)
                        _MetaChip(label: label),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
        color: c.background.withValues(alpha: 0.55),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w400,
          fontSize: 12,
          color: c.text.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
