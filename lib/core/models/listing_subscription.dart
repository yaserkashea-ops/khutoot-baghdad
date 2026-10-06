/// Directory listing visibility window (paid publish / renew).
abstract final class ListingSubscription {
  static const int periodDays = 30;

  static DateTime expiresFrom(DateTime start) =>
      start.add(const Duration(days: periodDays));

  static DateTime renewFromNow([DateTime? now]) =>
      expiresFrom(now ?? DateTime.now());

  /// Driver-facing note: 30-day visibility then renew (no fee wording).
  static String get driverVisibilityNote =>
      'يظهر المنشور في الدليل ويُعتمد آخر تحديث.';

  static String get driverVisibilityShort =>
      'الاعتماد على آخر تحديث';
}
