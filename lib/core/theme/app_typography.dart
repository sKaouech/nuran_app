import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographie de l'app. Inter pour latin, Amiri pour arabe.
/// Note : Amiri est une approximation gratuite. KFGQPC Uthman Taha sera intégrée
/// plus tard (police officielle Mushaf Madinah, à embarquer en assets).
class AppTypography {
  AppTypography._();

  static const String arabicFontFamily = 'Amiri';

  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        height: 64 / 57,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        height: 52 / 45,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Style spécifique pour les versets du Coran.
  /// Line-height généreux pour respecter les diacritiques (tashkil, madd).
  static TextStyle ayahLarge(Color color) => GoogleFonts.amiri(
        fontSize: 30,
        height: 2.0,
        color: color,
        fontWeight: FontWeight.w400,
      );

  static TextStyle ayahMedium(Color color) => GoogleFonts.amiri(
        fontSize: 24,
        height: 2.0,
        color: color,
        fontWeight: FontWeight.w400,
      );

  static TextStyle ayahSmall(Color color) => GoogleFonts.amiri(
        fontSize: 20,
        height: 2.0,
        color: color,
        fontWeight: FontWeight.w400,
      );

  /// Style pour les traductions (FR/EN sous un verset).
  static TextStyle translation(Color color) => GoogleFonts.inter(
        fontSize: 14,
        height: 22 / 14,
        color: color,
        fontWeight: FontWeight.w400,
      );
}
