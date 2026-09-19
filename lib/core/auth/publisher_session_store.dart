import 'publisher_session_store_stub.dart'
    if (dart.library.js_interop) 'publisher_session_store_web.dart'
    as impl;

/// Device-local publisher session (browser tab + installed PWA on same origin).
class PublisherSessionData {
  const PublisherSessionData({
    required this.token,
    required this.accountId,
    required this.login,
  });

  final String token;
  final String accountId;
  final String login;

  bool get isValid =>
      token.isNotEmpty && accountId.isNotEmpty && login.isNotEmpty;
}

abstract final class PublisherSessionStore {
  static const prefsTokenKey = 'publisher_session_token_v1';
  static const prefsLoginKey = 'publisher_display_login_v1';
  static const prefsAccountIdKey = 'publisher_account_id_v1';
  static const webBundleKey = 'masarat_publisher_session_v1';

  static Future<void> save(PublisherSessionData data) => impl.save(data);

  static Future<PublisherSessionData?> load() => impl.load();

  static Future<void> clear() => impl.clear();
}
