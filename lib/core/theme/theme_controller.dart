import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and broadcasts [ThemeMode] for light / dark / system.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController shared = ThemeController._();

  static const _prefsKey = 'masarat_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  bool _loaded = false;

  ThemeMode get mode => _mode;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }

  /// Switches between light and dark based on what the user currently sees.
  Future<void> toggle(BuildContext context) async {
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark =
        _mode == ThemeMode.dark || (_mode == ThemeMode.system && platformDark);
    await setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  bool isDarkEffective(BuildContext context) {
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return _mode == ThemeMode.dark ||
        (_mode == ThemeMode.system && platformDark);
  }
}
