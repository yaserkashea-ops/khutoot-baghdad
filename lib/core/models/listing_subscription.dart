/// Directory listing visibility window (paid publish / renew).
abstract final class ListingSubscription {
  static const int periodDays = 30;

  static DateTime expiresFrom(DateTime start) =>
      start.add(const Duration(days: periodDays));

  static DateTime renewFromNow([DateTime? now]) =>
      expiresFrom(now ?? DateTime.now());

  /// Driver-facing note: 30-day visibility then renew (no fee wording).
  static String get driverVisibilityNote =>
      'صلاحية ظهور الخط في الدليل $periodDays يوماً من تاريخ النشر، '
      'وبعدها عليك تجديد النشر ليبقى ظاهراً.';

  static String get driverVisibilityShort =>
      'الظهور لمدة $periodDays يوماً ثم تجديد النشر';
}
