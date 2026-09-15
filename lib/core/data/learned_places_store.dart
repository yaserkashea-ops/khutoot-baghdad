import 'package:shared_preferences/shared_preferences.dart';

import 'baghdad_places.dart';

/// Persists user-entered places so they reappear in filters and suggestions.
abstract final class LearnedPlacesStore {
  static const _areasKey = 'learned_areas_v1';
  static const _destinationsKey = 'learned_destinations_v1';

  static Future<List<String>> areas() => _read(_areasKey);

  static Future<List<String>> destinations() => _read(_destinationsKey);

  static Future<void> rememberArea(String value) =>
      _remember(_areasKey, value, known: BaghdadPlaces.areas);

  static Future<void> rememberDestination(String value) => _remember(
        _destinationsKey,
        value,
        known: {...BaghdadPlaces.areas, ...BaghdadPlaces.institutions},
      );

  static Future<void> rememberFromListing({
    required String area,
    required String destination,
    List<String> originSubs = const [],
    List<String> destinationSubs = const [],
  }) async {
    await rememberArea(area);
    for (final s in originSubs) {
      await rememberArea(s);
    }
    await rememberDestination(destination);
    for (final s in destinationSubs) {
      await rememberDestination(s);
    }
  }

  static Future<List<String>> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key) ?? const <String>[];
    final seen = <String>{};
    final out = <String>[];
    for (final item in raw) {
      final v = item.trim();
      if (v.isEmpty || !seen.add(v)) continue;
      out.add(v);
    }
    return out;
  }

  static Future<void> _remember(
    String key,
    String value, {
    required Iterable<String> known,
  }) async {
    final v = value.trim();
    if (v.isEmpty) return;
    if (known.contains(v)) return;

    final prefs = await SharedPreferences.getInstance();
    final current = [...(prefs.getStringList(key) ?? const <String>[])];
    final exists = current.any(
      (e) =>
          e == v ||
          BaghdadPlaces.normalizeArabic(e) == BaghdadPlaces.normalizeArabic(v),
    );
    if (exists) return;
    current.add(v);
    await prefs.setStringList(key, current);
  }
}
