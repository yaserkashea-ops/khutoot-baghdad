import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/listing.dart';
import '../../../core/models/listing_subscription.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/phone_digits.dart';
import '../../../data/listings_repository.dart';
import '../widgets/admin_double_confirm.dart';

enum _SubFilter { expired, endingSoon, active, hidden }

/// Admin tab: 30-day listing subscriptions — timings, expiry, renew/hide/delete.
class AdminSubscriptionsPage extends StatefulWidget {
  const AdminSubscriptionsPage({super.key});

  @override
  State<AdminSubscriptionsPage> createState() => _AdminSubscriptionsPageState();
}

class _AdminSubscriptionsPageState extends State<AdminSubscriptionsPage> {
  _SubFilter _filter = _SubFilter.expired;
  List<Listing> _items = const [];
  bool _loading = true;
  String? _busyId;

  String _fmt(DateTime d) {
    final l = d.toLocal();
    return '${l.year.toString().padLeft(4, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/'
        '${l.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await ListingsRepository.shared.fetchSubscriptionListings();
    if (!mounted) return;
    setState(() {
      _items = all;
      _loading = false;
    });
  }

  List<Listing> get _filtered {
    return _items.where((l) {
      return switch (_filter) {
        _SubFilter.expired => l.isExpired && !l.isHidden,
        _SubFilter.endingSoon =>
          !l.isExpired &&
              !l.isHidden &&
              l.wholeDaysLeft <= 7 &&
              l.isPublished,
        _SubFilter.active => l.isLiveInDirectory && l.wholeDaysLeft > 7,
        _SubFilter.hidden => l.isHidden,
      };
    }).toList();
  }

  String _expiryWhatsAppMessage(Listing listing) {
    final ref = listing.referenceCode ?? listing.id;
    final end = _fmt(listing.effectiveExpiresAt);
    return 'مرحباً، نود إبلاغك بأن اشتراك خطك في دليل خطوط بغداد '
        'قد انتهى أو أوشك على الانتهاء.\n'
        'المسار: ${listing.area} ← ${listing.destination}\n'
        'رقم الطلب: $ref\n'
        'تاريخ انتهاء الظهور: $end\n'
        'مدة الاشتراك: ${ListingSubscription.periodDays} يوماً.\n'
        'لتجديد الظهور لمدة ${ListingSubscription.periodDays} يوماً '
        'يُرجى إتمام رسوم التجديد والتواصل معنا.';
  }

  Future<void> _openExpiryWhatsApp(Listing listing) async {
    final phone = listing.contactPhone?.trim();
    final message = _expiryWhatsAppMessage(listing);
    await Clipboard.setData(ClipboardData(text: message));
    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'نُسخ نص الرسالة — لا يوجد رقم واتساب لهذا الخط',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
      return;
    }
    final digits = PhoneDigits.normalize(phone);
    final uri = Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _renew(Listing listing) async {
    final ok = await AdminDoubleConfirm.show(
      context,
      title: 'تجديد الاشتراك؟',
      detail:
          '${listing.area} ← ${listing.destination}\nسيُمدَّد الظهور ${ListingSubscription.periodDays} يوماً بعد تأكيد الدفع.',
      confirmLabel: 'تجديد 30 يوماً',
    );
    if (!ok || !mounted) return;

    setState(() => _busyId = listing.id);
    try {
      await ListingsRepository.shared.renewListing(listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم التجديد لمدة ${ListingSubscription.periodDays} يوماً',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تعذر التجديد',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _hide(Listing listing) async {
    final ok = await AdminDoubleConfirm.show(
      context,
      title: 'إخفاء الخط من الدليل؟',
      detail: '${listing.area} ← ${listing.destination}\nسيختفي عن العامة ويمكن إظهاره لاحقاً بالتجديد.',
      confirmLabel: 'إخفاء',
      destructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _busyId = listing.id);
    try {
      await ListingsRepository.shared.hideListing(listing.id);
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تعذر الإخفاء',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(Listing listing) async {
    final ok = await AdminDoubleConfirm.show(
      context,
      title: 'حذف الخط نهائياً؟',
      detail:
          '${listing.area} ← ${listing.destination}\nرقم الطلب: ${listing.referenceCode ?? listing.id}',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _busyId = listing.id);
    try {
      await ListingsRepository.shared.deleteById(listing.id);
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تعذر الحذف',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtered = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Text(
            'صلاحية كل خط ${ListingSubscription.periodDays} يوماً من تاريخ النشر أو التجديد',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12.5,
              color: c.text.withValues(alpha: 0.6),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              _Chip(
                label: 'منتهية',
                selected: _filter == _SubFilter.expired,
                onTap: () => setState(() => _filter = _SubFilter.expired),
              ),
              _Chip(
                label: 'تنتهي خلال 7 أيام',
                selected: _filter == _SubFilter.endingSoon,
                onTap: () => setState(() => _filter = _SubFilter.endingSoon),
              ),
              _Chip(
                label: 'سارية',
                selected: _filter == _SubFilter.active,
                onTap: () => setState(() => _filter = _SubFilter.active),
              ),
              _Chip(
                label: 'مخفية',
                selected: _filter == _SubFilter.hidden,
                onTap: () => setState(() => _filter = _SubFilter.hidden),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary))
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        'لا خطوط في هذه القائمة',
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: c.text.withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: c.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final listing = filtered[i];
                          final busy = _busyId == listing.id;
                          final start = _fmt(listing.subscriptionStart);
                          final end = _fmt(listing.effectiveExpiresAt);
                          final days = listing.isExpired
                              ? 'منتهٍ'
                              : 'متبقي ${listing.wholeDaysLeft} يوم';

                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: listing.isExpired || listing.isHidden
                                    ? c.riderAccent.withValues(alpha: 0.45)
                                    : c.border,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${listing.area} ← ${listing.destination}',
                                          style: GoogleFonts.ibmPlexSansArabic(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (busy)
                                        const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'الحالة: ${listing.statusLabel} · $days',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 12.5,
                                      color: c.text.withValues(alpha: 0.72),
                                    ),
                                  ),
                                  Text(
                                    'من $start → إلى $end',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      fontSize: 12.5,
                                      color: c.text.withValues(alpha: 0.72),
                                    ),
                                  ),
                                  if ((listing.referenceCode ?? '')
                                      .trim()
                                      .isNotEmpty)
                                    Text(
                                      'رقم الطلب: ${listing.referenceCode}',
                                      style: GoogleFonts.ibmPlexSansArabic(
                                        fontSize: 12,
                                        color: c.text.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: busy
                                            ? null
                                            : () => _openExpiryWhatsApp(listing),
                                        icon: const Icon(
                                          Icons.chat_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('واتساب انتهاء'),
                                      ),
                                      FilledButton(
                                        onPressed:
                                            busy ? null : () => _renew(listing),
                                        child: const Text('تجديد 30 يوماً'),
                                      ),
                                      OutlinedButton(
                                        onPressed: busy || listing.isHidden
                                            ? null
                                            : () => _hide(listing),
                                        child: const Text('إخفاء'),
                                      ),
                                      OutlinedButton(
                                        onPressed:
                                            busy ? null : () => _delete(listing),
                                        child: Text(
                                          'حذف',
                                          style: TextStyle(color: c.riderAccent),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(fontSize: 12.5),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: c.primary.withValues(alpha: 0.16),
        checkmarkColor: c.primary,
      ),
    );
  }
}
