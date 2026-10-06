import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/matches/listing_route_match.dart';
import 'package:masarat/core/models/listing.dart';

void main() {
  Listing listing({
    String area = 'المنصور',
    String destination = 'الجادرية',
    List<String> originSubs = const ['شارع الرواد', 'حي دراغ'],
    List<String> destinationSubs = const ['جامعة بغداد', 'مول الجادرية'],
  }) {
    return Listing(
      id: '1',
      type: ListingType.driver,
      area: area,
      destination: destination,
      originSubs: originSubs,
      destinationSubs: destinationSubs,
      timePeriod: TimePeriod.morning,
      genderRequirement: GenderRequirement.mixed,
      status: ListingStatus.published,
    );
  }

  test('directory search matches origin main and origin subs', () {
    final l = listing();
    expect(ListingRouteMatch.matchesOriginQuery(l, 'المنصور'), isTrue);
    expect(ListingRouteMatch.matchesOriginQuery(l, 'حي دراغ'), isTrue);
    expect(ListingRouteMatch.matchesOriginQuery(l, 'شارع الرواد'), isTrue);
    expect(ListingRouteMatch.matchesOriginQuery(l, 'الجادرية'), isFalse);
  });

  test('directory search matches destination main and destination subs', () {
    final l = listing();
    expect(ListingRouteMatch.matchesDestinationQuery(l, 'الجادرية'), isTrue);
    expect(ListingRouteMatch.matchesDestinationQuery(l, 'جامعة بغداد'), isTrue);
    expect(ListingRouteMatch.matchesDestinationQuery(l, 'مول الجادرية'), isTrue);
    expect(ListingRouteMatch.matchesDestinationQuery(l, 'المنصور'), isFalse);
  });

  test('route match requires origin and destination together', () {
    Listing rider({
      required String id,
      required String area,
      required String destination,
    }) {
      return Listing(
        id: id,
        type: ListingType.rider,
        area: area,
        destination: destination,
        timePeriod: TimePeriod.morning,
        genderRequirement: GenderRequirement.mixed,
        status: ListingStatus.published,
      );
    }

    final driver = listing();
    expect(
      ListingRouteMatch.isMatch(
        driver,
        rider(id: 'r1', area: 'المنصور', destination: 'الجادرية'),
      ),
      isTrue,
    );
    expect(
      ListingRouteMatch.isMatch(
        driver,
        rider(id: 'r2', area: 'المنصور', destination: 'باب المعظم'),
      ),
      isFalse,
    );
    expect(
      ListingRouteMatch.isMatch(
        driver,
        rider(id: 'r3', area: 'الدورة', destination: 'الجادرية'),
      ),
      isFalse,
    );
    expect(
      ListingRouteMatch.isMatch(
        driver,
        rider(id: 'r4', area: 'حي دراغ', destination: 'جامعة بغداد'),
      ),
      isTrue,
    );
  });
}
