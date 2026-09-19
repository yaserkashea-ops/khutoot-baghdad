import 'dart:async';

import 'package:flutter/material.dart';

import '../../app.dart';
import '../config/app_hosts.dart';
import 'install_app_button.dart';
import 'pwa_install.dart';

/// Shows the install sheet after a short delay (and again when Chrome becomes
/// install-ready). Does not require beforeinstallprompt up front.
class InstallPromptHost extends StatefulWidget {
  const InstallPromptHost({super.key, required this.child});

  final Widget child;

  @override
  State<InstallPromptHost> createState() => _InstallPromptHostState();
}

class _InstallPromptHostState extends State<InstallPromptHost> {
  static bool _promptedThisSession = false;

  Timer? _timer;
  StreamSubscription<void>? _stateSub;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_schedule());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  Duration get _delay {
    final preview = Uri.base.queryParameters['install_preview'];
    if (preview == '1' || preview == 'true') {
      return const Duration(seconds: 1);
    }
    return const Duration(seconds: 15);
  }

  Future<void> _schedule() async {
    if (!mounted) return;
    if (AppHosts.isAdminHost) return;
    if (PwaInstall.isStandalone) return;
    if (_promptedThisSession) return;

    _timer?.cancel();
    _timer = Timer(_delay, () {
      unawaited(_fireInstallPrompt());
    });

    // If Chrome becomes install-ready later, open the sheet then.
    _stateSub?.cancel();
    _stateSub = PwaInstall.onStateChanged.listen((_) {
      if (_fired || _promptedThisSession) return;
      if (!PwaInstall.canNativeInstall) return;
      if (_timer?.isActive == true) return;
      unawaited(_fireInstallPrompt());
    });
  }

  BuildContext? get _navContext {
    final nav = MasaratApp.navigatorKey.currentContext;
    if (nav != null && nav.mounted) return nav;
    return null;
  }

  Future<void> _fireInstallPrompt() async {
    if (_fired || !mounted) return;
    if (PwaInstall.isStandalone) return;
    if (_promptedThisSession) return;

    for (var i = 0; i < 20 && _navContext == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    final ctx = _navContext;
    if (ctx == null || !ctx.mounted) return;

    _fired = true;
    _promptedThisSession = true;
    _timer?.cancel();
    await _stateSub?.cancel();
    _stateSub = null;

    final again = _navContext;
    if (again == null || !again.mounted) return;
    await runInstallAppFlow(again, forAdmin: false, preferSheet: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
