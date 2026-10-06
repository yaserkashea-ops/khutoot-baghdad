import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/listings/legacy_listing_adapter.dart';
import 'package:masarat/core/theme/app_colors.dart';
import 'package:masarat/core/listings/unified_post_kind.dart';
import 'package:masarat/core/listings/unified_search_query.dart';
import 'package:masarat/core/models/listing.dart';
import 'package:masarat/core/theme/app_theme.dart';
import 'package:masarat/core/theme/theme_controller.dart';
import 'package:masarat/core/utils/listing_contact.dart';
import 'package:masarat/data/listings_repository.dart';
import 'package:masarat/features/feed/unified_compose_sheet.dart';
import 'package:masarat/features/feed/unified_feed_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('ar'),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ListingsRepository.bindPreview();
    await ThemeController.shared.setMode(ThemeMode.light);
  });

  test('official labels are the swapped-word phrases only', () {
    expect(UnifiedPostKind.available, 'متوفر خط');
    expect(UnifiedPostKind.wanted, 'مطلوب خط');
    expect(UnifiedPostKind.labelFor(ListingType.driver), 'متوفر خط');
    expect(UnifiedPostKind.labelFor(ListingType.rider), 'مطلوب خط');
    expect(UnifiedPostKind.available.contains('خط متوفر'), isFalse);
    expect(
      UnifiedPostKind.colorFor(ListingType.driver, MasaratColors.light),
      MasaratColors.light.primary,
    );
    expect(
      UnifiedPostKind.colorFor(ListingType.rider, MasaratColors.light),
      MasaratColors.light.wanted,
    );
  });

  test('adapter maps types without guessing a missing route', () {
    const incomplete = Listing(
      id: 'x',
      type: ListingType.rider,
      area: '',
      destination: '',
      timePeriod: TimePeriod.morning,
      genderRequirement: GenderRequirement.mixed,
      vehicleType: 'خط صباحي...',
    );
    final view = LegacyListingAdapter.toView(incomplete);
    expect(view.kindLabel, 'مطلوب خط');
    expect(view.routeComplete, isFalse);
    expect(view.legacyBadge, 'بيانات قديمة');
    expect(view.body, 'خط صباحي...');
    expect(view.origin, isEmpty);
  });

  test('adapter keeps structured origin/destination as written', () {
    const listing = Listing(
      id: 'd',
      type: ListingType.driver,
      area: 'الدورة',
      destination: 'جامعة بغداد',
      timePeriod: TimePeriod.morning,
      genderRequirement: GenderRequirement.mixed,
      vehicleType: 'سيارة صالون',
      contactPhone: '9647701234567',
    );
    final view = LegacyListingAdapter.toView(listing);
    expect(view.kindLabel, 'متوفر خط');
    expect(view.routeLine, 'الدورة ← جامعة بغداد');
    expect(view.body, isNull);
    expect(view.contacts.map((c) => c.label), containsAll(['اتصال', 'واتساب']));
  });

  test('phone and telegram become real links', () {
    expect(ListingContact.telUrl('07701234567'), startsWith('tel:+964'));
    expect(
      ListingContact.whatsappUrl('07701234567'),
      startsWith('https://wa.me/964'),
    );
    expect(ListingContact.telegramUrl('@baghdad_line'), 'https://t.me/baghdad_line');
    expect(ListingContact.telegramUrl('javascript:alert(1)'), isNull);
  });

  test('guest publish is idempotent for the same payload', () async {
    final repo = ListingsRepository();
    final listing = Listing(
      id: '',
      type: ListingType.driver,
      area: 'المنصور',
      destination: 'الجادرية',
      timePeriod: TimePeriod.morning,
      genderRequirement: GenderRequirement.mixed,
      vehicleType: 'اكتب تجربة',
      contactPhone: '9647701112233',
    );
    final a = await repo.publishUnifiedGuest(listing);
    final b = await repo.publishUnifiedGuest(listing);
    expect(a.id, b.id);
    expect(a.status, ListingStatus.published);
  });

  testWidgets('unified feed opens without login or account chrome', (tester) async {
    await tester.pumpWidget(_wrap(const UnifiedFeedPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('دليل خطوط بغداد'), findsWidgets);
    expect(find.text('ابحث في الإعلانات'), findsOneWidget);
    expect(find.text('اكتب إعلاناً'), findsOneWidget);
    expect(find.text('متوفر خط'), findsWidgets);
    expect(find.text('مطلوب خط'), findsWidgets);
    expect(find.text('حسابي'), findsNothing);
    expect(find.text('إنشاء حساب'), findsNothing);
    expect(find.text('تسجيل دخول'), findsNothing);
    expect(find.text('خط متوفر'), findsNothing);
    expect(find.text('خط مطلوب'), findsNothing);
  });

  testWidgets('compose sheet type options use official labels only', (tester) async {
    await tester.pumpWidget(_wrap(const UnifiedFeedPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('اكتب إعلاناً'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('متوفر خط'), findsWidgets);
    expect(find.text('مطلوب خط'), findsWidgets);
    expect(find.text('اكتب إعلانك هنا'), findsOneWidget);
    expect(find.text('نص الإعلان'), findsOneWidget);
    expect(find.text('نص الإعلان (اختياري)'), findsNothing);
    expect(find.text('صباحي'), findsWidgets);
    expect(find.text('مسائي'), findsWidgets);
    expect(find.byIcon(Icons.directions_car_rounded), findsWidgets);
    expect(find.byIcon(Icons.person_search_rounded), findsWidgets);
    expect(find.text('إنشاء حساب'), findsNothing);
    expect(find.text('تسجيل دخول'), findsNothing);
  });

  testWidgets('guest submit notice explains review and approval', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showGuestSubmitReceivedDialog(context),
                child: const Text('notify'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('notify'));
    await tester.pump();
    expect(find.text(guestSubmitReceivedTitle), findsOneWidget);
    expect(find.text(guestSubmitReceivedBody), findsOneWidget);
    expect(find.text('حسناً'), findsOneWidget);
  });

  testWidgets('preview before publish shows a completeness hint', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const Scaffold(body: UnifiedComposeSheet())));
    await tester.pump();

    await tester.tap(find.text('متوفر خط'));
    await tester.pump();
    await tester.tap(find.text('صباحي'));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'المنصور');
    await tester.enterText(fields.at(1), 'الجادرية');
    await tester.enterText(fields.at(2), 'ثلاثة مقاعد صالون');
    await tester.enterText(find.byKey(const Key('compose_phone')), '07701234567');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'معاينة ونشر'));
    await tester.tap(find.widgetWithText(FilledButton, 'معاينة ونشر'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('معاينة المنشور'), findsOneWidget);
    expect(
      find.text('احرص على كتابة تفاصيل كاملة مثل عدد المقاعد ونوع السيارة.'),
      findsOneWidget,
    );
  });

  testWidgets('compose rejects preview without a contact method', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const Scaffold(body: UnifiedComposeSheet())));
    await tester.pump();

    await tester.tap(find.text('متوفر خط'));
    await tester.pump();
    await tester.tap(find.text('صباحي'));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'المنصور');
    await tester.enterText(fields.at(1), 'الجادرية');
    await tester.enterText(fields.at(2), 'ثلاثة مقاعد صالون');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'معاينة ونشر'));
    await tester.tap(find.widgetWithText(FilledButton, 'معاينة ونشر'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('أضف وسيلة تواصل واحدة على الأقل'), findsAtLeastNWidgets(1));
    expect(find.text('معاينة المنشور'), findsNothing);
  });

  testWidgets('compose allows empty body when route time and contact are set',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const Scaffold(body: UnifiedComposeSheet())));
    await tester.pump();

    await tester.tap(find.text('متوفر خط'));
    await tester.pump();
    await tester.tap(find.text('صباحي'));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'المنصور');
    await tester.enterText(fields.at(1), 'الجادرية');
    await tester.enterText(find.byKey(const Key('compose_phone')), '07701234567');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'معاينة ونشر'));
    await tester.tap(find.widgetWithText(FilledButton, 'معاينة ونشر'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('اكتب نص الإعلان'), findsNothing);
    expect(find.text('معاينة المنشور'), findsOneWidget);
  });

  testWidgets('compose allows the same main area for origin and destination',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const Scaffold(body: UnifiedComposeSheet())));
    await tester.pump();

    await tester.tap(find.text('متوفر خط'));
    await tester.pump();
    await tester.tap(find.text('صباحي'));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'المنصور');
    await tester.enterText(fields.at(1), 'المنصور');
    await tester.enterText(find.byKey(const Key('compose_phone')), '07701234567');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'معاينة ونشر'));
    await tester.tap(find.widgetWithText(FilledButton, 'معاينة ونشر'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.textContaining('متطابقتين'), findsNothing);
    expect(find.text('معاينة المنشور'), findsOneWidget);
  });

  test('structured search requires origin, destination, and time together', () {
    const listing = Listing(
      id: '1',
      type: ListingType.driver,
      area: 'المنصور',
      destination: 'الجادرية',
        originSubs: ['شارع الرواد', 'حي دراغ'],
        destinationSubs: ['جامعة بغداد'],
      timePeriod: TimePeriod.morning,
      genderRequirement: GenderRequirement.mixed,
      contactPhone: '9647701234567',
    );
    const hit = UnifiedSearchQuery(
      origin: 'المنصور',
      destination: 'الجادرية',
      time: TimePeriod.morning,
    );
    expect(hit.matches(listing), isTrue);
    expect(
      const UnifiedSearchQuery(
        origin: 'حي دراغ',
        destination: 'جامعة بغداد',
        time: TimePeriod.morning,
      ).matches(listing),
      isTrue,
    );
    expect(
      const UnifiedSearchQuery(
        origin: 'المنصور',
        destination: 'الجادرية',
        time: TimePeriod.evening,
      ).matches(listing),
      isFalse,
    );
    expect(
      const UnifiedSearchQuery(
        origin: 'الدورة',
        destination: 'الجادرية',
        time: TimePeriod.morning,
      ).matches(listing),
      isFalse,
    );
  });

  testWidgets('search field opens origin destination and time then search',
      (tester) async {
    await tester.pumpWidget(_wrap(const UnifiedFeedPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.byKey(const Key('unified_search_field')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('الانطلاق'), findsOneWidget);
    expect(find.text('الوصول'), findsOneWidget);
    expect(find.text('بحث'), findsOneWidget);
    expect(find.text('صباحي'), findsWidgets);
    expect(find.text('مسائي'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'بحث'), findsOneWidget);
  });

  testWidgets('theme toggle switches the unified feed to dark', (tester) async {
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: ThemeController.shared,
        builder: (context, _) {
          return MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeController.shared.mode,
            locale: const Locale('ar'),
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: UnifiedFeedPage(),
            ),
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(ThemeController.shared.mode, ThemeMode.dark);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(find.text('دليل خطوط بغداد'), findsWidgets);
  });
}
