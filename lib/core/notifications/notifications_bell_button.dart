import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/publisher_auth_controller.dart';
import '../theme/app_colors.dart';
import 'match_notify_service.dart';
import 'notification_prefs.dart';
import 'publish_notify_service.dart';
import 'publisher_push_registrar.dart';
import 'web_local_notifications.dart';

/// Shared toggle for publisher system notifications (publish + matches).
Future<void> togglePublisherNotifications(
  BuildContext context, {
  VoidCallback? onBusyChanged,
}) async {
  final prefs = NotificationPrefs.shared;
  if (!prefs.isLoaded) await prefs.load();

  if (prefs.enabled) {
    await prefs.setEnabled(false);
    MatchNotifyService.shared.stop();
    PublishNotifyService.shared.stop();
    await PublisherPushRegistrar.unregister();
    if (context.mounted) {
      _notifyToast(context, 'تم إيقاف الإشعارات');
    }
    return;
  }

  if (!WebLocalNotifications.isSupported) {
    if (!context.mounted) return;
    await _notifyInfoDialog(
      context,
      title: 'الإشعارات غير متاحة',
      body:
          'جهازك أو متصفحك لا يدعم إشعارات النظام. جرّب تثبيت التطبيق أو استخدام كروم على أندرويد.',
    );
    return;
  }

  var permission = WebLocalNotifications.permission;
  if (permission != 'granted') {
    permission = await WebLocalNotifications.requestPermission();
  }
  if (permission != 'granted') {
    if (!context.mounted) return;
    await _notifyInfoDialog(
      context,
      title: 'يلزم السماح بالإشعارات',
      body:
          'فعّل الإشعارات من إعدادات المتصفح لهذا الموقع ثم أعد المحاولة.',
    );
    return;
  }

  final auth = PublisherAuthController.shared;
  if (!auth.isLoaded) await auth.load();
  if (!auth.isLoggedIn) {
    if (context.mounted) {
      _notifyToast(context, 'سجّل الدخول من حسابي لتفعيل الإشعارات');
    }
    return;
  }

  await MatchNotifyService.shared.baselineCurrentMatches();
  await PublishNotifyService.shared.baselineCurrentStatuses();
  await prefs.setEnabled(true);
  MatchNotifyService.shared.start();
  PublishNotifyService.shared.start();

  // Subscribe for true phone-tray push (works while app is closed).
  await PublisherPushRegistrar.register();

  await WebLocalNotifications.show(
    title: 'تم تفعيل إشعارات دليل خطوط بغداد',
    body: 'سنُعلمك عند تفعيل خطك',
    tag: 'khutoot-notify-on',
  );

  if (context.mounted) {
    _notifyToast(context, 'تم تفعيل الإشعارات');
  }
}

void _notifyToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(message, style: GoogleFonts.ibmPlexSansArabic()),
    ),
  );
}

Future<void> _notifyInfoDialog(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        title,
        style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
      ),
      content: Text(
        body,
        style: GoogleFonts.ibmPlexSansArabic(height: 1.45),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('حسناً'),
        ),
      ],
    ),
  );
}

/// AppBar bell icon.
class NotificationsBellButton extends StatefulWidget {
  const NotificationsBellButton({super.key});

  @override
  State<NotificationsBellButton> createState() =>
      _NotificationsBellButtonState();
}

class _NotificationsBellButtonState extends State<NotificationsBellButton> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final prefs = NotificationPrefs.shared;
    if (!prefs.isLoaded) {
      prefs.load();
    }
    prefs.addListener(_onPrefs);
  }

  @override
  void dispose() {
    NotificationPrefs.shared.removeListener(_onPrefs);
    super.dispose();
  }

  void _onPrefs() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await togglePublisherNotifications(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = NotificationPrefs.shared.enabled;
    final c = context.colors;
    return Semantics(
      button: true,
      label: enabled ? 'إيقاف الإشعارات' : 'تفعيل الإشعارات',
      child: IconButton(
        tooltip: enabled ? 'إيقاف الإشعارات' : 'تفعيل الإشعارات',
        onPressed: _busy ? null : _toggle,
        icon: Icon(
          enabled ? Icons.notifications_active : Icons.notifications_none,
          color: enabled ? c.primary : c.text,
        ),
      ),
    );
  }
}

/// Full-width control inside حسابي — hard to miss.
class NotificationsEnableTile extends StatefulWidget {
  const NotificationsEnableTile({super.key});

  @override
  State<NotificationsEnableTile> createState() =>
      _NotificationsEnableTileState();
}

class _NotificationsEnableTileState extends State<NotificationsEnableTile> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final prefs = NotificationPrefs.shared;
    if (!prefs.isLoaded) {
      prefs.load();
    }
    prefs.addListener(_onPrefs);
  }

  @override
  void dispose() {
    NotificationPrefs.shared.removeListener(_onPrefs);
    super.dispose();
  }

  void _onPrefs() {
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await togglePublisherNotifications(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = NotificationPrefs.shared.enabled;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _busy ? null : _toggle,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? c.primary.withValues(alpha: 0.35)
                  : c.border,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: c.primary.withValues(alpha: 0.12),
                child: Icon(
                  enabled
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: c.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled ? 'الإشعارات مفعّلة' : 'تفعيل الإشعارات',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled
                          ? 'سنُعلمك عند تفعيل خطك'
                          : 'اضغط للسماح بإشعارات تفعيل الخط',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        height: 1.35,
                        color: c.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                enabled ? Icons.toggle_on : Icons.toggle_off_outlined,
                size: 36,
                color: enabled ? c.primary : c.text.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
