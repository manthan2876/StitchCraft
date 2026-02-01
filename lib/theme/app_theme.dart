import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // TailorBook Palette
  static const Color primaryColor = Color(0xFF1E88E5); // Bright Blue
  static const Color accentColor = Color(0xFF42A5F5); // Lighter Blue
  static const Color backgroundColor = Colors.white; // Pure White
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A); // Near Black
  static const Color textSecondary = Color(0xFF757575); // Grey
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF4CAF50);

  // Custom Colors from design
  static const Color inputBorderColor = Color(0xFFE0E0E0);
  static const Color inputFillColor = Color(0xFFFAFAFA);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: backgroundColor,
      onSurface: textPrimary,
      error: errorColor,
      brightness: Brightness.light,
    ),

    // Typography
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      displayMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      headlineMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(color: textPrimary, fontSize: 16),
      bodyMedium: const TextStyle(color: textSecondary, fontSize: 14),
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Outfit', // Ensure font matches
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: inputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: primaryColor),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        )
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
    
    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFF9E9E9E),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
  );
}
