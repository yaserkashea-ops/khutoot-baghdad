import 'package:flutter/material.dart';

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
import 'pages/admin_published_contacts_page.dart';
import 'pages/admin_reports_page.dart';
import 'pages/admin_settings_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _index = 0;

  static const _titles = [
    'نظرة عامة',
    'الإعلانات',
    'جهات المنشورات',
    'المكرر',
    'استيراد',
    'دعوات',
    'البلاغات',
    'الإعدادات',
  ];

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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final page = switch (_index) {
      0 => AdminDashboardPage(onOpenTab: (i) => setState(() => _index = i)),
      1 => const AdminListingsPage(),
      2 => const AdminPublishedContactsPage(),
      3 => const AdminDuplicatesPage(),
      4 => const AdminImportPage(),
      5 => const AdminInvitesPage(),
      6 => const AdminReportsPage(),
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
        selectedIndex: _index,
        backgroundColor: c.background,
        indicatorColor: c.primary.withValues(alpha: 0.12),
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: c.primary),
            label: 'عامة',
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: c.primary),
            label: 'إعلانات',
          ),
          NavigationDestination(
            icon: const Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts, color: c.primary),
            label: 'جهات',
          ),
          NavigationDestination(
            icon: const Icon(Icons.copy_all_outlined),
            selectedIcon: Icon(Icons.copy_all, color: c.primary),
            label: 'مكرر',
          ),
          NavigationDestination(
            icon: const Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file, color: c.primary),
            label: 'استيراد',
          ),
          NavigationDestination(
            icon: const Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign, color: c.primary),
            label: 'دعوات',
          ),
          NavigationDestination(
            icon: const Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag, color: c.primary),
            label: 'بلاغات',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: c.primary),
            label: 'إعدادات',
          ),
        ],
      ),
    );
  }
}
