import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarat/core/config/preview_mode.dart';
import 'package:masarat/core/config/preview_mode_banner.dart';
import 'package:masarat/core/models/listing.dart';
import 'package:masarat/data/listings_repository.dart';

void main() {
  test('PREVIEW_MODE is off unless compiled with dart-define', () {
    expect(PreviewMode.enabled, isFalse);
  });

  test('local listings store has driver lines and rider requests', () async {
    final repo = ListingsRepository();
    expect(repo.isRemote, isFalse);
    final live = await repo.fetchAll();
    expect(live.any((l) => l.isDriver), isTrue);
    expect(live.any((l) => l.type == ListingType.rider), isTrue);
    expect(
      live.where((l) => l.isExpired && l.isDriver).every((l) => l.isLiveInDirectory),
      isTrue,
    );
    expect(live.first.directoryRibbon, isNot('متوفر'));
    expect(live.first.showsLivePulse, isTrue);
  });

  testWidgets('preview badge is visible when forced on', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PreviewModeBanner(
          visible: true,
          child: Scaffold(body: Text('دليل')),
        ),
      ),
    );
    expect(find.text(PreviewMode.badgeLabel), findsOneWidget);
    expect(find.text('دليل'), findsOneWidget);
  });

  testWidgets('preview badge is hidden by default in tests', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PreviewModeBanner(
          child: Scaffold(body: Text('دليل')),
        ),
      ),
    );
    expect(find.text(PreviewMode.badgeLabel), findsNothing);
  });
}
