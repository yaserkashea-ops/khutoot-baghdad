/// Iraqi / general phone digit helpers for listing ownership lookup.
abstract final class PhoneDigits {
  static String only(String raw) =>
      raw.replaceAll(RegExp(r'[^\d]'), '');

  /// Normalize to a comparable form (prefer 964…).
  static String normalize(String raw) {
    var d = only(raw);
    if (d.isEmpty) return '';
    if (d.startsWith('964')) return d;
    if (d.startsWith('0') && d.length >= 10) return '964${d.substring(1)}';
    if (d.length == 10 && d.startsWith('7')) return '964$d';
    return d;
  }

  static bool matches(String? stored, String input) {
    final a = normalize(stored ?? '');
    final b = normalize(input);
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || only(stored ?? '') == only(input);
  }
}
