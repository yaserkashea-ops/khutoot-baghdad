import '../data/baghdad_places.dart';
import '../models/listing.dart';

/// Route matching: opposite type, overlapping origin/destination (main or sub),
/// and the same time period.
abstract final class ListingRouteMatch {
  static bool samePlace(String a, String b) {
    final left = BaghdadPlaces.normalizeArabic(a);
    final right = BaghdadPlaces.normalizeArabic(b);
    if (left.isEmpty || right.isEmpty) return false;
    if (left == right) return true;
    if (left.length >= 3 && right.length >= 3) {
      return left.contains(right) || right.contains(left);
    }
    return false;
  }

  static List<String> originPlaces(Listing l) => [
        l.area,
        ...l.originSubs,
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  static List<String> destinationPlaces(Listing l) => [
        l.destination,
        ...l.destinationSubs,
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  /// Directory search: the typed/chosen place matches the main name or any
  /// nested sub on that side of the route (same rule as live matching).
  static bool matchesOriginQuery(Listing l, String query) =>
      _matchesSide(originPlaces(l), query);

  static bool matchesDestinationQuery(Listing l, String query) =>
      _matchesSide(destinationPlaces(l), query);

  static bool _matchesSide(List<String> places, String query) {
    final q = query.trim();
    if (q.isEmpty) return true;
    return places.any(
      (p) => samePlace(p, q) || BaghdadPlaces.matchesQuery(p, q),
    );
  }

  static bool placesOverlap(List<String> a, List<String> b) {
    for (final left in a) {
      for (final right in b) {
        if (samePlace(left, right)) return true;
      }
    }
    return false;
  }

  static bool sameTiming(Listing a, Listing b) {
    if (a.timePeriod != b.timePeriod) return false;
    final depA = _normTime(a.departureTime);
    final depB = _normTime(b.departureTime);
    if (depA.isNotEmpty && depB.isNotEmpty && depA != depB) return false;
    return true;
  }

  static String _normTime(String? raw) {
    var s = (raw ?? '').trim();
    if (s.isEmpty) return '';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(eastern[i], '$i');
    }
    return s.replaceAll(RegExp(r'\s+'), '');
  }

  /// Driver ↔ rider: origin must match origin, AND destination must match
  /// destination (main or sub on that same side). One side alone is not a match.
  static bool isMatch(Listing mine, Listing other) {
    if (mine.id.isEmpty || other.id.isEmpty) return false;
    if (mine.id == other.id) return false;
    if (mine.type == other.type) return false;
    if (mine.ownerAccountId != null &&
        other.ownerAccountId != null &&
        mine.ownerAccountId == other.ownerAccountId) {
      return false;
    }
    if (!sameTiming(mine, other)) return false;
    final originHit =
        placesOverlap(originPlaces(mine), originPlaces(other));
    final destinationHit =
        placesOverlap(destinationPlaces(mine), destinationPlaces(other));
    return originHit && destinationHit;
  }

  static List<Listing> filterMatches({
    required Listing mine,
    required Iterable<Listing> candidates,
  }) {
    final out = candidates.where((o) => isMatch(mine, o)).toList()
      ..sort((a, b) => b.sortAt.compareTo(a.sortAt));
    return out;
  }

  static String newMatchesLabel(int count) {
    if (count <= 0) return '';
    if (count == 1) return 'مطابقة جديدة';
    if (count == 2) return 'مطابقتان جديدتان';
    if (count >= 3 && count <= 10) return '$count مطابقات جديدة';
    return '$count مطابقة جديدة';
  }

  static String matchesCountLabel(int count) {
    if (count <= 0) return 'لا مطابقات';
    if (count == 1) return 'مطابقة';
    if (count == 2) return 'مطابقتان';
    if (count >= 3 && count <= 10) return '$count مطابقات';
    return '$count مطابقة';
  }
}
