import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.red,
      secondary: AppColors.green,
      surface: AppColors.surface,
      error: AppColors.red,
    ),
    textTheme: GoogleFonts.barlowCondensedTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.red,
      unselectedItemColor: AppColors.textDim,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: AppColors.border,
    useMaterial3: true,
  );
}
