import 'package:flutter/material.dart';

class AppColors {
  // Dribbble-like soft background
  static const bg = Color(0xFFF7F3F1);
  static const surface = Color(0xFFFFFFFF);
  static const stroke = Color(0xFFE5E7EB);

  // Text
  static const text = Color(0xFF111827);
  static const subtext = Color(0xFF6B7280);

  // Accent (orange/peach like the 3rd reference)
  static const primary = Color(0xFFF97316); // orange
  static const primarySoft = Color(0xFFFFEDD5);
}

class AppText {
  static TextStyle h1 = const TextStyle(
    fontSize: 26,
    height: 1.05,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
    letterSpacing: -0.6,
  );

  static TextStyle h2 = const TextStyle(
    fontSize: 18,
    height: 1.15,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    letterSpacing: -0.2,
  );

  static TextStyle body = const TextStyle(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static TextStyle muted = const TextStyle(
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: AppColors.subtext,
  );
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),

      // AppBar like Dribbble: clean, no shadow
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Rounded cards + soft shadow
      // cardTheme: CardTheme(
      //   color: AppColors.surface,
      //   elevation: 0,
      //   margin: EdgeInsets.zero,
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(22),
      //     side: const BorderSide(color: AppColors.stroke),
      //   ),
      // ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}
