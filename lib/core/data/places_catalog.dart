import 'package:flutter/foundation.dart';

import '../models/filter_place_override.dart';
import '../models/managed_place.dart';
import '../../data/places_repository.dart';
import 'baghdad_places.dart';

/// Merges static Baghdad catalog with admin-managed places and overrides.
class PlacesCatalog extends ChangeNotifier {
  PlacesCatalog._();
  static final PlacesCatalog shared = PlacesCatalog._();

  List<ManagedPlace> _managed = const [];
  List<FilterPlaceOverride> _overrides = const [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  bool get isLoading => _loading;
  bool get isLoaded => _loaded;
  String? get error => _error;
  List<ManagedPlace> get managed => List.unmodifiable(_managed);
  List<FilterPlaceOverride> get overrides => List.unmodifiable(_overrides);

  List<String> get extraAreas => [
        for (final p in _managed)
          if (p.active && p.isArea) p.name,
      ];

  List<String> get extraDestinations => [
        for (final p in _managed)
          if (p.active && p.isDestination) p.name,
      ];

  List<String> get areas => _applyOverrides(
        BaghdadPlaces.areasWith(extraAreas),
      );

  List<String> get destinations => _applyOverrides(
        BaghdadPlaces.destinationsWith(extraDestinations),
      );

  /// Builtin catalog names (areas + institutions) for admin editing UI.
  List<String> get builtinNames => BaghdadPlaces.destinationsWith(const []);

  FilterPlaceOverride? overrideFor(String name) {
    final key = name.trim().toLowerCase();
    for (final o in _overrides) {
      if (o.name.trim().toLowerCase() == key) return o;
    }
    return null;
  }

  ManagedPlace? managedForName(String name) {
    final key = name.trim().toLowerCase();
    for (final p in _managed) {
      if (p.name.trim().toLowerCase() == key) return p;
    }
    return null;
  }

  List<String> _applyOverrides(List<String> source) {
    if (_overrides.isEmpty) return source;
    final hidden = <String>{};
    final renames = <String, String>{};
    for (final o in _overrides) {
      final key = o.name.trim();
      if (key.isEmpty) continue;
      if (o.hidden) {
        hidden.add(key.toLowerCase());
      }
      final to = o.renamedTo?.trim();
      if (to != null && to.isNotEmpty) {
        renames[key.toLowerCase()] = to;
      }
    }

    final out = <String>[];
    final seen = <String>{};
    for (final raw in source) {
      final lower = raw.trim().toLowerCase();
      if (hidden.contains(lower)) continue;
      final name = renames[lower] ?? raw;
      final outKey = name.trim().toLowerCase();
      if (outKey.isEmpty || seen.contains(outKey)) continue;
      if (hidden.contains(outKey)) continue;
      seen.add(outKey);
      out.add(name);
    }
    return out;
  }

  Future<void> refresh({bool forAdmin = false}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    // Avoid notifying on start — keeps first paint fast.
    try {
      final managedFut = forAdmin
          ? PlacesRepository.shared.fetchAllForAdmin()
          : PlacesRepository.shared.fetchActive();
      final results = await Future.wait([
        managedFut,
        PlacesRepository.shared.fetchOverrides(),
      ]);
      _managed = results[0] as List<ManagedPlace>;
      _overrides = results[1] as List<FilterPlaceOverride>;
      _loaded = true;
    } catch (e) {
      _error = '$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
