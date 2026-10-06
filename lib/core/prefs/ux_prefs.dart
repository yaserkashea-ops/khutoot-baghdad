import 'package:shared_preferences/shared_preferences.dart';

/// Local-only UX flags. Never sent to production.
abstract final class UxPrefs {
  static const installCardKey = 'khutoot_home_install_card_dismissed_v1';
  static const installHelpKey = 'khutoot_install_help_dismissed_v1';

  static Future<bool> isDismissed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> dismiss(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}
