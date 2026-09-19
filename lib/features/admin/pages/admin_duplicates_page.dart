import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/contact_keys.dart';
import '../../../data/listings_repository.dart';
import '../../listings/publish_listing_page.dart';

enum _DupKind { phone, telegram }

class _DupGroup {
  const _DupGroup({
    required this.kind,
    required this.key,
    required this.label,
    required this.items,
  });

  final _DupKind kind;
  final String key;
  final String label;
  final List<Listing> items;
}

class AdminDuplicatesPage extends StatefulWidget {
  const AdminDuplicatesPage({super.key});

  @override
  State<AdminDuplicatesPage> createState() => _AdminDuplicatesPageState();
}

class _AdminDuplicatesPageState extends State<AdminDuplicatesPage> {
  List<_DupGroup> _groups = const [];
  bool _loading = true;
  bool _deleting = false;
  _DupKind? _kindFilter; // null = all
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await ListingsRepository.shared.fetchAll();
    if (!mounted) return;
    final groups = _buildGroups(all);
    final alive = {
      for (final g in groups)
        for (final l in g.items) l.id,
    };
    setState(() {
      _groups = groups;
      _selectedIds.removeWhere((id) => !alive.contains(id));
      _loading = false;
    });
  }

  List<_DupGroup> _buildGroups(List<Listing> all) {
    final byPhone = <String, List<Listing>>{};
    final byTelegram = <String, List<Listing>>{};
    final phoneLabel = <String, String>{};
    final telegramLabel = <String, String>{};

    for (final l in all) {
      final pk = ContactKeys.whatsappKey(l.contactPhone);
      if (pk != null) {
        (byPhone[pk] ??= []).add(l);
        phoneLabel.putIfAbsent(pk, () => (l.contactPhone ?? pk).trim());
      }
      final tk = ContactKeys.telegramKey(l.contactTelegram);
      if (tk != null) {
        (byTelegram[tk] ??= []).add(l);
        telegramLabel.putIfAbsent(
          tk,
          () => (l.contactTelegram ?? '@$tk').trim(),
        );
      }
    }

    final groups = <_DupGroup>[
      for (final e in byPhone.entries)
        if (e.value.length >= 2)
          _DupGroup(
            kind: _DupKind.phone,
            key: e.key,
            label: phoneLabel[e.key] ?? e.key,
            items: List<Listing>.from(e.value)
              ..sort((a, b) => (b.createdAt ?? DateTime(0))
                  .compareTo(a.createdAt ?? DateTime(0))),
          ),
      for (final e in byTelegram.entries)
        if (e.value.length >= 2)
          _DupGroup(
            kind: _DupKind.telegram,
            key: e.key,
            label: telegramLabel[e.key] ?? '@${e.key}',
            items: List<Listing>.from(e.value)
              ..sort((a, b) => (b.createdAt ?? DateTime(0))
                  .compareTo(a.createdAt ?? DateTime(0))),
          ),
    ];

    groups.sort((a, b) {
      final byCount = b.items.length.compareTo(a.items.length);
      if (byCount != 0) return byCount;
      return a.label.compareTo(b.label);
    });
    return groups;
  }

  List<_DupGroup> get _visible {
    if (_kindFilter == null) return _groups;
    return _groups.where((g) => g.kind == _kindFilter).toList();
  }

  Iterable<String> get _visibleIds sync* {
    for (final g in _visible) {
      for (final l in g.items) {
        yield l.id;
      }
    }
  }

  void _toggle(String id, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _selectGroup(_DupGroup group, {required bool select}) {
    setState(() {
      for (final l in group.items) {
        if (select) {
          _selectedIds.add(l.id);
        } else {
          _selectedIds.remove(l.id);
        }
      }
    });
  }

  void _selectAllVisible() {
    setState(() => _selectedIds.addAll(_visibleIds));
  }

  void _clearSelection() {
    setState(_selectedIds.clear);
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

  Future<void> _deleteSelected() async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty || _deleting) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        return AlertDialog(
          title: Text(
            'حذف المحدد؟',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'سيتم حذف ${ids.length} منشوراً محدداً فقط. المنشورات غير المحددة تبقى كما هي.',
            style: GoogleFonts.ibmPlexSansArabic(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'حذف المحدد',
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

    setState(() => _deleting = true);
    try {
      for (final id in ids) {
        await ListingsRepository.shared.deleteById(id);
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'تم حذف ${ids.length} منشوراً',
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visible = _visible;
    final visibleIdList = _visibleIds.toList();
    final selectedVisible =
        visibleIdList.where(_selectedIds.contains).length;
    final allVisibleSelected = visibleIdList.isNotEmpty &&
        selectedVisible == visibleIdList.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'حدّد يدوياً المنشورات المراد حذفها فقط، ثم احذف دفعة واحدة.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  color: c.text.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _FilterChip(
                    label: 'الكل',
                    selected: _kindFilter == null,
                    onTap: () => setState(() => _kindFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'واتساب',
                    selected: _kindFilter == _DupKind.phone,
                    onTap: () => setState(() => _kindFilter = _DupKind.phone),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'تلغرام',
                    selected: _kindFilter == _DupKind.telegram,
                    onTap: () =>
                        setState(() => _kindFilter = _DupKind.telegram),
                  ),
                  const Spacer(),
                  Text(
                    '${visible.length} مجموعة',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (visible.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: allVisibleSelected
                          ? _clearSelection
                          : _selectAllVisible,
                      child: Text(
                        allVisibleSelected
                            ? 'إلغاء تحديد الظاهر'
                            : 'تحديد كل الظاهر',
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
                      ),
                    ),
                    if (_selectedIds.isNotEmpty)
                      TextButton(
                        onPressed: _clearSelection,
                        child: Text(
                          'مسح التحديد',
                          style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
                        ),
                      ),
                    Text(
                      'محدد: ${_selectedIds.length}',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: c.primary,
                      ),
                    ),
                    FilledButton(
                      onPressed: _selectedIds.isEmpty || _deleting
                          ? null
                          : _deleteSelected,
                      style: FilledButton.styleFrom(
                        backgroundColor: c.riderAccent,
                        foregroundColor: c.onPrimary,
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: _deleting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.onPrimary,
                              ),
                            )
                          : Text(
                              'حذف المحدد',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Divider(height: 1, color: c.border),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: c.primary))
              : RefreshIndicator(
                  color: c.primary,
                  onRefresh: _load,
                  child: visible.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                'لا توجد منشورات مكررة حالياً',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: c.text.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final g = visible[index];
                            return _DupGroupCard(
                              group: g,
                              selectedIds: _selectedIds,
                              onToggle: _toggle,
                              onSelectGroup: (select) =>
                                  _selectGroup(g, select: select),
                              onEdit: _edit,
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _DupGroupCard extends StatelessWidget {
  const _DupGroupCard({
    required this.group,
    required this.selectedIds,
    required this.onToggle,
    required this.onSelectGroup,
    required this.onEdit,
  });

  final _DupGroup group;
  final Set<String> selectedIds;
  final void Function(String id, bool? selected) onToggle;
  final ValueChanged<bool> onSelectGroup;
  final ValueChanged<Listing> onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final kindLabel =
        group.kind == _DupKind.phone ? 'واتساب' : 'تلغرام';
    final selectedInGroup =
        group.items.where((l) => selectedIds.contains(l.id)).length;
    final allSelected = selectedInGroup == group.items.length;
    final someSelected = selectedInGroup > 0 && !allSelected;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            color: c.primary.withValues(alpha: 0.06),
            child: Row(
              children: [
                Checkbox(
                  tristate: true,
                  value: allSelected
                      ? true
                      : (someSelected ? null : false),
                  onChanged: (v) => onSelectGroup(v != false),
                ),
                Icon(
                  group.kind == _DupKind.phone
                      ? Icons.phone_outlined
                      : Icons.send_outlined,
                  size: 18,
                  color: c.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$kindLabel: ${group.label}',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '$selectedInGroup/${group.items.length}',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: c.primary,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < group.items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.border),
            ListTile(
              dense: true,
              leading: Checkbox(
                value: selectedIds.contains(group.items[i].id),
                onChanged: (v) => onToggle(group.items[i].id, v),
              ),
              title: Text(
                '${group.items[i].area} ← ${group.items[i].destination}',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                '${group.items[i].typeLabel} · ${group.items[i].scheduleLabel}',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 11),
              ),
              trailing: IconButton(
                tooltip: 'تعديل',
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => onEdit(group.items[i]),
              ),
              onTap: () => onToggle(
                group.items[i].id,
                !selectedIds.contains(group.items[i].id),
              ),
            ),
          ],
        ],
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
