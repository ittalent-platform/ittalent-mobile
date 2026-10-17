import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const colors = AppColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.light(
        surface: colors.card,
        primary: colors.primary,
        onPrimary: colors.primaryForeground,
        secondary: colors.secondary,
        onSecondary: colors.secondaryForeground,
        error: colors.destructive,
        onError: colors.destructiveForeground,
        outline: colors.border,
      ),
      extensions: const [colors],
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.display(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: colors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: AppTypography.body(color: colors.mutedForeground),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colors.input, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colors.input, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colors.destructive, width: 1),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.display(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: colors.foreground,
        ),
        headlineMedium: AppTypography.display(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
        titleLarge: AppTypography.display(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
        bodyLarge: AppTypography.body(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: colors.foreground,
        ),
        bodyMedium: AppTypography.body(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colors.foreground,
        ),
        bodySmall: AppTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colors.mutedForeground,
        ),
      ),
    );
  }

  static ThemeData get dark {
    const colors = AppColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.dark(
        surface: colors.card,
        primary: colors.primary,
        onPrimary: colors.primaryForeground,
        secondary: colors.secondary,
        onSecondary: colors.secondaryForeground,
        error: colors.destructive,
        onError: colors.destructiveForeground,
        outline: colors.border,
      ),
      extensions: const [colors],
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.display(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: colors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: AppTypography.body(color: colors.mutedForeground),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colors.input, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colors.input, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colors.destructive, width: 1),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.display(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: colors.foreground,
        ),
        headlineMedium: AppTypography.display(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
        titleLarge: AppTypography.display(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
        bodyLarge: AppTypography.body(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: colors.foreground,
        ),
        bodyMedium: AppTypography.body(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: colors.foreground,
        ),
        bodySmall: AppTypography.body(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colors.mutedForeground,
        ),
      ),
    );
  }
}
