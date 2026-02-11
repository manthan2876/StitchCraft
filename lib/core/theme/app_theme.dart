import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // High-Contrast "Tailor Shop" Palette
  static const Color primaryColor = Color(0xFF2C2C2C); // Dark Charcoal
  static const Color accentColor = Color(0xFFD4AF37); // Metallic Gold/Bronze for premium feel, or distinct function color
  static const Color backgroundColor = Color(0xFFF9F9F0); // Cream/Off-white (Paper-like)
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure White for cards
  
  static const Color textPrimary = Color(0xFF1A1A1A); // Almost Black
  static const Color textSecondary = Color(0xFF5A5A5A); // Dark Grey
  
  // Semantic Colors (High Visibility)
  static const Color success = Color(0xFF2E7D32); // Darker Green
  static const Color warning = Color(0xFFEF6C00); // High-vis Orange
  static const Color error = Color(0xFFC62828); // Strong Red
  static const Color info = Color(0xFF1565C0); // Strong Blue

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: surfaceColor,
    canvasColor: backgroundColor, 
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      onSurface: textPrimary,
      error: error,
      brightness: Brightness.light,
    ),

    // Typography - Outfit (Premium, Modern, Clean)
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32),
      displayMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 28),
      headlineMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 24),
      titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
      bodyLarge: const TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
      bodyMedium: const TextStyle(color: textSecondary, fontSize: 14, height: 1.5),
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: textPrimary, size: 28), // Larger icons
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Outfit', 
      ),
    ),

    // Card Theme - High Contrast Borders for visibility
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    // Input Decoration - Large touch targets
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: textPrimary, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // Large padding
      labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.7)),
      prefixIconColor: textPrimary,
    ),

    // Elevated Button - Large, Tactile
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32), // Min 48dp height
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0, // Flat with border often cleaner, or high elevation
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // Floating Action Button - Prominent
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
      iconSize: 32,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Bottom Navigation Bar - High Contrast
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Outfit'),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, fontFamily: 'Outfit'),
    ),
  );
}
