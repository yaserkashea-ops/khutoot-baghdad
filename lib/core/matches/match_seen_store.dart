import 'package:shared_preferences/shared_preferences.dart';

/// Persists which match listing ids the publisher has already opened.
abstract final class MatchSeenStore {
  static String _key(String mineListingId) => 'match_seen_$mineListingId';

  static Future<Set<String>> seenIds(String mineListingId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(mineListingId)) ?? const [];
    return raw.toSet();
  }

  static Future<void> markSeen(
    String mineListingId,
    Iterable<String> matchIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key(mineListingId)) ?? <String>[];
    final next = {...current, ...matchIds}.toList();
    await prefs.setStringList(_key(mineListingId), next);
  }

  static Future<int> newCount({
    required String mineListingId,
    required Iterable<String> matchIds,
  }) async {
    final seen = await seenIds(mineListingId);
    var n = 0;
    for (final id in matchIds) {
      if (!seen.contains(id)) n++;
    }
    return n;
  }
}
