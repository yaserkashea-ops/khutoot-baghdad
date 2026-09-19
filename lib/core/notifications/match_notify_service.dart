import 'dart:async';

import '../../data/listings_repository.dart';
import '../../data/publisher_repository.dart';
import '../auth/publisher_auth_controller.dart';
import '../models/listing.dart';
import 'match_notified_store.dart';
import 'notification_prefs.dart';
import 'web_local_notifications.dart';

/// Polls for new route matches and fires professional system notifications.
class MatchNotifyService {
  MatchNotifyService._();
  static final MatchNotifyService shared = MatchNotifyService._();

  static const _pollInterval = Duration(minutes: 2);

  Timer? _timer;
  bool _running = false;
  bool _checking = false;

  void start() {
    if (_running) return;
    _running = true;
    unawaited(checkNow());
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(checkNow()));
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Mark current matches as already notified so enabling does not spam.
  Future<void> baselineCurrentMatches() async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!auth.isLoggedIn) return;
    try {
      final mine = await PublisherRepository.shared.myListings();
      for (final listing in mine) {
        final matches =
            await ListingsRepository.shared.fetchRouteMatches(listing);
        if (matches.isEmpty) continue;
        await MatchNotifiedStore.mark(
          listing.id,
          matches.map((m) => m.id),
        );
      }
    } catch (_) {}
  }

  Future<void> checkNow() async {
    if (_checking) return;
    final prefs = NotificationPrefs.shared;
    if (!prefs.isLoaded) await prefs.load();
    if (!prefs.enabled) return;
    if (!WebLocalNotifications.isSupported) return;
    if (WebLocalNotifications.permission != 'granted') return;

    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!auth.isLoggedIn) return;

    _checking = true;
    try {
      final mine = await PublisherRepository.shared.myListings();
      if (mine.isEmpty) return;

      final freshRoutes = <Listing>[];
      var totalFresh = 0;

      for (final listing in mine) {
        final matches =
            await ListingsRepository.shared.fetchRouteMatches(listing);
        if (matches.isEmpty) continue;
        final already = await MatchNotifiedStore.ids(listing.id);
        final fresh =
            matches.where((m) => !already.contains(m.id)).toList();
        if (fresh.isEmpty) continue;
        freshRoutes.add(listing);
        totalFresh += fresh.length;
        await MatchNotifiedStore.mark(listing.id, fresh.map((e) => e.id));
      }

      if (totalFresh <= 0 || freshRoutes.isEmpty) return;

      final title = switch (totalFresh) {
        1 => 'توجد مطابقة جديدة لخطك',
        2 => 'توجد مطابقتان جديدتان لخطوطك',
        _ when totalFresh >= 3 && totalFresh <= 10 =>
          'توجد $totalFresh مطابقات جديدة لخطوطك',
        _ => 'توجد $totalFresh مطابقة جديدة لخطوطك',
      };

      final first = freshRoutes.first;
      final body = freshRoutes.length == 1
          ? '${first.area} ← ${first.destination} — افتح حسابك لعرض التفاصيل'
          : 'مطابقات على ${freshRoutes.length} من خطوطك — افتح حسابك';

      await WebLocalNotifications.show(
        title: title,
        body: body,
        tag: 'khutoot-match',
      );
    } catch (_) {
      // Silent — polling must never break the UI.
    } finally {
      _checking = false;
    }
  }
}
