import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'typography.dart';

/// The three theme variants MindFlow supports.
enum AppThemeMode { light, dark, sepia }

/// Builds a [ThemeData] for each [AppThemeMode].
///
/// Components are tuned for a premium feel: rounded 12dp card shapes, subtle
/// elevation, no harsh divider lines. The same component overrides apply to
/// all three schemes so the app's identity stays consistent across themes.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppColorSchemes.light());
  static ThemeData dark() => _build(AppColorSchemes.dark());
  static ThemeData sepia() => _build(AppColorSchemes.sepia());

  static ThemeData _build(ColorScheme scheme) {
    final textTheme = AppTypography.build(scheme);
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: scheme.outline.withValues(alpha: 0.2), thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          backgroundColor: scheme.surfaceContainerHighest,
          shape: const CircleBorder(),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.2),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall!.copyWith(
            color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.6),
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurface.withValues(alpha: 0.6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      color: isDark ? scheme.surface : scheme.surface,
    );
  }
}
