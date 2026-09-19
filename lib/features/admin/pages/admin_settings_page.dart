import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/admin_auth_controller.dart';
import '../../../core/config/admin_contact.dart';
import '../../../core/config/app_hosts.dart';
import '../../../core/theme/app_colors.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  final _whatsapp = TextEditingController();
  final _telegram = TextEditingController();
  bool _obscure = true;
  bool _savingPassword = false;
  bool _savingContact = false;
  bool _loadingContact = true;

  @override
  void initState() {
    super.initState();
    _whatsapp.text = AdminContact.shared.whatsappPhoneValue;
    _telegram.text = AdminContact.shared.telegramValue;
    _loadContact();
  }

  @override
  void dispose() {
    _password.dispose();
    _password2.dispose();
    _whatsapp.dispose();
    _telegram.dispose();
    super.dispose();
  }

  Future<void> _loadContact() async {
    setState(() => _loadingContact = true);
    await AdminContact.shared.refresh();
    if (!mounted) return;
    setState(() {
      _whatsapp.text = AdminContact.shared.whatsappPhoneValue;
      _telegram.text = AdminContact.shared.telegramValue;
      _loadingContact = false;
    });
  }

  Future<void> _savePassword() async {
    if (_password.text != _password2.text) {
      _toast('تأكيد كلمة المرور غير متطابق');
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await AdminAuthController.shared.updatePassword(_password.text);
      if (!mounted) return;
      _password.clear();
      _password2.clear();
      _toast('تم تحديث كلمة المرور', ok: true);
    } catch (e) {
      if (!mounted) return;
      _toast(e is ArgumentError ? e.message.toString() : 'تعذر الحفظ');
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _saveContact() async {
    setState(() => _savingContact = true);
    try {
      await AdminContact.shared.save(
        whatsappPhone: _whatsapp.text,
        telegram: _telegram.text,
      );
      if (!mounted) return;
      _toast('تم حفظ وسائل التواصل', ok: true);
    } catch (e) {
      if (!mounted) return;
      final msg = '$e';
      if (msg.contains('واتساب') || msg.contains('تلغرام')) {
        _toast(e is ArgumentError ? e.message.toString() : msg);
      } else if (msg.contains('PGRST') || msg.contains('404')) {
        _toast('نفّذ migrate_app_settings.sql في Supabase أولاً');
      } else {
        _toast(e is ArgumentError ? e.message.toString() : 'تعذر الحفظ');
      }
    } finally {
      if (mounted) setState(() => _savingContact = false);
    }
  }

  Future<void> _copy(String label, String value) async {
    final text = value.trim();
    if (text.isEmpty) {
      _toast('لا يوجد نص للنسخ');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _toast('تم نسخ $label', ok: true);
  }

  void _toast(String message, {bool ok = false}) {
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? c.primary : null,
        content: Text(message, style: GoogleFonts.ibmPlexSansArabic()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final email = AdminAuthController.shared.email;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('الحساب', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'المصادقة عبر Supabase Auth. البريد يُدار من لوحة Supabase.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: c.text.withValues(alpha: 0.55),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        _CopyableField(
          label: 'البريد الحالي',
          value: email.isEmpty ? '—' : email,
          onCopy: email.isEmpty ? null : () => _copy('البريد', email),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'كلمة المرور الجديدة',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _password2,
          obscureText: _obscure,
          decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            onPressed: _savingPassword ? null : _savePassword,
            child: Text(_savingPassword ? 'جاري الحفظ…' : 'حفظ كلمة المرور'),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text('التواصل مع الإدارة', style: theme.textTheme.titleMedium),
            const Spacer(),
            if (_loadingContact)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'عدّل الرقم والرابط هنا — يظهران مباشرة في نموذج تواصل المستخدمين.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: c.text.withValues(alpha: 0.55),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _whatsapp,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'واتساب (مع رمز الدولة)',
            hintText: '9647XXXXXXXXX',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: c.surface,
            suffixIcon: IconButton(
              tooltip: 'نسخ',
              onPressed: () => _copy('واتساب', _whatsapp.text),
              icon: const Icon(Icons.copy_outlined, size: 18),
            ),
          ),
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _telegram,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'تلغرام (رابط أو يوزر)',
            hintText: 'https://t.me/username',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: c.surface,
            suffixIcon: IconButton(
              tooltip: 'نسخ',
              onPressed: () => _copy('تلغرام', _telegram.text),
              icon: const Icon(Icons.copy_outlined, size: 18),
            ),
          ),
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            onPressed: _savingContact ? null : _saveContact,
            child: Text(
              _savingContact ? 'جاري الحفظ…' : 'حفظ وسائل التواصل',
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('الروابط', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _CopyableField(
          label: 'الأداة العامة',
          value: AppHosts.publicUrl,
          onCopy: () => _copy('رابط الأداة', AppHosts.publicUrl),
        ),
        const SizedBox(height: 8),
        _CopyableField(
          label: 'لوحة التحكم',
          value: AppHosts.adminUrl,
          onCopy: () => _copy('رابط لوحة التحكم', AppHosts.adminUrl),
        ),
        const SizedBox(height: 8),
        Text(
          'نسخة التطبيق ${AppHosts.buildLabel}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: c.text.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _CopyableField extends StatelessWidget {
  const _CopyableField({
    required this.label,
    required this.value,
    this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border.withValues(alpha: 0.9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: c.text.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: 'نسخ',
              onPressed: onCopy,
              icon: Icon(
                Icons.copy_outlined,
                size: 18,
                color: c.text.withValues(alpha: 0.55),
              ),
            ),
        ],
      ),
    );
  }
}
