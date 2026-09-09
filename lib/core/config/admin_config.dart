import 'app_hosts.dart';

/// Admin credentials & routes. Defaults can be overridden later from الإعدادات.
abstract final class AdminConfig {
  static const title = 'لوحة تحكم خطوط بغداد';
  static const shortName = 'تحكم خطوط';

  /// مسار داخلي (hash) داخل موقع لوحة التحكم.
  static const path = '/admin';

  /// أصل/رابط لوحة التحكم المنشور.
  static const publicOrigin = AppHosts.adminOrigin;
  static const publicUrl = AppHosts.adminUrl;

  /// القيم الابتدائية — غيّرها لاحقاً من الإعدادات أو من هنا قبل النشر.
  static const defaultEmail = 'admin@masarat.local';
  static const defaultPassword = 'Masarat@2026';
}
