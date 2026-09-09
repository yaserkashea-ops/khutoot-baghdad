import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/admin_report.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/admin_repository.dart';
import '../../../data/listings_repository.dart';

String _statusLabel(ReportStatus status) => switch (status) {
      ReportStatus.open => 'جديد',
      ReportStatus.inProgress => 'قيد المعالجة',
      ReportStatus.resolved => 'محلول',
      ReportStatus.dismissed => 'مرفوض',
    };

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  List<AdminReport> _items = [];
  bool _loading = true;
  ReportStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items =
        await AdminRepository.shared.fetchReports(status: _statusFilter);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _openDetails(AdminReport report) async {
    final note = TextEditingController(text: report.adminNote ?? '');
    var status = report.status;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final c = ctx.colors;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      report.kindLabel,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.message,
                      style: GoogleFonts.ibmPlexSansArabic(height: 1.5),
                    ),
                    if (report.listingId != null) ...[
                      const SizedBox(height: 8),
                      FutureBuilder(
                        future: ListingsRepository.shared
                            .findById(report.listingId!),
                        builder: (context, snap) {
                          final l = snap.data;
                          if (l == null) {
                            return Text(
                              'إعلان مرتبط: ${report.listingId}',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                color: c.text.withValues(alpha: 0.55),
                              ),
                            );
                          }
                          return Text(
                            'الإعلان: ${l.area} ← ${l.destination}',
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 13,
                              color: c.primary,
                            ),
                          );
                        },
                      ),
                    ],
                    if (report.contactHint != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'تواصل المبلّغ: ${report.contactHint}',
                        style: GoogleFonts.manrope(fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'الحالة',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in ReportStatus.values)
                          ChoiceChip(
                            label: Text(
                              _statusLabel(s),
                              style:
                                  GoogleFonts.ibmPlexSansArabic(fontSize: 12),
                            ),
                            selected: status == s,
                            onSelected: (_) => setModal(() => status = s),
                            selectedColor: c.primary.withValues(alpha: 0.15),
                            shape: const RoundedRectangleBorder(),
                            side: BorderSide(
                              color: status == s ? c.primary : c.border,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: note,
                      maxLines: 3,
                      style: GoogleFonts.ibmPlexSansArabic(),
                      decoration: InputDecoration(
                        labelText: 'ملاحظة الإدارة',
                        labelStyle: GoogleFonts.ibmPlexSansArabic(),
                        filled: true,
                        fillColor: c.surface,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: Text(
                        'حفظ',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await AdminRepository.shared.deleteReport(report.id);
                        if (ctx.mounted) Navigator.pop(ctx, false);
                      },
                      child: Text(
                        'حذف البلاغ',
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: c.riderAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true) {
      await AdminRepository.shared.updateReport(
        report.id,
        status: status,
        adminNote: note.text.trim().isEmpty ? null : note.text.trim(),
      );
    }
    note.dispose();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _StatusChip(
                label: 'الكل',
                selected: _statusFilter == null,
                onTap: () {
                  setState(() => _statusFilter = null);
                  _load();
                },
              ),
              const SizedBox(width: 8),
              for (final s in ReportStatus.values) ...[
                _StatusChip(
                  label: _statusLabel(s),
                  selected: _statusFilter == s,
                  onTap: () {
                    setState(() => _statusFilter = s);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
              ],
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
                  child: _items.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                'لا توجد بلاغات في هذا التصنيف',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  color: c.text.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: c.border,
                          ),
                          itemBuilder: (context, index) {
                            final r = _items[index];
                            return ListTile(
                              onTap: () => _openDetails(r),
                              title: Text(
                                '${r.kindLabel} · ${r.statusLabel}',
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                r.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.ibmPlexSansArabic(
                                  fontSize: 13,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_left),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
