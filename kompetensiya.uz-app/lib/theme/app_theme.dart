// THEME LOCK: light — source: domain signal (consumer/trust/outdoor use)
// Scaffold.backgroundColor = AppTheme.backgroundLight — ALL screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary palette
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color primaryContainer = Color(0xFFD6E4FF);
  static const Color secondary = Color(0xFFF57C00);
  static const Color secondaryContainer = Color(0xFFFFE0B2);

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningContainer = Color(0xFFFFF3E0);
  static const Color errorColor = Color(0xFFC62828);
  static const Color errorContainer = Color(0xFFFFEBEE);

  // Light surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F7FA);
  static const Color backgroundLight = Color(0xFFF0F4F8);
  static const Color outlineLight = Color(0xFFE0E6ED);
  static const Color outlineVariantLight = Color(0xFFF0F4F8);

  // Dark surfaces
  static const Color surfaceDark = Color(0xFF1E2535);
  static const Color surfaceVariantDark = Color(0xFF252D3E);
  static const Color backgroundDark = Color(0xFF141A27);

  // Card accent colors (for vacancy/course cards)
  static const Color cardBlue = Color(0xFF1565C0);
  static const Color cardOrange = Color(0xFFF57C00);
  static const Color cardDark = Color(0xFF212121);
  static const Color cardGreen = Color(0xFF2E7D32);
  static const Color cardPurple = Color(0xFF6A1B9A);
  static const Color cardTeal = Color(0xFF00695C);
  static const Color cardRed = Color(0xFFC62828);
  static const Color cardIndigo = Color(0xFF283593);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF0D2B6B),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF4A2500),
      surface: surfaceLight,
      onSurface: Color(0xFF1A1A2E),
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: Color(0xFF5A6478),
      error: errorColor,
      onError: Colors.white,
      outline: outlineLight,
      outlineVariant: outlineVariantLight,
      shadow: Color(0x1A000000),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    ),
    appBarTheme: const AppBarThemeData(
      backgroundColor: surfaceLight,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Color(0x1A000000),
      iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A2E),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: surfaceLight,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceVariantLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantLight,
      selectedColor: primaryContainer,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF0D2B6B),
      onPrimaryContainer: Color(0xFFD6E4FF),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF4A2500),
      onSecondaryContainer: Color(0xFFFFE0B2),
      surface: surfaceDark,
      onSurface: Color(0xFFE6E6E6),
      surfaceContainerHighest: surfaceVariantDark,
      onSurfaceVariant: Color(0xFFADB5C7),
      error: Color(0xFFCF6679),
      onError: Colors.white,
      outline: Color(0xFF3A4255),
      outlineVariant: Color(0xFF252D3E),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: Color(0xFFE6E6E6),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: Color(0xFFE6E6E6),
        ),
        bodyLarge: TextStyle(fontSize: 15, color: Color(0xFFE6E6E6)),
        bodyMedium: TextStyle(fontSize: 13, color: Color(0xFFADB5C7)),
      ),
    ),
    appBarTheme: const AppBarThemeData(
      backgroundColor: surfaceDark,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFE6E6E6)),
    ),
  );
}
