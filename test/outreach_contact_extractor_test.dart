import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/utils/outreach_contact_extractor.dart';

void main() {
  test('11-digit 077 / 078 phones', () {
    expect(
      OutreachContactExtractor.extract('07764040453').single.phone,
      '9647764040453',
    );
    expect(
      OutreachContactExtractor.extract('07808005888').single.phone,
      '9647808005888',
    );
    expect(
      OutreachContactExtractor.extract('07501234567').single.phone,
      '9647501234567',
    );
  });

  test('phones with spaces and bidi marks', () {
    const raw = '07\u200e76\u200f 404 0453';
    final list = OutreachContactExtractor.extract(raw);
    expect(list.single.phone, '9647764040453');
  });

  test('@username and fullwidth @', () {
    expect(
      OutreachContactExtractor.extract('@r_yzx1').single.telegram,
      '@r_yzx1',
    );
    expect(
      OutreachContactExtractor.extract('＠OT2022').single.telegram,
      '@OT2022',
    );
    expect(
      OutreachContactExtractor.extract('تلغرام: user_bag').single.telegram,
      '@user_bag',
    );
  });

  test('ad block pairs phone + telegram', () {
    const raw = '''
رقم الهاتف 07764040453 
تلغرام @r_yzx1
''';
    final list = OutreachContactExtractor.extract(raw);
    expect(list, hasLength(1));
    expect(list.single.phone, '9647764040453');
    expect(list.single.telegram, '@r_yzx1');
  });

  test('plain list of numbers and handles', () {
    const raw = '''
07767740001
@i_2005t
07808005888
''';
    final list = OutreachContactExtractor.extract(raw);
    expect(list.length, greaterThanOrEqualTo(3));
    expect(list.any((e) => e.phone == '9647767740001'), isTrue);
    expect(list.any((e) => e.telegram == '@i_2005t'), isTrue);
    expect(list.any((e) => e.phone == '9647808005888'), isTrue);
  });

  test('eastern digits', () {
    const raw = 'للتواصل ٠٧٧٠٧٣٤٧٥٨٦ @OT2022';
    final list = OutreachContactExtractor.extract(raw);
    expect(list.single.phone, '9647707347586');
    expect(list.single.telegram, '@OT2022');
  });
}
