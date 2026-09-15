import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/import/voice_listing_commands.dart';
import 'package:masarat/core/models/listing.dart';

void main() {
  test('guided type / period / gender', () {
    expect(
      VoiceListingCommands.parseStep(VoiceListingStep.type, 'سائق').value,
      ListingType.driver,
    );
    expect(
      VoiceListingCommands.parseStep(VoiceListingStep.type, 'باحث عن خط').value,
      ListingType.rider,
    );
    expect(
      VoiceListingCommands.parseStep(VoiceListingStep.period, 'صباحي').value,
      TimePeriod.morning,
    );
    expect(
      VoiceListingCommands.parseStep(VoiceListingStep.gender, 'طالبات').value,
      GenderRequirement.femaleOnly,
    );
  });

  test('spoken phone digits', () {
    final r = VoiceListingCommands.parseStep(
      VoiceListingStep.phone,
      'صفر سبعة سبعة ستة اربعة صفر اربعة صفر اربعة خمسة ثلاثه',
    );
    expect(r.isOk, isTrue);
    expect(r.value, '9647764040453');
  });

  test('phone skip', () {
    final r = VoiceListingCommands.parseStep(VoiceListingStep.phone, 'تخطي');
    expect(r.isOk, isTrue);
    expect(r.skipped, isTrue);
  });

  test('telegram handle', () {
    final r = VoiceListingCommands.parseStep(
      VoiceListingStep.telegram,
      'تلغرام r_yzx1',
    );
    expect(r.value, '@r_yzx1');
  });

  test('origin and destination subs', () {
    final origin = VoiceListingCommands.parseStep(
      VoiceListingStep.originSubs,
      'حي الجامعة و الخضراء',
    );
    expect(origin.isOk, isTrue);
    expect(origin.value, ['حي الجامعه', 'الخضراء']);

    final dest = VoiceListingCommands.parseStep(
      VoiceListingStep.destinationSubs,
      'مجمع الجادرية و بوابة الجامعة',
    );
    expect(dest.isOk, isTrue);
    expect(dest.value, ['مجمع الجادريه', 'بوابه الجامعه']);

    final skip = VoiceListingCommands.parseStep(
      VoiceListingStep.originSubs,
      'تخطي',
    );
    expect(skip.skipped, isTrue);
  });

  test('guided steps include sub-areas', () {
    final d = VoiceListingDraft()..type = ListingType.driver;
    expect(d.steps, contains(VoiceListingStep.originSubs));
    expect(d.steps, contains(VoiceListingStep.destinationSubs));
  });

  test('structured one-shot line', () {
    final d = VoiceListingCommands.parseStructuredLine(
      'سائق من العامرية الى الجادرية صباحي مختلط رقم 07764040453 تلغرام user_bag',
    );
    expect(d, isNotNull);
    expect(d!.type, ListingType.driver);
    expect(d.area, 'العامريه');
    expect(d.destination, 'الجادريه');
    expect(d.period, TimePeriod.morning);
    expect(d.gender, GenderRequirement.mixed);
    expect(d.phone, '9647764040453');
    expect(d.telegram, '@user_bag');
    expect(d.toListing(), isNotNull);
  });
}
