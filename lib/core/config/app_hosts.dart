/// روابط النشر النهائية — مصدر واحد لكل الواجهات والـ PWA.
abstract final class AppHosts {
  /// الأداة العامة (خطوط بغداد).
  static const publicOrigin = 'https://khutoot-baghdad.web.app';
  static const publicUrl = '$publicOrigin/';

  /// لوحة التحكم (نطاق منفصل حتى لا يفتحها كروم داخل التطبيق المثبت).
  static const adminOrigin = 'https://khutoot-baghdad-admin.web.app';
  static const adminUrl = '$adminOrigin/';
  static const adminHost = 'khutoot-baghdad-admin.web.app';

  /// يظهر في الواجهة للتأكد أن النسخة وصلت للجهاز.
  static const buildLabel = '14';

  /// هل الصفحة الحالية على موقع لوحة التحكم؟
  static bool get isAdminHost {
    final host = Uri.base.host.toLowerCase();
    if (host == adminHost) return true;
    if (Uri.base.queryParameters['mode'] == 'admin') return true;
    return false;
  }
}
