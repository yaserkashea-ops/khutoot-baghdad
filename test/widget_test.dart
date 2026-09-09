import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/config/admin_contact.dart';
import 'package:masarat/core/data/baghdad_places.dart';
import 'package:masarat/core/import/listing_text_parser.dart';
import 'package:masarat/core/models/admin_report.dart';
import 'package:masarat/core/models/listing.dart';
import 'package:masarat/data/admin_repository.dart';
import 'package:masarat/data/listings_repository.dart';

void main() {
  test('Baghdad places injects karkh, rusafa, universities, landmarks', () {
    expect(
      BaghdadPlaces.areas,
      containsAll(['المنصور', 'الكرادة', 'مدينة الصدر', 'أبو غريب', 'الغدير', 'الدورة', 'السيدية']),
    );
    expect(BaghdadPlaces.coreAreas, containsAll(['الدورة', 'السيدية']));
    expect(BaghdadPlaces.areasWith(const []).take(5), containsAll(['الدورة', 'السيدية']));
    expect(BaghdadPlaces.matchesQuery('السيدية', 'سيدية'), isTrue);
    expect(BaghdadPlaces.matchesQuery('الدورة', 'دورة'), isTrue);
    expect(BaghdadPlaces.areas.length, greaterThan(100));
    expect(BaghdadPlaces.destinations.length, greaterThan(150));
  });

  test('findByPhone returns existing listing with schedule', () async {
    final repo = ListingsRepository();
    final found = await repo.findByPhone('9647701234567');
    expect(found, isNotNull);
    expect(found!.area, 'المنصور');
    expect(found.timePeriod, TimePeriod.morning);
    expect(found.departureTime, '7:30');
    expect(found.returnTime, '2:00');
    expect(found.scheduleLabel, contains('صباحي'));
    expect(found.scheduleLabel, contains('انطلاق 7:30'));
    expect(found.originSubs, contains('شارع الرواد'));
    expect(found.destinationSubs, contains('مول الجادرية'));
  });

  test('admin stats and report workflow', () async {
    final admin = AdminRepository();
    final before = await admin.fetchStats();
    expect(before.listingsTotal, greaterThan(0));

    await admin.submitReport(
      kind: AdminContactKind.problem,
      message: 'اختبار بلاغ من الوحدة',
    );
    final open = await admin.fetchReports(status: ReportStatus.open);
    expect(open.any((r) => r.message.contains('اختبار')), isTrue);

    final stats = await admin.fetchStats();
    expect(stats.reportsTotal, greaterThanOrEqualTo(before.reportsTotal));
  });

  test('listing text parser imports telegram-style blocks', () async {
    const raw = '''
سائق
من المنصور إلى الجادرية
صباحي انطلاق 7:30 عودة 2:00
مختلط 3 مقاعد
07701239999

---

راكب
من الدورة للكرادة
بنات فقط مسائي
@test_rider
''';
    final drafts = ListingTextParser.parse(raw);
    expect(drafts.length, 2);
    expect(drafts[0].listing.type, ListingType.driver);
    expect(drafts[0].listing.area, 'المنصور');
    expect(drafts[0].listing.destination, contains('الجادرية'));
    expect(drafts[0].listing.contactPhone, '9647701239999');
    expect(drafts[1].listing.type, ListingType.rider);
    expect(drafts[1].listing.genderRequirement, GenderRequirement.femaleOnly);

    final repo = ListingsRepository();
    final before = repo.totalCount;
    await repo.insertMany(drafts.map((d) => d.listing));
    expect(repo.totalCount, before + 2);
  });
}
