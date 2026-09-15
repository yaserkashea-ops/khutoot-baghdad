import '../models/listing.dart';
import '../utils/phone_digits.dart';
import '../utils/place_text_rules.dart';

/// Guided voice-command steps for precise listing capture.
enum VoiceListingStep {
  type,
  area,
  originSubs,
  destination,
  destinationSubs,
  period,
  gender,
  phone,
  telegram,
  vehicle,
  seats,
  done,
}

extension VoiceListingStepX on VoiceListingStep {
  String get prompt => switch (this) {
        VoiceListingStep.type => 'قل نوع الإعلان: سائق، أو باحث عن خط',
        VoiceListingStep.area => 'قل منطقة الانطلاق فقط، مثال: العامرية',
        VoiceListingStep.originSubs =>
          'قل النقاط الفرعية داخل المنطقة مفصولة بـ «و»، مثال: حي الجامعة و الخضراء — أو قل تخطي',
        VoiceListingStep.destination =>
          'قل الوجهة فقط، مثال: الجادرية أو جامعة بغداد',
        VoiceListingStep.destinationSubs =>
          'قل النقاط الفرعية داخل الوجهة مفصولة بـ «و»، مثال: مجمع الجادرية و بوابة الجامعة — أو قل تخطي',
        VoiceListingStep.period => 'قل التوقيت: صباحي أو مسائي',
        VoiceListingStep.gender => 'قل الفئة: مختلط، أو اناث، أو ذكور',
        VoiceListingStep.phone =>
          'قل رقم الهاتف من 11 خانة يبدأ بـ صفر سبعة، أو قل تخطي',
        VoiceListingStep.telegram =>
          'قل يوزر تلغرام بعد كلمة تلغرام، مثال: تلغرام user، أو قل تخطي',
        VoiceListingStep.vehicle =>
          'قل نوع السيارة، مثال: خصوصي حديث، أو قل تخطي',
        VoiceListingStep.seats =>
          'قل عدد المقاعد رقمياً، مثال: ثلاثة، أو قل تخطي',
        VoiceListingStep.done =>
          'اكتملت البيانات. اختر إضافة للمسودات أو نشر مباشرة',
      };

  String get title => switch (this) {
        VoiceListingStep.type => 'النوع',
        VoiceListingStep.area => 'المنطقة',
        VoiceListingStep.originSubs => 'فرعي من',
        VoiceListingStep.destination => 'الوجهة',
        VoiceListingStep.destinationSubs => 'فرعي إلى',
        VoiceListingStep.period => 'التوقيت',
        VoiceListingStep.gender => 'الفئة',
        VoiceListingStep.phone => 'الهاتف',
        VoiceListingStep.telegram => 'تلغرام',
        VoiceListingStep.vehicle => 'السيارة',
        VoiceListingStep.seats => 'المقاعد',
        VoiceListingStep.done => 'تم',
      };

  bool get isOptional => switch (this) {
        VoiceListingStep.originSubs ||
        VoiceListingStep.destinationSubs ||
        VoiceListingStep.phone ||
        VoiceListingStep.telegram ||
        VoiceListingStep.vehicle ||
        VoiceListingStep.seats =>
          true,
        _ => false,
      };
}

class VoiceListingDraft {
  ListingType? type;
  String? area;
  List<String> originSubs = [];
  String? destination;
  List<String> destinationSubs = [];
  TimePeriod? period;
  GenderRequirement? gender;
  String? phone;
  String? telegram;
  String? vehicle;
  int? seats;

  bool get isDriver => type == ListingType.driver;

  bool get isComplete =>
      type != null &&
      (area ?? '').trim().isNotEmpty &&
      (destination ?? '').trim().isNotEmpty;

  List<VoiceListingStep> get steps {
    final base = <VoiceListingStep>[
      VoiceListingStep.type,
      VoiceListingStep.area,
      VoiceListingStep.originSubs,
      VoiceListingStep.destination,
      VoiceListingStep.destinationSubs,
      VoiceListingStep.period,
      VoiceListingStep.gender,
      VoiceListingStep.phone,
      VoiceListingStep.telegram,
    ];
    if (isDriver) {
      base.addAll([VoiceListingStep.vehicle, VoiceListingStep.seats]);
    }
    return base;
  }

