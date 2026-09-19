import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Last-seen listing status per id (for publish-activation notifications).
abstract final class ListingStatusStore {
  static const _key = 'khutoot_listing_status_v1';

  static Future<Map<String, String>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> _write(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(map));
  }

  static Future<String?> statusOf(String listingId) async {
    final map = await _read();
    return map[listingId];
  }

  static Future<void> setMany(Map<String, String> statuses) async {
    if (statuses.isEmpty) return;
    final map = await _read();
    map.addAll(statuses);
    await _write(map);
  }

  static Future<void> setOne(String listingId, String status) async {
    final map = await _read();
    map[listingId] = status;
    await _write(map);
  }
}
