import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/config/app_hosts.dart';
import '../../../core/config/directory_launch.dart';
import '../../../core/models/listing.dart';

/// بطاقة مشاركة — عرض ثابت، والارتفاع يتسع للمحتوى (حد أدنى 4:5) حتى لا تُقصّ.
class ListingSharePoster extends StatelessWidget {
  const ListingSharePoster({
    super.key,
    required this.listing,
    this.width = 360,
  });

  final Listing listing;
  final double width;

  /// نسبة إنستغرام كحد أدنى للارتفاع فقط.
  static const aspectRatio = 4 / 5;

  /// أيقونة التطبيق الظاهرة بجانب الاسم في رأس البطاقة.
  static const appIconAsset = 'assets/branding/app-icon-source-1024.png';

  static const _bg = Color(0xFFF4F8F7);
  static const _surface = Color(0xFFFFFFFF);
  static const _ink = Color(0xFF102221);
  static const _primary = Color(0xFF053F3E);
  static const _accent = Color(0xFFC5A059);
  static const _muted = Color(0xFF4A6361);
  static const _line = Color(0xFFD5E2E0);

  double get minHeight => width / aspectRatio;

  @override
  Widget build(BuildContext context) {
    final phone = listing.contactPhone?.trim();
    final telegram = listing.contactTelegram?.trim();
    final vehicle = listing.vehicleType?.trim();
    final seats = listing.seatsCount;
    final dep = listing.departureTime?.trim();
    final ret = listing.returnTime?.trim();
    final scale = width / 360;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: width,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8 * scale),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandHeader(scale: scale),
                  Container(height: 2.5 * scale, color: _accent),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20 * scale,
                      16 * scale,
                      20 * scale,
                      16 * scale,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          listing.isDriver ? 'يتوفر خط' : 'مطلوب خط',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        Text(
                          'من ${listing.area}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 24 * scale,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),
                        _FadeRule(scale: scale, emphasis: true),
                        Text(
                          'إلى ${listing.destination}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 24 * scale,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),
                        if (listing.hasRouteSubs) ...[
                          SizedBox(height: 12 * scale),
                          _SoftBox(
                            scale: scale,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (listing.originSubs.isNotEmpty)
                                  Text(
                                    'من ${listing.originSubsLabel}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 13 * scale,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                      color: _muted,
                                    ),
                                  ),
                                if (listing.originSubs.isNotEmpty &&
                                    listing.destinationSubs.isNotEmpty)
                                  _FadeRule(scale: scale, emphasis: false),
                                if (listing.destinationSubs.isNotEmpty)
                                  Text(
                                    'إلى ${listing.destinationSubsLabel}',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 13 * scale,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                      color: _muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 14 * scale),
                        Wrap(
                          spacing: 7 * scale,
                          runSpacing: 7 * scale,
                          alignment: WrapAlignment.center,
                          children: [
                            _Chip(listing.timePeriodLabel, scale: scale),
                            if (listing.publicGenderLabel != null)
                              _Chip(listing.publicGenderLabel!, scale: scale),
                            if (dep != null && dep.isNotEmpty)
                              _Chip('انطلاق $dep', scale: scale),
                            if (ret != null && ret.isNotEmpty)
                              _Chip('عودة $ret', scale: scale),
                            if (listing.isDriver &&
                                vehicle != null &&
                                vehicle.isNotEmpty)
                              _Chip('نوع السيارة: $vehicle', scale: scale),
                            if (seats != null && seats > 0)
                              _Chip('$seats مقاعد', scale: scale),
                          ],
                        ),
                        SizedBox(height: 14 * scale),
                        _SoftBox(
                          scale: scale,
                          child: listing.isDriver ||
                                  DirectoryLaunch.freeRiderContacts
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      listing.isDriver
                                          ? 'للتواصل مع السائق'
                                          : 'للتواصل مع الراكب',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 12 * scale,
                                        fontWeight: FontWeight.w700,
                                        color: _primary,
                                      ),
                                    ),
                                    SizedBox(height: 8 * scale),
                                    if (phone != null && phone.isNotEmpty)
                                      _ContactRow(
                                        label: 'واتساب',
                                        value: phone,
                                        scale: scale,
                                      ),
                                    if (telegram != null &&
                                        telegram.isNotEmpty) ...[
                                      if (phone != null && phone.isNotEmpty)
                                        SizedBox(height: 6 * scale),
                                      _ContactRow(
                                        label: 'تلغرام',
                                        value: telegram.startsWith('@')
                                            ? telegram
                                            : '@$telegram',
                                        scale: scale,
                                      ),
                                    ],
                                    if ((phone == null || phone.isEmpty) &&
                                        (telegram == null || telegram.isEmpty))
                                      Text(
                                        'لا توجد وسيلة تواصل',
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 13 * scale,
                                          color: _muted,
                                        ),
                                      ),
                                  ],
                                )
                              : Text(
                                  'احجز الطلب من دليل خطوط بغداد للتواصل مع الراكب',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 13 * scale,
                                    height: 1.45,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                  ),
                                ),
                        ),
                        SizedBox(height: 14 * scale),
                        Text(
                          AppHosts.publicUrl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          'ابحث عن خطوط بغداد وأضف خطك',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 11 * scale,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// خط رفيع يتلاشى عند الطرفين — للفصل بين «من» و«إلى».
class _FadeRule extends StatelessWidget {
  const _FadeRule({required this.scale, required this.emphasis});

  final double scale;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final h = (emphasis ? 1.15 : 0.9) * scale;
    final mid = ListingSharePoster._accent.withValues(
      alpha: emphasis ? 0.55 : 0.35,
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: (emphasis ? 8 : 6) * scale,
        horizontal: (emphasis ? 56 : 28) * scale,
      ),
      child: SizedBox(
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                mid,
                mid,
                Colors.transparent,
              ],
              stops: const [0.0, 0.28, 0.72, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.scale});

  final double scale;

  static const iconAsset = ListingSharePoster.appIconAsset;

  @override
  Widget build(BuildContext context) {
    final markSize = 42 * scale;
    return Container(
      color: ListingSharePoster._primary,
      padding: EdgeInsets.fromLTRB(16 * scale, 12 * scale, 16 * scale, 12 * scale),
      child: Row(
        children: [
          Container(
            width: markSize,
            height: markSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10 * scale),
              border: Border.all(
                color: ListingSharePoster._accent.withValues(alpha: 0.85),
                width: 1.2 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6 * scale,
                  offset: Offset(0, 2 * scale),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              iconAsset,
              width: markSize,
              height: markSize,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/branding/brand-mark.png',
                width: markSize,
                height: markSize,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: ListingSharePoster._surface,
                  child: Icon(
                    Icons.directions_bus_filled_rounded,
                    color: ListingSharePoster._primary,
                    size: markSize * 0.62,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Text(
              'دليل خطوط بغداد',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 17 * scale,
                fontWeight: FontWeight.w800,
                color: ListingSharePoster._surface,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBox extends StatelessWidget {
  const _SoftBox({required this.child, required this.scale});

  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ListingSharePoster._surface,
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(color: ListingSharePoster._line),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12 * scale,
          10 * scale,
          12 * scale,
          10 * scale,
        ),
        child: child,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: ListingSharePoster._primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ListingSharePoster._primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 11.5 * scale,
          fontWeight: FontWeight.w700,
          color: ListingSharePoster._primary,
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.label,
    required this.value,
    required this.scale,
  });

  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 15 * scale,
          height: 1.35,
          color: ListingSharePoster._ink,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: ListingSharePoster._primary,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
