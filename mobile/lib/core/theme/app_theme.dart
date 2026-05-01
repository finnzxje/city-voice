import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Assembles a complete [ThemeData] for CityVoice.
///
/// Provides both [lightTheme] and [darkTheme] built on top of
/// [ColorScheme.fromSeed] with custom overrides to match the civic design
/// language.
class AppTheme {
  AppTheme._();

  // ── Shared values ──────────────────────────────────────────────────────────
  static const double _borderRadius = 14.0;
  static final _roundedShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(_borderRadius),
  );

  // ═════════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═════════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.accent,
      secondaryContainer: AppColors.accentLight,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(AppColors.textPrimary, AppColors.textSecondary),
      fontFamily: AppTextStyles.fontFamily,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: _roundedShape,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: _roundedShape,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Input Decoration ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textHint,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),

      // ── Card ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        color: AppColors.surface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Floating Action Button ─────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Divider ────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: AppTextStyles.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Snackbar ───────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ═════════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primaryLight,
      primaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      secondaryContainer: AppColors.accentLight,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: AppColors.darkTextPrimary,
      onError: Colors.white,
      outline: AppColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme:
          _textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary),
      fontFamily: AppTextStyles.fontFamily,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: _roundedShape,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          shape: _roundedShape,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // ── Input Decoration ───────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide:
              const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),

      // ── Card ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        color: AppColors.darkSurface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Floating Action Button ─────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Bottom Navigation ──────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Divider ────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      // ── Chip ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ── Snackbar ───────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: AppColors.darkSurfaceVariant,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // Helper – applies the custom text styles into the Material [TextTheme].
  // ═════════════════════════════════════════════════════════════════════════════
  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: primary),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: primary),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: primary),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: primary),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: primary),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: primary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: secondary),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: secondary),
    );
  }
}
