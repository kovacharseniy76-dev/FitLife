import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Кольори з макетів Figma (стилі Bg, Surface, Accent/Lime тощо).
class AppColors {
  AppColors._();
  static const Color bg = Color(0xFF0E1116);
  static const Color surface = Color(0xFF171C23);
  static const Color surface2 = Color(0xFF232A33);
  static const Color border = Color(0xFF2A323C);
  static const Color nav = Color(0xFF151A21);
  static const Color track = Color(0xFF262E38);
  static const Color text = Color(0xFFF2F5F7);
  static const Color muted = Color(0xFF9AA4AF);
  static const Color subtle = Color(0xFF8B95A1);
  static const Color soft = Color(0xFFC9D0D6);
  static const Color lime = Color(0xFFC8F25A);
  static const Color orange = Color(0xFFFF8A3D);
  static const Color blue = Color(0xFF5AB8FF);
  static const Color purple = Color(0xFFB79CFF);
  static const Color danger = Color(0xFFFF6B6B);

  /// Напівпрозорий відтінок кольору (фон для іконок, бейджів).
  static Color tint(Color c, [int alpha = 36]) => c.withAlpha(alpha);
}

class AppText {
  AppText._();
  static TextStyle display(double size, {Color color = AppColors.text}) =>
      GoogleFonts.unbounded(fontSize: size, fontWeight: FontWeight.w700, color: color, height: 1.2);

  static TextStyle body(double size, {Color color = AppColors.text, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: 1.35);
}

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.lime,
      onPrimary: AppColors.bg,
      secondary: AppColors.orange,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: Color(0xFF6F7A86)),
      labelStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lime),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.bg, modalBackgroundColor: AppColors.bg),
  );
}
