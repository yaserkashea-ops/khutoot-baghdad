/// Web Push (VAPID) public config for phone notification tray.
abstract final class PushConfig {
  /// VAPID public key (safe to embed in the client).
  static const vapidPublicKey =
      'BHDfkVDS2xDDfXScUxFBvI8EAJZbfq5E50RUwWNOhKSahTd1v5HCNamN2IcIZZ1-kA2O49Tbucelg6N706x5zTc';

  static const vapidSubject = 'mailto:admin@khutoot-baghdad.web.app';
}
