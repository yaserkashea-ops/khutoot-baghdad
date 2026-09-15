import 'phone_digits.dart';

/// Normalized keys for detecting duplicate listing contacts.
abstract final class ContactKeys {
  /// Phone digits (964…) or WhatsApp username (lowercase).
  static String? whatsappKey(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    final digits = PhoneDigits.normalize(value);
    if (digits.length >= 10) return 'p:$digits';

    var user = value.toLowerCase();
    if (user.startsWith('http://') || user.startsWith('https://')) {
      final m = RegExp(
        r'(?:wa\.me|whatsapp\.com)/(?:u/)?(@?[a-z0-9._]{3,})',
        caseSensitive: false,
      ).firstMatch(user);
      if (m != null) user = m.group(1)!;
    }
    if (user.startsWith('@')) user = user.substring(1);
    user = user.trim();
    if (user.isEmpty || RegExp(r'^\d+$').hasMatch(user)) return null;
    if (!RegExp(r'^[a-z][a-z0-9._]{2,29}$').hasMatch(user)) return null;
    return 'u:$user';
  }

  /// Kept for phone-only ownership matching.
  static String? phoneKey(String? raw) {
    final n = PhoneDigits.normalize(raw ?? '');
    if (n.length < 10) return null;
    return n;
  }

  /// Lowercase username without @ / t.me prefix.
  static String? telegramKey(String? raw) {
    var v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return null;

    final fromUrl = RegExp(
      r'(?:https?://)?(?:t\.me|telegram\.me)/(@?[a-z0-9_]{3,})',
      caseSensitive: false,
    ).firstMatch(v);
    if (fromUrl != null) {
      v = fromUrl.group(1)!;
    }

    if (v.startsWith('@')) v = v.substring(1);
    v = v.trim();
    if (v.isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(v)) return null;
    if (!RegExp(r'^[a-z0-9_]{3,}$').hasMatch(v)) return null;
    return v;
  }
}
