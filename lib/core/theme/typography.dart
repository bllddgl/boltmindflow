import 'package:flutter/material.dart';

/// App-wide text styles.
///
/// One family (Google Fonts Inter), three weights (400/500/700). Body line
/// height 150%, headings 120%, per the design system. Inter is loaded via
/// [google_fonts] so it works on Android without bundling font files.
class AppTypography {
  const AppTypography._();

  static const String _family = 'Inter';

  static TextTheme build(ColorScheme scheme) {
    final base = const TextTheme().apply(
      fontFamily: _family,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
      displayMedium: base.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
      headlineLarge: base.headlineLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w500, height: 1.2),
      titleLarge: base.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w500, height: 1.25),
      titleMedium: base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, height: 1.25),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5),
      labelLarge: base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.25),
      labelSmall: base.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.25),
    );
  }
}
