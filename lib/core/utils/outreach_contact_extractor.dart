import 'phone_digits.dart';

/// One contact unit extracted from pasted outreach text.
class ExtractedOutreachContact {
  const ExtractedOutreachContact({
    this.phone,
    this.telegram,
    this.snippet,
  });

  final String? phone;
  final String? telegram;
  final String? snippet;

  bool get hasContact =>
      (phone ?? '').trim().isNotEmpty || (telegram ?? '').trim().isNotEmpty;
}

/// Pulls Iraqi phones (07x… / 11 digits) + @usernames from free text.
abstract final class OutreachContactExtractor {
  /// Local Iraqi mobile: 07XXXXXXXXX (11 digits), or +9647XXXXXXXX.
  static final RegExp _phoneLoose = RegExp(
    r'(?<![\d٠-٩۰-۹])'
    r'(?:(?:\+|00)?964[\s\u00A0\u200e\u200f\-./]*)?'
    r'0?[\s\u00A0\u200e\u200f\-./]*'
    r'7[\s\u00A0\u200e\u200f\-./]*[0-9٠-٩۰-۹]'
    r'(?:[\s\u00A0\u200e\u200f\-./]*[0-9٠-٩۰-۹]){8}'
    r'(?![\d٠-٩۰-۹])',
  );

  /// @user or ＠user (Telegram-style). Letter/digit/_ after @.
  static final RegExp _atUser = RegExp(
    r'[@＠]\s*([A-Za-z][A-Za-z0-9_]{2,31})',
  );

