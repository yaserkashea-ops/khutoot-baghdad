import '../data/baghdad_places.dart';
import '../models/listing.dart';

/// One parsed draft from a Telegram/SMS block before publish.
class ParsedListingDraft {
  const ParsedListingDraft({
    required this.sourceText,
    required this.listing,
    required this.warnings,
    required this.selected,
  });

  final String sourceText;
  final Listing listing;
  final List<String> warnings;
  final bool selected;

  bool get isPublishable =>
      listing.area.trim().isNotEmpty && listing.destination.trim().isNotEmpty;

  ParsedListingDraft copyWith({
    Listing? listing,
    List<String>? warnings,
    bool? selected,
  }) {
    return ParsedListingDraft(
      sourceText: sourceText,
      listing: listing ?? this.listing,
      warnings: warnings ?? this.warnings,
      selected: selected ?? this.selected,
    );
  }
}

/// Parses pasted Telegram-group / SMS transit ads into listing drafts.
abstract final class ListingTextParser {
  static List<ParsedListingDraft> parse(String raw) {
    final blocks = _splitBlocks(raw);
    final drafts = <ParsedListingDraft>[];
    for (final block in blocks) {
      final draft = _parseBlock(block);
      if (draft != null) drafts.add(draft);
    }
    return drafts;
  }

