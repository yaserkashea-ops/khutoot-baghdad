import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only drafts. Never sent to production.
abstract final class PublishDraftStore {
  static const driverKey = 'khutoot_draft_driver_v1';
  static const riderKey = 'khutoot_draft_rider_v1';
  static const savedIdsKey = 'khutoot_saved_listing_ids_v1';

  /// Bumped when saved listing ids change so cards and المحفوظات refresh.
  static final ValueNotifier<int> savedRevision = ValueNotifier(0);

  static List<String> _savedIds = const [];

  static bool isSaved(String id) => _savedIds.contains(id);

  static Future<void> save(String key, Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<Map<String, String>?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in map.entries) e.key: '${e.value ?? ''}',
      };
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<List<String>> savedIds() async {
    final prefs = await SharedPreferences.getInstance();
    _savedIds = List<String>.unmodifiable(
      prefs.getStringList(savedIdsKey) ?? const [],
    );
    return _savedIds;
  }

  static Future<void> toggleSaved(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = [...?prefs.getStringList(savedIdsKey)];
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    await prefs.setStringList(savedIdsKey, ids);
    _savedIds = List<String>.unmodifiable(ids);
    savedRevision.value++;
  }
}
