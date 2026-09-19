import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import 'publisher_session_store.dart';

Future<void> save(PublisherSessionData data) async {
  final prefs = await SharedPreferences.getInstance();
  await Future.wait([
    prefs.setString(PublisherSessionStore.prefsTokenKey, data.token),
    prefs.setString(PublisherSessionStore.prefsAccountIdKey, data.accountId),
    prefs.setString(PublisherSessionStore.prefsLoginKey, data.login),
  ]);

  final payload = jsonEncode({
    'token': data.token,
    'account_id': data.accountId,
    'login': data.login,
  });
  try {
    web.window.localStorage.setItem(
      PublisherSessionStore.webBundleKey,
      payload,
    );
  } catch (_) {}

  try {
    final encoded = Uri.encodeComponent(payload);
    // Same-site cookie so browser + installed PWA on this origin can share.
    web.document.cookie =
        '${PublisherSessionStore.webBundleKey}=$encoded; path=/; max-age=${400 * 24 * 60 * 60}; SameSite=Lax';
  } catch (_) {}
}

Future<PublisherSessionData?> load() async {
  final fromPrefs = await _fromPrefs();
  if (fromPrefs != null) return fromPrefs;

  final fromLocal = _fromLocalStorage();
  if (fromLocal != null) {
    await save(fromLocal);
    return fromLocal;
  }

  final fromCookie = _fromCookie();
  if (fromCookie != null) {
    await save(fromCookie);
    return fromCookie;
  }
  return null;
}

Future<void> clear() async {
  final prefs = await SharedPreferences.getInstance();
  await Future.wait([
    prefs.remove(PublisherSessionStore.prefsTokenKey),
    prefs.remove(PublisherSessionStore.prefsAccountIdKey),
    prefs.remove(PublisherSessionStore.prefsLoginKey),
  ]);
  try {
    web.window.localStorage.removeItem(PublisherSessionStore.webBundleKey);
  } catch (_) {}
  try {
    web.document.cookie =
        '${PublisherSessionStore.webBundleKey}=; path=/; max-age=0; SameSite=Lax';
  } catch (_) {}
}

Future<PublisherSessionData?> _fromPrefs() async {
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

PublisherSessionData? _fromLocalStorage() {
  try {
    final raw =
        web.window.localStorage.getItem(PublisherSessionStore.webBundleKey);
    return _parse(raw);
  } catch (_) {
    return null;
  }
}

PublisherSessionData? _fromCookie() {
  try {
    final all = web.document.cookie;
    final prefix = '${PublisherSessionStore.webBundleKey}=';
    for (final part in all.split(';')) {
      final s = part.trim();
      if (!s.startsWith(prefix)) continue;
      final encoded = s.substring(prefix.length);
      return _parse(Uri.decodeComponent(encoded));
    }
  } catch (_) {}
  return null;
}

PublisherSessionData? _parse(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final map = jsonDecode(raw);
    if (map is! Map) return null;
    final token = map['token']?.toString() ?? '';
    final accountId = map['account_id']?.toString() ?? '';
    final login = map['login']?.toString() ?? '';
    final data = PublisherSessionData(
      token: token,
      accountId: accountId,
      login: login,
    );
    return data.isValid ? data : null;
  } catch (_) {
    return null;
  }
}