  static List<String> _splitBlocks(String raw) {
    final normalized = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    if (normalized.isEmpty) return const [];

    // Explicit separators used when pasting many Telegram messages.
    final bySep = normalized.split(
      RegExp(r'\n\s*(?:---+|===+|٭+|•{3,}|\*{3,})\s*\n'),
    );
    if (bySep.length > 1) {
      return bySep.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    final byBlank = normalized.split(RegExp(r'\n\s*\n+'));
    if (byBlank.length > 1) {
      return byBlank.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    // Heuristic: a new message often starts with سائق/راكب/مطلوب/من
    final lines = normalized.split('\n');
    final blocks = <String>[];
    final buf = StringBuffer();
    for (final line in lines) {
      final t = line.trim();
      final startsNew = RegExp(
            r'^(?:سائق|راكب|مطلوب|أبحث|ابحث|يعرض|من\s)',
          ).hasMatch(t) &&
          buf.isNotEmpty;
      if (startsNew) {
        blocks.add(buf.toString().trim());
        buf.clear();
      }
      if (buf.isNotEmpty) buf.writeln();
      buf.write(line);
    }
    if (buf.isNotEmpty) blocks.add(buf.toString().trim());
    return blocks.where((e) => e.isNotEmpty).toList();
  }

  static ParsedListingDraft? _parseBlock(String block) {
    final text = block.trim();
    if (text.length < 8) return null;

    final warnings = <String>[];
    final type = _detectType(text);
    if (type == null) {
      warnings.add('لم يُحدَّد إن كان سائقاً أو راكباً — اعتُبر سائقاً');
    }

    final route = _detectRoute(text);
    var area = route.$1;
    var destination = route.$2;

    if (area == null || destination == null) {
      final places = _findPlacesInOrder(text);
      if (places.length >= 2) {
        area ??= places[0];
        destination ??= places[1];
      } else if (places.length == 1) {
        area ??= places[0];
      }
    }

    if (area == null || area.isEmpty) {
      warnings.add('تعذر استخراج المنطقة');
      area = '';
    }
    if (destination == null || destination.isEmpty) {
      warnings.add('تعذر استخراج الوجهة');
      destination = '';
    }

    final timePeriod = _detectPeriod(text) ?? TimePeriod.morning;
    if (_detectPeriod(text) == null) {
      warnings.add('لم يُذكر التوقيت — صباحي افتراضياً');
    }

    final gender = _detectGender(text) ?? GenderRequirement.mixed;
    if (_detectGender(text) == null) {
      warnings.add('لم يُذكر الجنس — مختلط افتراضياً');
    }

    final phone = _detectPhone(text);
    final telegram = _detectTelegram(text);
    if (phone == null && telegram == null) {
      warnings.add('لا يوجد رقم أو تلغرام واضح');
    }

    final listing = Listing(
      id: '',
      type: type ?? ListingType.driver,
      area: area,
      destination: destination,
      timePeriod: timePeriod,
      genderRequirement: gender,
      departureTime: _detectDeparture(text),
      returnTime: _detectReturn(text),
      vehicleType: _detectVehicle(text),
      seatsCount: _detectSeats(text),
      contactPhone: phone,
      contactTelegram: telegram,
      originSubs: const [],
      destinationSubs: const [],
    );

    // Skip junk that has neither route nor contact.
    if (listing.area.isEmpty &&
        listing.destination.isEmpty &&
        phone == null &&
        telegram == null) {
      return null;
    }

    return ParsedListingDraft(
      sourceText: text,
      listing: listing,
      warnings: warnings,
      selected: listing.area.isNotEmpty && listing.destination.isNotEmpty,
    );
  }

  static ListingType? _detectType(String text) {
    final n = BaghdadPlaces.normalizeArabic(text);
    if (RegExp(r'راكب|مطلوب\s*خط|ابحث|أبحث|محتاج\s*خط|اريد\s*خط').hasMatch(n)) {
      return ListingType.rider;
    }
    if (RegExp(r'سائق|يعرض\s*خط|عندي\s*خط|خط\s*متوفر|مقاعد\s*فارغه|مقاعد\s*فارغة')
        .hasMatch(n)) {
      return ListingType.driver;
    }
    return null;
  }

  static (String?, String?) _detectRoute(String text) {
    final patterns = <RegExp>[
      RegExp(
        r'من\s+(.+?)\s+(?:إلى|الى|إلي|الي|لـ|→|->|←)\s*(.+?)(?:\n|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'من\s+(.+?)\s+ل(ال\S.+?)(?:\n|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'^(.+?)\s*(?:←|->|→|–|-|—)\s*(.+?)(?:\n|$)',
        multiLine: true,
      ),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(text);
      if (m == null) continue;
      final a = _cleanPlaceToken(m.group(1)!);
      final b = _cleanPlaceToken(m.group(2)!);
      final area = _resolvePlace(a, preferArea: true) ?? a;
      final dest = _resolvePlace(b, preferArea: false) ?? b;
      if (area.isNotEmpty && dest.isNotEmpty) return (area, dest);
    }
    return (null, null);
  }

  static String _cleanPlaceToken(String raw) {
    return raw
        .replaceAll(RegExp(r'[|،,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^(?:المنطقة|الحي|منطقة)\s+'), '')
        .trim();
  }

  static String? _resolvePlace(String token, {required bool preferArea}) {
    final options = preferArea
        ? BaghdadPlaces.areasWith(const [])
        : BaghdadPlaces.destinationsWith(const []);
    // Exact-ish longest containment match.
    String? best;
    var bestLen = 0;
    final nToken = BaghdadPlaces.normalizeArabic(token);
    for (final opt in options) {
      final n = BaghdadPlaces.normalizeArabic(opt);
      if (n.length < 2) continue;
      if ((nToken.contains(n) || n.contains(nToken)) && n.length >= bestLen) {
        // Prefer longer official names.
        if (n.length > bestLen ||
            (n.length == bestLen && opt.length > (best?.length ?? 0))) {
          best = opt;
          bestLen = n.length;
        }
      }
    }
    return best;
  }

  static List<String> _findPlacesInOrder(String text) {
    final nText = BaghdadPlaces.normalizeArabic(text);
    final found = <({String name, int index, int len})>[];
    for (final opt in BaghdadPlaces.destinationsWith(const [])) {
      final n = BaghdadPlaces.normalizeArabic(opt);
      if (n.length < 3) continue;
      final i = nText.indexOf(n);
      if (i >= 0) {
        found.add((name: opt, index: i, len: n.length));
      }
    }
    found.sort((a, b) {
      final byIndex = a.index.compareTo(b.index);
      if (byIndex != 0) return byIndex;
      return b.len.compareTo(a.len);
    });
    // Drop overlapping shorter matches.
    final picked = <String>[];
    final used = <(int, int)>[];
    for (final f in found) {
      final start = f.index;
      final end = f.index + f.len;
      final overlaps = used.any((r) => start < r.$2 && end > r.$1);
      if (overlaps) continue;
      used.add((start, end));
      picked.add(f.name);
      if (picked.length >= 2) break;
    }
    return picked;
  }

  static TimePeriod? _detectPeriod(String text) {
    final n = BaghdadPlaces.normalizeArabic(text);
    if (RegExp(r'مسائي|مساء|العصر|بعد الظهر').hasMatch(n)) {
      return TimePeriod.evening;
    }
    if (RegExp(r'صباحي|صباح|الفجر').hasMatch(n)) {
      return TimePeriod.morning;
    }
    return null;
  }

  static GenderRequirement? _detectGender(String text) {
    final n = BaghdadPlaces.normalizeArabic(text);
    if (RegExp(r'بنات|نساء|اناث|إناث|طالبات').hasMatch(n)) {
      return GenderRequirement.femaleOnly;
    }
    if (RegExp(r'ذكور|رجال|شباب فقط|طلاب فقط').hasMatch(n)) {
      return GenderRequirement.maleOnly;
    }
    if (RegExp(r'مختلط|للكل|الجميع').hasMatch(n)) {
      return GenderRequirement.mixed;
    }
    return null;
  }

  static String? _detectDeparture(String text) {
    final m = RegExp(
      r'(?:انطلاق|خروج|يطلع|ساعة)?\s*([0-9٠-٩]{1,2}[:٫.][0-9٠-٩]{2})',
    ).firstMatch(text);
    if (m != null) return _westernDigits(m.group(1)!);
    // Morning default time mention without label — take first clock-like.
    final any = RegExp(r'([0-9٠-٩]{1,2}[:٫.][0-9٠-٩]{2})').firstMatch(text);
    return any == null ? null : _westernDigits(any.group(1)!);
  }

  static String? _detectReturn(String text) {
    final m = RegExp(
      r'(?:عوده|عودة|رجوع|يرجع)\s*([0-9٠-٩]{1,2}[:٫.][0-9٠-٩]{2})',
    ).firstMatch(text);
    return m == null ? null : _westernDigits(m.group(1)!);
  }

  static String _westernDigits(String s) {
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      final i = eastern.indexOf(ch);
      buf.write(i >= 0 ? '$i' : (ch == '٫' ? ':' : ch));
    }
    return buf.toString().replaceAll('.', ':');
  }

  static String? _detectVehicle(String text) {
    final n = BaghdadPlaces.normalizeArabic(text);
    if (n.contains('فان') || n.contains('باص صغير')) return 'فان';
    if (n.contains('باص')) return 'باص';
    if (n.contains('صالون') || n.contains('سياره') || n.contains('سيارة')) {
      return 'سيارة صالون';
    }
    return null;
  }

  static int? _detectSeats(String text) {
    final m = RegExp(
      r'([0-9٠-٩]{1,2})\s*(?:مقاعد|مقعد|اماكن|أماكن)',
    ).firstMatch(text);
    if (m == null) return null;
    return int.tryParse(_westernDigits(m.group(1)!));
  }

  static String? _detectPhone(String text) {
    final m = RegExp(
      r'(?:\+?964|0)?7[0-9٠-٩]{8,9}',
    ).firstMatch(text.replaceAll(RegExp(r'[\s\-()]'), ''));
    if (m == null) return null;
    var digits = _westernDigits(m.group(0)!).replaceAll(RegExp(r'[^\d+]'), '');
    digits = digits.replaceAll('+', '');
    if (digits.startsWith('964')) return digits;
    if (digits.startsWith('0')) return '964${digits.substring(1)}';
    if (digits.startsWith('7')) return '964$digits';
    return digits;
  }

  static String? _detectTelegram(String text) {
    final link = RegExp(
      r'(https?:\/\/)?t\.me\/[A-Za-z0-9_]{3,}',
      caseSensitive: false,
    ).firstMatch(text);
    if (link != null) {
      final v = link.group(0)!;
      return v.startsWith('http') ? v : 'https://$v';
    }
    final user = RegExp(r'@([A-Za-z0-9_]{3,})').firstMatch(text);
    return user?.group(0);
  }
}
