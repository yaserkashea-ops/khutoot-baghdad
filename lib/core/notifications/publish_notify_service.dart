import 'dart:async';

import '../../data/publisher_repository.dart';
import '../auth/publisher_auth_controller.dart';
import '../models/listing.dart';
import 'listing_status_store.dart';
import 'notification_prefs.dart';
import 'web_local_notifications.dart';

/// Polls the driver's listings and fires a system notification when a line
/// becomes published (activated after admin review).
class PublishNotifyService {
  PublishNotifyService._();
  static final PublishNotifyService shared = PublishNotifyService._();

  /// Keep short while the app is open — browsers throttle background timers.
  static const _pollInterval = Duration(seconds: 20);

  /// Recent publish window for first-sighting notifications (tab was closed).
  static const _recentPublishWindow = Duration(minutes: 60);

  Timer? _timer;
  bool _running = false;
  bool _checking = false;

  void start() {
    if (_running) {
      unawaited(checkNow());
      return;
    }
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

  /// Remember current statuses so enabling does not spam for already-live lines.
  Future<void> baselineCurrentStatuses() async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!auth.isLoggedIn) return;
    try {
      final mine = await PublisherRepository.shared.myListings();
      if (mine.isEmpty) return;
      await ListingStatusStore.setMany({
        for (final l in mine) l.id: l.status.name,
      });
    } catch (_) {}
  }

  /// Returns listings that newly became published (for in-app feedback).
  Future<List<Listing>> checkNow() async {
    if (_checking) return const [];
    final prefs = NotificationPrefs.shared;
    if (!prefs.isLoaded) await prefs.load();
    if (!prefs.enabled) return const [];
    if (!WebLocalNotifications.isSupported) return const [];
    if (WebLocalNotifications.permission != 'granted') return const [];

    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!auth.isLoggedIn) return const [];

    _checking = true;
    try {
      final mine = await PublisherRepository.shared.myListings();
      if (mine.isEmpty) return const [];

      final activated = <Listing>[];
      final now = DateTime.now().toUtc();

      for (final listing in mine) {
        final prev = await ListingStatusStore.statusOf(listing.id);
        final next = listing.status.name;

        if (prev == null) {
          await ListingStatusStore.setOne(listing.id, next);
          // Tab was closed during review: still notify if publish is recent.
          if (listing.status == ListingStatus.published &&
              _isRecentPublish(listing, now)) {
            activated.add(listing);
          }
          continue;
        }

        if (prev != next) {
          await ListingStatusStore.setOne(listing.id, next);
        }

        if (listing.status == ListingStatus.published &&
            prev != ListingStatus.published.name) {
          activated.add(listing);
        }
      }

      if (activated.isEmpty) return const [];

      if (activated.length == 1) {
        final l = activated.first;
        await WebLocalNotifications.show(
          title: 'تم تفعيل خطك',
          body: '${l.area} ← ${l.destination} — خطك ظاهر الآن في الدليل',
          tag: 'khutoot-publish-${l.id}',
        );
      } else {
        await WebLocalNotifications.show(
          title: 'تم تفعيل خطوطك',
          body: 'تم نشر ${activated.length} من خطوطك في الدليل',
          tag: 'khutoot-publish-batch',
        );
      }
      return activated;
    } catch (_) {
      return const [];
    } finally {
      _checking = false;
    }
  }

  bool _isRecentPublish(Listing listing, DateTime nowUtc) {
    final touched = listing.bumpedAt ?? listing.updatedAt;
    if (touched == null) return false;
    return nowUtc.difference(touched.toUtc()) <= _recentPublishWindow;
  }
}
