/// Soft-launch switches for the public directory.
abstract final class DirectoryLaunch {
  /// Hide fee / payment wording from drivers and public UI while the
  /// directory grows. Flip to `false` when monetization messaging returns.
  static const hidePaymentCopy = true;

  /// Show rider WhatsApp/Telegram in the directory with no booking fee.
  /// Flip to `false` to restore paid unlock.
  static const freeRiderContacts = true;
}
