import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class DipontoColors {
  static const primary = Color(0xFFFFB300);
  static const primaryDark = Color(0xFFFF8F00);
  static const primaryLight = Color(0xFFFFD54F);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceVariant = Color(0xFF2D2D2D);
  static const onPrimary = Color(0xFF000000);
  static const onSurface = Color(0xFFFFFFFF);
  static const error = Color(0xFFFF5252);
  static const success = Color(0xFF66BB6A);
}

ThemeData buildDipontoTheme() {
  final colorScheme = ColorScheme.dark(
    primary: DipontoColors.primary,
    onPrimary: DipontoColors.onPrimary,
    secondary: DipontoColors.primaryDark,
    onSecondary: DipontoColors.onPrimary,
    surface: DipontoColors.surface,
    onSurface: DipontoColors.onSurface,
    error: DipontoColors.error,
    onError: DipontoColors.onSurface,
  );

  final textTheme = GoogleFonts.robotoTextTheme(
    ThemeData.dark().textTheme.apply(
      bodyColor: DipontoColors.onSurface,
      displayColor: DipontoColors.onSurface,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: DipontoColors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: DipontoColors.surfaceVariant,
      foregroundColor: DipontoColors.primary,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: DipontoColors.primary,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: DipontoColors.surfaceVariant,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: DipontoColors.primaryDark,
      foregroundColor: DipontoColors.onPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DipontoColors.primary,
        foregroundColor: DipontoColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DipontoColors.surfaceVariant,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DipontoColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: DipontoColors.primaryLight),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: DipontoColors.surfaceVariant,
      contentTextStyle: TextStyle(color: DipontoColors.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DipontoColors.surfaceVariant,
      indicatorColor: DipontoColors.primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: DipontoColors.onSurface),
      ),
    ),
    textTheme: textTheme,
  );
}
