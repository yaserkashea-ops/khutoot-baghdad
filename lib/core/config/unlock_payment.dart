/// Copy + payment details for revealing a rider's contact.
abstract final class UnlockPayment {
  static const amountLabel = '5000 د.ع';
  static const notice = 'رسوم حجز هذا الطلب 5000 د.ع. تواصل مع الإدارة';
  static const availableInvite =
      'هذا الطلب غير محجوز — احجزه للتواصل مع الراكب';
  static const bookedNotice = 'هذا الطلب محجوز حالياً';
  static const bookAction = 'احجز الطلب';

  static String adminBriefMessage({
    required String code,
    required String origin,
    required String destination,
  }) {
    return '$code\n'
        'الانطلاق: $origin\n'
        'الوجهة: $destination\n'
        'طلب حجز والتواصل مع الراكب';
  }
}