  Listing? toListing() {
    if (!isComplete) return null;
    return Listing(
      id: '',
      type: type!,
      area: area!.trim(),
      destination: destination!.trim(),
      originSubs: List<String>.from(originSubs),
      destinationSubs: List<String>.from(destinationSubs),
      timePeriod: period ?? TimePeriod.morning,
      genderRequirement: gender ?? GenderRequirement.mixed,
      contactPhone: (phone ?? '').trim().isEmpty ? null : phone,
      contactTelegram: (telegram ?? '').trim().isEmpty ? null : telegram,
      vehicleType: type == ListingType.driver
          ? ((vehicle ?? '').trim().isEmpty ? null : vehicle)
          : null,
      seatsCount: type == ListingType.driver ? seats : null,
    );
  }

  List<String> get summaryLines {
    final lines = <String>[
      'النوع: ${type == null ? '—' : (type == ListingType.driver ? 'سائق' : 'باحث عن خط')}',
      'من: ${area ?? '—'}',
      'فرعي من: ${originSubs.isEmpty ? '—' : originSubs.join('، ')}',
      'إلى: ${destination ?? '—'}',
      'فرعي إلى: ${destinationSubs.isEmpty ? '—' : destinationSubs.join('، ')}',
      'التوقيت: ${period == null ? '—' : (period == TimePeriod.morning ? 'صباحي' : 'مسائي')}',
      'الفئة: ${gender == null ? '—' : switch (gender!) {
          GenderRequirement.femaleOnly => 'اناث',
          GenderRequirement.maleOnly => 'ذكور',
          GenderRequirement.mixed => 'مختلط',
        }}',
      'الهاتف: ${phone ?? '—'}',
      'تلغرام: ${telegram ?? '—'}',
    ];
    if (isDriver) {
      lines.add('السيارة: ${vehicle ?? '—'}');
      lines.add('المقاعد: ${seats?.toString() ?? '—'}');
    }
    return lines;
  }
}

class VoiceStepResult {
  const VoiceStepResult.ok(this.value, {this.skipped = false}) : error = null;
  const VoiceStepResult.fail(this.error)
      : value = null,
        skipped = false;

  final Object? value;
  final String? error;
  final bool skipped;

  bool get isOk => error == null;
}

