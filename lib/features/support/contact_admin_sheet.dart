import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/admin_contact.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/admin_repository.dart';

/// Professional single-sheet report flow (no stacked dialogs).
Future<void> showContactAdminSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _ReportFlowSheet(),
  );
}

enum _ReportStep { pickKind, compose, success }

class _ReportFlowSheet extends StatefulWidget {
  const _ReportFlowSheet();

  @override
  State<_ReportFlowSheet> createState() => _ReportFlowSheetState();
}

class _ReportFlowSheetState extends State<_ReportFlowSheet> {
  final _formKey = GlobalKey<FormState>();
  final _details = TextEditingController();
  final _phone = TextEditingController();
  final _telegram = TextEditingController();

  _ReportStep _step = _ReportStep.pickKind;
  AdminContactKind? _kind;
  bool _submitting = false;
  String? _formError;

  @override
  void dispose() {
    _details.dispose();
    _phone.dispose();
    _telegram.dispose();
    super.dispose();
  }

  void _pickKind(AdminContactKind kind) {
    setState(() {
      _kind = kind;
      _formError = null;
      _step = _ReportStep.compose;
    });
  }

  void _backToKinds() {
    if (_submitting) return;
    setState(() {
      _step = _ReportStep.pickKind;
      _formError = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting || _kind == null) return;
    FocusScope.of(context).unfocus();

    final details = _details.text.trim();
    if (details.isEmpty) {
      setState(() => _formError = 'اكتب تفاصيل ${_kind!.label} أولاً');
      return;
    }

    setState(() {
      _formError = null;
      _submitting = true;
    });

    try {
      final phone = _phone.text.trim();
      final telegram = _telegram.text.trim();
      await AdminRepository.shared.submitReport(
        kind: _kind!,
        message: details,
        contactPhone: phone.isEmpty ? null : phone,
        contactTelegram: telegram.isEmpty ? null : telegram,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _step = _ReportStep.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = 'تعذر الإرسال. تحقق من الاتصال وحاول مجدداً.';
      });
    }
  }

  Future<void> _openExternal(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'تعذر فتح الرابط',
          style: GoogleFonts.ibmPlexSansArabic(),
        ),
      ),
    );
  }

  void _close() {
    if (_submitting) return;
    Navigator.of(context).pop();
  }

  String get _successTitle => switch (_kind) {
        AdminContactKind.report => 'تم إرسال بلاغك',
        AdminContactKind.complaint => 'تم إرسال شكواك',
        AdminContactKind.problem => 'تم إرسال مشكلتك',
        null => 'تم الإرسال',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: switch (_step) {
                    _ReportStep.pickKind => _buildPickKind(c),
                    _ReportStep.compose => _buildCompose(c),
                    _ReportStep.success => _buildSuccess(c),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickKind(MasaratColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'التواصل مع الإدارة',
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: c.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'اختر نوع الرسالة، ثم اكتب التفاصيل في خطوة واحدة.',
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13,
            height: 1.4,
            color: c.text.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        for (final kind in AdminContactKind.values) ...[
          _KindTile(
            title: kind.label,
            subtitle: kind.subtitle,
            icon: switch (kind) {
              AdminContactKind.report => Icons.flag_outlined,
              AdminContactKind.complaint => Icons.report_problem_outlined,
              AdminContactKind.problem => Icons.support_agent_outlined,
            },
            onTap: () => _pickKind(kind),
          ),
          const SizedBox(height: 8),
        ],
        TextButton(
          onPressed: _close,
          child: Text(
            'إغلاق',
            style: GoogleFonts.ibmPlexSansArabic(),
          ),
        ),
      ],
    );
  }

  Widget _buildCompose(MasaratColors c) {
    final kind = _kind!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'رجوع',
                onPressed: _submitting ? null : _backToKinds,
                icon: const Icon(Icons.arrow_forward),
              ),
              Expanded(
                child: Text(
                  kind.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          Text(
            kind.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 12.5,
              height: 1.4,
              color: c.text.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _details,
            enabled: !_submitting,
            maxLines: 5,
            minLines: 4,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            decoration: _fieldDecoration(
              c,
              label: 'التفاصيل',
              hint: 'اكتب ما حدث باختصار ووضوح',
            ),
            onChanged: (_) {
              if (_formError != null) setState(() => _formError = null);
            },
          ),
          const SizedBox(height: 10),
            TextField(
            controller: _phone,
            enabled: !_submitting,
            keyboardType: TextInputType.text,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            decoration: _fieldDecoration(
              c,
              label: 'واتساب (رقم أو يوزر) اختياري',
              hint: '07XXXXXXXXX أو @username',
              prefix: Icons.chat_outlined,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _telegram,
            enabled: !_submitting,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.ibmPlexSansArabic(fontSize: 14),
            decoration: _fieldDecoration(
              c,
              label: 'تلغرام (اختياري)',
              hint: '@username أو رابط',
              prefix: Icons.send_outlined,
            ),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 10),
            Text(
              _formError!,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12.5,
                color: c.riderAccent,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _submitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: c.onPrimary,
                    ),
                  )
                : Text(
                    'إرسال ${kind.label}',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          TextButton(
            onPressed: _submitting ? null : _close,
            child: Text(
              'إلغاء',
              style: GoogleFonts.ibmPlexSansArabic(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(MasaratColors c) {
    final kind = _kind ?? AdminContactKind.report;
    final followUp = AdminContact.messageFor(kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Icon(Icons.check_circle_rounded, color: c.primary, size: 48),
        const SizedBox(height: 12),
        Text(
          _successTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: c.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'وصلت رسالتك إلى لوحة التحكم وسنراجعها قريباً.',
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 13.5,
            height: 1.45,
            color: c.text.withValues(alpha: 0.68),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'متابعة اختيارية',
          textAlign: TextAlign.center,
          style: GoogleFonts.ibmPlexSansArabic(
            fontSize: 12,
            color: c.text.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _openExternal(
            Uri.parse(AdminContact.whatsappUrl(followUp)),
          ),
          icon: const Icon(Icons.chat_outlined, size: 18),
          label: Text(
            'واتساب الإدارة',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.primary,
            side: BorderSide(color: c.primary.withValues(alpha: 0.4)),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _openExternal(Uri.parse(AdminContact.telegram)),
          icon: const Icon(Icons.send_outlined, size: 18),
          label: Text(
            'تلغرام الإدارة',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.primary,
            side: BorderSide(color: c.primary.withValues(alpha: 0.4)),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _close,
          style: FilledButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'تم',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(
    MasaratColors c, {
    required String label,
    required String hint,
    IconData? prefix,
  }) {
    final radius = BorderRadius.circular(10);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
      hintStyle: GoogleFonts.ibmPlexSansArabic(
        fontSize: 12,
        color: c.text.withValues(alpha: 0.38),
      ),
      prefixIcon: prefix == null ? null : Icon(prefix, size: 18),
      isDense: true,
      filled: true,
      fillColor: c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: c.primary),
      ),
    );
  }
}

class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: c.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 12,
                        height: 1.35,
                        color: c.text.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: c.text.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
