import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

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
  );
}
