import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/listing.dart';
import '../../../core/notifications/publisher_push_registrar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/listings_repository.dart';
import '../../listings/publish_listing_page.dart';
import '../widgets/admin_double_confirm.dart';

/// Admin queue: review → await payment → publish / reject.
class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  ListingStatus? _filter = ListingStatus.pendingReview;
  final _search = TextEditingController();
  List<Listing> _items = const [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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

  Future<void> _edit(Listing listing) async {
    final edited = await Navigator.of(context).push<Listing>(
      MaterialPageRoute(
        builder: (_) => PublishListingPage(
          repository: ListingsRepository.shared,
          initial: listing,
          draftOnly: true,
          allowFreeTextPlaces: true,
        ),
      ),
    );
    if (edited == null || !mounted) return;

    setState(() => _busyId = listing.id);
    try {
      await ListingsRepository.shared.update(
        edited.copyWith(
          id: listing.id,
          status: listing.status,
          referenceCode: listing.referenceCode,
          governorate: listing.governorate,
          adminNote: listing.adminNote,
          expiresAt: listing.expiresAt,
          isHidden: listing.isHidden,
          ownerAccountId: listing.ownerAccountId,
          viewCount: listing.viewCount,
          createdAt: listing.createdAt,
          bumpedAt: listing.bumpedAt,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم حفظ تعديل الطلب',
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
            'تعذر حفظ التعديل',
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
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'رفض الطلب — تأكيد 1 من 2',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
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
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'سبب الرفض (اختياري — يُحفظ مع الطلب)',
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
              child: const Text('متابعة إلى التأكيد النهائي'),
            ),
          ],
        );
      },
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (step1 != true || !mounted) return;

    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(
            'رفض الطلب — تأكيد 2 من 2',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'تأكيد نهائي لرفض هذا الطلب ولن يُنشر في الدليل.\n'
            '${listing.area} ← ${listing.destination}'
            '${note.isEmpty ? '' : '\nالسبب: $note'}',
            style: GoogleFonts.ibmPlexSansArabic(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: c.error,
                foregroundColor: c.onError,
              ),
              child: const Text('تأكيد نهائي: رفض'),
            ),
          ],
        );
      },
    );
    if (step2 != true || !mounted) return;

    setState(() => _busyId = listing.id);
    try {
      await ListingsRepository.shared.setStatus(
        id: listing.id,
        status: ListingStatus.rejected,
        adminNote: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم رفض الطلب',
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

  String _completionMessageDraft(Listing listing) {
    final ref = listing.referenceCode ?? listing.id;
    return 'مرحباً، بخصوص طلب نشر خطك في دليل خطوط بغداد.\n'
        'رقم الطلب: $ref\n'
        'المسار: ${listing.area} ← ${listing.destination}\n\n'
        'لاحظنا أن بعض المعلومات ناقصة أو تحتاج تصحيحاً.\n'
        'يرجى تزويدنا بالتفاصيل الصحيحة (المنطقة/الوجهة/التوقيت/وسيلة التواصل) '
        'حتى نتمكن من إكمال مراجعة طلبك.\n'
        'شكراً لتعاونك.';
  }

  Future<void> _messageToComplete(Listing listing) async {
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

    final msgCtrl = TextEditingController(text: _completionMessageDraft(listing));
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'مراسلة السائق لإكمال البيانات',
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
      final digits = phone.replaceAll(RegExp(r'\D'), '');
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
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visible = _visible;

    return Column(
      children: [
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
                            onEdit: () => _edit(listing),
                            onMessageComplete: () => _messageToComplete(listing),
                            onCopyRef: () async {
                              final ref =
                                  listing.referenceCode ?? listing.id;
                              await Clipboard.setData(ClipboardData(text: ref));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    'نُسخ رقم الطلب',
                                    style: GoogleFonts.ibmPlexSansArabic(),
                                  ),
                                ),
                              );
                            },
                            onWhatsApp: () => _openContact(listing),
                            onApproveReview: () => _setStatus(
                              listing,
                              ListingStatus.awaitingPayment,
                              confirmTitle: 'موافقة على الطلب؟',
                              confirmLabel: 'موافقة → انتظار الدفع',
                            ),
                            onConfirmPayment: () => _setStatus(
                              listing,
                              ListingStatus.published,
                              confirmTitle: 'تأكيد الدفع والنشر؟',
                              confirmLabel: 'نشر في الدليل',
                            ),
                            onReject: () => _reject(listing),
                            onReopen: () => _setStatus(
                              listing,
                              ListingStatus.pendingReview,
                              confirmTitle: 'إعادة الطلب للمراجعة؟',
                              confirmLabel: 'إعادة للمراجعة',
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
    required this.onMessageComplete,
    required this.onCopyRef,
    required this.onWhatsApp,
    required this.onApproveReview,
    required this.onConfirmPayment,
    required this.onReject,
    required this.onReopen,
  });

  final Listing listing;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onMessageComplete;
  final VoidCallback onCopyRef;
  final VoidCallback onWhatsApp;
  final VoidCallback onApproveReview;
  final VoidCallback onConfirmPayment;
  final VoidCallback onReject;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ref = listing.referenceCode ?? listing.id;
    final phone = listing.contactPhone?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _MetaChip(label: listing.statusLabel),
                _MetaChip(label: listing.governorate),
                _MetaChip(label: listing.scheduleLabel),
                _MetaChip(label: listing.genderLabel),
                if (listing.vehicleType != null &&
                    listing.vehicleType!.trim().isNotEmpty)
                  _MetaChip(label: listing.vehicleType!.trim()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'رقم الطلب: $ref',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12.5,
                    color: c.text.withValues(alpha: 0.7),
                  ),
                ),
                IconButton(
                  tooltip: 'نسخ',
                  onPressed: onCopyRef,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
              ],
            ),
            if (phone != null && phone.isNotEmpty)
              Text(
                'هاتف: $phone',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
              ),
            if ((listing.contactTelegram ?? '').trim().isNotEmpty)
              Text(
                'تلغرام: ${listing.contactTelegram}',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
              ),
            if ((listing.adminNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'ملاحظة: ${listing.adminNote}',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 12.5,
                  color: c.riderAccent,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('تعديل'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : onMessageComplete,
                  icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                  label: const Text('مراسلة لإكمال البيانات'),
                ),
                if (phone != null && phone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onWhatsApp,
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('واتساب'),
                  ),
                if (listing.status == ListingStatus.pendingReview) ...[
                  FilledButton(
                    onPressed: busy ? null : onApproveReview,
                    child: const Text('موافقة → انتظار الدفع'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : onReject,
                    child: Text(
                      'رفض',
                      style: TextStyle(color: c.riderAccent),
                    ),
                  ),
                ],
                if (listing.status == ListingStatus.awaitingPayment) ...[
                  FilledButton(
                    onPressed: busy ? null : onConfirmPayment,
                    child: const Text('تأكيد الدفع ونشر'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : onReject,
                    child: Text(
                      'رفض',
                      style: TextStyle(color: c.riderAccent),
                    ),
                  ),
                ],
                if (listing.status == ListingStatus.rejected)
                  OutlinedButton(
                    onPressed: busy ? null : onReopen,
                    child: const Text('إعادة للمراجعة'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 11.5,
          color: c.text.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
