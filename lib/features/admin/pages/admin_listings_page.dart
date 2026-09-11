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
  String? _typeFilter; // driver | rider

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
    final all = await ListingsRepository.shared.fetchAll();
    if (!mounted) return;
    setState(() {
      _items = all;
      _loading = false;
    });
  }

  List<Listing> get _filtered {
    final q = _search.text.trim();
    return _items.where((l) {
      if (_typeFilter == 'driver' && !l.isDriver) return false;
      if (_typeFilter == 'rider' && l.isDriver) return false;
      if (q.isEmpty) return true;
      final blob = [
        l.area,
        l.destination,
        l.contactPhone ?? '',
        l.contactTelegram ?? '',
        ...l.originSubs,
        ...l.destinationSubs,
      ].join(' ');
      return blob.contains(q);
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
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PublishListingPage(
          repository: ListingsRepository.shared,
          initial: listing,
        ),
      ),
    );
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtered = _filtered;

    return Column(
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
                  hintText: 'بحث بالمنطقة أو الوجهة أو رقم التواصل',
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
              Row(
                children: [
                  _FilterChip(
                    label: 'الكل',
                    selected: _typeFilter == null,
                    onTap: () => setState(() => _typeFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'سائق لديه خط',
                    selected: _typeFilter == 'driver',
                    onTap: () => setState(() => _typeFilter = 'driver'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'يبحث عن خط',
                    selected: _typeFilter == 'rider',
                    onTap: () => setState(() => _typeFilter = 'rider'),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length}',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                  ),
                ],
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
                          '${l.typeLabel} · ${l.scheduleLabel}\n'
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
    return Material(
      color: selected ? c.primary.withValues(alpha: 0.12) : c.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? c.primary : c.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
              color: selected ? c.primary : c.text,
            ),
          ),
        ),
      ),
    );
  }
}
