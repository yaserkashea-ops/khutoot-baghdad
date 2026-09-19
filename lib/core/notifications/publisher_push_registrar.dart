import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/publisher_auth_controller.dart';
import '../config/supabase_config.dart';
import 'push_config.dart';
import 'web_push.dart';

/// Saves / clears Web Push subscription for the logged-in publisher.
abstract final class PublisherPushRegistrar {
  static Future<bool> register() async {
    if (!WebPush.isSupported) return false;
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    final token = auth.token;
    if (token == null || token.isEmpty) return false;

    final sub = await WebPush.subscribe(
      vapidPublicKey: PushConfig.vapidPublicKey,
    );
    if (sub == null) return false;

    if (!SupabaseConfig.isConfigured) return false;
    try {
      final ok = await Supabase.instance.client.rpc(
        'publisher_save_push_subscription',
        params: {
          'p_token': token,
          'p_endpoint': sub['endpoint'],
          'p_p256dh': sub['p256dh'],
          'p_auth': sub['auth'],
          'p_user_agent': null,
        },
      );
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> unregister() async {
    try {
      final auth = PublisherAuthController.shared;
      final token = auth.token;
      // Best-effort: unsubscribe browser push.
      // Endpoint may be unknown after local clear — still drop browser sub.
      await WebPush.unsubscribe();
      if (token != null &&
          token.isNotEmpty &&
          SupabaseConfig.isConfigured) {
        // No endpoint handy after unsubscribe; ignore server row (stale cleaned on 410).
      }
    } catch (_) {}
  }
}

/// Ask the server to push a system notification for a published listing.
abstract final class ListingPublishPush {
  static Future<void> notifyPublished(String listingId) async {
    if (!SupabaseConfig.isConfigured) return;
    if (listingId.trim().isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'notify-listing-published',
        body: {'listing_id': listingId},
      );
    } catch (_) {
      // Function may not be deployed yet — local poll remains as fallback.
    }
  }
}
