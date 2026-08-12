import 'package:flutter/material.dart';

/// Material 3 [ColorScheme] for each theme variant.
///
/// Primary is teal/emerald (never purple/indigo). Each scheme is built with
/// [ColorScheme.fromSeed] then overridden where the seed produces unreadable
/// combinations, so contrast ratios stay ≥ 4.5:1 on every surface.
class AppColorSchemes {
  const AppColorSchemes._();

  static const Color _seed = Color(0xFF0F766E); // teal-700

  static ColorScheme light() {
    final base = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
    return base.copyWith(
      surface: const Color(0xFFFBFBFB),
      onSurface: const Color(0xFF1C1B1F),
      primary: const Color(0xFF0F766E),
      onPrimary: Colors.white,
    );
  }

  static ColorScheme dark() {
    final base = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return base.copyWith(
      surface: const Color(0xFF121212),
      onSurface: const Color(0xFFE6E1E5),
      primary: const Color(0xFF5EEAD4),
      onPrimary: const Color(0xFF00382F),
    );
  }

  /// Sepia: warm paper background, dark brown text. Tuned for long-form reading.
  static ColorScheme sepia() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0F766E),
      onPrimary: Colors.white,
      secondary: Color(0xFFB45309),
      onSecondary: Colors.white,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: Color(0xFFF5EFE0),
      onSurface: Color(0xFF3D341F),
      surfaceContainer: Color(0xFFEDE4D0),
      surfaceContainerHighest: Color(0xFFE4D9C0),
      outline: Color(0xFF7A6B4F),
    );
  }
}
