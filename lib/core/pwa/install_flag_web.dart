import 'package:web/web.dart' as web;

abstract final class InstallFlag {
  static const _justInstalledSession = 'khutoot_just_installed';
  static const _justInstalledLs = 'khutoot_just_installed_ls';
  static const installKeyLs = 'khutoot_install_key';
  static const recordedLs = 'khutoot_install_recorded_v1';

  static bool consumeJustInstalled() {
    var hit = false;
    try {
      final flag = web.window.sessionStorage.getItem(_justInstalledSession);
      if (flag == '1') {
        web.window.sessionStorage.removeItem(_justInstalledSession);
        hit = true;
      }
    } catch (_) {}
    try {
      final flag = web.window.localStorage.getItem(_justInstalledLs);
      if (flag == '1') {
        web.window.localStorage.removeItem(_justInstalledLs);
        hit = true;
      }
    } catch (_) {}
    return hit;
  }

  static bool get isRecordedInBrowser {
    try {
      return web.window.localStorage.getItem(recordedLs) == '1';
    } catch (_) {
      return false;
    }
  }

  static void markRecordedInBrowser() {
    try {
      web.window.localStorage.setItem(recordedLs, '1');
    } catch (_) {}
  }

  static String? readInstallKey() {
    try {
      final k = web.window.localStorage.getItem(installKeyLs);
      if (k != null && k.length >= 8) return k;
    } catch (_) {}
    return null;
  }

  static void writeInstallKey(String key) {
    try {
      web.window.localStorage.setItem(installKeyLs, key);
    } catch (_) {}
  }

  static String? readUserAgent() {
    try {
      final ua = web.window.navigator.userAgent;
      return ua.isEmpty ? null : ua;
    } catch (_) {
      return null;
    }
  }
}
