import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/baghdad_places.dart';
import '../../../core/listings/unified_post_kind.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/listing_contact.dart';
import '../../../core/utils/phone_digits.dart';
import '../../../data/listings_repository.dart';
import '../listings/widgets/listing_card.dart';
import 'place_suggest_field.dart';

Future<Listing?> showUnifiedComposeSheet(
  BuildContext context, {
  bool asAdminDirect = false,
}) {
  return showModalBottomSheet<Listing>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => UnifiedComposeSheet(asAdminDirect: asAdminDirect),
  );
}

const guestSubmitReceivedTitle = 'تم إرسال المنشور';
const guestSubmitReceivedBody =
    'تم إرسال منشورك للمراجعة والموافقة، وسيظهر في الدليل بعد اعتماده.';

Future<void> showGuestSubmitReceivedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final c = ctx.colors;
      return AlertDialog(
        title: Text(
          guestSubmitReceivedTitle,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          guestSubmitReceivedBody,
          style: GoogleFonts.ibmPlexSansArabic(
            height: 1.5,
            color: c.text.withValues(alpha: 0.86),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'حسناً',
              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    },
  );
}

class UnifiedComposeSheet extends StatefulWidget {
  const UnifiedComposeSheet({super.key, this.asAdminDirect = false});

  /// Admin panel: publish live instead of sending for review.
  final bool asAdminDirect;

  @override
  State<UnifiedComposeSheet> createState() => _UnifiedComposeSheetState();
}

class _UnifiedComposeSheetState extends State<UnifiedComposeSheet> {
  static const _maxBody = 300;

