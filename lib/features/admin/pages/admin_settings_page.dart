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
            'ØªØ£ÙƒÙŠØ¯ ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± ØºÙŠØ± Ù…ØªØ·Ø§Ø¨Ù‚',
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
            'ØªÙ… ØªØ­Ø¯ÙŠØ« Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø¯Ø®ÙˆÙ„',
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
            e is ArgumentError ? e.message.toString() : 'ØªØ¹Ø°Ø± Ø§Ù„Ø­ÙØ¸',
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
          'Ù‚Ù†ÙˆØ§Øª Ø§Ù„ØªÙˆØ§ØµÙ„ Ù…Ø¹ Ø§Ù„Ø¥Ø¯Ø§Ø±Ø©',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ØªÙØ³ØªØ®Ø¯Ù… Ø¹Ù†Ø¯Ù…Ø§ ÙŠØ±Ø³Ù„ Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… Ø¨Ù„Ø§ØºØ§Ù‹ Ø£Ùˆ Ø´ÙƒÙˆÙ‰ Ø£Ùˆ Ù…Ø´ÙƒÙ„Ø© Ù…Ù† Ø§Ù„ØªØ·Ø¨ÙŠÙ‚.',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            color: c.text.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        _InfoTile(
          title: 'ÙˆØ§ØªØ³Ø§Ø¨',
          value: AdminContact.whatsappPhone,
        ),
        const SizedBox(height: 8),
        _InfoTile(
          title: 'ØªÙ„ØºØ±Ø§Ù…',
          value: AdminContact.telegram,
        ),
        const SizedBox(height: 24),
        Text(
          'Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø¯Ø®ÙˆÙ„',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ØºÙŠÙ‘Ø± Ø§Ù„Ø¨Ø±ÙŠØ¯ ÙˆÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ù‡Ù†Ø§ ÙÙŠ Ø£ÙŠ ÙˆÙ‚Øª. ØªÙØ­ÙØ¸ Ù…Ø­Ù„ÙŠØ§Ù‹ Ø¹Ù„Ù‰ Ù‡Ø°Ø§ Ø§Ù„Ø¬Ù‡Ø§Ø² Ø­ØªÙ‰ Ø±Ø¨Ø· Ù…ØµØ§Ø¯Ù‚Ø© Ø®Ø§Ø¯Ù… Ù„Ø§Ø­Ù‚Ø§Ù‹.',
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
            labelText: 'Ø§Ù„Ø¨Ø±ÙŠØ¯ Ø§Ù„Ø¥Ù„ÙƒØªØ±ÙˆÙ†ÙŠ',
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
            labelText: 'ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ± Ø§Ù„Ø¬Ø¯ÙŠØ¯Ø©',
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
            labelText: 'ØªØ£ÙƒÙŠØ¯ ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±',
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
              _saving ? 'Ø¬Ø§Ø±ÙŠ Ø§Ù„Ø­ÙØ¸â€¦' : 'Ø­ÙØ¸ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø¯Ø®ÙˆÙ„',
              style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ØªØ«Ø¨ÙŠØª Ù„ÙˆØ­Ø© Ø§Ù„ØªØ­ÙƒÙ…',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ø£Ø¶Ù Ø§Ø®ØªØµØ§Ø±Ø§Ù‹ Ø¹Ù„Ù‰ Ø§Ù„Ø´Ø§Ø´Ø© Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ© ÙŠÙØªØ­ Ù„ÙˆØ­Ø© Ø§Ù„ØªØ­ÙƒÙ… Ù…Ø¨Ø§Ø´Ø±Ø© Ø¨Ø§Ø³Ù… Â«ØªØ­ÙƒÙ… Ø®Ø·ÙˆØ·Â».',
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
              'ØªØ«Ø¨ÙŠØª Ù„ÙˆØ­Ø© Ø§Ù„ØªØ­ÙƒÙ… Ø¹Ù„Ù‰ Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©',
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ø§Ù„Ù…Ø¸Ù‡Ø±',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ø¨Ø¯Ù‘Ù„ Ù…Ù† Ø£ÙŠÙ‚ÙˆÙ†Ø© Ø§Ù„Ù‚Ù…Ø±/Ø§Ù„Ø´Ù…Ø³ ÙÙŠ Ø§Ù„Ø´Ø±ÙŠØ·. Ø§Ø¶ØºØ· Ù…Ø·ÙˆÙ‘Ù„Ø§Ù‹ Ù„Ø§Ø®ØªÙŠØ§Ø± Ù†Ù‡Ø§Ø±ÙŠ / Ù„ÙŠÙ„ÙŠ / Ø­Ø³Ø¨ Ø§Ù„Ù†Ø¸Ø§Ù….',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            height: 1.5,
            color: c.text.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ø§Ù„Ø±Ø§Ø¨Ø· Ø§Ù„Ù…Ø³ØªÙ‚Ù„',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        _InfoTile(
          title: 'Ù…Ø³Ø§Ø± Ù„ÙˆØ­Ø© Ø§Ù„ØªØ­ÙƒÙ…',
          value: '/admin',
        ),
        const SizedBox(height: 8),
        Text(
          'Ù…Ø«Ø§Ù„: https://khutoot-baghdad.web.app/admin',
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            height: 1.5,
            color: c.text.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ù…Ù„Ø§Ø­Ø¸Ø©',
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø­Ø§Ù„ÙŠØ§Ù‹ Ù…Ø­Ù„ÙŠØ© Ù„Ù„ØªØ¬Ø±Ø¨Ø©. Ø¹Ù†Ø¯ Ø±Ø¨Ø· Supabase Ø³ØªÙØ²Ø§Ù…ÙŽÙ† Ø§Ù„Ø¥Ø¹Ù„Ø§Ù†Ø§Øª ÙˆØ§Ù„Ø¨Ù„Ø§ØºØ§Øª Ù…Ø¹ Ù‚Ø§Ø¹Ø¯Ø© Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª.',
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

