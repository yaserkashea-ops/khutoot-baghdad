/// Admin credentials & routes. Defaults can be overridden later from الإعدادات.
abstract final class AdminConfig {
  static const title = 'لوحة تحكم خطوط بغداد';
  static const shortName = 'تحكم خطوط';

  /// رابط مستقل عن الأداة العامة.
  static const path = '/admin';

  /// القيم الابتدائية — غيّرها لاحقاً من الإعدادات أو من هنا قبل النشر.
  static const defaultEmail = 'admin@masarat.local';
  static const defaultPassword = 'Masarat@2026';
}
