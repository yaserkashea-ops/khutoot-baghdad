import 'package:flutter/services.dart';

import '../data/baghdad_places.dart';

/// Rules for area / destination / sub-place text fields.
abstract final class PlaceTextRules {
  /// Main area / destination fields.
  /// Applies to **custom** free-text places only — catalog/filter names may be longer.
  static const maxLength = 20;

  /// Upper bound for TextField when the value may be a catalog place name.
  static const listedMaxLength = 80;

  /// Custom main places (not in the list): one word or a two-word compound.
  static const maxCustomWords = 2;

  /// Nested origin/destination sub-place fields.
  static const subMaxLength = 60;

  /// Blocks common link patterns (http, www, t.me, domain.tld…).
  static final RegExp linkPattern = RegExp(
    r'(https?:\/\/|www\.|t\.me\/|telegram\.me\/|bit\.ly\/|wa\.me\/|'
    r'[a-z0-9-]+\.(com|net|org|io|app|me|co|iq|info|link)(/|\b))',
    caseSensitive: false,
  );

  /// Separators that usually mean two places were typed in one field.
  static final RegExp multiPlacePattern = RegExp(
    r'[،,/|+]|'
    r'\s+[-–—]\s+|'
    r'\s+و\s+|'
    r'\s+و(?=[\u0600-\u06FF])|'
    r'\s+(الى|إلى|إلي|الي)\s+|'
    r'\s+(and|&)\s+',
    caseSensitive: false,
  );

  /// Dots, commas, punctuation, and symbols — not allowed in custom main places.
  static final RegExp disallowedCustomChars = RegExp(
    r'[^\u0621-\u064Aa-zA-Z0-9\s]',
  );

  /// One word, or exactly two words separated by a single space (compound).
  static final RegExp customMainShape = RegExp(
    r'^[\u0621-\u064Aa-zA-Z0-9]+(?:\s[\u0621-\u064Aa-zA-Z0-9]+)?$',
  );

  static final RegExp _wordSplit = RegExp(r'\s+');

  /// Arabic or Latin letters.
  static final RegExp _letterPattern = RegExp(r'[\u0600-\u06FFa-zA-Z]');

  /// Keep only letters and digits for "meaningful" length checks.
  static final RegExp _nonAlnumPattern =
      RegExp(r'[^\u0600-\u06FFa-zA-Z0-9]');

  static bool containsLink(String value) => linkPattern.hasMatch(value);

  static bool containsMultiplePlaces(String value) =>
      multiPlacePattern.hasMatch(value.trim());

  static bool containsDisallowedCustomChars(String value) =>
      disallowedCustomChars.hasMatch(value);

  static int wordCount(String value) {
    final parts = value.trim().split(_wordSplit);
    return parts.where((w) => w.isNotEmpty).length;
  }

  /// Exact or normalized match against the known filter/list options.
  static String? resolveListed(String value, Iterable<String> options) {
    final v = value.trim();
    if (v.isEmpty) return null;
    for (final o in options) {
      if (o == v) return o;
    }
    final n = BaghdadPlaces.normalizeArabic(v);
    if (n.isEmpty) return null;
    for (final o in options) {
      if (BaghdadPlaces.normalizeArabic(o) == n) return o;
    }
    return null;
  }

  static bool isListed(String value, Iterable<String> options) =>
      resolveListed(value, options) != null;

