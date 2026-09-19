abstract final class InstallFlag {
  static bool consumeJustInstalled() => false;

  static bool get isRecordedInBrowser => false;

  static void markRecordedInBrowser() {}

  static String? readInstallKey() => null;

  static void writeInstallKey(String key) {}

  static String? readUserAgent() => null;
}
