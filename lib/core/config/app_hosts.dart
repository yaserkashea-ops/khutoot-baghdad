/// روابط النشر النهائية — مصدر واحد لكل الواجهات والـ PWA.
abstract final class AppHosts {
  /// الأداة العامة (خطوط بغداد) — آيفون والويب.
  static const publicOrigin = 'https://khutoot-baghdad.web.app';
  static const publicUrl = '$publicOrigin/';

  /// تحميل APK لأندرويد فقط (صفحة منفصلة عن الرابط الأصلي).
  static const androidDownloadOrigin = 'https://khutoot-baghdad-app.web.app';
  static const androidDownloadUrl = '$androidDownloadOrigin/';
  static const androidApkUrl =
      'https://github.com/yaserkashea-ops/khutoot-baghdad/releases/download/android-v1.0.0/khutoot-baghdad-1.0.0.apk';

  /// لوحة التحكم (نطاق منفصل حتى لا يفتحها كروم داخل التطبيق المثبت).
  static const adminOrigin = 'https://khutoot-baghdad-admin.web.app';
  static const adminUrl = '$adminOrigin/';
  static const adminHost = 'khutoot-baghdad-admin.web.app';

  /// يظهر في الواجهة للتأكد أن النسخة وصلت للجهاز.
  static const buildLabel = '221';

  /// هل الصفحة الحالية على موقع لوحة التحكم؟
  static bool get isAdminHost {
    final host = Uri.base.host.toLowerCase();
    if (host == adminHost) return true;
    // قنوات Firebase التجريبية: khutoot-baghdad-admin--trial-….web.app
    if (host.contains('khutoot-baghdad-admin')) return true;
    if (Uri.base.queryParameters['mode'] == 'admin') return true;
    return false;
  }
}
