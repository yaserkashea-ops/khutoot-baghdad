/// Non-web stub — push unavailable.
abstract final class WebPush {
  static bool get isSupported => false;

  static Future<Map<String, String>?> subscribe({
    required String vapidPublicKey,
  }) async =>
      null;

  static Future<void> unsubscribe() async {}
}
