import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(MasaratColors.light, Brightness.light);

  static ThemeData get dark => _build(MasaratColors.dark, Brightness.dark);

  static ThemeData _build(MasaratColors c, Brightness brightness) {
    final arabic = GoogleFonts.ibmPlexSansArabicTextTheme();
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        secondary: c.accent,
        onSecondary: c.onPrimary,
        surface: c.surface,
        onSurface: c.text,
        error: c.riderAccent,
        onError: c.onPrimary,
        outline: c.border,
      ),
      extensions: [c],
    );

    return base.copyWith(
      textTheme: arabic
          .apply(bodyColor: c.text, displayColor: c.text)
          .copyWith(
            displaySmall: arabic.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
            titleLarge: arabic.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
            titleMedium: arabic.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
            bodyLarge: arabic.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
              color: c.text,
            ),
            bodyMedium: arabic.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
              color: c.text,
            ),
            labelLarge: arabic.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: c.background,
        foregroundColor: c.text,
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: c.text,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.background,
        indicatorColor: c.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.ibmPlexSansArabic(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: GoogleFonts.ibmPlexSansArabic(color: c.background),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border.withValues(alpha: 0.9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.primary.withValues(alpha: 0.9)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.riderAccent),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          minimumSize: const Size.fromHeight(44),
          side: BorderSide(color: c.primary.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.primary.withValues(alpha: 0.16),
        side: BorderSide(color: c.border),
        labelStyle: GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w400,
          fontSize: 13,
          color: c.text,
        ),
        secondaryLabelStyle: GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: c.primary,
        ),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        shape: StadiumBorder(side: BorderSide(color: c.border)),
      ),
      dividerColor: c.border,
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    );
  }

  /// Latin / digits (times, counts) — Manrope per brief.
  /// Pass [context] or [color] so dark mode stays readable.
  static TextStyle manrope({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    BuildContext? context,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ??
          (context != null ? AppColors.of(context).text : null),
    );
  }
}
