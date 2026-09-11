import 'package:flutter/material.dart';

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
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (_password.text != _password2.text) {
      _toast('تأكيد كلمة المرور غير متطابق');
      return;
    }
    setState(() => _saving = true);
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
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message, {bool ok = false}) {
    final c = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? c.primary : null,
        content: Text(message),
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
        _InfoTile(title: 'البريد الحالي', value: email.isEmpty ? '—' : email),
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
            onPressed: _saving ? null : _savePassword,
            child: Text(_saving ? 'جاري الحفظ…' : 'حفظ كلمة المرور'),
          ),
        ),
        const SizedBox(height: 28),
        Text('التواصل مع الإدارة', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _InfoTile(title: 'واتساب', value: AdminContact.whatsappPhone),
        const SizedBox(height: 8),
        _InfoTile(title: 'تلغرام', value: AdminContact.telegram),
        const SizedBox(height: 28),
        Text('الروابط', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _InfoTile(title: 'الأداة العامة', value: AppHosts.publicUrl),
        const SizedBox(height: 8),
        _InfoTile(title: 'لوحة التحكم', value: AppHosts.adminUrl),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border.withValues(alpha: 0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: c.text.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
