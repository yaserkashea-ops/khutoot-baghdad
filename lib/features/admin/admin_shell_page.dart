import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/admin_auth_controller.dart';
import '../../core/config/admin_config.dart';
import '../../core/pwa/install_app_button.dart';
import '../../core/pwa/pwa_install.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_toggle_button.dart';
import 'admin_gate_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_duplicates_page.dart';
import 'pages/admin_import_page.dart';
import 'pages/admin_invites_page.dart';
import 'pages/admin_listings_page.dart';
import 'pages/admin_places_page.dart';
import 'pages/admin_published_contacts_page.dart';
import 'pages/admin_reports_page.dart';
import 'pages/admin_requests_page.dart';
import 'pages/admin_settings_page.dart';
import 'pages/admin_subscriptions_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  /// Full page index (0–10). Bottom bar shows only 0–3 + «المزيد».
  int _index = 0;

  static const _titles = [
    'نظرة عامة',
    'طلبات الدليل',
    'الاشتراكات',
    'الإعلانات',
    'جهات المنشورات',
    'المكرر',
    'استيراد',
    'دعوات',
    'البلاغات',
    'المناطق',
    'الإعدادات',
  ];

  static const _primaryCount = 4;

  int get _navIndex => _index < _primaryCount ? _index : _primaryCount;

  @override
  void initState() {
    super.initState();
    PwaInstall.setMode('admin');
  }

  Future<void> _logout() async {
    await AdminAuthController.shared.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const AdminGatePage(),
      ),
    );
  }

  void _openTab(int pageIndex) {
    if (!mounted) return;
    setState(() => _index = pageIndex);
  }

  Future<void> _openMoreMenu() async {
    final c = context.colors;
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'المزيد',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أدوات إضافية للتشغيل والدعم',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    color: c.text.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 16),
                _MoreSection(
                  title: 'التشغيل',
                  children: [
                    _MoreItem(
                      icon: Icons.contacts_outlined,
                      title: 'جهات المنشورات',
                      subtitle: 'أرقام ويوزرات الخطوط المنشورة',
                      pageIndex: 4,
                      selected: _index == 4,
                    ),
                    _MoreItem(
                      icon: Icons.copy_all_outlined,
                      title: 'المكرر',
                      subtitle: 'نفس واتساب أو تلغرام',
                      pageIndex: 5,
                      selected: _index == 5,
                    ),
                    _MoreItem(
                      icon: Icons.upload_file_outlined,
                      title: 'استيراد',
                      subtitle: 'لصق منشورات أو أوامر صوتية',
                      pageIndex: 6,
                      selected: _index == 6,
                    ),
                    _MoreItem(
                      icon: Icons.campaign_outlined,
                      title: 'دعوات',
                      subtitle: 'استخراج أرقام ودعوة يدوية',
                      pageIndex: 7,
                      selected: _index == 7,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MoreSection(
                  title: 'الدعم والنظام',
                  children: [
                    _MoreItem(
                      icon: Icons.support_agent_outlined,
                      title: 'البلاغات',
                      subtitle: 'بلاغ / شكوى / مشكلة',
                      pageIndex: 8,
                      selected: _index == 8,
                    ),
                    _MoreItem(
                      icon: Icons.place_outlined,
                      title: 'المناطق',
                      subtitle: 'قوائم مناطق الفلاتر',
                      pageIndex: 9,
                      selected: _index == 9,
                    ),
                    _MoreItem(
                      icon: Icons.settings_outlined,
                      title: 'الإعدادات',
                      subtitle: 'تواصل الإدارة والحساب',
                      pageIndex: 10,
                      selected: _index == 10,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) _openTab(selected);
  }

  void _onNavSelected(int navIndex) {
    if (navIndex < _primaryCount) {
      _openTab(navIndex);
      return;
    }
    unawaited(_openMoreMenu());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final page = switch (_index) {
      0 => AdminDashboardPage(onOpenTab: _openTab),
      1 => const AdminRequestsPage(),
      2 => const AdminSubscriptionsPage(),
      3 => const AdminListingsPage(),
      4 => const AdminPublishedContactsPage(),
      5 => const AdminDuplicatesPage(),
      6 => const AdminImportPage(),
      7 => const AdminInvitesPage(),
      8 => const AdminReportsPage(),
      9 => const AdminPlacesPage(),
      _ => const AdminSettingsPage(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AdminConfig.shortName} — ${_titles[_index]}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          const InstallAppIconButton(forAdmin: true),
          const ThemeToggleButton(),
          TextButton(
            onPressed: _logout,
            child: Text(
              'خروج',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
          ),
        ],
      ),
      body: page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        backgroundColor: c.background,
        indicatorColor: c.primary.withValues(alpha: 0.12),
        height: 68,
        onDestinationSelected: _onNavSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: c.primary),
            label: 'عامة',
          ),
          NavigationDestination(
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox, color: c.primary),
            label: 'طلبات',
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available, color: c.primary),
            label: 'اشتراكات',
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: c.primary),
            label: 'إعلانات',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.more_horiz_rounded,
              color: _navIndex == _primaryCount ? c.primary : null,
            ),
            selectedIcon: Icon(Icons.more_horiz_rounded, color: c.primary),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  const _MoreSection({required this.title, required this.children});

  final String title;
  final List<_MoreItem> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
          child: Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.text.withValues(alpha: 0.5),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
            color: c.background,
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: c.border.withValues(alpha: 0.7)),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pageIndex,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int pageIndex;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: selected
            ? c.primary.withValues(alpha: 0.14)
            : c.primary.withValues(alpha: 0.08),
        child: Icon(icon, size: 20, color: c.primary),
      ),
      title: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
          color: c.text,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.ibmPlexSansArabic(
          fontSize: 12,
          color: c.text.withValues(alpha: 0.55),
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: c.primary, size: 20)
          : Icon(
              Icons.chevron_left_rounded,
              color: c.text.withValues(alpha: 0.35),
            ),
      onTap: () => Navigator.pop(context, pageIndex),
    );
  }
}
