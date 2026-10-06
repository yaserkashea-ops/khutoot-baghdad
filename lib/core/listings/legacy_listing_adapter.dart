import '../models/listing.dart';
import '../utils/listing_contact.dart';
import 'unified_post_kind.dart';

/// Display-only mapping of stored listings into the unified feed card.
/// Does not mutate records, guess routes from free text, or write to the DB.
abstract final class LegacyListingAdapter {
  static UnifiedListingView toView(Listing listing) {
    final origin = listing.area.trim();
    final destination = listing.destination.trim();
    final routeComplete = origin.isNotEmpty && destination.isNotEmpty;
    final body = _originalBody(listing);
    String? badge;
    if (!routeComplete) {
      badge = origin.isEmpty && destination.isEmpty
          ? 'بيانات قديمة'
          : 'المسار غير مكتمل';
    }
    return UnifiedListingView(
      source: listing,
      kindLabel: UnifiedPostKind.labelFor(listing.type),
      available: listing.type != ListingType.rider,
      origin: origin,
      destination: destination,
      routeComplete: routeComplete,
      body: body,
      legacyBadge: badge,
      postedLabel: _sinceLabel(listing),
      contacts: ListingContact.optionsFor(listing),
    );
  }

  /// Display the stored free-text field as written. Never infer a route.
  /// Driver vehicle names stay structured metadata, not ad copy.
  static String? _originalBody(Listing listing) {
    const vehicles = {'سيارة صالون', 'فان', 'كيا', 'ستاركس', 'باص'};
    for (final raw in [listing.routeDetails, listing.vehicleType]) {
      final text = raw?.trim();
      if (text == null || text.isEmpty) continue;
      if (listing.type == ListingType.driver && vehicles.contains(text)) {
        continue;
      }
      return text;
    }
    return null;
  }

  static String _sinceLabel(Listing listing) {
    final at = (listing.bumpedAt ?? listing.updatedAt ?? listing.createdAt)
        ?.toLocal();
    if (at == null) return 'منذ لحظات';
    final diff = DateTime.now().difference(at);
    if (diff.isNegative || diff.inSeconds < 45) return 'منذ لحظات';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes.clamp(1, 59)} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours.clamp(1, 23)} س';
    return 'منذ ${diff.inDays.clamp(1, 999)} ي';
  }
}

class UnifiedListingView {
  const UnifiedListingView({
    required this.source,
    required this.kindLabel,
    required this.available,
    required this.origin,
    required this.destination,
    required this.routeComplete,
    required this.postedLabel,
    required this.contacts,
    this.body,
    this.legacyBadge,
  });

  final Listing source;
  final String kindLabel;
  final bool available;
  final String origin;
  final String destination;
  final bool routeComplete;
  final String postedLabel;
  final List<ContactOption> contacts;
  final String? body;
  final String? legacyBadge;

  String get routeLine {
    if (!routeComplete) {
      if (origin.isEmpty && destination.isEmpty) return '';
      if (origin.isEmpty) return destination;
      return origin;
    }
    return '$origin ← $destination';
  }
}
