import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/import/listing_text_parser.dart';
import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/listings_repository.dart';
import '../../listings/publish_listing_page.dart';

/// Paste Telegram / SMS ads → review → publish into the public feed.
class AdminImportPage extends StatefulWidget {
  const AdminImportPage({super.key});

  @override
  State<AdminImportPage> createState() => _AdminImportPageState();
}

class _AdminImportPageState extends State<AdminImportPage> {
  final _raw = TextEditingController();
  List<ParsedListingDraft> _drafts = [];
  bool _publishing = false;

  static const _sample = '''
سائق
من المنصور إلى الجادرية
صباحي انطلاق 7:30 عودة 2:00
مختلط · 3 مقاعد · سيارة صالون
07701234567

---

راكب
من الدورة للكرادة
بنات فقط مسائي
للتواصل @baghdad_rider

---
مطلوب خط من السيدية إلى الجامعة التكنولوجية صباحي 7:00
ذكور فقط
9647801112233
''';

  @override
  void dispose() {
    _raw.dispose();
    super.dispose();
  }

  void _parse() {
    final drafts = ListingTextParser.parse(_raw.text);
    setState(() => _drafts = drafts);
    if (drafts.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'لم يُستخرج أي إعلان — افصل الرسائل بسطر فارغ أو ---',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'الحافظة فارغة',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
      return;
    }
    setState(() {
      _raw.text = text;
      _drafts = ListingTextParser.parse(text);
    });
  }

  void _loadSample() {
    setState(() {
      _raw.text = _sample;
      _drafts = ListingTextParser.parse(_sample);
    });
  }

  Future<void> _editDraft(int index) async {
    final draft = _drafts[index];
    final edited = await Navigator.of(context).push<Listing>(
      MaterialPageRoute(
        builder: (_) => PublishListingPage(
          repository: ListingsRepository.shared,
          initial: draft.listing,
          draftOnly: true,
        ),
      ),
    );
    if (edited == null || !mounted) return;
    setState(() {
      _drafts[index] = draft.copyWith(
        listing: edited,
        selected: edited.area.isNotEmpty && edited.destination.isNotEmpty,
        warnings: const [],
      );
    });
  }

  Future<void> _publishSelected() async {
    final selected = _drafts.where((d) => d.selected && d.isPublishable).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'حدّد مسودات صالحة (بمنطقة ووجهة) أولاً',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
      return;
    }
    setState(() => _publishing = true);
    final created = await ListingsRepository.shared.insertMany(
      selected.map((d) => d.listing),
    );
    if (!mounted) return;
    setState(() {
      _publishing = false;
      _drafts = [
        for (final d in _drafts)
          if (!d.selected) d else d.copyWith(selected: false),
      ];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.colors.primary,
        content: Text(
          'نُشر ${created.length} إعلاناً في الأداة',
          style: GoogleFonts.ibmPlexSansArabic(
            color: context.colors.onPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final selectedCount =
        _drafts.where((d) => d.selected && d.isPublishable).length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Text(
                'استيراد من تلغرام أو رسالة نصية',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'الصق منشورات الكروب أو الرسائل كما هي. افصل كل إعلان بسطر فارغ أو --- ثم راجع قبل النشر.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  height: 1.45,
                  color: c.text.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pasteFromClipboard,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.primary,
                      side: BorderSide(color: c.border),
                      shape: const RoundedRectangleBorder(),
                    ),
                    icon: const Icon(Icons.paste_outlined, size: 18),
                    label: Text(
                      'لصق',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _loadSample,
                    child: Text(
                      'مثال',
                      style: GoogleFonts.ibmPlexSansArabic(color: c.primary),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _parse,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimary,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      'تحليل',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _raw,
                maxLines: 10,
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 13, height: 1.45),
                decoration: InputDecoration(
                  hintText: 'الصق هنا رسائل الكروب أو SMS…',
                  hintStyle: GoogleFonts.ibmPlexSansArabic(
                    color: c.text.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: c.surface,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: c.primary, width: 1.4),
                  ),
                ),
              ),
              if (_drafts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'المسودات (${_drafts.length})',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _drafts = [
                            for (final d in _drafts)
                              d.copyWith(selected: d.isPublishable),
                          ];
                        });
                      },
                      child: Text(
                        'تحديد الكل',
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _drafts = [
                            for (final d in _drafts) d.copyWith(selected: false),
                          ];
                        });
                      },
                      child: Text(
                        'إلغاء',
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _drafts.length; i++) ...[
                  _DraftCard(
                    draft: _drafts[i],
                    onToggle: (v) {
                      setState(() {
                        _drafts[i] = _drafts[i].copyWith(selected: v);
                      });
                    },
                    onEdit: () => _editDraft(i),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
        if (_drafts.isNotEmpty)
          Material(
            color: c.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _publishing ? null : _publishSelected,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimary,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: _publishing
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.onPrimary,
                            ),
                          )
                        : Text(
                            'نشر المحدد ($selectedCount)',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.onToggle,
    required this.onEdit,
  });

  final ParsedListingDraft draft;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = draft.listing;
    return Material(
      color: c.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: draft.selected ? c.primary : c.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              value: draft.selected,
              onChanged: draft.isPublishable
                  ? (v) => onToggle(v ?? false)
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                l.area.isEmpty && l.destination.isEmpty
                    ? 'مسودة غير مكتملة'
                    : '${l.area.isEmpty ? '؟' : l.area} ← ${l.destination.isEmpty ? '؟' : l.destination}',
                style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${l.typeLabel} · ${l.scheduleLabel} · ${l.genderLabel}\n'
                '${l.contactPhone ?? l.contactTelegram ?? 'بدون تواصل'}',
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
              ),
              secondary: IconButton(
                tooltip: 'تعديل',
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: c.primary),
              ),
            ),
            if (draft.warnings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  draft.warnings.map((w) => '• $w').join('\n'),
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 11,
                    height: 1.4,
                    color: c.accent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
