import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/config/app_hosts.dart';
import 'package:masarat/core/models/listing.dart';
import 'package:masarat/core/theme/app_theme.dart';
import 'package:masarat/features/admin/pages/admin_listing_review_page.dart';
import 'package:masarat/features/admin/pages/admin_requests_page.dart';
import 'package:masarat/features/feed/unified_compose_sheet.dart';

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

Listing _legacy() {
  return const Listing(
    id: 'rev-1',
    type: ListingType.driver,
    area: 'الدورة',
    destination: 'الكرادة',
    timePeriod: TimePeriod.morning,
    genderRequirement: GenderRequirement.mixed,
    originSubs: ['حي المعلمين'],
    destinationSubs: ['باب الشرقي'],
    departureTime: '07:30',
    returnTime: '16:00',
    seatsCount: 3,
    vehicleType: 'خط يومي من الدورة',
    contactPhone: '07701234567',
  );
}

void main() {
  testWidgets('admin review uses unified fields only', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(AdminListingReviewPage(listing: _legacy())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('ساعة الانطلاق'), findsNothing);
    expect(find.text('ساعة العودة'), findsNothing);
    expect(find.text('عدد المقاعد'), findsNothing);
    expect(find.text('نقطة الانطلاق'), findsWidgets);
    expect(find.text('نقطة الوصول'), findsWidgets);
    expect(find.text('اختر مكان أو مدينة'), findsWidgets);
    expect(find.byIcon(Icons.location_on_rounded), findsNWidgets(2));
    expect(find.text('نص الإعلان'), findsOneWidget);
    expect(find.text('هاتف'), findsOneWidget);
    expect(find.text('تلغرام'), findsOneWidget);
    expect(find.text('متوفر خط'), findsWidgets);
    expect(find.text('مطلوب خط'), findsWidgets);
    expect(find.text('صباحي'), findsWidgets);
    expect(find.text('حذف'), findsWidgets);
    expect(find.text('حذف المنشور'), findsOneWidget);
  });

  testWidgets('admin compose uses the unified sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(const Scaffold(body: UnifiedComposeSheet(asAdminDirect: true))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('نشر في الدليل'), findsOneWidget);
    expect(find.text('معاينة ونشر'), findsOneWidget);
    expect(find.text('نقطة الانطلاق'), findsOneWidget);
    expect(find.text('نقطة الوصول'), findsOneWidget);
    expect(find.text('اختر مكان أو مدينة'), findsWidgets);
    expect(find.byIcon(Icons.location_on_rounded), findsNWidgets(2));
    expect(find.text('أضف وسيلة تواصل واحدة على الأقل'), findsOneWidget);
    expect(find.text('ساعة الانطلاق'), findsNothing);
    expect(find.text('عدد المقاعد'), findsNothing);
  });

  test('rejection WhatsApp notice ends with the app link', () {
    final message = listingRejectionNotice(
      reference: 'BG-12',
      origin: 'الدورة',
      destination: 'الكرادة',
      reason: 'أكمل نقطة الوصول',
    );
    expect(message.trim().endsWith(AppHosts.publicUrl), isTrue);
    expect(message, contains('أكمل نقطة الوصول'));
    expect(message, contains('رقم الطلب: BG-12'));
  });
}
