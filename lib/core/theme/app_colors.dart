import 'package:flutter/material.dart';

/// Brand palette — light and dark variants via [ThemeExtension].
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

  /// Day — product brief tokens.
  static const light = MasaratColors(
    background: Color(0xFFFAF7F2),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF2B2621),
    primary: Color(0xFF1E4D4A),
    onPrimary: Color(0xFFFAF7F2),
    accent: Color(0xFFC08A2E),
    riderAccent: Color(0xFFB5623F),
    border: Color(0xFFE4DFD5),
  );

  /// Night — deep teal ink, warm text, lifted accents (no purple/glow).
  static const dark = MasaratColors(
    background: Color(0xFF0F1615),
    surface: Color(0xFF1A2221),
    text: Color(0xFFEDE8E0),
    primary: Color(0xFF6BA8A2),
    onPrimary: Color(0xFF0F1615),
    accent: Color(0xFFD4A354),
    riderAccent: Color(0xFFC97B5C),
    border: Color(0xFF2E3A38),
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
  static const Color background = Color(0xFFFAF7F2);
  static const Color primary = Color(0xFF1E4D4A);
  static const Color text = Color(0xFF2B2621);
  static const Color accent = Color(0xFFC08A2E);
  static const Color riderAccent = Color(0xFFB5623F);
  static const Color border = Color(0xFFE4DFD5);
}

extension MasaratColorsX on BuildContext {
  MasaratColors get colors => AppColors.of(this);
}
