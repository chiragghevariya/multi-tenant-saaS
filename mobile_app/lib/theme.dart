import 'package:flutter/material.dart';

/// Brand accent — indigo, matching the Vue admin panel (#4F46E5).
const Color kPrimary = Color(0xFF4F46E5);

/// Light indigo used for soft backgrounds (chips, info bars).
const Color kPrimarySoft = Color(0xFFEEF2FF);

/// Builds the app-wide Material 3 theme.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, primary: kPrimary),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
