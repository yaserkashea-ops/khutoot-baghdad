import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Admin contact channels for reports / complaints / issues.
/// Defaults are constants; live values load from Supabase `app_settings`.
class AdminContact extends ChangeNotifier {
  AdminContact._();
  static final AdminContact shared = AdminContact._();

  static const _defaultWhatsapp = '9647760000989';
  static const _defaultTelegram = 'https://t.me/Opal10';

  String _whatsappPhone = _defaultWhatsapp;
  String _telegram = _defaultTelegram;
  bool _loaded = false;

  /// Digits only, country code included (Iraq example).
  static String get whatsappPhone => shared._whatsappPhone;

  /// Telegram username or full t.me link.
  static String get telegram => shared._telegram;

  bool get isLoaded => _loaded;
  String get whatsappPhoneValue => _whatsappPhone;
  String get telegramValue => _telegram;

  static String whatsappUrl(String message) {
    final encoded = Uri.encodeComponent(message);
    return 'https://wa.me/$whatsappPhone?text=$encoded';
  }

  static String messageFor(AdminContactKind kind) {
    return switch (kind) {
      AdminContactKind.report =>
        'مرحباً، أود تقديم بلاغ عبر أداة خطوط بغداد.',
      AdminContactKind.complaint =>
        'مرحباً، أود تقديم شكوى عبر أداة خطوط بغداد.',
      AdminContactKind.problem =>
        'مرحباً، أواجه مشكلة في أداة خطوط بغداد وأحتاج مساعدة الإدارة.',
    };
  }

  Future<void> refresh() async {
    if (!SupabaseConfig.isConfigured) {
      _loaded = true;
      return;
    }
    try {
      final client = Supabase.instance.client;
      final raw = await client.rpc('get_app_settings');
      final map = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      final wa = '${map['whatsapp_phone'] ?? ''}'.trim();
      final tg = '${map['telegram'] ?? ''}'.trim();
      if (wa.isNotEmpty) _whatsappPhone = wa.replaceAll(RegExp(r'\D'), '');
      if (tg.isNotEmpty) _telegram = tg;
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Table/RPC may not exist yet — keep defaults.
      _loaded = true;
    }
  }

  Future<void> save({
    required String whatsappPhone,
    required String telegram,
  }) async {
    final wa = whatsappPhone.replaceAll(RegExp(r'\D'), '').trim();
    final tg = telegram.trim();
    if (wa.length < 8) {
      throw ArgumentError('رقم واتساب غير صالح');
    }
    if (tg.isEmpty) {
      throw ArgumentError('رابط أو يوزر تلغرام مطلوب');
    }

    if (!SupabaseConfig.isConfigured) {
      throw StateError('Supabase غير مُعد');
    }
    final client = Supabase.instance.client;
    await client.rpc(
      'admin_set_app_setting',
      params: {'p_key': 'whatsapp_phone', 'p_value': wa},
    );
    await client.rpc(
      'admin_set_app_setting',
      params: {'p_key': 'telegram', 'p_value': tg},
    );
    _whatsappPhone = wa;
    _telegram = tg;
    notifyListeners();
  }
}

enum AdminContactKind {
  report,
  complaint,
  problem,
}

extension AdminContactKindLabel on AdminContactKind {
  String get label => switch (this) {
        AdminContactKind.report => 'بلاغ',
        AdminContactKind.complaint => 'شكوى',
        AdminContactKind.problem => 'مشكلة',
      };

  String get subtitle => switch (this) {
        AdminContactKind.report => 'الإبلاغ عن إعلان مخالف أو سلوك مسيء',
        AdminContactKind.complaint => 'تقديم شكوى بخصوص خدمة أو منشور',
        AdminContactKind.problem => 'مشكلة تقنية أو صعوبة في استخدام الأداة',
      };
}
