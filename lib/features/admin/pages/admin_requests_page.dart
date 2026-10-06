import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_hosts.dart';
import '../../../core/listings/unified_post_kind.dart';
import '../../../core/models/listing.dart';
import '../../../core/notifications/publisher_push_registrar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/listing_contact.dart';
import '../../../core/utils/phone_digits.dart';
import '../../../data/listings_repository.dart';
import '../../listings/widgets/listing_card.dart';
import '../widgets/admin_double_confirm.dart';
import '../widgets/admin_publish_flow.dart';
import 'admin_listing_review_page.dart';

/// WhatsApp body sent when admin rejects a listing.
String listingRejectionNotice({
  required String reference,
  required String origin,
  required String destination,
  required String reason,
}) {
  return 'مرحباً، بخصوص منشورك في دليل خطوط بغداد.\n'
      'رقم الطلب: $reference\n'
      'المسار: $origin ← $destination\n\n'
      'لم يُنشر حالياً لهذا السبب:\n$reason\n\n'
      'يرجى تعديل المنشور وفق الملاحظات وإعادة الإرسال.\n'
      'شكراً لك.\n\n'
      '${AppHosts.publicUrl}';
}

/// Admin queue: review a full card then publish, edit, or reject.
class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  /// Dashboard shortcuts: false = متوفر خط, true = مطلوب خط.
  static final ValueNotifier<bool> preferRidersTab = ValueNotifier(false);

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  ListingStatus? _filter = ListingStatus.pendingReview;
  /// null = الكل, false = متوفر خط, true = مطلوب خط
  bool? _wantedOnly;
  final _search = TextEditingController();
  List<Listing> _items = const [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _wantedOnly = AdminRequestsPage.preferRidersTab.value ? true : null;
    AdminRequestsPage.preferRidersTab.addListener(_onPreferRiders);
    _load();
  }

  void _onPreferRiders() {
    final riders = AdminRequestsPage.preferRidersTab.value;
    if (!mounted) return;
    setState(() {
      _wantedOnly = riders ? true : false;
      if (_wantedOnly == true && _filter == ListingStatus.awaitingPayment) {
        _filter = ListingStatus.pendingReview;
      }
    });
  }

  @override
  void dispose() {
    AdminRequestsPage.preferRidersTab.removeListener(_onPreferRiders);
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Load every status so رقم الطلب can find published / rejected / pending.
    final all = await ListingsRepository.shared.fetchAdminQueue();
    if (!mounted) return;
    setState(() {
      _items = all;
      _loading = false;
    });
  }

  String get _query => _search.text.trim();

  bool get _hasQuery => _query.isNotEmpty;

  List<Listing> get _visible {
    final q = _query;
    final qNorm = _normalizeRef(q);
    return _items.where((l) {
      if (_wantedOnly == false && !l.isDriver) return false;
      if (_wantedOnly == true && l.isDriver) return false;
      if (_hasQuery) {
        return _matchesSearch(l, q, qNorm);
      }
      if (_filter == null) {
        return l.status != ListingStatus.published;
      }
      return l.status == _filter;
    }).toList();
  }

  static String _normalizeRef(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool _matchesSearch(Listing l, String q, String qNorm) {
    final ref = _normalizeRef(l.referenceCode ?? '');
    final id = l.id.toUpperCase();
    if (ref.isNotEmpty && ref.contains(qNorm)) {
      return true;
    }
    // Allow typing without KH- prefix.
    final bare = ref.startsWith('KH-') ? ref.substring(3) : ref;
    final qBare = qNorm.startsWith('KH-') ? qNorm.substring(3) : qNorm;
    if (bare.isNotEmpty && qBare.isNotEmpty && bare.contains(qBare)) {
      return true;
    }
    if (id.contains(qNorm)) return true;

    final blob = [
      l.area,
      l.destination,
      l.contactPhone ?? '',
      l.contactTelegram ?? '',
      l.statusLabel,
      ...l.originSubs,
      ...l.destinationSubs,
    ].join(' ').toLowerCase();
    return blob.contains(q.toLowerCase());
  }

  Future<void> _openReview(Listing listing) async {
    final edited = await openAdminListingReview(context, listing);
    if (!mounted) return;
    if (edited != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم حفظ تعديل الطلب',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    }
    await _load();
  }

  Future<void> _delete(Listing listing) async {
    final ok = await AdminDoubleConfirm.showDouble(
      context,
      title: 'حذف المنشور؟',
      detail:
          '${listing.area} ← ${listing.destination}\nسيُحذف نهائياً ولن يظهر في الدليل.',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busyId = listing.id);
    try {
      await ListingsRepository.shared.deleteById(listing.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم حذف المنشور',
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
            'تعذر الحذف',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _setStatus(
    Listing listing,
    ListingStatus status, {
    String? note,
    required String confirmTitle,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final ok = await AdminDoubleConfirm.show(
      context,
      title: confirmTitle,
      detail:
          '${listing.area} ← ${listing.destination}\nرقم الطلب: ${listing.referenceCode ?? listing.id}',
      confirmLabel: confirmLabel,
      destructive: destructive,
    );
    if (!ok || !mounted) return;

    setState(() => _busyId = listing.id);
    try {
      await ListingsRepository.shared.setStatus(
        id: listing.id,
        status: status,
        adminNote: note,
      );
      if (status == ListingStatus.published) {
        // Fire-and-forget Web Push to driver's phone notification tray.
        // ignore: unawaited_futures
        ListingPublishPush.notifyPublished(listing.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            status == ListingStatus.published
                ? 'نُشر في الدليل'
                : switch (status) {
                    ListingStatus.pendingReview => 'أُعيد للمراجعة',
                    ListingStatus.awaitingPayment => 'بانتظار الدفع',
                    ListingStatus.rejected => 'مرفوض',
                    ListingStatus.published => 'منشور',
                  },
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
            'تعذر تحديث الحالة',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(Listing listing) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            'رفض المنشور؟',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${listing.area} ← ${listing.destination}',
                style: GoogleFonts.ibmPlexSansArabic(height: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'سبب الرفض — يُرسل لصاحب المنشور عبر واتساب',
                  hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                ),
                style: GoogleFonts.ibmPlexSansArabic(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: c.error,
                foregroundColor: c.onError,
              ),
              child: const Text('رفض وإبلاغ'),
            ),
          ],
        );
      },
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (ok != true || !mounted) return;
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'اكتب سبب الرفض قبل الإرسال',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
      return;
    }

    setState(() => _busyId = listing.id);
    try {
      await ListingsRepository.shared.setStatus(
        id: listing.id,
        status: ListingStatus.rejected,
        adminNote: note,
      );
      if (!mounted) return;
      await _openRejectionWhatsApp(listing, note);
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تعذر تحديث الحالة',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openRejectionWhatsApp(Listing listing, String reason) async {
    final message = listingRejectionNotice(
      reference: listing.referenceCode ?? listing.id,
      origin: listing.area,
      destination: listing.destination,
      reason: reason,
    );
    final url = ListingContact.whatsappUrl(
      listing.contactPhone,
      message: message,
    );
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'رُفض المنشور — لا يوجد واتساب لإبلاغ صاحب المنشور',
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
      ),
    );
  }

  String _completionMessageDraft(Listing listing) {
    final ref = listing.referenceCode ?? listing.id;
    if (!listing.isDriver) {
      return 'مرحباً، بخصوص طلبك للبحث عن خط في دليل خطوط بغداد.\n'
          'رقم الطلب: $ref\n'
          'المسار: ${listing.area} ← ${listing.destination}\n\n'
          'لاحظنا أن بعض المعلومات ناقصة أو تحتاج تصحيحاً.\n'
          'يرجى تزويدنا بالتفاصيل الصحيحة حتى نتمكن من إكمال مراجعة طلبك.\n'
          'شكراً لتعاونك.';
    }
    return 'مرحباً، بخصوص طلب نشر خطك في دليل خطوط بغداد.\n'
        'رقم الطلب: $ref\n'
        'المسار: ${listing.area} ← ${listing.destination}\n\n'
        'لاحظنا أن بعض المعلومات ناقصة أو تحتاج تصحيحاً.\n'
        'يرجى تزويدنا بالتفاصيل الصحيحة (المنطقة/الوجهة/التوقيت/وسيلة التواصل) '
        'حتى نتمكن من إكمال مراجعة طلبك.\n'
        'شكراً لتعاونك.';
  }

  String _paymentMessageDraft(Listing listing) {
    final ref = listing.referenceCode ?? listing.id;
    return 'مرحباً، بخصوص طلب نشر خطك في دليل خطوط بغداد.\n'
        'رقم الطلب: $ref\n'
        'المسار: ${listing.area} ← ${listing.destination}\n'
        'تمت مراجعة طلبك والموافقة عليه.\n'
        'لإكمال الدفع ونشر الخط في الدليل + النشر في مجموعة تلغرام، '
        'يرجى إتمام رسوم النشر عبر هذه المحادثة والبالغة (5000 د.ع)\n'
        'عبر كي كارد: 7118965883\n'
        'او رصيد اسيا: 07760000989\n'
        'ثم إعلامنا بتأكيد الدفع\n'
        'شكراً لك.';
  }

  Future<void> _messageToComplete(Listing listing) {
    return _messageDriver(
      listing,
      title: 'مراسلة السائق لإكمال البيانات',
      draft: _completionMessageDraft(listing),
    );
  }

  Future<void> _messageForPayment(Listing listing) {
    return _messageDriver(
      listing,
      title: 'مراسلة لإكمال الدفع',
      draft: _paymentMessageDraft(listing),
    );
  }

  Future<void> _messageDriver(
    Listing listing, {
    required String title,
    required String draft,
  }) async {
    final phone = listing.contactPhone?.trim();
    final telegram = listing.contactTelegram?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final hasTg = telegram != null && telegram.isNotEmpty;
    if (!hasPhone && !hasTg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'لا توجد وسيلة تواصل على هذا الطلب — عدّل الطلب أولاً أو أضف رقماً',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
      return;
    }

    final msgCtrl = TextEditingController(text: draft);
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: msgCtrl,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: 'نص الرسالة',
                hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                border: const OutlineInputBorder(),
              ),
              style: GoogleFonts.ibmPlexSansArabic(height: 1.45, fontSize: 13.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: msgCtrl.text));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'نُسخ النص',
                        style: GoogleFonts.ibmPlexSansArabic(),
                      ),
                    ),
                  );
                }
              },
              child: const Text('نسخ'),
            ),
            if (hasTg)
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 'telegram'),
                child: const Text('تلغرام'),
              ),
            if (hasPhone)
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'whatsapp'),
                child: const Text('واتساب'),
              ),
          ],
        );
      },
    );
    final message = msgCtrl.text.trim();
    msgCtrl.dispose();
    if (choice == null || message.isEmpty || !mounted) return;

    await Clipboard.setData(ClipboardData(text: message));
    if (choice == 'whatsapp' && hasPhone) {
      final digits = PhoneDigits.forWhatsApp(phone);
      if (digits == null) return;
      final uri = Uri.parse(
        'https://wa.me/$digits?text=${Uri.encodeComponent(message)}',
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (choice == 'telegram' && hasTg) {
      var user = telegram;
      if (user.startsWith('https://')) {
        await launchUrl(Uri.parse(user), mode: LaunchMode.externalApplication);
      } else {
        user = user.replaceFirst('@', '');
        await launchUrl(
          Uri.parse('https://t.me/$user'),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  Future<void> _openContact(Listing listing) async {
    final phone = listing.contactPhone?.trim();
    if (phone == null || phone.isEmpty) return;
    final digits = PhoneDigits.forWhatsApp(phone);
    if (digits == null) return;
    final uri = Uri.parse('https://wa.me/$digits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visible = _visible;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await openAdminPublishFlow(context);
          if (!mounted || saved == null) return;
          setState(() {
            _wantedOnly = saved.isDriver ? false : true;
            AdminRequestsPage.preferRidersTab.value = _wantedOnly == true;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                'تم نشر الإعلان في الدليل',
                style: GoogleFonts.ibmPlexSansArabic(),
              ),
            ),
          );
          await _load();
        },
        icon: const Icon(Icons.publish_outlined),
        label: Text(
          'نشر',
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TypeTab(
                    label: 'الكل',
                    selected: _wantedOnly == null,
                    onTap: () => setState(() => _wantedOnly = null),
                  ),
                ),
                Expanded(
                  child: _TypeTab(
                    label: UnifiedPostKind.available,
                    selected: _wantedOnly == false,
                    onTap: () => setState(() => _wantedOnly = false),
                  ),
                ),
                Expanded(
                  child: _TypeTab(
                    label: UnifiedPostKind.wanted,
                    selected: _wantedOnly == true,
                    color: UnifiedPostKind.colorFor(ListingType.rider, c),
                    onTap: () => setState(() => _wantedOnly = true),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            style: GoogleFonts.ibmPlexSansArabic(),
            decoration: InputDecoration(
              hintText: 'بحث برقم الطلب (مثل KH-A1B2C3) أو المنطقة أو التواصل',
              hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 12.5),
              prefixIcon: const Icon(Icons.tag_rounded),
              suffixIcon: _hasQuery
                  ? IconButton(
                      tooltip: 'مسح',
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: c.surface,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.border),
              ),
            ),
          ),
        ),
        if (_hasQuery)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                visible.isEmpty
                    ? 'لا نتائج لرقم/نص البحث'
                    : 'نتائج البحث: ${visible.length}',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12.5,
                  color: c.text.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'بانتظار المراجعة',
                  selected: _filter == ListingStatus.pendingReview,
                  onTap: () {
                    setState(() => _filter = ListingStatus.pendingReview);
                  },
                ),
                _FilterChip(
                  label: 'بانتظار الدفع',
                  selected: _filter == ListingStatus.awaitingPayment,
                  onTap: () {
                    setState(() => _filter = ListingStatus.awaitingPayment);
                  },
                ),
                _FilterChip(
                  label: 'مرفوض',
                  selected: _filter == ListingStatus.rejected,
                  onTap: () {
                    setState(() => _filter = ListingStatus.rejected);
                  },
                ),
                _FilterChip(
                  label: 'الكل (غير منشور)',
                  selected: _filter == null,
                  onTap: () {
                    setState(() => _filter = null);
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary))
              : visible.isEmpty
                  ? Center(
                      child: Text(
                        _hasQuery
                            ? 'لا طلب بهذا الرقم أو النص'
                            : 'لا طلبات في هذه القائمة',
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
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final listing = visible[i];
                          final busy = _busyId == listing.id;
                          return _RequestCard(
                            listing: listing,
                            busy: busy,
                            onEdit: () => _openReview(listing),
                            onPublish: () => _setStatus(
                              listing,
                              ListingStatus.published,
                              confirmTitle: 'نشر المنشور في الدليل؟',
                              confirmLabel: 'نشر',
                            ),
                            onReject: () => _reject(listing),
                            onDelete: () => _delete(listing),
                            onReopen: () => _setStatus(
                              listing,
                              ListingStatus.pendingReview,
                              confirmTitle: 'إعادة المنشور للمراجعة؟',
                              confirmLabel: 'إعادة للمراجعة',
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = color ?? c.primary;
    return Material(
      color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
              color: selected ? accent : c.text.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.listing,
    required this.busy,
    required this.onEdit,
    required this.onPublish,
    required this.onReject,
    required this.onDelete,
    required this.onReopen,
  });

  final Listing listing;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onReject;
  final VoidCallback onDelete;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ref = listing.referenceCode ?? listing.id;
    final canDecide = listing.status == ListingStatus.pendingReview ||
        listing.status == ListingStatus.awaitingPayment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListingCard(
          listing: listing,
          unifiedPublicCard: true,
          showContactAction: true,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'رقم الطلب: $ref · ${listing.statusLabel}',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                color: c.text.withValues(alpha: 0.62),
              ),
            ),
            if (busy) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        if ((listing.adminNote ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'ملاحظة: ${listing.adminNote}',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12.5,
              color: c.riderAccent,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (canDecide) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onPublish,
                  child: const Text('نشر'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onEdit,
                  child: const Text('تعديل'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  child: Text(
                    'رفض',
                    style: TextStyle(color: c.riderAccent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy ? null : onDelete,
            child: Text(
              'حذف',
              style: TextStyle(color: c.riderAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ] else if (listing.status == ListingStatus.rejected)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReopen,
                  child: const Text('إعادة للمراجعة'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDelete,
                  child: Text(
                    'حذف',
                    style: TextStyle(color: c.riderAccent),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onEdit,
                  child: const Text('تعديل'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDelete,
                  child: Text(
                    'حذف',
                    style: TextStyle(color: c.riderAccent),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