/// Precise parsers for each guided voice step + one-shot structured line.
abstract final class VoiceListingCommands {
  static String prep(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'ـ+'), '');
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    s = s.replaceAll(RegExp('[أإآ]'), 'ا');
    s = s.replaceAll('ة', 'ه');
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  static bool isSkip(String raw) {
    final n = prep(raw);
    return RegExp(
      r'^(?:تخطي|تخطى|سكب|سkip|لا|بدون|ماكو|ما عندي|none)$',
      caseSensitive: false,
    ).hasMatch(n);
  }

  static VoiceStepResult parseStep(VoiceListingStep step, String raw) {
    if (raw.trim().isEmpty) {
      return const VoiceStepResult.fail('لم يُلتقط صوت واضح — أعد المحاولة');
    }
    return switch (step) {
      VoiceListingStep.type => _parseType(raw),
      VoiceListingStep.area => _parsePlace(raw, label: 'المنطقة'),
      VoiceListingStep.originSubs => _parseSubs(raw),
      VoiceListingStep.destination => _parsePlace(raw, label: 'الوجهة'),
      VoiceListingStep.destinationSubs => _parseSubs(raw),
      VoiceListingStep.period => _parsePeriod(raw),
      VoiceListingStep.gender => _parseGender(raw),
      VoiceListingStep.phone => _parsePhone(raw),
      VoiceListingStep.telegram => _parseTelegram(raw),
      VoiceListingStep.vehicle => _parseVehicle(raw),
      VoiceListingStep.seats => _parseSeats(raw),
      VoiceListingStep.done => const VoiceStepResult.ok(null),
    };
  }

  static void apply(
    VoiceListingDraft draft,
    VoiceListingStep step,
    Object? value,
  ) {
    switch (step) {
      case VoiceListingStep.type:
        draft.type = value as ListingType?;
      case VoiceListingStep.area:
        draft.area = value as String?;
      case VoiceListingStep.originSubs:
        draft.originSubs = value == null
            ? <String>[]
            : List<String>.from(value as List<String>);
      case VoiceListingStep.destination:
        draft.destination = value as String?;
      case VoiceListingStep.destinationSubs:
        draft.destinationSubs = value == null
            ? <String>[]
            : List<String>.from(value as List<String>);
      case VoiceListingStep.period:
        draft.period = value as TimePeriod?;
      case VoiceListingStep.gender:
        draft.gender = value as GenderRequirement?;
      case VoiceListingStep.phone:
        draft.phone = value as String?;
      case VoiceListingStep.telegram:
        draft.telegram = value as String?;
      case VoiceListingStep.vehicle:
        draft.vehicle = value as String?;
      case VoiceListingStep.seats:
        draft.seats = value as int?;
      case VoiceListingStep.done:
        break;
    }
  }

  /// One-shot structured line.
  static VoiceListingDraft? parseStructuredLine(String raw) {
    final n = prep(raw);
    if (n.length < 8) return null;

    final draft = VoiceListingDraft();
    final type = _parseType(n);
    if (type.isOk) draft.type = type.value as ListingType;

    final fromTo = RegExp(
      r'من\s+(.+?)\s+(?:الي|الى)\s+(.+?)(?:\s+صباحي|\s+مسائي|\s+مختلط|\s+اناث|\s+ذكور|\s+رقم|\s+هاتف|\s+تلغرام|\s+تلكرام|\s+يمر|\s+فرعي|$)',
    ).firstMatch(n);
    if (fromTo != null) {
      draft.area = _cleanPlace(fromTo.group(1)!);
      draft.destination = _cleanPlace(fromTo.group(2)!);
    }

    final via = RegExp(
      r'(?:يمر|فرعي من|نقاط من)\s*(?:ب)?(?:المناطق)?\s*(.+?)(?:\s+الي|\s+الى|\s+صباحي|\s+مسائي|\s+رقم|\s+تلغرام|$)',
    ).firstMatch(n);
    if (via != null) {
      final subs = _parseSubs(via.group(1)!);
      if (subs.isOk && !subs.skipped) {
        draft.originSubs = List<String>.from(subs.value as List<String>);
      }
    }

    final viaDest = RegExp(
      r'(?:فرعي الي|فرعي الى|نقاط الي|نقاط الى)\s*(.+?)(?:\s+صباحي|\s+مسائي|\s+رقم|\s+تلغرام|$)',
    ).firstMatch(n);
    if (viaDest != null) {
      final subs = _parseSubs(viaDest.group(1)!);
      if (subs.isOk && !subs.skipped) {
        draft.destinationSubs =
            List<String>.from(subs.value as List<String>);
      }
    }

    final period = _parsePeriod(n);
    if (period.isOk) draft.period = period.value as TimePeriod;
    final gender = _parseGender(n);
    if (gender.isOk) draft.gender = gender.value as GenderRequirement;

    final phone = _parsePhone(n);
    if (phone.isOk && !phone.skipped) draft.phone = phone.value as String?;

    final tgMatch = RegExp(
      r'(?:تلغرام|تلكرام|تيليجرام|telegram)\s*[:：]?\s*@?\s*([A-Za-z][A-Za-z0-9_]{2,31})',
      caseSensitive: false,
    ).firstMatch(raw);
    if (tgMatch != null) {
      draft.telegram = '@${tgMatch.group(1)}';
    }

    if (draft.type == ListingType.driver) {
      final vehicle =
          RegExp(r'(?:سياره|مركبه|خصوصي)\s*([^\d@]{2,30})').firstMatch(n);
      if (vehicle != null) {
        draft.vehicle = _cleanPlace(vehicle.group(0)!);
      }
      final seats = _parseSeats(n);
      if (seats.isOk && !seats.skipped) draft.seats = seats.value as int?;
    }

    if (!draft.isComplete) return null;
    draft.period ??= TimePeriod.morning;
    draft.gender ??= GenderRequirement.mixed;
    return draft;
  }

  static VoiceStepResult _parseType(String raw) {
    final n = prep(raw);
    if (RegExp(r'باحث|راكب|مطلوب|ابحث|محتاج|اريد خط').hasMatch(n)) {
      return const VoiceStepResult.ok(ListingType.rider);
    }
    if (RegExp(r'سائق|يعرض|عندي خط|يتوفر|متوفر|خط سائق|سواق').hasMatch(n)) {
      return const VoiceStepResult.ok(ListingType.driver);
    }
    return const VoiceStepResult.fail('قل بوضوح: سائق، أو باحث عن خط');
  }

  static VoiceStepResult _parsePlace(String raw, {required String label}) {
    if (isSkip(raw)) {
      return const VoiceStepResult.fail('هذا الحقل مطلوب — لا يمكن تخطيه');
    }
    var t = _cleanPlace(raw);
    t = t.replaceFirst(
      RegExp(r'^(?:المنطقه|الوجهه|منطقه|وجهه|من|الي|الى)\s+'),
      '',
    );
    if (t.length < 2 || t.length > PlaceTextRules.maxLength) {
      return VoiceStepResult.fail(
        'قل $label بشكل أوضح (٢–${PlaceTextRules.maxLength} حرفاً)',
      );
    }
    if (RegExp(r'https?:|www\.|t\.me').hasMatch(t)) {
      return const VoiceStepResult.fail('غير مسموح بروابط هنا');
    }
    return VoiceStepResult.ok(t);
  }

  static VoiceStepResult _parseSubs(String raw) {
    if (isSkip(raw)) return const VoiceStepResult.ok(<String>[], skipped: true);
    var t = prep(raw);
    t = t.replaceFirst(
      RegExp(
        r'^(?:يمر|بالنقاط|نقاط|فرعي|فرعيه|المناطق|التاليه|التالية)\s*',
      ),
      '',
    );
    final parts = t
        .split(RegExp(r'\s+و\s+|\s*[-–—,/،]\s*|\s+ثم\s+'))
        .map(_cleanPlace)
        .where((e) => e.length >= 2)
        .where((e) => e.length <= PlaceTextRules.subMaxLength)
        .where((e) => !RegExp(r'^(?:تخطي|تخطى)$').hasMatch(e))
        .toList();
    if (parts.isEmpty) {
      return const VoiceStepResult.fail(
        'قل نقاطاً مفصولة بـ و، أو قل تخطي',
      );
    }
    return VoiceStepResult.ok(parts);
  }

  static VoiceStepResult _parsePeriod(String raw) {
    final n = prep(raw);
    if (RegExp(r'مسائي|مساء|عصر|بعد الظهر').hasMatch(n)) {
      return const VoiceStepResult.ok(TimePeriod.evening);
    }
    if (RegExp(r'صباحي|صباح|فجر').hasMatch(n)) {
      return const VoiceStepResult.ok(TimePeriod.morning);
    }
    return const VoiceStepResult.fail('قل: صباحي أو مسائي');
  }

  static VoiceStepResult _parseGender(String raw) {
    final n = prep(raw);
    if (RegExp(r'طالبات|بنات|نساء|اناث|انثي').hasMatch(n)) {
      return const VoiceStepResult.ok(GenderRequirement.femaleOnly);
    }
    if (RegExp(r'ذكور|رجال|شباب فقط|اولاد').hasMatch(n)) {
      return const VoiceStepResult.ok(GenderRequirement.maleOnly);
    }
    if (RegExp(r'مختلط|للكل|الجميع|الكل').hasMatch(n)) {
      return const VoiceStepResult.ok(GenderRequirement.mixed);
    }
    return const VoiceStepResult.fail('قل: مختلط أو اناث أو ذكور');
  }

  static VoiceStepResult _parsePhone(String raw) {
    if (isSkip(raw)) return const VoiceStepResult.ok(null, skipped: true);
    final digits = _spokenToDigits(raw);
    final compact = digits.replaceAll(RegExp(r'\D'), '');
    var n = PhoneDigits.normalize(compact);
    if (RegExp(r'^07\d{9}$').hasMatch(compact)) {
      n = PhoneDigits.normalize(compact);
    } else if (RegExp(r'^7\d{9}$').hasMatch(compact)) {
      n = PhoneDigits.normalize('0$compact');
    }
    if (!RegExp(r'^9647\d{9}$').hasMatch(n)) {
      return const VoiceStepResult.fail(
        'قل الرقم كاملاً مثل: صفر سبعة سبعة … أو قل تخطي',
      );
    }
    return VoiceStepResult.ok(n);
  }

  static VoiceStepResult _parseTelegram(String raw) {
    if (isSkip(raw)) return const VoiceStepResult.ok(null, skipped: true);
    var t = raw.trim();
    t = t.replaceFirst(
      RegExp(
        r'^(?:تلغرام|تلكرام|تيليجرام|telegram|يوزر|معرف)\s*[:：]?\s*',
        caseSensitive: false,
      ),
      '',
    );
    t = t.replaceFirst(RegExp(r'^(?:at|أت|اات)\s+', caseSensitive: false), '');
    t = t.replaceAll(' ', '');
    t = t.replaceAll('＠', '@');
    if (t.startsWith('@')) t = t.substring(1);
    t = t.replaceAll(
      RegExp(r'(?:اندروسكور|اندرسكور|تحت|_)+', caseSensitive: false),
      '_',
    );
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]{2,31}$').hasMatch(t)) {
      return const VoiceStepResult.fail(
        'قل: تلغرام ثم اليوزر بالإنجليزية، أو قل تخطي',
      );
    }
    return VoiceStepResult.ok('@$t');
  }

  static VoiceStepResult _parseVehicle(String raw) {
    if (isSkip(raw)) return const VoiceStepResult.ok(null, skipped: true);
    final t = _cleanPlace(raw);
    if (t.length < 2) {
      return const VoiceStepResult.fail('قل نوع السيارة أو تخطي');
    }
    return VoiceStepResult.ok(t);
  }

  static VoiceStepResult _parseSeats(String raw) {
    if (isSkip(raw)) return const VoiceStepResult.ok(null, skipped: true);
    final digits = _spokenToDigits(raw).replaceAll(RegExp(r'\D'), '');
    final n = int.tryParse(digits);
    if (n == null || n < 1 || n > 14) {
      return const VoiceStepResult.fail('قل عدداً بين 1 و 14، أو تخطي');
    }
    return VoiceStepResult.ok(n);
  }

  static String _cleanPlace(String raw) {
    return prep(raw)
        .replaceAll(RegExp(r'[«»""]'), '')
        .replaceAll(RegExp(r'^[\s،,.\-]+|[\s،,.\-]+$'), '')
        .trim();
  }

  static String _spokenToDigits(String raw) {
    var s = prep(raw);
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      var i = eastern.indexOf(ch);
      if (i < 0) i = persian.indexOf(ch);
      buf.write(i >= 0 ? '$i' : ch);
    }
    s = buf.toString();

    const words = <String, String>{
      'صفر': '0',
      'زبرو': '0',
      'واحد': '1',
      'واحده': '1',
      'اثنين': '2',
      'اثنان': '2',
      'ثنين': '2',
      'ثلاثه': '3',
      'ثلاث': '3',
      'اربعه': '4',
      'اربع': '4',
      'خمسه': '5',
      'خمس': '5',
      'سته': '6',
      'ست': '6',
      'سبعه': '7',
      'سبع': '7',
      'ثمانيه': '8',
      'ثمان': '8',
      'ثماني': '8',
      'تسعه': '9',
      'تسع': '9',
    };

    final keys = words.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final w in keys) {
      s = s.replaceAll(w, words[w]!);
    }
    return s;
  }
}