  static final RegExp _tMeUser = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?t\.me\/([A-Za-z][A-Za-z0-9_]{2,31})',
    caseSensitive: false,
  );

  static List<ExtractedOutreachContact> extract(String raw) {
    final text = _normalizePaste(raw);
    if (text.isEmpty) return const [];

    final phones = _allPhones(text);
    final telegrams = _allTelegrams(text);

    // Pair phone + @ from the same block when possible.
    final blocks = _splitBlocks(text);
    final out = <ExtractedOutreachContact>[];
    final seenPhone = <String>{};
    final seenTg = <String>{};

    void add(String? phone, String? telegram, String? snippet) {
      final p = phone == null ? null : _canonicalPhone(phone);
      final t = telegram == null ? null : _canonicalTelegram(telegram);
      if (p == null && t == null) return;

      if (p != null && seenPhone.contains(p)) {
        if (t != null && !seenTg.contains(t)) {
          final i = out.indexWhere((e) => e.phone == p);
          if (i >= 0 && (out[i].telegram == null || out[i].telegram!.isEmpty)) {
            out[i] = ExtractedOutreachContact(
              phone: out[i].phone,
              telegram: t,
              snippet: out[i].snippet ?? snippet,
            );
            seenTg.add(t.toLowerCase());
          }
        }
        return;
      }
      if (t != null && seenTg.contains(t.toLowerCase())) {
        if (p != null && !seenPhone.contains(p)) {
          final i = out.indexWhere(
            (e) => (e.telegram ?? '').toLowerCase() == t.toLowerCase(),
          );
          if (i >= 0 && (out[i].phone == null || out[i].phone!.isEmpty)) {
            out[i] = ExtractedOutreachContact(
              phone: p,
              telegram: out[i].telegram,
              snippet: out[i].snippet ?? snippet,
            );
            seenPhone.add(p);
          }
        }
        return;
      }

      if (p != null) seenPhone.add(p);
      if (t != null) seenTg.add(t.toLowerCase());
      out.add(ExtractedOutreachContact(phone: p, telegram: t, snippet: snippet));
    }

    for (final block in blocks) {
      final blockPhones = _allPhones(block);
      final blockTgs = _allTelegrams(block);
      if (blockPhones.isEmpty && blockTgs.isEmpty) continue;

      if (blockPhones.length == 1 && blockTgs.length == 1) {
        add(blockPhones.first, blockTgs.first, _snippet(block));
        continue;
      }
      if (blockPhones.length == 1 && blockTgs.isEmpty) {
        add(blockPhones.first, null, _snippet(block));
        continue;
      }
      if (blockTgs.length == 1 && blockPhones.isEmpty) {
        add(null, blockTgs.first, _snippet(block));
        continue;
      }
      // Multiple in one block: emit separately (still captured).
      for (final p in blockPhones) {
        add(p, null, _snippet(block));
      }
      for (final t in blockTgs) {
        add(null, t, _snippet(block));
      }
    }

    // Safety sweep — anything missed by block pairing.
    for (final p in phones) {
      add(p, null, null);
    }
    for (final t in telegrams) {
      add(null, t, null);
    }

    return out;
  }

  static String _normalizePaste(String raw) {
    var s = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Bidi / zero-width / BOM noise from Telegram/WhatsApp paste.
    s = s.replaceAll(
      RegExp(r'[\u200e\u200f\u202a-\u202e\u2066-\u2069\uFEFF\u00AD]'),
      '',
    );
    s = s.replaceAll('\u00A0', ' ');
    s = s.replaceAll('＠', '@');
    s = _westernDigits(s);
    return s.trim();
  }

  static String _westernDigits(String s) {
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      var i = eastern.indexOf(ch);
      if (i < 0) i = persian.indexOf(ch);
      buf.write(i >= 0 ? '$i' : ch);
    }
    return buf.toString();
  }

  static List<String> _splitBlocks(String raw) {
    final bySep =
        raw.split(RegExp(r'\n\s*(?:---+|===+|٭+|•{3,}|\*{3,})\s*\n'));
    if (bySep.length > 1) {
      return bySep.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    final byBlank = raw.split(RegExp(r'\n\s*\n+'));
    if (byBlank.length > 1) {
      return byBlank.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    // One contact per line only for bare lists (numbers / @handles),
    // not for prose ads that mention "رقم الهاتف" on one line and "@" on the next.
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.length > 1 && lines.every(_isBareContactLine)) {
      return lines;
    }
    return [raw.trim()];
  }

  static bool _isBareContactLine(String line) {
    if (line.length > 48) return false;
    if (_allPhones(line).isEmpty && _allTelegrams(line).isEmpty) return false;
    final arabicLetters =
        RegExp(r'[\u0600-\u06FF]').allMatches(line).length;
    return arabicLetters <= 2;
  }

  static String _snippet(String block) {
    final line = block
        .split('\n')
        .map((e) => e.trim())
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (line.length <= 80) return line;
    return '${line.substring(0, 80)}…';
  }

  /// Digits-only then canonical 9647XXXXXXXX (12–13 digits).
  static String? _canonicalPhone(String raw) {
    final digits = PhoneDigits.only(_westernDigits(raw));
    if (digits.isEmpty) return null;

    // Exact local 11 digits: 07XXXXXXXXX
    if (RegExp(r'^07\d{9}$').hasMatch(digits)) {
      return '964${digits.substring(1)}';
    }
    // Without leading 0: 7XXXXXXXXX (10 digits)
    if (RegExp(r'^7\d{9}$').hasMatch(digits)) {
      return '964$digits';
    }
    // Already international
    if (RegExp(r'^9647\d{9}$').hasMatch(digits)) {
      return digits;
    }
    if (RegExp(r'^009647\d{9}$').hasMatch(digits)) {
      return digits.substring(2);
    }

    // Fallback normalize, then require Iraqi mobile shape.
    final n = PhoneDigits.normalize(digits);
    if (RegExp(r'^9647\d{9}$').hasMatch(n)) return n;
    return null;
  }

  static String? _canonicalTelegram(String raw) {
    var v = raw.trim();
    if (v.isEmpty) return null;
    final fromUrl = _tMeUser.firstMatch(v);
    if (fromUrl != null) v = fromUrl.group(1)!;
    if (v.startsWith('@') || v.startsWith('＠')) {
      v = v.substring(1).trim();
    }
    v = v.trim();
    if (v.isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(v)) return null;
    // Telegram username: 5–32 in practice; accept 3+ for short handles in groups.
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]{2,31}$').hasMatch(v)) return null;
    return '@$v';
  }

  static List<String> _allPhones(String text) {
    final out = <String>[];
    final seen = <String>{};
    for (final m in _phoneLoose.allMatches(text)) {
      final c = _canonicalPhone(m.group(0)!);
      if (c == null || seen.contains(c)) continue;
      seen.add(c);
      out.add(c);
    }
    // Also catch compact digit runs (no separators) that the loose regex missed.
    final compact = text.replaceAll(RegExp(r'[\s\u00A0\u200e\u200f\-./()]'), '');
    for (final m in RegExp(r'0?7\d{9}').allMatches(compact)) {
      final c = _canonicalPhone(m.group(0)!);
      if (c == null || seen.contains(c)) continue;
      seen.add(c);
      out.add(c);
    }
    for (final m in RegExp(r'(?:964|00964)7\d{9}').allMatches(compact)) {
      final c = _canonicalPhone(m.group(0)!);
      if (c == null || seen.contains(c)) continue;
      seen.add(c);
      out.add(c);
    }
    return out;
  }

  static List<String> _allTelegrams(String text) {
    final out = <String>[];
    final seen = <String>{};
    void addRaw(String raw) {
      final c = _canonicalTelegram(raw);
      if (c == null) return;
      final key = c.toLowerCase();
      if (seen.contains(key)) return;
      seen.add(key);
      out.add(c);
    }

    for (final m in _tMeUser.allMatches(text)) {
      addRaw(m.group(1)!);
    }
    for (final m in _atUser.allMatches(text)) {
      addRaw(m.group(0)!);
    }
    // Labeled without @: تلغرام user_name
    for (final m in RegExp(
      r'(?:تلغرام|تلكرام|تيليجرام|telegram|مراسلة|مراسله)\s*[:：]?\s*@?\s*([A-Za-z][A-Za-z0-9_]{2,31})',
      caseSensitive: false,
    ).allMatches(text)) {
      addRaw(m.group(1)!);
    }
    return out;
  }
}
