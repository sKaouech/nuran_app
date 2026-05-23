import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Thèmes Material 3 pour l'app : light, dark, sepia (lecture longue).
class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          tertiary: AppColors.tertiary,
          tertiaryContainer: AppColors.tertiaryContainer,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.onSurfaceLight,
          onSurfaceVariant: AppColors.onSurfaceVariantLight,
          surfaceContainer: AppColors.surfaceContainerLight,
          surfaceContainerHigh: AppColors.surfaceContainerHighLight,
          error: AppColors.error,
          onError: Colors.white,
        ),
      );

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        scheme: const ColorScheme.dark(
          primary: AppColors.primaryContainer,
          onPrimary: AppColors.onPrimaryContainer,
          primaryContainer: AppColors.primary,
          onPrimaryContainer: AppColors.primaryContainer,
          secondary: AppColors.secondaryContainer,
          onSecondary: Color(0xFF3D2E00),
          tertiary: AppColors.tertiaryContainer,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.onSurfaceDark,
          onSurfaceVariant: AppColors.onSurfaceVariantDark,
          surfaceContainer: AppColors.surfaceContainerDark,
          surfaceContainerHigh: AppColors.surfaceContainerHighDark,
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
        ),
      );

  /// Mode sépia : pour lecture longue du mushaf.
  static ThemeData get sepia => _buildTheme(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: AppColors.tertiary,
          onPrimary: Colors.white,
          surface: AppColors.surfaceSepia,
          onSurface: AppColors.onSurfaceSepia,
          surfaceContainer: Color(0xFFEEE0C5),
          surfaceContainerHigh: Color(0xFFE5D5B5),
        ),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: AppTypography.textTheme(brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          AppTypography.textTheme(brightness).labelMedium,
        ),
      ),
    );
  }
}
