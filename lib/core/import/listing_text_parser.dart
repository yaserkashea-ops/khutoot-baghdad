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

    final lines = normalized.split('\n');
    final blocks = <String>[];
    final buf = StringBuffer();
    for (final line in lines) {
      final t = _prep(line);
      final startsNew = RegExp(
            r'^(?:سائق|راكب|مطلوب|ابحث|يعرض|يتوفر\s*خط|متوفر\s*خط|تكمله\s*خط|'
            r'الى\s|الي\s|السلام عليكم)',
          ).hasMatch(t) &&
          buf.isNotEmpty &&
          buf.toString().length > 40;
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

  static String _prep(String input) {
    var s = input.trim();
    s = s.replaceAll(RegExp(r'ـ+'), '');
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    s = s.replaceAll(RegExp('[أإآ]'), 'ا');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll('ؤ', 'و');
    s = s.replaceAll('ئ', 'ي');
    s = s.replaceAll(RegExp(r'[«»""„]'), '"');
    // Keep underscores (Telegram @user_name); strip other markdown noise.
    s = s.replaceAll(RegExp(r'[#*~`]+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  static ParsedListingDraft? _parseBlock(String block) {
    final text = block.trim();
    if (text.length < 8) return null;
    final prep = _prep(text);

    final warnings = <String>[];
    final type = _detectType(prep);
    if (type == null) {
      warnings.add('لم يُحدَّد إن كان سائقاً أو راكباً — اعتُبر سائقاً');
    }

    final route = _detectRouteRich(text, prep);
    var area = route.area;
    var destination = route.destination;
    var originSubs = List<String>.from(route.originSubs);

    if ((area == null || area.isEmpty) ||
        (destination == null || destination.isEmpty)) {
      final places = _findPlacesInOrder(prep);
      if (places.length >= 2) {
        area = (area == null || area.isEmpty) ? places[0] : area;
        destination =
            (destination == null || destination.isEmpty) ? places[1] : destination;
      } else if (places.length == 1) {
        area = (area == null || area.isEmpty) ? places[0] : area;
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

    final period = _detectPeriod(prep);
    final timePeriod = period ?? TimePeriod.morning;
    if (period == null) {
      warnings.add('لم يُذكر التوقيت — صباحي افتراضياً');
    }

    final genderDetected = _detectGender(prep);
    final gender = genderDetected ?? GenderRequirement.mixed;
    if (genderDetected == null) {
      warnings.add('لم يُذكر الجنس — مختلط افتراضياً');
    }

    final phone = _detectPhone(text);
    final telegram = _detectTelegram(text);
    if (phone == null && telegram == null) {
      warnings.add('لا يوجد رقم أو تلغرام واضح');
    }

    // Keep area out of originSubs duplicate.
    originSubs = originSubs
        .where((s) => _prep(s) != _prep(area!))
        .toList();

    final listing = Listing(
      id: '',
      type: type ?? ListingType.driver,
      area: area,
      destination: destination,
      timePeriod: timePeriod,
      genderRequirement: gender,
      departureTime: _detectDeparture(text),
      returnTime: _detectReturn(text),
      vehicleType: _detectVehicle(prep),
      seatsCount: _detectSeats(prep),
      contactPhone: phone,
      contactTelegram: telegram,
      originSubs: originSubs,
      destinationSubs: const [],
    );

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

  static ListingType? _detectType(String prep) {
    if (RegExp(
      r'راكب|مطلوب\s*خط|ابحث|محتاج\s*خط|اريد\s*خط|اطلب\s*خط',
    ).hasMatch(prep)) {
      return ListingType.rider;
    }
    if (RegExp(
      r'سائق|يعرض\s*خط|عندي\s*خط|يتوفر\s*خط|متوفر\s*خط|تكمله\s*خط|'
      r'خط\s*متوفر|خط\s*نقل|مقاعد\s*فارغ|صاحب\s*الخط|خط\s*\(?\s*خصوصي|'
      r'عرض\s*خط|خط\s*طالبات|خط\s*صباحي',
    ).hasMatch(prep)) {
      return ListingType.driver;
    }
    return null;
  }

  /// Word-safe helpers for "الى/الي" — `_prep` maps ى→ي so "الى" becomes "الي",
  /// which must not match inside "التاليه".
  static bool _isToTokenAt(String prep, int index) {
    if (index < 0 || index >= prep.length) return false;
    final before = index == 0 ? '' : prep[index - 1];
    final afterIdx = index + 3; // الي / الى
    final after = afterIdx >= prep.length ? '' : prep[afterIdx];
    final beforeOk = before.isEmpty || !_isArabicLetter(before);
    final afterOk = after.isEmpty || !_isArabicLetter(after);
    return beforeOk && afterOk;
  }

  static bool _isArabicLetter(String ch) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(ch);

  static int? _findToTokenIndex(String prep, [int from = 0]) {
    var i = from;
    while (i < prep.length) {
      final slice = prep.substring(i);
      final bare = RegExp(r'الي|الى').firstMatch(slice);
      if (bare == null) return null;
      final abs = i + bare.start;
      if (_isToTokenAt(prep, abs)) return abs;
      i = abs + 1;
    }
    return null;
  }

  static bool _looksLikeFalseToSplit(String a, String b) {
    // "ه (حي الجامعة..." means we split داخل التاليه
    if (RegExp(r'^ه\b').hasMatch(b)) return true;
    if (a.endsWith('الت') || a.endsWith('التا')) return true;
    return false;
  }

  static ({
    String? area,
    String? destination,
    List<String> originSubs,
  }) _detectRouteRich(String raw, String prep) {
    // 1) Labeled: منطقة الانطلاق / الوجهة
    final labeledOrigin = RegExp(
      r'(?:منطقه\s*الانطلاق|الانطلاق)\s*[:：]?\s*([^\n🎓📍🚗📞❄️]+)',
      caseSensitive: false,
    ).firstMatch(prep);
    final labeledDest = RegExp(
      r'(?:الوجهه|الوجهة|الوجه)\s*[:：]?\s*([^\n🎓📍🚗📞❄️]+)',
      caseSensitive: false,
    ).firstMatch(prep);
    if (labeledOrigin != null || labeledDest != null) {
      final aRaw = labeledOrigin == null
          ? null
          : _cleanPlaceToken(labeledOrigin.group(1)!);
      final dRaw =
          labeledDest == null ? null : _cleanPlaceToken(labeledDest.group(1)!);
      return (
        area: aRaw == null
            ? null
            : (_resolvePlace(aRaw, preferArea: true) ?? aRaw),
        destination: dRaw == null
            ? null
            : (_resolveDestinationBlob(dRaw) ??
                _resolvePlace(dRaw, preferArea: false) ??
                dRaw),
        originSubs: const [],
      );
    }

    // 2) من ( … nested … ) … الى جامعة (…) [الجادرية]
    //    before classic من–الى so nested parens are not truncated early.
    final fromParen = _detectFromParenRoute(prep);
    if (fromParen != null) return fromParen;

    // 3) Classic من X الى Y (no leading paren after من)
    final fromMatch = RegExp(
      r'(?:^|[^\u0600-\u06FF])من\s+(?![\(])(?:منطقه\s+)?',
      caseSensitive: false,
    ).firstMatch(prep);
    if (fromMatch != null) {
      final afterMin = fromMatch.end;
      final toAt = _findToTokenIndex(prep, afterMin);
      if (toAt != null && toAt > afterMin) {
        final a = _cleanPlaceToken(prep.substring(afterMin, toAt));
        final b = _cleanPlaceToken(
          prep.substring(toAt).replaceFirst(RegExp(r'^(?:الي|الى)\s*'), ''),
        );
        if (!_looksLikeFalseToSplit(a, b) && a.isNotEmpty && b.isNotEmpty) {
          final origins = _splitPassList(a);
          final area = origins.isNotEmpty
              ? origins.first
              : (_resolvePlace(a, preferArea: true) ?? a);
          final dest = _resolveDestinationBlob(b) ??
              _resolvePlace(b, preferArea: false) ??
              b;
          if (area.isNotEmpty && dest.isNotEmpty) {
            return (
              area: area,
              destination: dest,
              originSubs: origins.length > 1 ? origins.sublist(1) : const [],
            );
          }
        }
      }
    }

    // 4) Pass via Abu Ghraib style: يمر عبر X: • a • b
    final viaBullets = _detectViaBullets(raw, prep);
    if (viaBullets.area != null || viaBullets.subs.isNotEmpty) {
      final dest = _detectToDestination(prep) ??
          _resolveDestinationBlob(prep) ??
          _bestInstitution(prep);
      return (
        area: viaBullets.area ??
            (viaBullets.subs.isEmpty ? null : viaBullets.subs.first),
        destination: dest,
        originSubs: viaBullets.subs,
      );
    }

    // 5) من المناطق / A - B - C  + destination elsewhere
    final fromRegions = RegExp(
      r'(?:^|[^\u0600-\u06FF])من\s*المناطق\s*[/:]?\s*(.+?)(?:\n|الخط|صباحي|مسائي|للاستفسار|للتواصل|$)',
      caseSensitive: false,
    ).firstMatch(prep);
    if (fromRegions != null) {
      final origins = _splitPassList(fromRegions.group(1)!);
      final dest = _detectToDestination(prep) ??
          _detectDestAnywhere(prep) ??
          _bestInstitution(prep);
      return (
        area: origins.isEmpty ? null : origins.first,
        destination: dest,
        originSubs: origins,
      );
    }

    // 6) Areas list then الى DEST — only real "الى" tokens
    final listTo = _detectListThenTo(prep);
    if (listTo != null) return listTo;

    // 7) يمر بالمناطق التالية …
    final pass = _detectPassAreasDetailed(prep);
    String? destination = _detectToDestination(prep) ??
        _detectDestAnywhere(prep) ??
        _bestInstitution(prep);
    String? area = pass.area;
    var originSubs = pass.subs;

    area ??= originSubs.isNotEmpty
        ? originSubs.first
        : _firstAreaMention(prep, excluding: destination);

    return (
      area: area,
      destination: destination,
      originSubs: originSubs,
    );
  }

  static ({
    String? area,
    String? destination,
    List<String> originSubs,
  })? _detectFromParenRoute(String prep) {
    final start = RegExp(
      r'(?:^|[^\u0600-\u06FF])من\s*\(',
      caseSensitive: false,
    ).firstMatch(prep);
    if (start == null) return null;
    final openIdx = start.end - 1; // the '(' that ends the match
    if (openIdx < 0 || prep[openIdx] != '(') return null;

    // Prefer balanced close; many ads forget the outer ")" before الى.
    var closeIdx = _closingParen(prep, openIdx);
    final toInFull = _findToTokenIndex(prep, openIdx + 1);
    if (toInFull == null) return null;

    String inside;
    if (closeIdx > openIdx && closeIdx < toInFull) {
      inside = prep.substring(openIdx + 1, closeIdx);
    } else {
      // Unclosed / closes after الى — take text until الى.
      inside = prep.substring(openIdx + 1, toInFull);
    }

    final destPart = prep.substring(toInFull).replaceFirst(
          RegExp(r'^(?:الي|الى)\s*'),
          '',
        );
    final dest = _resolveDestinationBlob(destPart) ??
        _detectToDestination('الي $destPart') ??
        _bestInstitution(destPart);

    final origins = _splitPassList(
      inside.split(RegExp(r'السياره|المركبه')).first,
    ).where((o) {
      final n = _prep(o);
      return n.isNotEmpty &&
          !n.contains('خصوصي') &&
          !n.contains('راكب') &&
          !RegExp(r'^\d+$').hasMatch(n);
    }).toList();
    if (origins.isEmpty && (dest == null || dest.isEmpty)) return null;
    return (
      area: origins.isEmpty ? null : origins.first,
      destination: dest,
      originSubs: origins.length > 1 ? origins.sublist(1) : const [],
    );
  }

  static int _closingParen(String s, int openIdx) {
    var depth = 0;
    for (var i = openIdx; i < s.length; i++) {
      final ch = s[i];
      if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  static ({
    String? area,
    String? destination,
    List<String> originSubs,
  })? _detectListThenTo(String prep) {
    // Find a real الى token that is not at the very start (audience ads).
    final toIdx = _findToTokenIndex(prep);
    if (toIdx == null || toIdx < 8) return null;
    final left = prep.substring(0, toIdx).trim();
    // Trim a leading non-letter from lookbehind consume
    final leftClean = left.replaceFirst(RegExp(r'^[^\u0600-\u06FF]+'), '');
    final right = _cleanPlaceToken(prep.substring(toIdx).replaceFirst(
          RegExp(r'^(?:الي|الى)\s*'),
          '',
        ));
    if (RegExp(r'[-–—,/]').allMatches(leftClean).length >= 2 ||
        leftClean.contains('المناطق') ||
        leftClean.contains('محيط')) {
      // Avoid "يمر بالمناطق التالية" ads — those are handled in step 7.
      if (RegExp(r'يمر\s*(?:ب)?(?:المناطق|بالمناطق)').hasMatch(leftClean)) {
        return null;
      }
      final origins = _splitPassList(leftClean);
      final dest = _resolveDestinationBlob(right) ??
          _resolvePlace(right, preferArea: false) ??
          right;
      if (origins.isNotEmpty && dest.isNotEmpty) {
        return (
          area: origins.first,
          destination: dest,
          originSubs: origins,
        );
      }
    }
    return null;
  }

  static ({String? area, List<String> subs}) _detectViaBullets(
    String raw,
    String prep,
  ) {
    final head = RegExp(
      r'(?:الخط\s*)?يمر\s*عبر\s*([^:\n]+)\s*:',
      caseSensitive: false,
    ).firstMatch(prep);
    if (head == null) return (area: null, subs: const []);
    final area =
        _resolvePlace(_cleanPlaceToken(head.group(1)!), preferArea: true) ??
            _cleanPlaceToken(head.group(1)!);

    final bullets = <String>[];
    for (final line in raw.split('\n')) {
      final t = line.trim();
      if (RegExp(r'^[•\-–—*]\s*').hasMatch(t) ||
          RegExp(r'^\u2022').hasMatch(t)) {
        final item = _cleanPlaceToken(
          t.replaceFirst(RegExp(r'^[•\-–—*\u2022]\s*'), ''),
        );
        if (item.isEmpty) continue;
        // Drop nested paren note like (بدور بغداد) from name keep main
        final main = item.split('(').first.trim();
        final resolved = _resolvePlace(main, preferArea: true) ?? main;
        if (!bullets.contains(resolved)) bullets.add(resolved);
      }
    }
    return (area: area, subs: bullets);
  }

  static String? _detectToDestination(String prep) {
    final toIdx = _findToTokenIndex(prep);
    if (toIdx == null) {
      // Audience ads sometimes start with الي طالبات جامعه (…)
      if (RegExp(r'^(?:الي|الى)\s+').hasMatch(prep)) {
        return _resolveDestinationBlob(prep) ?? _bestInstitution(prep);
      }
      return null;
    }
    final after = prep.substring(toIdx).replaceFirst(
          RegExp(r'^(?:الي|الى)\s*'),
          '',
        );

    final uniParen = RegExp(
      r'.*?جامع[ةه]?\s*\(([^)]+)\)\s*(جادريه)?',
      caseSensitive: false,
    ).firstMatch(after);
    if (uniParen != null) {
      final inside =
          '${uniParen.group(1)} ${uniParen.group(2) ?? ''}'.trim();
      final resolved = _resolveDestinationBlob(inside);
      if (resolved != null) return resolved;
    }

    final toUni = RegExp(
      r'^(?:طالبات|طلبه|طلبة|طلاب|موظفي|موظفين|ماجستير)?\s*'
      r'(جامع[ةه]?\s*[\w\u0600-\u06FF\s—\-]{2,40})',
      caseSensitive: false,
    ).firstMatch(after);
    if (toUni != null) {
      final blob = _cleanPlaceToken(toUni.group(1)!);
      final resolved = _resolveDestinationBlob(blob);
      if (resolved != null) return resolved;
    }

    final toBlob = RegExp(
      r'^(.+?)(?:\s+يتوفر|\s+يمر|\s+صباحي|\s+مسائي|\s+المركبه|\s+للتواصل|\s+للاستفسار|\s+والسياره|\s+علما|$)',
      caseSensitive: false,
    ).firstMatch(after);
    if (toBlob != null) {
      final blob = _cleanPlaceToken(toBlob.group(1)!);
      final resolved = _resolveDestinationBlob(blob);
      if (resolved != null) return resolved;
      final place = _resolvePlace(blob, preferArea: false);
      if (place != null && place.trim().isNotEmpty) return place;
      if (blob.length >= 3 && blob.length <= 48) return blob;
    }
    return _resolveDestinationBlob(after) ?? _bestInstitution(after);
  }

  static String? _detectDestAnywhere(String prep) {
    // تكملة خط صباحي مجمع الجادرية / الى جامعة بغداد الجادرية
    if (RegExp(r'مجمع\s*الجادريه|مجمع\s*جادريه').hasMatch(prep)) {
      return 'مجمع الجادرية';
    }
    if (RegExp(r'جامع[ةه]?\s*النهرين').hasMatch(prep)) {
      return 'جامعة النهرين';
    }
    if (RegExp(r'جامع[ةه]?\s*بغداد\s*الجادريه|جامع[ةه]?\s*بغداد\s*جادريه')
        .hasMatch(prep)) {
      return 'جامعة بغداد — الجادرية';
    }
    if (RegExp(r'جامع[ةه]?\s*بغداد').hasMatch(prep)) {
      return 'جامعة بغداد';
    }
    return _resolveDestinationBlob(prep);
  }

  static String? _resolveDestinationBlob(String blob) {
    final n = _prep(blob);
    const preferred = <String>[
      'مجمع الجادرية',
      'جامعة بغداد — الجادرية',
      'جامعة النهرين',
      'جامعة بغداد',
      'مول الجادرية',
      'الجادرية',
    ];
    for (final p in preferred) {
      final pn = _prep(p).replaceFirst(RegExp(r'^ال'), '');
      if (pn.isEmpty) continue;
      if (n.contains(pn) ||
          n.contains(BaghdadPlaces.normalizeArabic(p)) ||
          n.contains(_prep(p.replaceAll('—', ' ')))) {
        return p;
      }
    }
    if (n.contains('مجمع') && n.contains('جادريه')) return 'مجمع الجادرية';
    if (n.contains('جادريه')) {
      if (n.contains('نهرين')) return 'جامعة النهرين';
      if (n.contains('بغداد')) return 'جامعة بغداد — الجادرية';
      return 'الجادرية';
    }
    if (n.contains('نهرين')) return 'جامعة النهرين';
    if (n.contains('بغداد') && n.contains('جامع')) {
      return 'جامعة بغداد';
    }
    return _resolvePlace(blob, preferArea: false);
  }

  static ({String? area, List<String> subs}) _detectPassAreasDetailed(
    String prep,
  ) {
    final nested = RegExp(
      r'يمر\s*(?:ب)?(?:المناطق|بالمناطق)\s*(?:التاليه|التالية)?\s+'
      r'(?!التاليه|التالية)([^\n()]{2,48}?)\s*\(([^)]+)\)',
      caseSensitive: false,
    ).firstMatch(prep);
    if (nested != null) {
      var main = _cleanPlaceToken(nested.group(1)!);
      main = main.replaceAll(RegExp(r'^(?:التاليه|التالية)\s*'), '').trim();
      if (main.isNotEmpty &&
          !RegExp(r'^(?:يمر|ب|المناطق|بالمناطق)$').hasMatch(main)) {
        final area = _resolvePlace(main, preferArea: true) ?? main;
        final subs = _splitPassList(nested.group(2)!);
        return (area: area, subs: subs);
      }
    }

    final flat = RegExp(
      r'يمر\s*(?:ب)?(?:المناطق|بالمناطق)\s*(?:التاليه|التالية)?\s*\(([^)]+)\)',
      caseSensitive: false,
    ).firstMatch(prep);
    final blob = flat?.group(1);
    if (blob == null) return (area: null, subs: const []);
    final parts = _splitPassList(blob);
    if (parts.isEmpty) return (area: null, subs: const []);
    return (area: parts.first, subs: parts);
  }

  static List<String> _splitPassList(String blob) {
    var cleaned = blob;
    cleaned = cleaned.replaceAll(
      RegExp(r'وكافه\s*المناطق\s*المجاوره|وكافة\s*المناطق\s*المجاورة'),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'والمناطق\s*(?:المحيطه|المحيطة|المجاوره).*'),
      '',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'المناطق\s*المحيطه.*|محيط\s+ابو\s*ن[وؤ]اس.*'),
      '',
    );

    final parts = cleaned
        .split(RegExp(r'\s*[-–—,/،]\s*|\s+و\s+'))
        .map(_cleanPlaceToken)
        .map((e) => e.replaceAll(RegExp(r'^\(+|\)+$'), '').trim())
        .where((e) => e.isNotEmpty)
        .where(
          (e) => !RegExp(
            r'^(?:كافه|المجاوره|المناطق|المحيطه|كامل)$',
          ).hasMatch(e),
        )
        .toList();

    final out = <String>[];
    for (final part in parts) {
      // Keep nested street note: العامرية (شارع المنظمة...) → العامرية + maybe street as sub
      final main = part.split('(').first.trim();
      if (main.isEmpty) continue;
      final resolved = _resolvePlace(main, preferArea: true) ?? main;
      if (!out.contains(resolved)) out.add(resolved);
    }
    return out;
  }

  static String? _bestInstitution(String prep) {
    String? best;
    var bestLen = 0;
    for (final opt in BaghdadPlaces.destinationsWith(const [])) {
      final n = _prep(opt);
      if (n.length < 4) continue;
      final stripped = n.startsWith('ال') ? n.substring(2) : n;
      if (!prep.contains(n) && !prep.contains(stripped)) continue;
      if (n.length >= bestLen) {
        best = opt;
        bestLen = n.length;
      }
    }
    return best;
  }

  static String? _firstAreaMention(String prep, {String? excluding}) {
    final excl = excluding == null ? '' : _prep(excluding);
    // Prefer longer area names.
    final areas = BaghdadPlaces.areasWith(const []).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final opt in areas) {
      final n = _prep(opt);
      if (n.length < 3) continue;
      if (excl.isNotEmpty && (excl.contains(n) || n.contains(excl))) continue;
      final stripped = n.startsWith('ال') ? n.substring(2) : n;
      if (prep.contains(n) || prep.contains(stripped)) return opt;
    }
    return null;
  }

  static String _cleanPlaceToken(String raw) {
    return _prep(raw)
        .replaceAll(RegExp(r'[|،,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
          RegExp(
            r'^(?:المنطقه|الحي|منطقه|طالبات|طلاب|طلبه|بنات|اناث|ذكور|ماجستير)\s+',
          ),
          '',
        )
        .trim();
  }

  static String? _resolvePlace(String token, {required bool preferArea}) {
    final options = preferArea
        ? BaghdadPlaces.areasWith(const [])
        : BaghdadPlaces.destinationsWith(const []);
    String? best;
    var bestLen = 0;
    final nToken = _prep(token);
    final nTokenNorm = BaghdadPlaces.normalizeArabic(token);
    for (final opt in options) {
      final n = _prep(opt);
      final nNorm = BaghdadPlaces.normalizeArabic(opt);
      if (n.length < 2) continue;
      final hit = nToken.contains(n) ||
          n.contains(nToken) ||
          nTokenNorm.contains(nNorm) ||
          nNorm.contains(nTokenNorm);
      if (!hit) continue;
      if (n.length > bestLen ||
          (n.length == bestLen && opt.length > (best?.length ?? 0))) {
        best = opt;
        bestLen = n.length;
      }
    }
    return best;
  }

  static List<String> _findPlacesInOrder(String prep) {
    final found = <({String name, int index, int len})>[];
    for (final opt in BaghdadPlaces.destinationsWith(const [])) {
      final n = _prep(opt);
      if (n.length < 3) continue;
      final i = prep.indexOf(n);
      if (i >= 0) found.add((name: opt, index: i, len: n.length));
    }
    found.sort((a, b) {
      final byIndex = a.index.compareTo(b.index);
      if (byIndex != 0) return byIndex;
      return b.len.compareTo(a.len);
    });
    final picked = <String>[];
    final used = <(int, int)>[];
    for (final f in found) {
      final start = f.index;
      final end = f.index + f.len;
      if (used.any((r) => start < r.$2 && end > r.$1)) continue;
      used.add((start, end));
      picked.add(f.name);
      if (picked.length >= 2) break;
    }
    return picked;
  }

  static TimePeriod? _detectPeriod(String prep) {
    if (RegExp(r'مسائي|مساء|العصر|بعد الظهر').hasMatch(prep)) {
      return TimePeriod.evening;
    }
    if (RegExp(r'صباحي|صباح|الفجر').hasMatch(prep)) {
      return TimePeriod.morning;
    }
    return null;
  }

  static GenderRequirement? _detectGender(String prep) {
    if (RegExp(r'طالبات|بنات|نساء|اناث').hasMatch(prep)) {
      return GenderRequirement.femaleOnly;
    }
    if (RegExp(r'طلبه\s*وموظف|طلبة\s*وموظف|طلاب\s*وموظف|موظفي\s*جامع')
        .hasMatch(prep)) {
      return GenderRequirement.mixed;
    }
    if (RegExp(r'ذكور|رجال|شباب فقط|طلاب فقط').hasMatch(prep)) {
      return GenderRequirement.maleOnly;
    }
    if (RegExp(r'نقل\s*طلاب|خط\s*نقل\s*طلاب').hasMatch(prep)) {
      return GenderRequirement.mixed;
    }
    if (RegExp(r'مختلط|للكل|الجميع').hasMatch(prep)) {
      return GenderRequirement.mixed;
    }
    return null;
  }

  static String? _detectDeparture(String text) {
    final m = RegExp(
      r'(?:انطلاق|خروج|يطلع|ساعه)\s*([0-9٠-٩]{1,2}[:٫.][0-9٠-٩]{2})',
    ).firstMatch(text);
    return m == null ? null : _westernDigits(m.group(1)!);
  }

  static String? _detectReturn(String text) {
    final m = RegExp(
      r'(?:عوده|عوده|رجوع|يرجع)\s*([0-9٠-٩]{1,2}[:٫.][0-9٠-٩]{2})',
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

  static String? _detectVehicle(String prep) {
    final labeled = RegExp(
      r'(?:المركبه|السياره)\s*\(([^)]+)\)',
      caseSensitive: false,
    ).firstMatch(prep);
    if (labeled != null) {
      final v = _cleanPlaceToken(labeled.group(1)!);
      if (v.isNotEmpty) return v;
    }
    if (RegExp(r'صالون\s*خصوصي').hasMatch(prep)) return 'صالون خصوصي';
    if (RegExp(r'خصوصي\s*(?:حديث|حديثه)').hasMatch(prep)) {
      return 'خصوصي حديث';
    }
    if (RegExp(r'سياره\s*حديثه|سياره\s*خصوصي').hasMatch(prep)) {
      return 'سيارة خصوصي';
    }
    if (RegExp(r'خصوصي').hasMatch(prep)) return 'خصوصي';
    if (prep.contains('فان') || prep.contains('باص صغير')) return 'فان';
    if (prep.contains('باص')) return 'باص';
    if (prep.contains('صالون')) return 'سيارة صالون';
    return null;
  }

  static int? _detectSeats(String prep) {
    final m = RegExp(
      r'([0-9٠-٩]{1,2})\s*(?:مقاعد|مقعد|راكب|ركاب|اماكن|أماكن)',
    ).firstMatch(prep);
    if (m == null) return null;
    return int.tryParse(_westernDigits(m.group(1)!));
  }

  static String? _detectPhone(String text) {
    final westernized = _westernDigits(text);
    final compact = westernized.replaceAll(RegExp(r'[\s\-()]'), '');
    final m = RegExp(r'(?:\+?964|0)?7\d{8,9}').firstMatch(compact);
    if (m == null) return null;
    var digits = m.group(0)!.replaceAll(RegExp(r'[^\d]'), '');
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
    final labeled = RegExp(
      r'(?:تلغرام|تلكرام|تيليجرام|telegram|مراسله|مراسلة)\s*[:：]?\s*(@?[A-Za-z0-9_]{3,})',
      caseSensitive: false,
    ).firstMatch(_prep(text));
    if (labeled != null) {
      final v = labeled.group(1)!;
      return v.startsWith('@') ? v : '@$v';
    }
    final via = RegExp(
      r'(?:عبر\s*)?(?:التلغرام|التلكرام)\s*(@?[A-Za-z0-9_]{3,})',
      caseSensitive: false,
    ).firstMatch(_prep(text));
    if (via != null) {
      final v = via.group(1)!;
      return v.startsWith('@') ? v : '@$v';
    }
    final user = RegExp(r'@([A-Za-z0-9_]{3,})').firstMatch(text);
    return user?.group(0);
  }
}
