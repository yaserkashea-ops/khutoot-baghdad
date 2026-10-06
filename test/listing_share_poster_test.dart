import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/config/app_hosts.dart';
import 'package:masarat/core/models/listing.dart';
import 'package:masarat/core/theme/app_theme.dart';
import 'package:masarat/features/admin/widgets/listing_share_poster.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('saved card poster includes an app QR code', (tester) async {
    const listing = Listing(
      id: 'p1',
      type: ListingType.driver,
      area: 'الدورة',
      destination: 'الكرادة',
      timePeriod: TimePeriod.morning,
      genderRequirement: GenderRequirement.mixed,
      vehicleType: 'خط يومي من الدورة',
      contactPhone: '9647701234567',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: ListingSharePoster(listing: listing),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('امسح الباركود لفتح دليل خطوط بغداد'), findsOneWidget);
    expect(find.text(AppHosts.publicOrigin), findsOneWidget);
    expect(find.text('متوفر خط'), findsOneWidget);
    expect(find.textContaining('نوع السيارة'), findsNothing);
    expect(find.text('خط يومي من الدورة'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! RichText) return false;
        final plain = widget.text.toPlainText();
        return plain.contains('07701234567') && !plain.contains('964');
      }),
      findsOneWidget,
    );
  });
}
