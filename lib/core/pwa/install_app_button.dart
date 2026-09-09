import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'pwa_install.dart';

/// Opens the browser native install UI (no instructional copy).
Future<void> runInstallAppFlow(
  BuildContext context, {
  bool forAdmin = false,
}) async {
  if (forAdmin) {
    PwaInstall.setMode('admin');
    PwaInstall.ensureAdminHash();
  }

  // Prefer the system install dialog immediately when ready.
  if (PwaInstall.canNativeInstall) {
    await PwaInstall.promptInstall();
    return;
  }

  // Brief wait — Chrome often exposes the prompt right after engagement.
  final ready = await PwaInstall.waitForPrompt();
  if (ready || PwaInstall.canNativeInstall) {
    await PwaInstall.promptInstall();
    return;
  }

  if (!context.mounted) return;
  // Fallback UI: install action only (no how-to text).
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(),
    isDismissible: true,
    builder: (ctx) => _InstallNowSheet(forAdmin: forAdmin),
  );
}

/// Compact AppBar install control — icon only.
class InstallAppIconButton extends StatefulWidget {
  const InstallAppIconButton({
    super.key,
    this.forAdmin = false,
  });

  /// When true, switches to the admin PWA manifest before install.
  final bool forAdmin;

  @override
  State<InstallAppIconButton> createState() => _InstallAppIconButtonState();
}

class _InstallAppIconButtonState extends State<InstallAppIconButton> {
  StreamSubscription<void>? _sub;
  bool _show = true;

  @override
  void initState() {
    super.initState();
    if (widget.forAdmin) {
      PwaInstall.setMode('admin');
    }
    _sub = PwaInstall.onStateChanged.listen((_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    // Admin install stays visible even if the public app is already installed.
    if (widget.forAdmin) {
      setState(() => _show = true);
      return;
    }
    var standalone = false;
    try {
      standalone = PwaInstall.isStandalone;
    } catch (_) {
      standalone = false;
    }
    setState(() => _show = !standalone);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();

    final c = context.colors;
    final tip = widget.forAdmin
        ? 'تثبيت لوحة التحكم على الرئيسية'
        : 'تثبيت على الشاشة الرئيسية';
    return Tooltip(
      message: tip,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 2, end: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key(widget.forAdmin ? 'install_admin_icon' : 'install_home_icon'),
            onTap: () => runInstallAppFlow(context, forAdmin: widget.forAdmin),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: c.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.app_shortcut_outlined,
                    size: 16,
                    color: c.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-action install surface — triggers native browser install dialog.
class _InstallNowSheet extends StatefulWidget {
  const _InstallNowSheet({this.forAdmin = false});

  final bool forAdmin;

  @override
  State<_InstallNowSheet> createState() => _InstallNowSheetState();
}

class _InstallNowSheetState extends State<_InstallNowSheet> {
  bool _busy = false;

  Future<void> _install() async {
    setState(() => _busy = true);
    if (widget.forAdmin) {
      PwaInstall.setMode('admin');
      PwaInstall.ensureAdminHash();
    }
    await PwaInstall.waitForPrompt(
      timeout: const Duration(milliseconds: 1500),
    );
    final outcome = await PwaInstall.promptInstall();
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome == 'accepted' || outcome == 'dismissed') {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label =
        widget.forAdmin ? 'تثبيت لوحة التحكم الآن' : 'تثبيت الآن';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _busy ? null : _install,
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  shape: const RoundedRectangleBorder(),
                ),
                child: _busy
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.onPrimary,
                        ),
                      )
                    : Text(
                        label,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
