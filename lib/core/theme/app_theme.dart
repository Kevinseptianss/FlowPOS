import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static OutlineInputBorder _border([Color color = AppPallete.divider]) =>
      OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 3),
        borderRadius: BorderRadius.circular(10),
      );

  static final lightThemeMode = ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppPallete.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppPallete.primary,
      foregroundColor: AppPallete.onPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.all(27),
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(AppPallete.primary),
      errorBorder: _border(AppPallete.error),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      ),
    ),
  );
}
