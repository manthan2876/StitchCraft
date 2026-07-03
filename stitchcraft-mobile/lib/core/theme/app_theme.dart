import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- StitchCraft 3.0 Dark Premium Palette (Frontend Mapped) ---
  static const Color brandPurple = Color(0xFF465FFF); // Brand Accent Purple
  static const Color darkCard = Color(0xFF1A2231); // Header/Card/Input bg (Dark)
  static const Color darkBg = Color(0xFF101828); // Page body bg (Dark)
  
  static const Color trustGreen = Color(0xFF10B981); // Success, Profit, money
  static const Color safetyOrange = Color(0xFFF59E0B); // Warnings, Non-critical errors
  static const Color alertRed = Color(0xFFF43F5E); // Critical alerts
  static const Color softWhite = Color(0xFFFAFAFA); 
  static const Color darkEarth = Color(0xFFFFFFFF); // Primary text (White)
  static const Color cream = darkCard; // Mapped for backward compatibility
  
  // --- Mapped for backward compatibility ---
  static const Color deepBronze = brandPurple;
  static const Color bronzeTint = Color(0xFF98A2B3); // Muted text/border gray
  
  // --- Backward Compatibility Aliases ---
  static const Color navyBlue = brandPurple;
  static const Color marigold = brandPurple;
  static const Color emerald = trustGreen;
  static const Color brickRed = alertRed;
  static const Color lightGrey = Color(0xFF1D2939); // Subtle border
  static const Color darkGrey = Color(0xFF98A2B3); // Muted text

  static TextStyle get buttonText => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Typography shift to Outfit (Frontend visual match)
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.outfit(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    titleLarge: GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    titleMedium: GoogleFonts.outfit(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodyLarge: GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.outfit(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Colors.white,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: brandPurple,
    ),
    labelSmall: GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: darkGrey,
    ),
  );

  static ThemeData get masterjiTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBg,
      primaryColor: brandPurple,
      colorScheme: const ColorScheme.dark(
        primary: brandPurple,
        secondary: trustGreen,
        surface: darkBg,
        error: alertRed,
        outline: lightGrey,
      ),
      textTheme: textTheme,
      
      // Card Theme (Tactile/Skeuomorphic Lite)
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightGrey, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),

      // App Bar Theme (Premium Header)
      appBarTheme: AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Input Decoration (Voice-First focused)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightGrey.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandPurple, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: GoogleFonts.outfit(color: darkGrey, fontSize: 18),
      ),

      // Big, Bold Buttons for Tailor's Hands
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: trustGreen,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),
    );
  }
}
