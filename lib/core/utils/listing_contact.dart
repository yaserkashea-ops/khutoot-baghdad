import 'package:url_launcher/url_launcher.dart';

import '../models/listing.dart';
import 'phone_digits.dart';

class ContactOption {
  const ContactOption({
    required this.label,
    required this.url,
    this.detail,
  });

  final String label;
  final String url;
  /// Visible phone / Telegram handle inside the option tile.
  final String? detail;
}

/// Opens WhatsApp or Telegram for a listing contact.
abstract final class ListingContact {
  static String? whatsappUrl(String? raw, {String? message}) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    // Full WhatsApp links as entered.
    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      if (lower.contains('wa.me') ||
          lower.contains('whatsapp.com') ||
          lower.contains('api.whatsapp.com')) {
        return value;
      }
      return null;
    }

    final digits = PhoneDigits.normalize(value);
    final String base;
    if (digits.length >= 10) {
      base = 'https://wa.me/$digits';
    } else {
      // WhatsApp username (not a phone number).
      var user = value.startsWith('@') ? value.substring(1) : value;
      user = user.trim();
      if (user.isEmpty) return null;
      if (RegExp(r'^\d+$').hasMatch(user)) return null;
      if (!RegExp(r'^[A-Za-z][A-Za-z0-9._]{2,29}$').hasMatch(user)) {
        return null;
      }
      base = 'https://wa.me/$user';
    }

    if (message == null || message.trim().isEmpty) return base;
    final sep = base.contains('?') ? '&' : '?';
    return '$base${sep}text=${Uri.encodeComponent(message.trim())}';
  }

  static String? telegramUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final user = value.startsWith('@') ? value.substring(1) : value;
    if (user.isEmpty) return null;
    // Digits-only strings are phones, not Telegram usernames.
    if (RegExp(r'^\d+$').hasMatch(user)) return null;
    return 'https://t.me/$user';
  }

  /// Native Telegram app deep link to a user chat (falls back to https if needed).
  static String? telegramAppUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    var user = value;
    final fromHttp = RegExp(
      r'(?:https?:\/\/)?(?:t\.me|telegram\.me)\/([A-Za-z0-9_]+)',
      caseSensitive: false,
    ).firstMatch(value);
    if (fromHttp != null) {
      user = fromHttp.group(1)!;
    } else if (user.startsWith('@')) {
      user = user.substring(1);
    }
    user = user.trim();
    if (user.isEmpty || RegExp(r'^\d+$').hasMatch(user)) return null;
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]{2,31}$').hasMatch(user)) return null;
    return 'tg://resolve?domain=$user';
  }

  /// Opens Telegram's share sheet with [text] already filled (unlike a DM link).
  static String telegramShareUrl({required String text, String? url}) {
    final params = <String, String>{
      'text': text.trim(),
    };
    final link = (url ?? '').trim();
    if (link.isNotEmpty) params['url'] = link;
    return Uri.https('t.me', '/share/url', params).toString();
  }

  /// Open user chat: prefer native app scheme, then https://t.me/user.
  static Future<bool> openTelegramChat(String? raw) async {
    final app = telegramAppUrl(raw);
    if (app != null) {
      final uri = Uri.parse(app);
      try {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return true;
      } catch (_) {
        // Fall through to https.
      }
    }
    final web = telegramUrl(raw);
    if (web == null) return false;
    return openUrl(web);
  }

  /// Separate phone + Telegram fields (preferred for reports).
  static List<ContactOption> optionsForChannels({
    String? phone,
    String? telegram,
    String? whatsappMessage,
  }) {
    final out = <ContactOption>[];
    final wa = whatsappUrl(phone, message: whatsappMessage);
    if (wa != null) {
      out.add(ContactOption(
        label: 'واتساب',
        url: wa,
        detail: (phone ?? '').trim().isEmpty ? null : phone!.trim(),
      ));
    }
    final tg = telegramUrl(telegram);
    if (tg != null) {
      out.add(ContactOption(
        label: 'تلغرام',
        url: tg,
        detail: (telegram ?? '').trim().isEmpty ? null : telegram!.trim(),
      ));
    }
    return out;
  }

  /// Resolve a free-text contact hint (legacy) into openable channels.
  static List<ContactOption> optionsForHint(
    String? raw, {
    String? whatsappMessage,
  }) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return const [];

    final lower = value.toLowerCase();
    final looksTelegram = value.contains('@') ||
        lower.contains('t.me') ||
        lower.contains('telegram') ||
        RegExp(r'^[A-Za-z][A-Za-z0-9_]{3,31}$').hasMatch(value);
    final digits = PhoneDigits.normalize(value);
    final looksPhone = digits.length >= 10;

    final out = <ContactOption>[];
    if (looksPhone) {
      final wa = whatsappUrl(digits, message: whatsappMessage);
      if (wa != null) {
        out.add(ContactOption(label: 'واتساب', url: wa, detail: value));
      }
    } else {
      // Username-looking value: prefer WhatsApp username, else Telegram.
      final wa = whatsappUrl(value, message: whatsappMessage);
      if (wa != null) {
        out.add(ContactOption(label: 'واتساب', url: wa, detail: value));
      } else if (looksTelegram || value.isNotEmpty) {
        final tg = telegramUrl(value);
        if (tg != null) {
          out.add(ContactOption(label: 'تلغرام', url: tg, detail: value));
        }
      }
    }
    return out;
  }

  /// Available channels for this listing (caller shows chooser when > 1).
  static List<ContactOption> optionsFor(Listing listing) {
    final out = <ContactOption>[];
    final phone = (listing.contactPhone ?? '').trim();
    final telegram = (listing.contactTelegram ?? '').trim();
    final wa = whatsappUrl(phone);
    if (wa != null) {
      out.add(ContactOption(label: 'واتساب', url: wa, detail: phone));
    }
    final tg = telegramUrl(telegram);
    if (tg != null) {
      out.add(ContactOption(label: 'تلغرام', url: tg, detail: telegram));
    }
    return out;
  }

  static Future<bool> openUrl(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
