import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'pwa_install.dart';

/// Opens the browser native install UI, with a clear fallback when unavailable.
Future<void> runInstallAppFlow(
  BuildContext context, {
  bool forAdmin = false,
}) async {
  if (forAdmin) {
    // Keep any deferred beforeinstallprompt â€” setMode no-ops if already admin.
    PwaInstall.setMode('admin');
  }

  if (PwaInstall.canNativeInstall) {
    await PwaInstall.promptInstall();
    return;
  }

  final ready = await PwaInstall.waitForPrompt(
    timeout: const Duration(milliseconds: 4000),
  );
  if (ready || PwaInstall.canNativeInstall) {
    await PwaInstall.promptInstall();
    return;
  }

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(),
    isDismissible: true,
    builder: (ctx) => _InstallNowSheet(forAdmin: forAdmin),
  );
}

/// Compact AppBar install control â€” icon only.
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
        ? 'ØªØ«Ø¨ÙŠØª Ù„ÙˆØ­Ø© Ø§Ù„ØªØ­ÙƒÙ… Ø¹Ù„Ù‰ Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©'
        : 'ØªØ«Ø¨ÙŠØª Ø¹Ù„Ù‰ Ø§Ù„Ø´Ø§Ø´Ø© Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©';
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

class _InstallNowSheet extends StatefulWidget {
  const _InstallNowSheet({this.forAdmin = false});

  final bool forAdmin;

  @override
  State<_InstallNowSheet> createState() => _InstallNowSheetState();
}

class _InstallNowSheetState extends State<_InstallNowSheet> {
  bool _busy = false;
  String? _hint;

  Future<void> _install() async {
    setState(() {
      _busy = true;
      _hint = null;
    });
    if (widget.forAdmin) {
      PwaInstall.setMode('admin');
    }
    await PwaInstall.waitForPrompt(
      timeout: const Duration(milliseconds: 4000),
    );
    final outcome = await PwaInstall.promptInstall();
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome == 'accepted' || outcome == 'dismissed') {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _hint = PwaInstall.isIos
          ? 'Ù…Ù† Safari: Ø²Ø± Ø§Ù„Ù…Ø´Ø§Ø±ÙƒØ© â† Â«Ø¥Ø¶Ø§ÙØ© Ø¥Ù„Ù‰ Ø§Ù„Ø´Ø§Ø´Ø© Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©Â».'
          : 'Ù…Ù† Chrome: Ø§Ù„Ù‚Ø§Ø¦Ù…Ø© â‹® â† Â«ØªØ«Ø¨ÙŠØª Ø§Ù„ØªØ·Ø¨ÙŠÙ‚Â» Ø£Ùˆ Â«Ø¥Ø¶Ø§ÙØ© Ø¥Ù„Ù‰ Ø§Ù„Ø´Ø§Ø´Ø© Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©Â».';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label =
        widget.forAdmin ? 'ØªØ«Ø¨ÙŠØª Ù„ÙˆØ­Ø© Ø§Ù„ØªØ­ÙƒÙ… Ø§Ù„Ø¢Ù†' : 'ØªØ«Ø¨ÙŠØª Ø§Ù„Ø¢Ù†';
    final title = widget.forAdmin
        ? 'ØªØ«Ø¨ÙŠØª Ù„ÙˆØ­Ø© Ø§Ù„ØªØ­ÙƒÙ…'
        : 'ØªØ«Ø¨ÙŠØª Ø§Ù„ØªØ·Ø¨ÙŠÙ‚';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.forAdmin
                  ? 'Ø³ÙŠØ¸Ù‡Ø± Ø§Ø®ØªØµØ§Ø± Ø¨Ø§Ø³Ù… Â«ØªØ­ÙƒÙ… Ø®Ø·ÙˆØ·Â» Ø¹Ù„Ù‰ Ø§Ù„Ø´Ø§Ø´Ø© Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©.'
                  : 'Ø³ÙŠØ¸Ù‡Ø± Ø§Ø®ØªØµØ§Ø± Ø¨Ø§Ø³Ù… Â«Ø®Ø·ÙˆØ· Ø¨ØºØ¯Ø§Ø¯Â» Ø¹Ù„Ù‰ Ø§Ù„Ø´Ø§Ø´Ø© Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                height: 1.45,
                color: c.text.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
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
            if (_hint != null) ...[
              const SizedBox(height: 14),
              Text(
                _hint!,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSansArabic(
                  fontSize: 13,
                  height: 1.5,
                  color: c.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

