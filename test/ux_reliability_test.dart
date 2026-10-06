import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/listings/duplicate_listing.dart';
import 'package:masarat/core/listings/publish_draft_store.dart';
import 'package:masarat/core/models/listing.dart';
import 'package:masarat/core/widgets/app_kit.dart';
import 'package:masarat/data/listings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Listing _line({
  required String id,
  required String area,
  required String dest,
  ListingType type = ListingType.driver,
  String? phone,
}) {
  return Listing(
    id: id,
    type: type,
    area: area,
    destination: dest,
    timePeriod: TimePeriod.morning,
    genderRequirement: GenderRequirement.mixed,
    contactPhone: phone,
  );
}

void main() {
  test('duplicate warning matches same route and time', () {
    final mine = [
      _line(id: '1', area: 'المنصور', dest: 'الجادرية', phone: '964770111'),
    ];
    expect(
      DuplicateListing.similar(
        mine: mine,
        type: ListingType.driver,
        area: 'المنصور',
        destination: 'الجادرية',
        time: TimePeriod.morning,
        phone: '964770111',
      )?.id,
      '1',
    );
    expect(
      DuplicateListing.similar(
        mine: mine,
        type: ListingType.rider,
        area: 'المنصور',
        destination: 'الجادرية',
        time: TimePeriod.morning,
      ),
      isNull,
    );
  });

  test('local insert is idempotent for the same payload', () async {
    final repo = ListingsRepository();
    final draft = _line(id: '', area: 'الكرادة', dest: 'زيونة');
    final a = await repo.insert(draft);
    final b = await repo.insert(draft);
    expect(a.id, b.id);
  });

  test('publish draft store round-trips locally', () async {
    SharedPreferences.setMockInitialValues({});
    await PublishDraftStore.save(PublishDraftStore.riderKey, {
      'area': 'الدورة',
      'dest': 'الجادرية',
    });
    final loaded = await PublishDraftStore.load(PublishDraftStore.riderKey);
    expect(loaded?['area'], 'الدورة');
    await PublishDraftStore.clear(PublishDraftStore.riderKey);
    expect(await PublishDraftStore.load(PublishDraftStore.riderKey), isNull);
  });

  testWidgets('form stepper highlights the current step', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FormStepper(
            step: 1,
            labels: ['الطريق', 'التفاصيل', 'التواصل'],
          ),
        ),
      ),
    );
    expect(find.textContaining('«2 التفاصيل»'), findsOneWidget);
    expect(find.textContaining('1 الطريق'), findsOneWidget);
  });
}
