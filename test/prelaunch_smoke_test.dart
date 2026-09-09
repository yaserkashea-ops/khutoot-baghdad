import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/app.dart';
import 'package:masarat/core/auth/admin_auth_controller.dart';
import 'package:masarat/core/config/admin_config.dart';
import 'package:masarat/core/import/listing_text_parser.dart';
import 'package:masarat/data/listings_repository.dart';
import 'package:masarat/features/admin/admin_gate_page.dart';
import 'package:masarat/features/admin/admin_shell_page.dart';
import 'package:masarat/features/admin/pages/admin_import_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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

    expect(find.text('نشر إعلان'), findsWidgets);
    expect(find.textContaining('سائق'), findsWidgets);
  });

  testWidgets('admin gate rejects wrong password', (tester) async {
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

    expect(find.textContaining('غير صحيحة'), findsOneWidget);
    expect(find.byType(AdminShellPage), findsNothing);
  });

  testWidgets('admin gate accepts default credentials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminGatePage(),
      ),
    );
    await tester.pumpAndSettle();

    final emailField = find.byType(TextField).at(0);
    final passField = find.byType(TextField).at(1);
    await tester.enterText(emailField, AdminConfig.defaultEmail);
    await tester.enterText(passField, AdminConfig.defaultPassword);
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminShellPage), findsOneWidget);
    expect(find.textContaining('نظرة عامة'), findsWidgets);
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

  test('auth update credentials then validate', () async {
    await AdminAuthController.shared.updateCredentials(
      email: 'ops@masarat.local',
      password: 'Secret99',
    );
    expect(
      AdminAuthController.shared.validate('ops@masarat.local', 'Secret99'),
      isTrue,
    );
    expect(
      AdminAuthController.shared.validate(
        AdminConfig.defaultEmail,
        AdminConfig.defaultPassword,
      ),
      isFalse,
    );
  });

  test('import then listings feed grows', () async {
    final repo = ListingsRepository();
    final before = repo.totalCount;
    final drafts = ListingTextParser.parse('''
سائق
من البياع إلى الكرادة
صباحي 8:00
مختلط
07709998877
''');
    expect(drafts, isNotEmpty);
    await repo.insertMany(drafts.map((d) => d.listing));
    expect(repo.totalCount, before + drafts.length);
    expect(repo.driverCount, greaterThan(0));
  });
}
