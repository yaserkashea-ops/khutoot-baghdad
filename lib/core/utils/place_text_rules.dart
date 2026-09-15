import 'package:flutter/services.dart';

/// Rules for area / destination / sub-place text fields.
abstract final class PlaceTextRules {
  /// Main area / destination fields.
  static const maxLength = 20;

  /// Nested origin/destination sub-place fields.
  static const subMaxLength = 60;

  /// Blocks common link patterns (http, www, t.me, domain.tld…).
  static final RegExp linkPattern = RegExp(
    r'(https?:\/\/|www\.|t\.me\/|telegram\.me\/|bit\.ly\/|wa\.me\/|'
    r'[a-z0-9-]+\.(com|net|org|io|app|me|co|iq|info|link)(/|\b))',
    caseSensitive: false,
  );

  static bool containsLink(String value) => linkPattern.hasMatch(value);

  static String? validate(
    String? value, {
    bool required = false,
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
    return null;
  }

  static bool isAllowed(
    String value, {
    int maxLength = PlaceTextRules.maxLength,
  }) =>
      validate(value, maxLength: maxLength) == null;
}

/// Enforces max length and rejects edits that introduce a link.
class PlaceTextInputFormatter extends TextInputFormatter {
  const PlaceTextInputFormatter({this.maxLength = PlaceTextRules.maxLength});

  final int maxLength;

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
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
