import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/listing.dart';
import '../../../core/config/directory_launch.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/contact_unlocks_repository.dart';
import '../../../data/listings_repository.dart';
import '../widgets/admin_double_confirm.dart';
import '../widgets/admin_publish_flow.dart';
import '../widgets/share_listing_card_sheet.dart';
import 'admin_listing_review_page.dart';

class AdminListingsPage extends StatefulWidget {
  const AdminListingsPage({super.key});

  @override
  State<AdminListingsPage> createState() => _AdminListingsPageState();
}

class _AdminListingsPageState extends State<AdminListingsPage> {
  final _search = TextEditingController();
  List<Listing> _items = [];
  bool _loading = true;
  bool _ridersLane = false;

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
    final all = await ListingsRepository.shared.fetchAll(publishedOnly: false);
    if (!mounted) return;
    setState(() {
      _items = all;
      _loading = false;
    });
  }

  List<Listing> get _filtered {
    final q = _search.text.trim();
    return _items.where((l) {
      if (l.isDriver == _ridersLane) return false;
      if (q.isEmpty) return true;
      final blob = [
        l.area,
        l.destination,
        l.contactPhone ?? '',
        l.contactTelegram ?? '',
        l.statusLabel,
        l.referenceCode ?? '',
        l.id,
        ...l.originSubs,
        ...l.destinationSubs,
      ].join(' ');
      return blob.toLowerCase().contains(q.toLowerCase()) ||
          (l.referenceCode ?? '')
              .toUpperCase()
              .contains(q.trim().toUpperCase());
    }).toList();
  }

  Future<void> _delete(Listing listing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        return AlertDialog(
          title: Text(
            'حذف الإعلان؟',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
          ),
          content: Text(
            '${listing.area} ← ${listing.destination}',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'حذف',
                style: GoogleFonts.ibmPlexSansArabic(
                  color: c.riderAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await ListingsRepository.shared.deleteById(listing.id);
    await _load();
  }

  Future<void> _edit(Listing listing) async {
    final saved = await openAdminListingReview(context, listing);
    if (saved != null) await _load();
  }

  Future<void> _unbook(Listing listing) async {
    final ok = await AdminDoubleConfirm.show(
      context,
      title: 'إزالة الحجز؟',
      detail: 'يُزال وسم محجوز فوراً ويُعاد نشر الطلب في الدليل ليصبح متاحاً للحجز.',
      confirmLabel: 'تأكيد الإزالة',
    );
    if (!ok || !mounted) return;
    setState(() {
      _items = [
        for (final l in _items)
          l.id == listing.id ? l.copyWith(isBooked: false) : l,
      ];
    });
    try {
      await ContactUnlocksRepository.shared.releaseActiveForRequest(listing.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تعذر إزالة الحجز. أعد المحاولة.',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'أُزيل الحجز وأُعيد نشر الطلب',
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
      ),
    );
    await _load();
  }

  Future<void> _publishManual() async {
    final saved = await openAdminPublishFlow(context);
    if (!mounted) return;
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم نشر الإعلان في الدليل',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtered = _filtered;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publishManual,
        icon: const Icon(Icons.publish_outlined),
        label: Text(
          'نشر',
          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.ibmPlexSansArabic(),
                decoration: InputDecoration(
                  hintText: 'بحث برقم الطلب أو المنطقة أو الوجهة أو التواصل',
                  hintStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: c.surface,
                  isDense: true,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: c.border),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _AdminLaneTab(
                      label: 'خطوط السائقين',
                      count: _items.where((l) => l.isDriver).length,
                      selected: !_ridersLane,
                      onTap: () => setState(() => _ridersLane = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AdminLaneTab(
                      label: 'طلبات الركاب',
                      count: _items.where((l) => !l.isDriver).length,
                      selected: _ridersLane,
                      onTap: () => setState(() => _ridersLane = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  '${filtered.length}',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: c.border),
        Expanded(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(color: c.primary),
                )
              : RefreshIndicator(
                  color: c.primary,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: c.border),
                    itemBuilder: (context, index) {
                      final l = filtered[index];
                      return ListTile(
                        onTap: () => _edit(l),
                        title: Text(
                          '${l.area} ← ${l.destination}',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${l.isDriver ? 'خط سائق' : 'طلب راكب'} · ${l.statusLabel} · ${l.scheduleLabel}\n'
                          '${l.contactPhone ?? l.contactTelegram ?? '—'}',
                          style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'share') {
                              showShareListingCardSheet(
                                context,
                                l.isDriver || DirectoryLaunch.freeRiderContacts
                                    ? l
                                    : l.withoutPublicContacts(),
                              );
                            }
                            if (v == 'edit') _edit(l);
                            if (v == 'unbook') _unbook(l);
                            if (v == 'delete') _delete(l);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'share',
                              child: Text(
                                'حفظ البطاقة',
                                style: GoogleFonts.ibmPlexSansArabic(),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                'مراجعة وتعديل',
                                style: GoogleFonts.ibmPlexSansArabic(),
                              ),
                            ),
                            if (!l.isDriver && l.isBooked)
                              PopupMenuItem(
                                value: 'unbook',
                                child: Text(
                                  'إزالة الحجز وإعادة النشر',
                                  style: GoogleFonts.ibmPlexSansArabic(),
                                ),
                              ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'حذف',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: c.riderAccent,
                                ),
                              ),
                            ),
                          ],
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

class _AdminLaneTab extends StatelessWidget {
  const _AdminLaneTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primary.withValues(alpha: 0.12) : c.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? c.primary : c.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? c.primary : c.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: selected ? c.primary : c.text.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
