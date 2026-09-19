import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/publisher_auth_controller.dart';
import '../../core/models/listing_subscription.dart';
import '../../core/theme/app_colors.dart';

/// Publisher accounts (username/phone + password, no OTP).
Future<bool> showPublisherAuthSheet(
  BuildContext context, {
  String? listingIdToClaim,
  String title = 'إنشاء حساب مطلوب لإضافة خطك',
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _PublisherAuthSheet(
      listingIdToClaim: listingIdToClaim,
      title: title,
    ),
  );
  return result == true;
}

class _PublisherAuthSheet extends StatefulWidget {
  const _PublisherAuthSheet({
    this.listingIdToClaim,
    required this.title,
  });

  final String? listingIdToClaim;
  final String title;

  @override
  State<_PublisherAuthSheet> createState() => _PublisherAuthSheetState();
}

class _PublisherAuthSheetState extends State<_PublisherAuthSheet> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _registerMode = true;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final login = _login.text.trim();
    final password = _password.text;
    if (login.length < 3) {
      setState(() => _error = 'اكتب اسماً أو رقماً أوضح (٣ أحرف على الأقل)');
      return;
    }
    if (password.length < 4) {
      setState(() => _error = 'كلمة المرور قصيرة جداً (٤ أحرف على الأقل)');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = PublisherAuthController.shared;
    final ok = _registerMode
        ? await auth.register(login, password)
        : await auth.signIn(login, password);

    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      setState(() => _error = auth.lastError ?? 'تعذر إتمام العملية');
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
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
            widget.title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: c.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'إضافة خط إلى الدليل تتطلب حساباً. من حسابك تتابع المراجعة '
            'وصلاحية الظهور (${ListingSubscription.periodDays} يوماً) وتجديد النشر.',
            style: GoogleFonts.ibmPlexSansArabic(
              fontSize: 13,
              height: 1.4,
              color: c.text.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('أنشئ حساب')),
              ButtonSegment(value: false, label: Text('تسجيل دخول')),
            ],
            selected: {_registerMode},
            onSelectionChanged: (s) {
              setState(() {
                _registerMode = s.first;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _login,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'اسم مستخدم أو رقم هاتف',
              hintText: 'مثال: ahmed أو 07xxxxxxxx',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _submit(),
            autofillHints: _registerMode
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              hintText: '٤ أحرف على الأقل',
              suffixIcon: IconButton(
                tooltip: _obscure ? 'إظهار' : 'إخفاء',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 13,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_registerMode ? 'إنشاء وحفظ' : 'تسجيل دخول'),
          ),
        ],
      ),
    );
  }
}
