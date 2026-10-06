import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/notifications/notifications_bell_button.dart';
import '../../core/pwa/pwa_install.dart';
import '../../core/pwa/share_app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_toggle_button.dart';
import '../listings/directory_browse.dart';
import '../support/contact_admin_sheet.dart';
import 'home_action_card.dart';
import 'home_layout.dart';
import 'install_app_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onOpenExplore});

  final VoidCallback onOpenExplore;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<void>? _installStateSub;
  StreamSubscription<String>? _installOutcomeSub;
  bool _showInstall = !PwaInstall.isStandalone;

  @override
  void initState() {
    super.initState();
    _installStateSub = PwaInstall.onStateChanged.listen((_) => _syncInstall());
    _installOutcomeSub = PwaInstall.onInstallOutcome.listen((outcome) {
      if (outcome == 'accepted') _syncInstall();
    });
  }

  void _syncInstall() {
    final show = !PwaInstall.isStandalone;
    if (mounted && show != _showInstall) {
      setState(() => _showInstall = show);
    }
  }

  @override
  void dispose() {
    _installStateSub?.cancel();
    _installOutcomeSub?.cancel();
    super.dispose();
  }

  void _browse({required bool riders}) {
    DirectoryBrowse.open(DirectoryBrowseQuery(riders: riders));
    widget.onOpenExplore();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'دليل خطوط بغداد',
          maxLines: 1,
          softWrap: false,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
        ),
        actionsPadding: const EdgeInsetsDirectional.only(end: 2),
        actions: [
          IconButtonTheme(
            data: IconButtonThemeData(
              style: IconButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShareAppIconButton(),
                ThemeToggleButton(),
                NotificationsBellButton(),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'التواصل مع الإدارة',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: 'التواصل مع الإدارة',
              onPressed: () => showContactAdminSheet(context),
              icon: const Icon(Icons.support_agent_rounded),
            ),
          ),
        ],
      ),
      body: HomeLayout.fill(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'كيف نساعدك اليوم؟',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.25,
                  color: c.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ابحث عن خط يناسب طريقك، أو انشر طلبك لتصل إلى السائق المناسب.',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  height: 1.45,
                  color: c.text.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 14),
              HomeActionCard(
                title: 'أنا طالب/موظف',
                subtitle: 'أريد البحث عن سائق',
                icon: Icons.person_search_rounded,
                color: c.primary,
                onTap: () => _browse(riders: false),
              ),
              const SizedBox(height: 10),
              HomeActionCard(
                title: 'أنا سائق',
                subtitle: 'أريد البحث عن راكب',
                icon: Icons.directions_car_filled_rounded,
                color: c.opportunity,
                onTap: () => _browse(riders: true),
              ),
              const Spacer(),
              if (_showInstall) ...[
                const SizedBox(height: 12),
                InstallAppCard(onInstalled: _syncInstall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
