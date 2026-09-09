import 'package:url_launcher/url_launcher.dart';

import '../models/listing.dart';

/// Opens WhatsApp or Telegram for a listing contact.
abstract final class ListingContact {
  static String? whatsappUrl(String? rawPhone) {
    final digits = (rawPhone ?? '').replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    return 'https://wa.me/$digits';
  }

  static String? telegramUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final user = value.startsWith('@') ? value.substring(1) : value;
    if (user.isEmpty) return null;
    return 'https://t.me/$user';
  }

  /// Prefer WhatsApp, then Telegram. Returns false if nothing to open.
  static Future<bool> open(Listing listing) async {
    final wa = whatsappUrl(listing.contactPhone);
    if (wa != null) {
      return launchUrl(Uri.parse(wa), mode: LaunchMode.externalApplication);
    }
    final tg = telegramUrl(listing.contactTelegram);
    if (tg != null) {
      return launchUrl(Uri.parse(tg), mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
