import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary - Deep Teal #007A6E
  static const Color primary = Color(0xFF007A6E);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // Gradient teal
  static const Color primaryLight = Color(0xFF00BCD4);

  // Accent - Amber #F59E0B
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentForeground = Color(0xFFFFFFFF);

  // Forest green #2E7D32
  static const Color forest = Color(0xFF2E7D32);

  // Success #10B981
  static const Color success = Color(0xFF10B981);
  static const Color successForeground = Color(0xFFFFFFFF);

  // Destructive #EF4444
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFFFFFF);

  // Background #F7FAFA
  static const Color background = Color(0xFFF7FAFA);

  // Card #FFFFFF
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF1C2B2A);

  // Foreground / Text #1C2B2A
  static const Color foreground = Color(0xFF1C2B2A);

  // Muted text #6B7B7A
  static const Color mutedForeground = Color(0xFF6B7B7A);

  // Muted bg
  static const Color muted = Color(0xFFE8EDED);

  // Border
  static const Color border = Color(0xFFE5EBEB);

  // Input
  static const Color input = Color(0xFFE5EBEB);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF007A6E), Color(0xFF00BCD4)],
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF007A6E), Color(0xFF00ACC1)],
  );
}

class AppTextStyles {
  // Primary font: Poppins
  static TextStyle headingBold(double size, {Color color = AppColors.foreground}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextStyle headingMedium(double size, {Color color = AppColors.foreground}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w500, color: color);

  static TextStyle headingRegular(double size, {Color color = AppColors.foreground}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w400, color: color);

  static TextStyle headingItalic(double size, {Color color = AppColors.foreground}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, color: color);

  static TextStyle bodyBold(double size, {Color color = AppColors.foreground}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w700, color: color);

  static TextStyle bodySemiBold(double size, {Color color = AppColors.foreground}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w600, color: color);

  static TextStyle bodyMedium(double size, {Color color = AppColors.foreground}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w500, color: color);

  static TextStyle bodyRegular(double size, {Color color = AppColors.foreground}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: FontWeight.w400, color: color);

  static TextStyle mono(double size, {Color color = AppColors.mutedForeground}) =>
      GoogleFonts.firaCode(fontSize: size, color: color);
}

class AppDecorations {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF007A6E).withOpacity(0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration elevatedDecoration = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF007A6E).withOpacity(0.12),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration gradientDecoration({double radius = 0}) => BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(radius),
      );

  static InputDecoration inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  static InputDecoration pillInputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyRegular(14, color: AppColors.mutedForeground),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.card,
          background: AppColors.background,
          error: AppColors.destructive,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: GoogleFonts.poppins().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.card,
          elevation: 0,
          titleTextStyle: AppTextStyles.headingBold(18),
          iconTheme: const IconThemeData(color: AppColors.foreground),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryForeground,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            textStyle: AppTextStyles.bodyBold(16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 2),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
            textStyle: AppTextStyles.bodySemiBold(16),
          ),
        ),
      );
}
