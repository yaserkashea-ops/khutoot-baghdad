import '../matches/listing_route_match.dart';
import '../models/listing.dart';

/// Structured public search: origin + destination + time period.
class UnifiedSearchQuery {
  const UnifiedSearchQuery({
    required this.origin,
    required this.destination,
    required this.time,
  });

  final String origin;
  final String destination;
  final TimePeriod time;

  String get timeLabel =>
      time == TimePeriod.morning ? 'صباحي' : 'مسائي';

  String get summary => '$origin ← $destination · $timeLabel';

  bool matches(Listing listing) {
    if (listing.timePeriod != time) return false;
    return ListingRouteMatch.matchesOriginQuery(listing, origin) &&
        ListingRouteMatch.matchesDestinationQuery(listing, destination);
  }
}