  /// Main departure/arrival field.
  /// When [listedOnly] is true, value must match [options] (no free-text places).
  /// Catalog/filter places are accepted even if longer than [maxLength].
  static String? validateMain(
    String? value, {
    required Iterable<String> options,
    bool required = true,
    bool listedOnly = false,
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return required ? 'مطلوب' : null;
    if (containsLink(v)) {
      return 'غير مسموح بكتابة روابط هنا';
    }

    // Listed filter/catalog places win over the free-text 20-char rule.
    if (isListed(v, options)) return null;

    if (v.length > maxLength) {
      return listedOnly
          ? 'اختر منطقة من القائمة فقط — إن لم تجدها تواصل مع الإدارة'
          : 'الحد الأقصى $maxLength حرفاً للنص الحر — أو اختر منطقة من القائمة';
    }

    if (listedOnly) {
      return 'اختر منطقة من القائمة فقط — إن لم تجدها تواصل مع الإدارة';
    }

    if (containsDisallowedCustomChars(v) || !customMainShape.hasMatch(v)) {
      return 'اكتب كلمة أو كلمتين فقط بدون نقطة أو رموز أو فواصل';
    }
    if (containsMultiplePlaces(v)) {
      return 'اختر منطقة واحدة من القائمة، أو اكتب كلمة أو كلمتين';
    }
    if (wordCount(v) > maxCustomWords) {
      return 'إن لم تكن في القائمة اكتب كلمة أو كلمتين فقط (مثل: شارع حيفا)';
    }

    final meaningful = v.replaceAll(_nonAlnumPattern, '');
    if (meaningful.isEmpty ||
        meaningful.length < 2 ||
        !_letterPattern.hasMatch(v)) {
      return 'اكتب اسم منطقة واضحاً أو اختر من القائمة';
    }
    return null;
  }

  /// Canonical main place: listed name if matched, otherwise null when listed-only.
  static String? canonicalizeMain(
    String value,
    Iterable<String> options, {
    bool listedOnly = false,
  }) {
    final v = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    final listed = resolveListed(v, options);
    if (listed != null) return listed;
    if (listedOnly) return null;
    return v;
  }

  static String? validate(
    String? value, {
    bool required = false,
    bool singleOnly = false,
    int maxLength = PlaceTextRules.maxLength,
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return required ? 'مطلوب' : null;
    if (v.length > maxLength) {
      return 'الحد الأقصى $maxLength حرفاً';
    }
    if (containsLink(v)) {
      return 'غير مسموح بكتابة روابط هنا';
    }
    if (singleOnly && containsMultiplePlaces(v)) {
      return 'اكتب منطقة واحدة فقط — التفاصيل في الحقول الفرعية';
    }
    if (required) {
      final meaningful = v.replaceAll(_nonAlnumPattern, '');
      if (meaningful.isEmpty ||
          meaningful.length < 2 ||
          !_letterPattern.hasMatch(v)) {
        return 'اكتب اسم منطقة واضحاً (ليس نقطة أو حرفاً أو رمزاً فقط)';
      }
    }
    return null;
  }

  static bool isAllowed(
    String value, {
    bool singleOnly = false,
    int maxLength = PlaceTextRules.maxLength,
  }) =>
      validate(value, singleOnly: singleOnly, maxLength: maxLength) == null;
}

/// Enforces max length and rejects edits that introduce a link.
/// [singleOnly] blocks multi-place separators.
/// [maxWords] blocks typing more than N words (for custom main places).
/// [lettersWordsOnly] blocks dots, commas, and symbols while typing.
class PlaceTextInputFormatter extends TextInputFormatter {
  const PlaceTextInputFormatter({
    this.maxLength = PlaceTextRules.maxLength,
    this.singleOnly = false,
    this.maxWords,
    this.lettersWordsOnly = false,
  });

  final int maxLength;
  final bool singleOnly;
  final int? maxWords;
  final bool lettersWordsOnly;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (text.length > maxLength) {
      text = text.substring(0, maxLength);
    }
    if (PlaceTextRules.containsLink(text)) {
      return oldValue;
    }
    if (lettersWordsOnly &&
        PlaceTextRules.containsDisallowedCustomChars(text)) {
      return oldValue;
    }
    if (singleOnly && PlaceTextRules.containsMultiplePlaces(text)) {
      return oldValue;
    }
    if (maxWords != null && PlaceTextRules.wordCount(text) > maxWords!) {
      return oldValue;
    }
    // Collapse accidental double spaces while typing custom main places.
    if (lettersWordsOnly && text.contains(RegExp(r'\s{2,}'))) {
      return oldValue;
    }
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
