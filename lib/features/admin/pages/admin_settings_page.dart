import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/auth/admin_auth_controller.dart';
import '../../../core/config/admin_config.dart';
import '../../../core/config/admin_contact.dart';
import '../../../core/pwa/install_app_button.dart';
import '../../../core/theme/app_colors.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _email.text = AdminAuthController.shared.email;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _saveCredentials() async {
    if (_password.text != _password2.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'تأكيد كلمة المرور غير متطابق',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AdminAuthController.shared.updateCredentials(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      _password.clear();
      _password2.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.colors.primary,
          content: Text(
            'تم تحديث بيانات الدخول',
            style: GoogleFonts.ibmPlexSansArabic(
              color: context.colors.onPrimary,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            e is ArgumentError ? e.message.toString() : 'تعذر الحفظ',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'قنوات التواصل مع الإدارة',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'تُستخدم عندما يرسل المستخدم بلاغاً أو شكوى أو مشكلة من التطبيق.',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            color: c.text.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        _InfoTile(
          title: 'واتساب',
          value: AdminContact.whatsappPhone,
        ),
        const SizedBox(height: 8),
        _InfoTile(
          title: 'تلغرام',
          value: AdminContact.telegram,
        ),
        const SizedBox(height: 24),
        Text(
          'بيانات الدخول',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'غيّر البريد وكلمة المرور هنا في أي وقت. تُحفظ محلياً على هذا الجهاز حتى ربط مصادقة خادم لاحقاً.',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            height: 1.45,
            color: c.text.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.ibmPlexSansArabic(),
          decoration: InputDecoration(
            labelText: 'البريد الإلكتروني',
            labelStyle: GoogleFonts.ibmPlexSansArabic(),
            filled: true,
            fillColor: c.surface,
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          obscureText: _obscure,
          style: GoogleFonts.manrope(),
          decoration: InputDecoration(
            labelText: 'كلمة المرور الجديدة',
            labelStyle: GoogleFonts.ibmPlexSansArabic(),
            filled: true,
            fillColor: c.surface,
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
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
          style: GoogleFonts.manrope(),
          decoration: InputDecoration(
            labelText: 'تأكيد كلمة المرور',
            labelStyle: GoogleFonts.ibmPlexSansArabic(),
            filled: true,
            fillColor: c.surface,
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            onPressed: _saving ? null : _saveCredentials,
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              shape: const RoundedRectangleBorder(),
            ),
            child: Text(
              _saving ? 'جاري الحفظ…' : 'حفظ بيانات الدخول',
              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'تثبيت لوحة التحكم',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'أضف اختصاراً على الشاشة الرئيسية يفتح لوحة التحكم مباشرة باسم «تحكم خطوط».',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            height: 1.5,
            color: c.text.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            key: const Key('install_admin_settings_btn'),
            onPressed: () => runInstallAppFlow(context, forAdmin: true),
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              shape: const RoundedRectangleBorder(),
            ),
            icon: const Icon(Icons.app_shortcut_outlined, size: 20),
            label: Text(
              'تثبيت لوحة التحكم على الرئيسية',
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'المظهر',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'بدّل من أيقونة القمر/الشمس في الشريط. اضغط مطوّلاً لاختيار نهاري / ليلي / حسب النظام.',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            height: 1.5,
            color: c.text.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'الرابط المستقل',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        _InfoTile(
          title: 'مسار لوحة التحكم',
          value: '#${AdminConfig.path}',
        ),
        const SizedBox(height: 8),
        Text(
          'مثال: https://yaserkashea-ops.github.io/khutoot-baghdad/#${AdminConfig.path}',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            height: 1.5,
            color: c.text.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ملاحظة',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'البيانات حالياً محلية للتجربة. عند ربط Supabase ستُزامَن الإعلانات والبلاغات مع قاعدة البيانات.',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            height: 1.5,
            color: c.text.withValues(alpha: 0.65),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: c.text.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
