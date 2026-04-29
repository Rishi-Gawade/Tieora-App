import 'package:flutter/material.dart';

class AppTheme {
  // ===== BRAND COLORS =====

  // Primary Blue (buttons, active states)
  static const Color primaryBlue = Color(0xFF1D4ED8);

  // Pure white background
  static const Color backgroundWhite = Colors.white;

  // Main black text
  static const Color textBlack = Colors.black;

  // Sub text (slightly muted)
  static const Color textGrey = Color(0xFF6B7280);

  // Light border for cards & inputs
  static const Color borderLight = Color(0xFFE5E7EB);

  // Global border radius
  static const double defaultRadius = 14;

  // ================= LIGHT THEME =================
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Entire app background
    scaffoldBackgroundColor: backgroundWhite,

    // Core color system
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryBlue,
      surface: Colors.white,
    ),

    // ================= TEXT THEME =================
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: textBlack,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textBlack,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: textGrey,
        fontSize: 12,
      ),
      titleMedium: TextStyle(
        color: textBlack,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),

    // ================= APP BAR =================
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textBlack,
      elevation: 0,
      centerTitle: false,
    ),

    // ================= CARD STYLE =================
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(defaultRadius),
        side: const BorderSide(color: borderLight),
      ),
    ),

    // ================= INPUT FIELDS =================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(defaultRadius),
        borderSide: const BorderSide(color: borderLight),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(defaultRadius),
        borderSide:
            const BorderSide(color: primaryBlue, width: 1.5),
      ),

      hintStyle: const TextStyle(color: textGrey),
    ),

    // ================= BUTTON STYLE =================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(defaultRadius),
        ),
        elevation: 0,
      ),
    ),

    // ================= CHIP STYLE =================
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFE0E7FF),
      selectedColor: primaryBlue,
      labelStyle: const TextStyle(color: textBlack),
      secondaryLabelStyle:
          const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(defaultRadius),
      ),
    ),

    // ================= BOTTOM NAV =================
    bottomNavigationBarTheme:
        const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Remove splash grey effect
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}