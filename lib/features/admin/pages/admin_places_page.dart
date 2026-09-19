import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/baghdad_places.dart';
import '../../../core/data/places_catalog.dart';
import '../../../core/models/managed_place.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/places_repository.dart';

class AdminPlacesPage extends StatefulWidget {
  const AdminPlacesPage({super.key});

  @override
  State<AdminPlacesPage> createState() => _AdminPlacesPageState();
}

class _AdminPlacesPageState extends State<AdminPlacesPage> {
  final _name = TextEditingController();
  final _search = TextEditingController();
  String _kind = 'both';
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await PlacesCatalog.shared.refresh(forAdmin: true);
    } catch (_) {
      if (mounted) _toast('تعذر تحميل المناطق');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_EditablePlace> get _rows {
    final catalog = PlacesCatalog.shared;
    final q = _search.text.trim();
    final byLower = <String, _EditablePlace>{};

    for (final name in catalog.builtinNames) {
      final o = catalog.overrideFor(name);
      final display = o?.renamedTo?.trim().isNotEmpty == true
          ? o!.renamedTo!.trim()
          : name;
      byLower[name.trim().toLowerCase()] = _EditablePlace(
        originalName: name,
        displayName: display,
        kind: 'both',
        source: _PlaceSource.builtin,
        managed: null,
        hidden: o?.hidden == true,
        renamed: o?.renamedTo,
        overrideId: o?.id,
      );
    }

    for (final p in catalog.managed) {
      final key = p.name.trim().toLowerCase();
      byLower[key] = _EditablePlace(
        originalName: p.name,
        displayName: p.name,
        kind: p.kind,
        source: _PlaceSource.managed,
        managed: p,
        hidden: !p.active,
        renamed: null,
        overrideId: null,
      );
    }

    var list = byLower.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    if (q.isNotEmpty) {
      list = list
          .where(
            (e) =>
                BaghdadPlaces.matchesQuery(e.displayName, q) ||
                BaghdadPlaces.matchesQuery(e.originalName, q),
          )
          .toList();
    }
    return list;
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      _toast('اكتب اسم المنطقة (حرفان على الأقل)');
      return;
    }
    setState(() => _saving = true);
    try {
      await PlacesRepository.shared.add(name: name, kind: _kind);
      if (!mounted) return;
      _name.clear();
      _toast('تمت الإضافة', ok: true);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast(_friendlyError('$e', fallback: 'تعذر الإضافة'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(_EditablePlace place) async {
    final nameCtrl = TextEditingController(text: place.displayName);
    var kind = place.kind;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return AlertDialog(
              title: Text(
                'تعديل المنطقة',
                style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(),
                      ),
                      style: GoogleFonts.ibmPlexSansArabic(),
                    ),
                    if (place.source == _PlaceSource.managed) ...[
                      const SizedBox(height: 12),
                      Text(
                        'تظهر في',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _KindChip(
                            label: 'منطقة ووجهة',
                            selected: kind == 'both',
                            onTap: () => setModal(() => kind = 'both'),
                          ),
                          _KindChip(
                            label: 'انطلاق',
                            selected: kind == 'area',
                            onTap: () => setModal(() => kind = 'area'),
                          ),
                          _KindChip(
                            label: 'وجهة',
                            selected: kind == 'destination',
                            onTap: () => setModal(() => kind = 'destination'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: c.primary),
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
    final nextName = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (saved != true) return;
    if (nextName.length < 2) {
      _toast('الاسم قصير جداً');
      return;
    }

    try {
      if (place.source == _PlaceSource.managed && place.managed != null) {
        await PlacesRepository.shared.updateManaged(
          id: place.managed!.id,
          name: nextName,
          kind: kind,
        );
      } else if (nextName == place.originalName) {
        // No rename — clear rename override if any, keep hidden state.
        if (place.renamed != null) {
          if (place.hidden) {
            await PlacesRepository.shared.upsertOverride(
              name: place.originalName,
              renamedTo: null,
              hidden: true,
            );
          } else {
            await PlacesRepository.shared.clearOverrideByName(place.originalName);
          }
        }
      } else {
        await PlacesRepository.shared.upsertOverride(
          name: place.originalName,
          renamedTo: nextName,
          hidden: place.hidden,
        );
      }
      if (!mounted) return;
      _toast('تم التعديل', ok: true);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _toast(_friendlyError('$e', fallback: 'تعذر التعديل'));
    }
  }

  Future<void> _delete(_EditablePlace place) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.colors;
        final isManaged = place.source == _PlaceSource.managed;
        return AlertDialog(
          title: Text(
            isManaged ? 'حذف المنطقة؟' : 'إخفاء من الفلاتر؟',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
          ),
          content: Text(
            isManaged
                ? '«${place.displayName}» ستُحذف من الفلاتر ونموذج النشر.'
                : '«${place.displayName}» منطقة أساسية — ستُخفى من الفلاتر ويمكن استعادتها لاحقاً.',
            style: GoogleFonts.ibmPlexSansArabic(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: c.primary),
              child: Text(isManaged ? 'حذف' : 'إخفاء'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      if (place.source == _PlaceSource.managed && place.managed != null) {
        await PlacesRepository.shared.delete(place.managed!.id);
      } else {
        await PlacesRepository.shared.upsertOverride(
          name: place.originalName,
          renamedTo: place.renamed,
          hidden: true,
        );
      }
      if (!mounted) return;
      _toast(place.source == _PlaceSource.managed ? 'تم الحذف' : 'تم الإخفاء', ok: true);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _toast('تعذر الحذف — نفّذ ملفات SQL للمناطق إن لم تُنفَّذ');
    }
  }

  Future<void> _restore(_EditablePlace place) async {
    try {
      if (place.source == _PlaceSource.managed && place.managed != null) {
        await PlacesRepository.shared.updateManaged(
          id: place.managed!.id,
          name: place.managed!.name,
          kind: place.managed!.kind,
        );
      } else {
        final renamed = place.renamed;
        if (renamed == null || renamed.trim().isEmpty) {
          await PlacesRepository.shared.clearOverrideByName(place.originalName);
        } else {
          await PlacesRepository.shared.upsertOverride(
            name: place.originalName,
            renamedTo: renamed,
            hidden: false,
          );
        }
      }
      if (!mounted) return;
      _toast('تمت الاستعادة', ok: true);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _toast('تعذر الاستعادة');
    }
  }

  String _friendlyError(String msg, {required String fallback}) {
    if (msg.contains('INVALID_NAME')) return 'الاسم غير صالح';
    if (msg.contains('NAME_TOO_LONG')) return 'الاسم طويل جداً';
    if (msg.contains('NAME_EXISTS')) return 'الاسم موجود مسبقاً';
    if (msg.contains('NOT_FOUND')) return 'المنطقة غير موجودة';
    if (msg.contains('NO_CHANGE')) return 'لا يوجد تغيير للحفظ';
    if (msg.contains('migrate_') || msg.contains('PGRST') || msg.contains('404')) {
      return 'نفّذ ملفات SQL للمناطق في Supabase أولاً';
    }
    return fallback;
  }

  void _toast(String message, {bool ok = false}) {
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? c.primary : null,
        content: Text(message, style: GoogleFonts.ibmPlexSansArabic()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final rows = _rows;
    final hiddenCount = rows.where((e) => e.hidden).length;

    return RefreshIndicator(
      color: c.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'مناطق الفلاتر',
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'أضف، عدّل الاسم، أو احذف/أخفِ أي منطقة من الفلاتر ونموذج النشر مباشرة من هنا.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: c.text.withValues(alpha: 0.58),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saving ? null : _add(),
            decoration: InputDecoration(
              labelText: 'إضافة منطقة جديدة',
              hintText: 'مثال: حي القاهرة',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: c.surface,
            ),
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _KindChip(
                label: 'منطقة ووجهة',
                selected: _kind == 'both',
                onTap: () => setState(() => _kind = 'both'),
              ),
              _KindChip(
                label: 'انطلاق فقط',
                selected: _kind == 'area',
                onTap: () => setState(() => _kind = 'area'),
              ),
              _KindChip(
                label: 'وجهة فقط',
                selected: _kind == 'destination',
                onTap: () => setState(() => _kind = 'destination'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _add,
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
              ),
              child: _saving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.onPrimary,
                      ),
                    )
                  : Text(
                      'إضافة',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'بحث في المناطق',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: c.surface,
            ),
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'كل المناطق (${rows.length})',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (hiddenCount > 0) ...[
                const SizedBox(width: 8),
                Text(
                  'مخفي: $hiddenCount',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: c.text.withValues(alpha: 0.5),
                  ),
                ),
              ],
              const Spacer(),
              if (_loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (!_loading && rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'لا نتائج.',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  color: c.text.withValues(alpha: 0.5),
                ),
              ),
            ),
          for (final place in rows) ...[
            Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              child: ListTile(
                title: Text(
                  place.displayName,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    decoration:
                        place.hidden ? TextDecoration.lineThrough : null,
                    color: place.hidden
                        ? c.text.withValues(alpha: 0.45)
                        : null,
                  ),
                ),
                subtitle: Text(
                  [
                    place.source == _PlaceSource.managed ? 'مضافة' : 'أساسية',
                    if (place.source == _PlaceSource.managed)
                      ManagedPlace(
                        id: place.managed?.id ?? '',
                        name: place.displayName,
                        kind: place.kind,
                        active: !place.hidden,
                      ).kindLabel,
                    if (place.renamed != null &&
                        place.renamed != place.originalName)
                      'كانت: ${place.originalName}',
                    if (place.hidden) 'مخفية',
                  ].join(' · '),
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12,
                    color: c.text.withValues(alpha: 0.55),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (place.hidden)
                      IconButton(
                        tooltip: 'استعادة',
                        onPressed: () => _restore(place),
                        icon: Icon(
                          Icons.undo_rounded,
                          color: c.primary.withValues(alpha: 0.85),
                        ),
                      )
                    else ...[
                      IconButton(
                        tooltip: 'تعديل',
                        onPressed: () => _edit(place),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: c.text.withValues(alpha: 0.55),
                        ),
                      ),
                      IconButton(
                        tooltip: place.source == _PlaceSource.managed
                            ? 'حذف'
                            : 'إخفاء',
                        onPressed: () => _delete(place),
                        icon: Icon(
                          Icons.delete_outline,
                          color: c.text.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

enum _PlaceSource { builtin, managed }

class _EditablePlace {
  const _EditablePlace({
    required this.originalName,
    required this.displayName,
    required this.kind,
    required this.source,
    required this.managed,
    required this.hidden,
    required this.renamed,
    required this.overrideId,
  });

  final String originalName;
  final String displayName;
  final String kind;
  final _PlaceSource source;
  final ManagedPlace? managed;
  final bool hidden;
  final String? renamed;
  final String? overrideId;
}

class _KindChip extends StatelessWidget {
  const _KindChip({
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
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: c.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? c.primary : c.text,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
