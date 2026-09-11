/// Result of attempting the OS / browser share sheet.
enum NativeShareOutcome {
  /// User completed a share action (or the sheet opened successfully).
  shared,

  /// User dismissed the system sheet without sharing.
  dismissed,

  /// System share is not available on this device/browser.
  unavailable,
}

/// Non-web stub — always unavailable so callers can use another path.
abstract final class NativeShare {
  static Future<NativeShareOutcome> share({
    required String title,
    required String text,
    required String url,
  }) async {
    return NativeShareOutcome.unavailable;
  }
}
