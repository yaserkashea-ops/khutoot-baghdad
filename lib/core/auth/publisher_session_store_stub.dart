import 'package:shared_preferences/shared_preferences.dart';

import 'publisher_session_store.dart';

Future<void> save(PublisherSessionData data) async {
  final prefs = await SharedPreferences.getInstance();
  await Future.wait([
    prefs.setString(PublisherSessionStore.prefsTokenKey, data.token),
    prefs.setString(PublisherSessionStore.prefsAccountIdKey, data.accountId),
    prefs.setString(PublisherSessionStore.prefsLoginKey, data.login),
  ]);
}

Future<PublisherSessionData?> load() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(PublisherSessionStore.prefsTokenKey);
  final accountId = prefs.getString(PublisherSessionStore.prefsAccountIdKey);
  final login = prefs.getString(PublisherSessionStore.prefsLoginKey);
  if (token == null ||
      token.isEmpty ||
      accountId == null ||
      accountId.isEmpty ||
      login == null ||
      login.isEmpty) {
    return null;
  }
  return PublisherSessionData(
    token: token,
    accountId: accountId,
    login: login,
  );
}

Future<void> clear() async {
  final prefs = await SharedPreferences.getInstance();
  await Future.wait([
    prefs.remove(PublisherSessionStore.prefsTokenKey),
    prefs.remove(PublisherSessionStore.prefsAccountIdKey),
    prefs.remove(PublisherSessionStore.prefsLoginKey),
  ]);
}
