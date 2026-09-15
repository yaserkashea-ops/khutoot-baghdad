import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/import/listing_text_parser.dart';
import 'package:masarat/core/models/listing.dart';

void main() {
  test('طالبات + يمر بالمناطق (حي الجامعة - حي الخضراء)', () {
    const raw = '''
الـــــى طالبات جامعة (بغداد و النهرين بمجمع الجادرية  ) يتوفر خط ( خصوصي ) 
(صباحي ) يمر بالمناطق التالية
 (حي الجامعة -  حي الخضراء  )
المركبة (  خصوصي حديث ) 
رقم الهاتف 07764040453 
تلغرام @r_yzx1
''';
    final l = ListingTextParser.parse(raw).single.listing;
    expect(l.type, ListingType.driver);
    expect(l.timePeriod, TimePeriod.morning);
    expect(l.genderRequirement, GenderRequirement.femaleOnly);
    expect(l.contactPhone, '9647764040453');
    expect(l.contactTelegram, '@r_yzx1');
    expect(l.vehicleType, 'خصوصي حديث');
    expect(l.destination, anyOf('مجمع الجادرية', 'جامعة بغداد — الجادرية', 'الجادرية'));
    expect(l.area, anyOf('حي الجامعة', 'الجامعة'));
  });

  test('طلبة وموظفي + حي الجهاد (فروع)', () {
    const raw = '''
الـــــى طلبة وموظفي جامعة (بغداد و النهرين بمجمع الجادرية  ) يتوفر خط ( خصوصي ) 
يمر بالمناطق التالية
حي الجهاد (  الفرات - الأطباء - المخابرات - الامانة والشارقة - حي الحسين - الديوان - حي السلام وكافه المناطق المجاورة)
المركبة (  خصوصي حديث )
رقم الهاتف 07767740001 
تلغرام @i_2005t
''';
    final l = ListingTextParser.parse(raw).single.listing;
    expect(l.genderRequirement, GenderRequirement.mixed);
    expect(l.area, 'حي الجهاد');
    expect(l.originSubs.length, greaterThanOrEqualTo(3));
    expect(l.contactPhone, '9647767740001');
    expect(l.contactTelegram, '@i_2005t');
  });

  test('من العامرية الى جامعة بغداد', () {
    const raw =
        'السلام عليكم متوفر خط من منطقة العامرية الى جامعة بغداد والسياره تدخل الى الحرم الجامعي.\nللاستفسار/07808005888';
    final l = ListingTextParser.parse(raw).single.listing;
    expect(l.area, 'العامرية');
    expect(l.destination, anyOf('جامعة بغداد', 'جامعة بغداد — الجادرية'));
    expect(l.contactPhone, '9647808005888');
  });

  test('منطقة الانطلاق / الوجهة labels', () {
    const raw = '''
🚘 تكملة خط  سيارة خصوصي 
📍 منطقة الانطلاق: الحرية 
🎓 الوجهة: جامعة بغداد
🚗 سيارة حديثة (موديل 2024)
📞 07737358413
او مراسلة @opelw1
''';
    final l = ListingTextParser.parse(raw).single.listing;
    expect(l.area, 'الحرية');
    expect(l.destination, 'جامعة بغداد');
    expect(l.contactPhone, '9647737358413');
    expect(l.contactTelegram, '@opelw1');
  });

  test('من المناطق / قائمة + جامعة بغداد الجادرية', () {
    const raw = '''
متوفر خط نقل طلاب الى جامعة بغداد الجادرية
سيارة حديثة خصوصي ٢٠٢٣
من المناطق / البلديات - الحبيبية - الاورفلي - الداخل - الفلاح - شارع فلسطين
الخط صباحي
للاستفسار: 07700558503
او عبر التلكرام @brshaa
''';
    final l = ListingTextParser.parse(raw).single.listing;
    expect(l.timePeriod, TimePeriod.morning);
    expect(l.destination, anyOf('جامعة بغداد — الجادرية', 'جامعة بغداد', 'الجادرية'));
    expect(l.area, isNotEmpty);
    expect(l.originSubs, isNotEmpty);
    expect(l.contactPhone, '9647700558503');
    expect(l.contactTelegram, '@brshaa');
  });

  test('قائمة مناطق ثم الى جامعة النهرين', () {
    const raw = '''
شارع فلسطين - جميلة - المهندسين - حي القاهرة - شيخ عمر - المناطق المحيطة بشارع فلسطين - محيط ابو نؤاس كامل - الجادرية 
الى
جامعة النهرين 
#صباحي 
07783600160
''';
    final l = ListingTextParser.parse(raw).single.listing;
    expect(l.destination, 'جامعة النهرين');
    expect(l.timePeriod, TimePeriod.morning);
    expect(l.contactPhone, '9647783600160');
    expect(l.area, isNotEmpty);
  });

  test('من الدورة الى جامعه بغداد جادريه', () {
    const raw = '''
يتوفر خط سياره خصوصي من الدوره الى جامعه بغداد جادريه علما ان صاحب الخط طالب تربيه رياضيه
@HSO_33
07806354606
''';
    final l = ListingTextParser.parse(raw).single.listing;
    expect(l.area, 'الدورة');
    expect(l.destination, anyOf('جامعة بغداد — الجادرية', 'الجادرية', 'جامعة بغداد'));
    expect(l.contactPhone, '9647806354606');
    expect(l.contactTelegram, '@HSO_33');
  });

  test('يمر عبر ابو غريب مع نقاط •', () {
    const raw = '''
تكملة خط صباحي مجمع الجادرية
📍 الخط يمر عبر ابو غريب:
• شارع الزيتون
• مجمع الزيتون
• مجمع البدور (بدور بغداد)
🚗 السيارة خصوصي حديث وتدخل الى حرم جامعة النهرين 
للتواصل: 07802249545
''';
    final l = ListingTextParser.parse(raw).single.listing;
    expect(l.area, 'أبو غريب');
    expect(l.destination, anyOf('مجمع الجادرية', 'جامعة النهرين'));
    expect(l.originSubs, isNotEmpty);
    expect(l.contactPhone, '9647802249545');
    expect(l.timePeriod, TimePeriod.morning);
  });

  test('طالبات + أرقام هندية + من (حي الخضراء والعامرية)', () {
    const raw = '''
( خط طالبات / ماجستير ) يتوفر خط للعام الدراسي (2026-2027)  باجور ( يوميه ) من ( حي الخضراء و العامرية (شارع المنظمة والاقتصاديين ) السيارة (خصوصي ٧ راكب ) الى جامعة ( بغداد و النهرين ) الجادرية علما ان صاحب الخط ملتزم و الخط يدخل الحرم الجامعي.
للتواصل ٠٧٧٠٧٣٤٧٥٨٦ 
@OT2022
''';
    final l = ListingTextParser.parse(raw).single.listing;
    expect(l.genderRequirement, GenderRequirement.femaleOnly);
    expect(l.contactPhone, '9647707347586');
    expect(l.contactTelegram, '@OT2022');
    expect(l.seatsCount, 7);
    expect(l.destination, anyOf('مجمع الجادرية', 'جامعة بغداد — الجادرية', 'الجادرية', 'جامعة بغداد'));
    expect(l.area, anyOf('حي الخضراء', 'الخضراء', 'حي الخضراء (المنطقة الخضراء)'));
  });
}
