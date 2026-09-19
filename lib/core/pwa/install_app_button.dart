import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'app_install_tracker.dart';
import 'pwa_install.dart';

bool _installSheetOpen = false;

/// Always opens the install sheet. Native Chrome install runs from the HTML
/// hit-target button (preserves the required user gesture).
Future<void> runInstallAppFlow(
  BuildContext context, {
  bool forAdmin = false,
  bool preferSheet = false,
}) async {
  if (PwaInstall.isStandalone) return;

  if (forAdmin) {
    if (!PwaInstall.isAdminEntry && PwaInstall.openAdminEntry()) {
      return;
    }
    PwaInstall.setMode('admin');
  }

  if (!context.mounted) return;
  await _showInstallSheet(context, forAdmin: forAdmin);
}

Future<void> _showInstallSheet(
  BuildContext context, {
  required bool forAdmin,
}) async {
  if (!context.mounted) return;
  if (_installSheetOpen) return;
  _installSheetOpen = true;
  try {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isDismissible: true,
      isScrollControlled: true,
      builder: (ctx) => _InstallNowSheet(forAdmin: forAdmin),
    );
  } finally {
    _installSheetOpen = false;
    PwaInstall.hideNativeInstallButton();
  }
}

class InstallAppIconButton extends StatefulWidget {
  const InstallAppIconButton({
    super.key,
    this.forAdmin = false,
  });

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

class _InstallNowSheet extends StatefulWidget {
  const _InstallNowSheet({this.forAdmin = false});

  final bool forAdmin;

  @override
  State<_InstallNowSheet> createState() => _InstallNowSheetState();
}

class _InstallNowSheetState extends State<_InstallNowSheet> {
  String? _hint;
  StreamSubscription<void>? _stateSub;
  StreamSubscription<String>? _outcomeSub;
  final GlobalKey _buttonSlotKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _stateSub = PwaInstall.onStateChanged.listen((_) {
      if (!mounted) return;
      setState(() {});
      _syncNativeButton();
    });
    _outcomeSub = PwaInstall.onInstallOutcome.listen(_onNativeOutcome);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncNativeButton();
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (mounted) _syncNativeButton();
      });
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _outcomeSub?.cancel();
    PwaInstall.hideNativeInstallButton();
    super.dispose();
  }

  String get _buttonLabel =>
      widget.forAdmin ? 'تثبيت لوحة التحكم' : 'تثبيت الآن';

  void _syncNativeButton() {
    if (!mounted) return;
    final box = _buttonSlotKey.currentContext?.findRenderObject() as RenderBox?;
    var bottom = 88.0;
    if (box != null && box.hasSize) {
      final offset = box.localToGlobal(Offset.zero);
      final screenH = MediaQuery.sizeOf(context).height;
      bottom = (screenH - offset.dy - box.size.height).clamp(24.0, 220.0);
    }
    // Always show the DOM button so a real click can call Chrome's prompt().
    PwaInstall.showNativeInstallButton(
      label: _buttonLabel,
      bottomPx: bottom,
    );
  }

  Future<void> _onNativeOutcome(String outcome) async {
    if (!mounted) return;
    if (outcome == 'accepted') {
      unawaited(
        AppInstallTracker.recordAfterAccepted(
          source: widget.forAdmin ? 'admin' : 'app',
        ),
      );
      PwaInstall.hideNativeInstallButton();
      Navigator.pop(context);
      return;
    }
    if (outcome == 'ready') {
      setState(() {
        _hint = 'جاهز للتثبيت — اضغط «تثبيت الآن» مرة أخرى.';
      });
      _syncNativeButton();
      return;
    }
    if (outcome == 'dismissed') {
      setState(() {
        _hint = 'أُلغي التثبيت. يمكنك الضغط على «تثبيت الآن» مجدداً.';
      });
      _syncNativeButton();
      return;
    }
    setState(() {
      _hint = PwaInstall.isIos
          ? 'على iPhone: من Safari اضغط المشاركة ثم «إضافة إلى الشاشة الرئيسية».'
          : 'إن لم تظهر نافذة التثبيت: من Chrome اضغط ⋮ ثم «تثبيت التطبيق».';
    });
    _syncNativeButton();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = widget.forAdmin ? 'تثبيت لوحة التحكم' : 'تثبيت التطبيق';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط «تثبيت الآن» لتظهر نافذة التثبيت من المتصفح.',
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                height: 1.45,
                color: c.text.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              key: _buttonSlotKey,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _buttonLabel,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: c.primary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                PwaInstall.hideNativeInstallButton();
                Navigator.pop(context);
              },
              child: Text(
                'لاحقاً',
                style: GoogleFonts.ibmPlexSansArabic(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_hint != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _hint!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    height: 1.55,
                    color: c.text.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