  ListingType? _type;
  TimePeriod? _time;
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _body = TextEditingController();
  final _phone = TextEditingController();
  final _telegram = TextEditingController();
  bool _preview = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _origin.dispose();
    _destination.dispose();
    _body.dispose();
    _phone.dispose();
    _telegram.dispose();
    super.dispose();
  }

  List<String> get _places => BaghdadPlaces.prioritize({
        ...BaghdadPlaces.areas,
        ...BaghdadPlaces.destinations,
      });

  bool _looksUnsafe(String raw) {
    final v = raw.trim().toLowerCase();
    return v.contains('<') ||
        v.contains('javascript:') ||
        v.contains('onerror=') ||
        v.contains('onclick=');
  }

  String? _validate({required bool forPublish}) {
    if (_type == null) return 'اختر نوع الإعلان';
    if (_time == null) return 'اختر التوقيت صباحي أو مسائي';
    final origin = _origin.text.trim();
    final dest = _destination.text.trim();
    if (origin.isEmpty) return 'اختر منطقة الانطلاق';
    if (dest.isEmpty) return 'اختر منطقة الوصول';
    if (!BaghdadPlaces.areas.contains(origin) &&
        !BaghdadPlaces.destinations.contains(origin) &&
        !_places.contains(origin)) {
      return 'اختر منطقة الانطلاق من القائمة';
    }
    if (!BaghdadPlaces.areas.contains(dest) &&
        !BaghdadPlaces.destinations.contains(dest) &&
        !_places.contains(dest)) {
      return 'اختر منطقة الوصول من القائمة';
    }
    if (_body.text.characters.length > _maxBody) {
      return 'النص بحد أقصى $_maxBody حرفاً';
    }
    if (_looksUnsafe(_phone.text) || _looksUnsafe(_telegram.text)) {
      return 'بيانات التواصل غير صالحة';
    }
    final phone = _phone.text.trim();
    final tg = _telegram.text.trim();
    if (phone.isEmpty && tg.isEmpty) {
      return 'أضف وسيلة تواصل واحدة على الأقل';
    }
    if (phone.isNotEmpty && PhoneDigits.normalize(phone).length < 10) {
      return 'رقم الهاتف غير صحيح';
    }
    if (tg.isNotEmpty && ListingContact.telegramUrl(tg) == null) {
      return 'يوزر تلغرام غير صحيح';
    }
    if (forPublish && _busy) return 'جاري النشر';
    return null;
  }

  Listing _draft() {
    final phone = _phone.text.trim();
    final tg = _telegram.text.trim();
    final body = _body.text.trim();
    return Listing(
      id: '',
      type: _type ?? ListingType.driver,
      area: _origin.text.trim(),
      destination: _destination.text.trim(),
      timePeriod: _time ?? TimePeriod.morning,
      genderRequirement: GenderRequirement.mixed,
      vehicleType: body.isEmpty ? null : body,
      contactPhone: phone.isEmpty ? null : PhoneDigits.normalize(phone),
      contactTelegram: tg.isEmpty ? null : tg.replaceFirst('@', ''),
      status: ListingStatus.published,
      governorate: 'بغداد',
      createdAt: DateTime.now(),
      bumpedAt: DateTime.now(),
    );
  }

  Future<void> _publish() async {
    final err = _validate(forPublish: true);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = _draft();
      final saved = widget.asAdminDirect
          ? await ListingsRepository.shared.insert(draft)
          : await ListingsRepository.shared.publishUnifiedGuest(draft);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'تعذر النشر حالياً. حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = MediaQuery.sizeOf(context).height * 0.92;
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    _preview
                        ? 'معاينة المنشور'
                        : (widget.asAdminDirect
                            ? 'نشر في الدليل'
                            : 'اكتب إعلاناً'),
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _error!,
                  style: GoogleFonts.ibmPlexSansArabic(
                    color: c.riderAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Expanded(
              child: _preview ? _previewPane() : _formPane(c),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    if (_preview)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _preview = false),
                          child: const Text('تعديل'),
                        ),
                      ),
                    if (_preview) const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy
                            ? null
                            : () {
                                if (!_preview) {
                                  final err = _validate(forPublish: false);
                                  if (err != null) {
                                    setState(() => _error = err);
                                    return;
                                  }
                                  setState(() {
                                    _error = null;
                                    _preview = true;
                                  });
                                  return;
                                }
                                _publish();
                              },
                        child: Text(
                          _busy
                              ? 'جاري النشر'
                              : (_preview ? 'نشر' : 'معاينة ونشر'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewPane() {
    final c = context.colors;
    final wanted = _type == ListingType.rider;
    final hint = wanted
        ? 'احرص على كتابة تفاصيل كاملة مثل عدد المقاعد المطلوبة وأي ملاحظة مهمة.'
        : 'احرص على كتابة تفاصيل كاملة مثل عدد المقاعد ونوع السيارة.';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.primary.withValues(alpha: 0.14)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.45,
                    color: c.text.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListingCard(
          listing: _draft(),
          unifiedPublicCard: true,
          showContactAction: true,
        ),
      ],
    );
  }

  Widget _formPane(MasaratColors c) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Text(
          'نوع الإعلان',
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _KindPick(
                label: UnifiedPostKind.available,
                icon: UnifiedPostKind.iconFor(ListingType.driver),
                selected: _type == ListingType.driver,
                color: c.primary,
                onTap: () => setState(() => _type = ListingType.driver),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KindPick(
                label: UnifiedPostKind.wanted,
                icon: UnifiedPostKind.iconFor(ListingType.rider),
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
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _KindPick(
                label: 'صباحي',
                icon: Icons.wb_sunny_outlined,
                selected: _time == TimePeriod.morning,
                color: c.accent,
                onTap: () => setState(() => _time = TimePeriod.morning),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KindPick(
                label: 'مسائي',
                icon: Icons.nights_stay_outlined,
                selected: _time == TimePeriod.evening,
                color: c.primary,
                onTap: () => setState(() => _time = TimePeriod.evening),
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
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _body,
          maxLines: 6,
          maxLength: _maxBody,
          textAlign: TextAlign.right,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.ibmPlexSansArabic(),
          decoration: InputDecoration(
            hintText: 'اكتب إعلانك هنا',
            hintStyle: GoogleFonts.ibmPlexSansArabic(
              color: c.text.withValues(alpha: 0.28),
              fontWeight: FontWeight.w400,
            ),
            alignLabelWithHint: true,
            counterText: '${_body.text.characters.length}/$_maxBody',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'التواصل',
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'أضف وسيلة تواصل واحدة على الأقل',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 12.5,
            color: c.text.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('compose_phone'),
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'هاتف'),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('compose_telegram'),
          controller: _telegram,
          decoration: const InputDecoration(labelText: 'تلغرام'),
        ),
      ],
    );
  }
}

class _KindPick extends StatelessWidget {
  const _KindPick({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : context.colors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? color : context.colors.text),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w600,
                  color: selected ? color : context.colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
