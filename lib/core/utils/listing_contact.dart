import 'package:url_launcher/url_launcher.dart';

import '../models/listing.dart';

class ContactOption {
  const ContactOption({required this.label, required this.url});

  final String label;
  final String url;
}

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

  /// Available channels for this listing (caller shows chooser when > 1).
  static List<ContactOption> optionsFor(Listing listing) {
    final out = <ContactOption>[];
    final wa = whatsappUrl(listing.contactPhone);
    if (wa != null) out.add(ContactOption(label: 'واتساب', url: wa));
    final tg = telegramUrl(listing.contactTelegram);
    if (tg != null) out.add(ContactOption(label: 'تلغرام', url: tg));
    return out;
  }

  static Future<bool> openUrl(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
