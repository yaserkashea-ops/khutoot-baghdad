/// Non-web stub.
class PwaInstall {
  static bool get isStandalone => false;
  static bool get canNativeInstall => false;
  static bool get isIos => false;
  static bool get isMobile => false;

  static Stream<void> get onStateChanged => const Stream.empty();

  static void setMode(String mode) {}

  static bool ensureAdminHash() => false;`r`n`r`n  static bool get isAdminEntry => false;`r`n`r`n  static bool openAdminEntry() => false;

  static Future<bool> waitForPrompt({
    Duration timeout = const Duration(milliseconds: 2500),
  }) async =>
      false;

  static Future<String> promptInstall() async => 'unavailable';
}

