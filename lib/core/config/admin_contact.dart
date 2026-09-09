/// Admin contact channels for reports / complaints / issues.
/// Replace placeholders with real numbers before production.
abstract final class AdminContact {
  /// Digits only, country code included (Iraq example).
  static const whatsappPhone = '9647700000000';

  /// Optional Telegram username or full t.me link.
  static const telegram = 'https://t.me/khutut_baghdad_admin';

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
