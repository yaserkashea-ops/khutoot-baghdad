import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/baghdad_places.dart';
import '../../../core/listings/unified_post_kind.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/listing_contact.dart';
import '../../../core/utils/phone_digits.dart';
import '../../../data/listings_repository.dart';
import '../../feed/place_suggest_field.dart';
import '../../listings/widgets/listing_card.dart';

/// Admin desk to correct a unified listing: route, time, free text, contact.
Future<Listing?> openAdminListingReview(
  BuildContext context,
  Listing listing,
) {
  return Navigator.of(context).push<Listing>(
    MaterialPageRoute(
      builder: (_) => AdminListingReviewPage(listing: listing),
    ),
  );
}

class AdminListingReviewPage extends StatefulWidget {
  const AdminListingReviewPage({super.key, required this.listing});

  final Listing listing;

  @override
  State<AdminListingReviewPage> createState() => _AdminListingReviewPageState();
}

class _AdminListingReviewPageState extends State<AdminListingReviewPage> {
  late ListingType _type;
  late TimePeriod _period;
  late final TextEditingController _origin;
  late final TextEditingController _destination;
  late final TextEditingController _body;
  late final TextEditingController _phone;
  late final TextEditingController _telegram;
  bool _saving = false;

  Listing get _source => widget.listing;

  List<String> get _places => BaghdadPlaces.prioritize({
        ...BaghdadPlaces.areas,
        ...BaghdadPlaces.destinations,
      });

  @override
  void initState() {
    super.initState();
    final l = _source;
    _type = l.type;
    _period = l.timePeriod;
    _origin = TextEditingController(text: l.area);
    _destination = TextEditingController(text: l.destination);
    _body = TextEditingController(
      text: (l.vehicleType ?? l.routeDetails ?? '').trim(),
    );
    _phone = TextEditingController(text: l.contactPhone ?? '');
    _telegram = TextEditingController(text: l.contactTelegram ?? '');
    for (final c in [_origin, _destination, _body, _phone, _telegram]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_origin, _destination, _body, _phone, _telegram]) {
      c.removeListener(_refresh);
      c.dispose();
    }
    super.dispose();
  }

  Listing _draft() {
    final phone = _phone.text.trim();
    final tg = _telegram.text.trim();
    final body = _body.text.trim();
    return _source.copyWith(
      type: _type,
      area: _origin.text.trim(),
      destination: _destination.text.trim(),
      timePeriod: _period,
      originSubs: const [],
      destinationSubs: const [],
      vehicleType: body,
      contactPhone: phone.isEmpty ? null : PhoneDigits.normalize(phone),
      contactTelegram: tg.isEmpty ? null : tg.replaceFirst('@', ''),
      clearVehicle: body.isEmpty,
      clearPhone: phone.isEmpty,
      clearTelegram: tg.isEmpty,
      clearDeparture: true,
      clearReturn: true,
      clearSeats: true,
    );
  }

  Future<void> _save() async {
    final origin = _origin.text.trim();
    final dest = _destination.text.trim();
    if (origin.isEmpty || dest.isEmpty) {
      _toast('الانطلاق والوصول مطلوبان');
      return;
    }
    final phone = _phone.text.trim();
    final tg = _telegram.text.trim();
    if (phone.isEmpty && tg.isEmpty) {
      _toast('أضف وسيلة تواصل واحدة على الأقل');
      return;
    }
    if (phone.isNotEmpty && PhoneDigits.normalize(phone).length < 10) {
      _toast('رقم الهاتف غير صحيح');
      return;
    }
    if (tg.isNotEmpty && ListingContact.telegramUrl(tg) == null) {
      _toast('يوزر تلغرام غير صحيح');
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await ListingsRepository.shared.update(_draft());
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      _toast('تعذر حفظ التعديل');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: GoogleFonts.ibmPlexSansArabic()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = _source;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          'تعديل المنشور',
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.displayCode,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.statusLabel,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    color: c.text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                ListingCard(
                  listing: _draft(),
                  unifiedPublicCard: true,
                  showContactAction: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'نوع الإعلان',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _KindChip(
                        label: UnifiedPostKind.available,
                        selected: _type == ListingType.driver,
                        color: c.primary,
                        onTap: () => setState(() => _type = ListingType.driver),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KindChip(
                        label: UnifiedPostKind.wanted,
                        selected: _type == ListingType.rider,
                        color: UnifiedPostKind.colorFor(ListingType.rider, c),
                        onTap: () => setState(() => _type = ListingType.rider),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'التوقيت',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _KindChip(
                        label: 'صباحي',
                        selected: _period == TimePeriod.morning,
                        color: c.accent,
                        onTap: () =>
                            setState(() => _period = TimePeriod.morning),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KindChip(
                        label: 'مسائي',
                        selected: _period == TimePeriod.evening,
                        color: c.primary,
                        onTap: () =>
                            setState(() => _period = TimePeriod.evening),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PlaceSuggestField(
                  label: 'نقطة الانطلاق',
                  hint: 'اختر مكان أو مدينة',
                  controller: _origin,
                  options: _places,
                ),
                const SizedBox(height: 10),
                PlaceSuggestField(
                  label: 'نقطة الوصول',
                  hint: 'اختر مكان أو مدينة',
                  controller: _destination,
                  options: _places,
                ),
                const SizedBox(height: 16),
                Text(
                  'نص الإعلان',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _body,
                  maxLines: 5,
                  maxLength: 300,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.ibmPlexSansArabic(),
                  decoration: InputDecoration(
                    hintText: 'اكتب إعلانك هنا',
                    hintStyle: GoogleFonts.ibmPlexSansArabic(
                      color: c.text.withValues(alpha: 0.28),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'هاتف'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _telegram,
                  decoration: const InputDecoration(labelText: 'تلغرام'),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'جاري الحفظ' : 'حفظ التعديلات'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.16) : context.colors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : context.colors.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              color: selected ? color : context.colors.text,
            ),
          ),
        ),
      ),
    );
  }
}
