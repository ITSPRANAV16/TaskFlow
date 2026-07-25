import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';

class AppTheme {
  // Brand Colors (Vibrant HSL Curated Palette)
  static const Color primaryViolet = Color(0xFF6366F1); // Indigo Primary
  static const Color primaryTeal = Color(0xFF14B8A6);   // Electric Teal
  static const Color accentRose = Color(0xFFF43F5E);     // Urgent Accent
  static const Color accentAmber = Color(0xFFF59E0B);    // Medium Priority
  static const Color accentEmerald = Color(0xFF10B981);  // Low Priority

  // Dark Theme Palette
  static const Color darkBg = Color(0xFF0F172A);         // Deep Slate Dark
  static const Color darkSurface = Color(0xFF1E293B);    // Surface Slate
  static const Color darkCard = Color(0xFF334155);       // Card Surface
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Theme Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Priority Color Mapping
  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return accentRose;
      case TaskPriority.high:
        return const Color(0xFFEC4899); // Deep Pink / Magenta
      case TaskPriority.medium:
        return accentAmber;
      case TaskPriority.low:
        return accentEmerald;
    }
  }

  // Category Color Mapping
  static Color getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.all:
        return primaryViolet;
      case TaskCategory.work:
        return const Color(0xFF3B82F6); // Blue
      case TaskCategory.personal:
        return const Color(0xFF8B5CF6); // Purple
      case TaskCategory.study:
        return const Color(0xFF06B6D4); // Cyan
      case TaskCategory.health:
        return const Color(0xFF10B981); // Emerald
      case TaskCategory.shopping:
        return const Color(0xFFF59E0B); // Amber
      case TaskCategory.finance:
        return const Color(0xFFEC4899); // Pink
      case TaskCategory.other:
        return const Color(0xFF64748B); // Slate
    }
  }

  // Dark Theme Definition
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryViolet,
      colorScheme: const ColorScheme.dark(
        primary: primaryViolet,
        secondary: primaryTeal,
        surface: darkSurface,
        surfaceContainerHighest: darkCard,
        onSurface: darkTextPrimary,
        error: accentRose,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: darkTextPrimary),
        bodyMedium: GoogleFonts.inter(color: darkTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryViolet,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
      ),
    );
  }

  // Light Theme Definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: primaryViolet,
      colorScheme: const ColorScheme.light(
        primary: primaryViolet,
        secondary: primaryTeal,
        surface: lightSurface,
        surfaceContainerHighest: lightCard,
        onSurface: lightTextPrimary,
        error: accentRose,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: lightTextPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: lightTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: lightTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: lightTextPrimary),
        bodyMedium: GoogleFonts.inter(color: lightTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryViolet,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
      ),
    );
  }
}
