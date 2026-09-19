import '../data/baghdad_places.dart';
import '../models/listing.dart';

/// Route matching for publisher account: opposite type + same main places only.
abstract final class ListingRouteMatch {
  static bool sameMainPlace(String a, String b) {
    final left = BaghdadPlaces.normalizeArabic(a);
    final right = BaghdadPlaces.normalizeArabic(b);
    if (left.isEmpty || right.isEmpty) return false;
    return left == right;
  }

  /// Driver ↔ rider on the same main area → destination line.
  static bool isMatch(Listing mine, Listing other) {
    if (mine.id.isEmpty || other.id.isEmpty) return false;
    if (mine.id == other.id) return false;
    if (mine.type == other.type) return false;
    if (mine.ownerAccountId != null &&
        other.ownerAccountId != null &&
        mine.ownerAccountId == other.ownerAccountId) {
      return false;
    }
    return sameMainPlace(mine.area, other.area) &&
        sameMainPlace(mine.destination, other.destination);
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
