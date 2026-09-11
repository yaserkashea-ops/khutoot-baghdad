import 'package:flutter/material.dart';

/// Brand palette aligned with the app icon (deep teal + gold).
@immutable
class MasaratColors extends ThemeExtension<MasaratColors> {
  const MasaratColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.riderAccent,
    required this.border,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color riderAccent;
  final Color border;

  /// Day — deep teal frame / gold accent from icon.
  static const light = MasaratColors(
    background: Color(0xFFF4F8F7),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF102221),
    primary: Color(0xFF053F3E),
    onPrimary: Color(0xFFF4F8F7),
    accent: Color(0xFFC5A059),
    riderAccent: Color(0xFFB5623F),
    border: Color(0xFFD5E2E0),
  );

  /// Night — icon forest teal, mint actions, gold sparingly.
  static const dark = MasaratColors(
    background: Color(0xFF02130D),
    surface: Color(0xFF0A2422),
    text: Color(0xFFF0F5F4),
    primary: Color(0xFF5FBDB4),
    onPrimary: Color(0xFF02130D),
    accent: Color(0xFFD4AF37),
    riderAccent: Color(0xFFC97B5C),
    border: Color(0xFF1A3532),
  );

  @override
  MasaratColors copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? riderAccent,
    Color? border,
  }) {
    return MasaratColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      riderAccent: riderAccent ?? this.riderAccent,
      border: border ?? this.border,
    );
  }

  @override
  MasaratColors lerp(ThemeExtension<MasaratColors>? other, double t) {
    if (other is! MasaratColors) return this;
    return MasaratColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      riderAccent: Color.lerp(riderAccent, other.riderAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

/// Convenience accessors. Prefer [of] inside widgets.
abstract final class AppColors {
  static MasaratColors of(BuildContext context) {
    return Theme.of(context).extension<MasaratColors>() ?? MasaratColors.light;
  }

  /// Light-brief defaults for non-widget / fallback use.
  static const Color background = Color(0xFFF4F8F7);
  static const Color primary = Color(0xFF053F3E);
  static const Color text = Color(0xFF102221);
  static const Color accent = Color(0xFFC5A059);
  static const Color riderAccent = Color(0xFFB5623F);
  static const Color border = Color(0xFFD5E2E0);
}

extension MasaratColorsX on BuildContext {
  MasaratColors get colors => AppColors.of(this);
}
