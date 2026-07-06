import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class DipontoColors {
  static const primary = Color(0xFFFFB300);
  static const surface = Color(0xFF121212);
  static const surfaceVariant = Color(0xFF2D2D2D);
  static const cardElevated = Color(0xFF1E1E1E);
  static const onSurface = Color(0xFFFFFFFF);
  static const error = Color(0xFFFF5252);
  static const success = Color(0xFF66BB6A);
  static const primaryLight = Color(0xFFB0BEC5);
}

ThemeData buildDipontoTheme() {
  final textTheme = GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: DipontoColors.primary,
      surface: DipontoColors.surface,
      onSurface: DipontoColors.onSurface,
      error: DipontoColors.error,
    ),
    scaffoldBackgroundColor: DipontoColors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: DipontoColors.surfaceVariant,
      foregroundColor: DipontoColors.primary,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: DipontoColors.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: DipontoColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
