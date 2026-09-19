import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preference for publisher system notifications (publish + matches).
class NotificationPrefs extends ChangeNotifier {
  NotificationPrefs._();
  static final NotificationPrefs shared = NotificationPrefs._();

  static const _key = 'khutoot_notify_matches';

  bool _loaded = false;
  bool _enabled = false;

  bool get isLoaded => _loaded;
  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value && _loaded) return;
    _enabled = value;
    _loaded = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
