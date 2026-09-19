import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'install_flag.dart';
import 'pwa_install.dart';

/// Records unique PWA installs (deduped per device) for the admin dashboard.
abstract final class AppInstallTracker {
  static const _keyId = 'khutoot_install_key';
  static const _keyRecorded = 'khutoot_install_recorded_v1';

  /// Call once after Flutter starts (standalone or just-installed flag).
  static Future<void> syncOnLaunch({String source = 'app'}) async {
    final justInstalled = InstallFlag.consumeJustInstalled();
    if (justInstalled || PwaInstall.isStandalone) {
      await PwaInstall.recordInstallInBrowser(source: source);
      await _record(source: source);
      return;
    }
    // JS may have recorded already; keep Dart prefs in sync.
    if (InstallFlag.isRecordedInBrowser) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRecorded, true);
    }
  }

  /// Call after the user accepts the native install prompt.
  static Future<void> recordAfterAccepted({String source = 'app'}) async {
    // Prefer browser keepalive fetch — survives PWA install teardown.
    await PwaInstall.recordInstallInBrowser(source: source);
    await _record(source: source);
  }

  static Future<void> _record({required String source}) async {
    if (!SupabaseConfig.isConfigured) return;

    if (InstallFlag.isRecordedInBrowser) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRecorded, true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyRecorded) == true) {
      InstallFlag.markRecordedInBrowser();
      return;
    }

    final key = await _installKey(prefs);
    final platform = PwaInstall.isMobile ? 'phone' : 'desktop';

    try {
      final client = Supabase.instance.client;
      await client.rpc(
        'record_app_install',
        params: {
          'p_install_key': key,
          'p_platform': platform,
          'p_source': source,
          'p_user_agent': InstallFlag.readUserAgent(),
        },
      );
      await prefs.setBool(_keyRecorded, true);
      InstallFlag.markRecordedInBrowser();
    } catch (_) {
      // Table/RPC may not exist yet — retry next launch.
    }
  }

  static Future<String> _installKey(SharedPreferences prefs) async {
    final fromBrowser = InstallFlag.readInstallKey();
    if (fromBrowser != null) {
      await prefs.setString(_keyId, fromBrowser);
      return fromBrowser;
    }
    final existing = prefs.getString(_keyId);
    if (existing != null && existing.length >= 8) {
      InstallFlag.writeInstallKey(existing);
      return existing;
    }
    final key =
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    await prefs.setString(_keyId, key);
    InstallFlag.writeInstallKey(key);
    return key;
  }
}
