import 'package:flutter/material.dart';

/// Design tokens following 8pt grid, inspired by SSENSE/ZARA/Nike digital design systems.
/// Dark-first palette with high contrast for product photography.

class AppColors {
  // Surfaces — near-black layering for depth
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF111111);
  static const Color surfaceElevated = Color(0xFF1A1A1A);
  static const Color surfaceOverlay = Color(0xFF222222);
  static const Color surfaceBright = Color(0xFF2C2C2C);

  // Brand — mountain blue inspired by Kyrgyz peaks & Issyk-Kul
  static const Color accent = Color(0xFF4A90E2);
  static const Color accentSoft = Color(0xFF14202E);
  static const Color gold = Color(0xFFCFAA45);
  static const Color goldSoft = Color(0xFF2A2418);

  // Text — WCAG AAA on dark backgrounds
  static const Color textPrimary = Color(0xFFF2F2F2);
  static const Color textSecondary = Color(0xFF999999);
  static const Color textTertiary = Color(0xFF5A5A5A);
  static const Color textInverse = Color(0xFF0A0A0A);

  // Semantic
  static const Color sale = Color(0xFFFF3B30);
  static const Color saleSoft = Color(0xFF3A1512);
  static const Color divider = Color(0xFF1E1E1E);
  static const Color shimmer = Color(0xFF1A1A1A);

  // Loyalty tiers
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFB8B8B8);
  static const Color goldTier = Color(0xFFCFAA45);
  static const Color platinum = Color(0xFFDCDAD8);
}

/// 8pt spatial scale
class S {
  static const double x2 = 2;
  static const double x4 = 4;
  static const double x6 = 6;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16;
  static const double x20 = 20;
  static const double x24 = 24;
  static const double x32 = 32;
  static const double x40 = 40;
  static const double x48 = 48;
  static const double x56 = 56;
  static const double x64 = 64;
}

class R {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        error: AppColors.sale,
      ),
      fontFamily: '.SF Pro Display', // system font — crisp on iOS
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        unselectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 0.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: S.x24, vertical: S.x16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.pill)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.surfaceBright),
          padding: const EdgeInsets.symmetric(horizontal: S.x24, vertical: S.x16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.pill)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: S.x16, vertical: S.x12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.sm), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.sm), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(R.sm),
          borderSide: const BorderSide(color: AppColors.textTertiary, width: 1),
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14, fontWeight: FontWeight.w400),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 0.5, space: 0),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.sm)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
