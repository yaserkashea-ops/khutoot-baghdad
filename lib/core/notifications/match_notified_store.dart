import 'package:shared_preferences/shared_preferences.dart';

/// Match ids already delivered as a system notification.
abstract final class MatchNotifiedStore {
  static String _key(String mineListingId) =>
      'match_notified_$mineListingId';

  static Future<Set<String>> ids(String mineListingId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(mineListingId)) ?? const []).toSet();
  }

  static Future<void> mark(
    String mineListingId,
    Iterable<String> matchIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key(mineListingId)) ?? <String>[];
    final next = {...current, ...matchIds}.toList();
    await prefs.setStringList(_key(mineListingId), next);
  }
}
