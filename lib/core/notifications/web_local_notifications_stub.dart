/// Local / system notifications bridge (non-web stub).
abstract final class WebLocalNotifications {
  static bool get isSupported => false;

  static String get permission => 'denied';

  static Future<String> requestPermission() async => 'denied';

  static Future<bool> show({
    required String title,
    required String body,
    String? tag,
  }) async =>
      false;
}
