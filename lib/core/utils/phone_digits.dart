/// Iraqi / general phone digit helpers for listing ownership lookup.
abstract final class PhoneDigits {
  static const iraqCountryCode = '964';

  static String only(String raw) =>
      raw.replaceAll(RegExp(r'[^\d]'), '');

  /// Normalize to international digits for WhatsApp (`wa.me`).
  ///
  /// Local Iraqi mobiles are accepted without a country code:
  /// `07XXXXXXXXX`, `7XXXXXXXXX` → `9647XXXXXXXXX`.
  static String normalize(String raw) {
    var d = only(raw);
    if (d.isEmpty) return '';

    // +964 / 00964 / 964…
    if (d.startsWith('00964')) d = d.substring(2);
    if (d.startsWith(iraqCountryCode)) return d;

    // Local Baghdad/Iraq mobile: 07XXXXXXXXX (11) or 7XXXXXXXXX (10).
    if (d.startsWith('0') && d.length >= 10) {
      return '$iraqCountryCode${d.substring(1)}';
    }
    if (d.length == 10 && d.startsWith('7')) {
      return '$iraqCountryCode$d';
    }
    if (d.length == 11 && d.startsWith('07')) {
      return '$iraqCountryCode${d.substring(1)}';
    }

    return d;
  }

  /// Iraqi mobile as written locally: 07XXXXXXXXX (no country code).
  static String? iraqLocal(String? raw) {
    final n = normalize(raw ?? '');
    if (!RegExp(r'^9647\d{9}$').hasMatch(n)) return null;
    return '0${n.substring(3)}';
  }

  /// Number shown on cards: local 07… never +964 / 964.
  static String forDisplay(String? raw) {
    final local = iraqLocal(raw);
    if (local != null) return local;
    return (raw ?? '').trim();
  }

  /// Digits safe for `https://wa.me/…` (always prefers 964 for local Iraq).
  static String? forWhatsApp(String? raw) {
    final n = normalize(raw ?? '');
    if (n.length < 10) return null;
    return n;
  }

  static bool matches(String? stored, String input) {
    final a = normalize(stored ?? '');
    final b = normalize(input);
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || only(stored ?? '') == only(input);
  }
}
