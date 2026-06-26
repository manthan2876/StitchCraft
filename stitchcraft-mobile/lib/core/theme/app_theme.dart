import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- StitchCraft 2.0 Premium Palette ---
  static const Color deepBronze = Color(0xFF765220); // Earthy, Raw materials
  static const Color bronzeTint = Color(0xFFD3BDA0); // Accents, highlights
  static const Color trustGreen = Color(0xFF2E7D32); // Success, Profit, Money
  static const Color safetyOrange = Color(0xFFEF6C00); // Warnings, Non-critical errors
  static const Color alertRed = Color(0xFFC62828); // Critical alerts
  static const Color softWhite = Color(0xFFFAFAFA); // Paper-like background
  static const Color darkEarth = Color(0xFF291801); // Primary text
  static const Color cream = Color(0xFFFFFFF0); // Secondary background

  // --- Backward Compatibility Aliases (StitchCraft 2.0 Mapping) ---
  static const Color navyBlue = deepBronze;
  static const Color marigold = deepBronze; // Mapped to Deep Bronze as per 2.0 specs
  static const Color emerald = trustGreen;
  static const Color brickRed = alertRed;
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = darkEarth;

  static TextStyle get buttonText => GoogleFonts.anekDevanagari(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Typography for Low Digital Literacy & Indic Scripts (Anek Devanagari)
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.anekDevanagari(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: deepBronze,
    ),
    displayMedium: GoogleFonts.anekDevanagari(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: deepBronze,
    ),
    headlineMedium: GoogleFonts.anekDevanagari(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: deepBronze,
    ),
    titleLarge: GoogleFonts.anekDevanagari(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: deepBronze,
    ),
    titleMedium: GoogleFonts.anekDevanagari(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: deepBronze,
    ),
    bodyLarge: GoogleFonts.anekDevanagari(
      fontSize: 18, // Minimum 18sp rule for Masterjis
      fontWeight: FontWeight.w500,
      color: darkEarth,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.anekDevanagari(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: darkEarth,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.anekDevanagari(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: deepBronze,
    ),
    labelSmall: GoogleFonts.anekDevanagari(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Colors.grey,
    ),
  );

  static ThemeData get masterjiTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: softWhite,
      primaryColor: deepBronze,
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepBronze,
        primary: deepBronze,
        secondary: trustGreen,
        surface: softWhite,
        error: alertRed,
        outline: bronzeTint,
      ),
      textTheme: textTheme,
      
      // Card Theme (Tactile/Skeuomorphic Lite)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 6,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),

      // App Bar Theme (Premium Header)
      appBarTheme: AppBarTheme(
        backgroundColor: deepBronze,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: GoogleFonts.anekDevanagari(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Input Decoration (Voice-First focused)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: bronzeTint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: bronzeTint.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: deepBronze, width: 2),
        ),
        labelStyle: const TextStyle(color: deepBronze),
        hintStyle: GoogleFonts.anekDevanagari(color: Colors.grey, fontSize: 18),
      ),

      // Big, Bold Buttons for Tailor's Hands
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepBronze,
          foregroundColor: Colors.white,
          elevation: 6,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.anekDevanagari(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: trustGreen,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
    );
  }
}
