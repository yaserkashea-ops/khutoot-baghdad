import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/app.dart';
import 'package:masarat/core/auth/admin_auth_controller.dart';
import 'package:masarat/core/import/listing_text_parser.dart';
import 'package:masarat/data/listings_repository.dart';
import 'package:masarat/features/admin/admin_gate_page.dart';
import 'package:masarat/features/admin/admin_shell_page.dart';
import 'package:masarat/features/admin/pages/admin_import_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await AdminAuthController.shared.load();
    await AdminAuthController.shared.signOut();
  });

  testWidgets('public listings show brand and sample cards', (tester) async {
    await tester.pumpWidget(const MasaratApp());
    await tester.pumpAndSettle();

    expect(find.text('خطوط بغداد'), findsWidgets);
    expect(find.textContaining('المنصور'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byKey(const Key('install_home_icon')), findsOneWidget);
  });

  testWidgets('open publish form from FAB', (tester) async {
    await tester.pumpWidget(const MasaratApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('أبحث عن مقعد'), findsOneWidget);
    await tester.tap(find.text('لدي مقاعد متاحة'));
    await tester.pumpAndSettle();

    expect(find.text('نشر إعلان'), findsWidgets);
    expect(find.textContaining('سائق'), findsWidgets);
  });

  testWidgets('admin gate shows login and rejects without supabase',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminGatePage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'wrong@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'bad-pass');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminShellPage), findsNothing);
    expect(find.textContaining('غير'), findsWidgets);
  });

  testWidgets('admin import page parses sample paste', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AdminImportPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('مثال'));
    await tester.pumpAndSettle();

    expect(find.textContaining('المسودات'), findsOneWidget);
    expect(find.textContaining('المنصور'), findsWidgets);
    expect(find.text('نشر المحدد (3)'), findsOneWidget);
  });

  test('import then listings feed grows', () async {
    final repo = ListingsRepository();
    final before = repo.totalCount;
    final drafts = ListingTextParser.parse('''
سائق
من البياع إلى الكرادة
صباحي 8:00
مختلط
سيارة صالون 3 مقاعد
07701234567
''');
    expect(drafts, isNotEmpty);
    for (final d in drafts) {
      await repo.insert(d.listing);
    }
    expect(repo.totalCount, greaterThan(before));
  });
}
