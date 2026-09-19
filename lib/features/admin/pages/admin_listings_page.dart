import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/listings_repository.dart';
import '../../listings/publish_listing_page.dart';

class AdminListingsPage extends StatefulWidget {
  const AdminListingsPage({super.key});

  @override
  State<AdminListingsPage> createState() => _AdminListingsPageState();
}

class _AdminListingsPageState extends State<AdminListingsPage> {
  final _search = TextEditingController();
  List<Listing> _items = [];
  bool _loading = true;

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
    final saved = await Navigator.of(context).push<Listing>(
      MaterialPageRoute(
        builder: (_) => PublishListingPage(
          repository: ListingsRepository.shared,
          initial: listing,
          allowFreeTextPlaces: true,
        ),
      ),
    );
    if (saved != null) await _load();
  }

  Future<void> _publishManual() async {
    final saved = await Navigator.of(context).push<Listing>(
      MaterialPageRoute(
        builder: (_) => PublishListingPage(
          repository: ListingsRepository.shared,
          initialType: ListingType.driver,
          allowFreeTextPlaces: true,
        ),
      ),
    );
    if (!mounted) return;
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تم نشر الخط في الدليل',
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
        icon: const Icon(Icons.add),
          label: Text(
          'إضافة خط',
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
                        title: Text(
                          '${l.area} ← ${l.destination}',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${l.statusLabel} · ${l.scheduleLabel}\n'
                          '${l.contactPhone ?? l.contactTelegram ?? '—'}',
                          style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _edit(l);
                            if (v == 'delete') _delete(l);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                'تعديل',
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
