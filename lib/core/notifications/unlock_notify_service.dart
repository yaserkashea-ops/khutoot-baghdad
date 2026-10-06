import 'dart:async';

import '../../data/contact_unlocks_repository.dart';
import '../auth/publisher_auth_controller.dart';
import '../config/directory_launch.dart';
import 'listing_status_store.dart';
import 'notification_prefs.dart';
import 'web_local_notifications.dart';

/// Polls unlock rows and fires a tray notification when admin reveals contact.
class UnlockNotifyService {
  UnlockNotifyService._();
  static final UnlockNotifyService shared = UnlockNotifyService._();

  static const _pollInterval = Duration(seconds: 20);

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

  Future<void> checkNow() async {
    if (_checking) return;
    final prefs = NotificationPrefs.shared;
    if (!prefs.isLoaded) await prefs.load();
    if (!prefs.enabled) return;
    if (DirectoryLaunch.freeRiderContacts) return;
    if (!WebLocalNotifications.isSupported) return;
    if (WebLocalNotifications.permission != 'granted') return;

    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!auth.isLoggedIn) return;

    _checking = true;
    try {
      final rows = await ContactUnlocksRepository.shared.mine();
      for (final u in rows) {
        final key = 'unlock:${u.id}';
        final prev = await ListingStatusStore.statusOf(key);
        final next = u.status.name;
        if (prev == null) {
          await ListingStatusStore.setOne(key, next);
          continue;
        }
        if (prev == next) continue;
        await ListingStatusStore.setOne(key, next);
        if (!u.isApproved) continue;
        final listing = u.request;
        final route = listing == null
            ? 'طلب راكب'
            : '${listing.area} ← ${listing.destination}';
        await WebLocalNotifications.show(
          title: 'تم فتح تواصل الراكب',
          body: '$route — افتح البطاقة واتساب أو تلغرام',
          tag: 'khutoot-unlock-${u.id}',
        );
      }
    } catch (_) {
    } finally {
      _checking = false;
    }
  }
}
