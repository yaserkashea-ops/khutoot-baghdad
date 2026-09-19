/// Limits for publisher accounts.
abstract final class PublisherLimits {
  static const maxActiveListings = 3;

  static String get limitReachedMessage =>
      'يمكنك نشر $maxActiveListings منشورات فقط في نفس الوقت. '
      'احذف أحد منشوراتك الحالية ثم أضف منشوراً جديداً.';
}
