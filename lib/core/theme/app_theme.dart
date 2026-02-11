import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors (Masterji Palette)
  static const Color cream = Color(0xFFFFFFF0); // Paper notebook background
  static const Color navyBlue = Color(0xFF1A237E); // Headers, Primary Text
  static const Color marigold = Color(0xFFFFD700); // Buttons, Highlights
  static const Color emerald = Color(0xFF2E7D32); // Success, Money
  static const Color brickRed = Color(0xFFC62828); // Error, Pending
  static const Color darkGrey = Color(0xFF424242); // Body Text
  static const Color lightGrey = Color(0xFFE0E0E0); // Dividers

  // Typography (Hindi/Gujarati/Tamil friendly)
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.hind(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: navyBlue,
    ),
    headlineMedium: GoogleFonts.hind(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: navyBlue,
    ),
    titleMedium: GoogleFonts.hind(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: navyBlue,
    ),
    bodyLarge: GoogleFonts.hind(
      fontSize: 18, // Minimum 16sp rule
      fontWeight: FontWeight.w500,
      color: darkGrey,
    ),
    bodyMedium: GoogleFonts.hind(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: darkGrey,
    ),
    labelLarge: GoogleFonts.hind(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: navyBlue,
    ),
  );

  static TextStyle get buttonText => GoogleFonts.hind(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: navyBlue,
  );

  static ThemeData get masterjiTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      primaryColor: navyBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navyBlue,
        primary: navyBlue,
        secondary: marigold,
        surface: cream, // Cards are white, background is cream
        error: brickRed,
      ),
      textTheme: textTheme,
      
      // Card Theme (Tactile)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      // Input Decoration (Voice-First)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Clean look
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navyBlue, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: navyBlue),
        hintStyle: GoogleFonts.hind(color: Colors.grey, fontSize: 16),
      ),

      // Button Theme (Big & Bold)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: marigold,
          foregroundColor: navyBlue,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.hind(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: marigold,
        foregroundColor: navyBlue,
        elevation: 6,
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.hind(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
