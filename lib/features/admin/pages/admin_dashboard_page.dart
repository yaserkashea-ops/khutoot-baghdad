import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/activity/directory_activity.dart';
import '../../../core/models/admin_report.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/admin_repository.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await AdminRepository.shared.fetchStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_loading || _stats == null) {
      return Center(
        child: CircularProgressIndicator(color: c.primary),
      );
    }
    final s = _stats!;

    return RefreshIndicator(
      color: c.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ملخص سريع',
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                title: 'المستخدمون',
                value: DirectoryActivity.formatCount(s.directoryUsers),
                subtitle: DirectoryActivity.progressDelta(s.directoryUsers) == 0
                    ? 'رصد التقدم من ${DirectoryActivity.formatCount(DirectoryActivity.progressFloor)}'
                    : '+${DirectoryActivity.formatCount(DirectoryActivity.progressDelta(s.directoryUsers))} منذ ${DirectoryActivity.formatCount(DirectoryActivity.progressFloor)}',
                wide: true,
              ),
              _StatCard(
                title: 'خطوط السائقين',
                value: '${s.drivers}',
                onTap: () => widget.onOpenTab(3),
              ),
              _StatCard(
                title: 'طلبات الخطوط',
                value: '${s.riders}',
                onTap: () => widget.onOpenTab(3),
              ),
              _StatCard(
                title: 'المنشورات الظاهرة',
                value: '${s.listingsTotal}',
                onTap: () => widget.onOpenTab(3),
              ),
              _StatCard(
                title: 'المناطق',
                value: '${s.placesTotal}',
                onTap: () => widget.onOpenTab(9),
              ),
              _StatCard(
                title: 'تثبيتات الهاتف',
                value: '${s.phoneInstalls}',
              ),
              _StatCard(
                title: 'البلاغات',
                value: '${s.reportsTotal}',
                onTap: () => widget.onOpenTab(8),
              ),
              _StatCard(
                title: 'دعوات',
                value: '${s.outreachTotal}',
                onTap: () => widget.onOpenTab(7),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'اختصارات',
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          _ShortcutTile(
            title: 'مراجعة المنشورات',
            subtitle: 'بطاقة كاملة — نشر أو تعديل أو رفض',
            icon: Icons.fact_check_outlined,
            onTap: () => widget.onOpenTab(1),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            title: 'متابعة المنشورات',
            subtitle: 'آخر تحديث، إخفاء، حذف',
            icon: Icons.event_available_outlined,
            onTap: () => widget.onOpenTab(2),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            title: 'إدارة الإعلانات',
            subtitle: 'عرض، بحث، حذف المنشورات',
            icon: Icons.list_alt,
            onTap: () => widget.onOpenTab(3),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            title: 'جهات المنشورات',
            subtitle: 'أرقام ويوزرات المنشورة حسب نوع الإعلان',
            icon: Icons.contacts_outlined,
            onTap: () => widget.onOpenTab(4),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            title: 'المنشورات المكررة',
            subtitle: 'نفس واتساب أو معرف التلغرام',
            icon: Icons.copy_all_outlined,
            onTap: () => widget.onOpenTab(5),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            title: 'استيراد من تلغرام / SMS',
            subtitle: 'لصق منشورات أو أوامر صوتية ثم النشر',
            icon: Icons.upload_file_outlined,
            onTap: () => widget.onOpenTab(6),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            title: 'أوامر صوتية لإضافة خط',
            subtitle: 'خطوة بخطوة أو جملة واحدة — من تبويب الاستيراد',
            icon: Icons.mic,
            onTap: () => widget.onOpenTab(6),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            title: 'دعوات التطبيق',
            subtitle: 'استخراج أرقام ويوزرات ودعوة يدوية',
            icon: Icons.campaign_outlined,
            onTap: () => widget.onOpenTab(7),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            title: 'متابعة البلاغات',
            subtitle: 'بلاغ / شكوى / مشكلة',
            icon: Icons.flag_outlined,
            onTap: () => widget.onOpenTab(8),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            title: 'مناطق الفلاتر',
            subtitle: 'إضافة مناطق جديدة للقوائم دون تحديث التطبيق',
            icon: Icons.place_outlined,
            onTap: () => widget.onOpenTab(9),
          ),
          const SizedBox(height: 8),
          _ShortcutTile(
            title: 'إعدادات التواصل',
            subtitle: 'مراجعة قنوات الإدارة',
            icon: Icons.settings_outlined,
            onTap: () => widget.onOpenTab(10),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
    this.wide = false,
  });

  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final stripe = c.primary;
    return SizedBox(
      width: wide ? 312 : 150,
      child: Material(
        color: c.surface,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: stripe),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: c.border),
                        bottom: BorderSide(color: c.border),
                        left: BorderSide(color: c.border),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13,
                            color: c.text.withValues(alpha: 0.65),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: GoogleFonts.ibmPlexSansArabic(
                              fontSize: 11.5,
                              height: 1.35,
                              color: c.text.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: c.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        color: c.text.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
