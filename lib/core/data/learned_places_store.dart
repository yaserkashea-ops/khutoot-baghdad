import 'package:shared_preferences/shared_preferences.dart';

/// Previously persisted user-entered places into filter suggestions.
/// User-added places are no longer allowed in filters — this store only
/// clears legacy local data and ignores new remember calls.
abstract final class LearnedPlacesStore {
  static const _areasKey = 'learned_areas_v1';
  static const _destinationsKey = 'learned_destinations_v1';

  static bool _purged = false;

  /// Wipe any places users previously added on this device.
  static Future<void> purgeUserPlaces() async {
    if (_purged) return;
    _purged = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_areasKey);
    await prefs.remove(_destinationsKey);
  }

  static Future<List<String>> areas() async {
    await purgeUserPlaces();
    return const [];
  }

  static Future<List<String>> destinations() async {
    await purgeUserPlaces();
    return const [];
  }

  static Future<void> rememberArea(String value) async {
    await purgeUserPlaces();
  }

  static Future<void> rememberDestination(String value) async {
    await purgeUserPlaces();
  }

  static Future<void> rememberFromListing({
    required String area,
    required String destination,
    List<String> originSubs = const [],
    List<String> destinationSubs = const [],
  }) async {
    await purgeUserPlaces();
  }
}
