import 'package:flutter/material.dart';

/// Brand accent — indigo, matching the Vue admin panel (#4F46E5).
const Color kPrimary = Color(0xFF4F46E5);

/// Light indigo used for soft backgrounds (chips, info bars).
const Color kPrimarySoft = Color(0xFFEEF2FF);

/// Slate colors for premium SaaS neutrals (slate scale)
const Color kSlate50 = Color(0xFFF8FAFC);
const Color kSlate100 = Color(0xFFF1F5F9);
const Color kSlate200 = Color(0xFFE2E8F0);
const Color kSlate300 = Color(0xFFCBD5E1);
const Color kSlate500 = Color(0xFF64748B);
const Color kSlate700 = Color(0xFF334155);
const Color kSlate800 = Color(0xFF1E293B);
const Color kSlate900 = Color(0xFF0F172A);
const Color kSlate950 = Color(0xFF020617);

/// Status colors
const Color kSuccess = Color(0xFF10B981);
const Color kSuccessSoft = Color(0xFFD1FAE5);
const Color kWarning = Color(0xFFF59E0B);
const Color kWarningSoft = Color(0xFFFEF3C7);
const Color kError = Color(0xFFEF4444);
const Color kErrorSoft = Color(0xFFFEE2E2);

/// Legacy alias for light theme, for backward compatibility.
ThemeData buildAppTheme() => buildLightTheme();

/// Builds the app-wide Light Theme.
ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      surface: Colors.white,
      background: kSlate50,
      error: kError,
    ),
    scaffoldBackgroundColor: kSlate50,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kSlate900,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: kSlate900,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: kSlate900),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kSlate100, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kSlate100, width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: kSlate900,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kSlate200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kSlate200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 2),
      ),
      labelStyle: const TextStyle(color: kSlate500, fontSize: 14),
      hintStyle: const TextStyle(color: kSlate300, fontSize: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kSlate700,
        side: const BorderSide(color: kSlate200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kSlate100,
      labelStyle: const TextStyle(color: kSlate700, fontSize: 12, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      indicatorColor: kPrimarySoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.bold);
        }
        return const TextStyle(color: kSlate500, fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: kPrimary);
        }
        return const IconThemeData(color: kSlate500);
      }),
    ),
  );
}

/// Builds the app-wide Dark Theme.
ThemeData buildDarkTheme() {
  const darkBg = Color(0xFF0F172A); // Slate 900
  const darkSurface = Color(0xFF1E293B); // Slate 800
  const darkCard = Color(0xFF1E293B); // Slate 800
  const darkPrimary = Color(0xFF818CF8); // Indigo 400 (easier to read on dark)

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      primaryContainer: Color(0xFF2E3875), // Dark indigo for containers (contrast against primary)
      onPrimaryContainer: Color(0xFFE0E7FF), // Light indigo for elements inside container
      surface: darkSurface,
      background: darkBg,
      error: kError,
    ),
    scaffoldBackgroundColor: darkBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155), width: 1), // Slate 700
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0B0F19), // Darker Slate inputs
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: const Color(0xFF0F172A), // Slate 900
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE2E8F0),
        side: const BorderSide(color: Color(0xFF334155)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF334155),
      labelStyle: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 12, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkBg,
      elevation: 8,
      indicatorColor: const Color(0xFF1E1B4B), // Dark indigo soft
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: darkPrimary, fontSize: 12, fontWeight: FontWeight.bold);
        }
        return const TextStyle(color: Color(0xFF94A3B8), fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: darkPrimary);
        }
        return const IconThemeData(color: Color(0xFF94A3B8));
      }),
    ),
  );
}
