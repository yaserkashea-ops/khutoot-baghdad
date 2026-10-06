import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/auth/guest_access_guard.dart';
import 'package:masarat/core/pwa/install_instructions_sheet.dart';
import 'package:masarat/core/theme/app_theme.dart';
import 'package:masarat/features/feed/unified_feed_page.dart';
import 'package:masarat/data/listings_repository.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ListingsRepository.bindPreview();
  });

  test('guest browsing does not require an account', () {
    expect(GuestAccessGuard.canBrowse, isTrue);
  });

  testWidgets('home opens without a login sheet', (tester) async {
    await tester.pumpWidget(_wrap(const UnifiedFeedPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('دليل خطوط بغداد'), findsWidgets);
    expect(find.text('إنشاء حساب'), findsNothing);
    expect(find.text('تسجيل دخول'), findsNothing);
  });

  testWidgets('unified feed shows search, kind chips, and compose', (tester) async {
    await tester.pumpWidget(_wrap(const UnifiedFeedPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('ابحث في الإعلانات'), findsOneWidget);
    expect(find.text('اكتب إعلاناً'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byTooltip('مشاركة التطبيق'), findsOneWidget);
    expect(find.text('ثبّت دليل خطوط بغداد على شاشة هاتفك'), findsOneWidget);
    expect(find.text('عرض الخطوط'), findsNothing);
    expect(find.text('أنا طالب/موظف'), findsNothing);
  });

  testWidgets('install card stays visible even if previously dismissed',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'khutoot_home_install_card_dismissed_v1': true,
    });
    await tester.pumpWidget(_wrap(const UnifiedFeedPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('ثبّت دليل خطوط بغداد على شاشة هاتفك'), findsOneWidget);
    expect(find.byTooltip('إغلاق'), findsNothing);
  });

  testWidgets('install instructions can be dismissed', (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showInstallInstructionsSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('ثبّت دليل خطوط بغداد'), findsOneWidget);
    expect(find.text('فهمت'), findsOneWidget);
    await tester.tap(find.text('فهمت'));
    await tester.pumpAndSettle();
    expect(find.text('فهمت'), findsNothing);
  });
}
