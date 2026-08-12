import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mindflow/core/di/app_providers.dart';
import 'package:mindflow/core/di/feature_flags.dart';
import 'package:mindflow/core/theme/app_theme.dart';

void main() {
  group('themeDataProvider', () {
    test('returns light theme by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final theme = container.read(themeDataProvider);
      expect(theme.brightness, Brightness.light);
    });

    test('returns dark theme when mode is dark', () {
      final container = ProviderContainer(
        overrides: [themeModeProvider.overrideWith((_) => AppThemeMode.dark)],
      );
      addTearDown(container.dispose);
      final theme = container.read(themeDataProvider);
      expect(theme.brightness, Brightness.dark);
    });

    test('returns sepia theme when mode is sepia', () {
      final container = ProviderContainer(
        overrides: [themeModeProvider.overrideWith((_) => AppThemeMode.sepia)],
      );
      addTearDown(container.dispose);
      final theme = container.read(themeDataProvider);
      expect(theme.colorScheme.surface, const Color(0xFFF5EFE0));
    });
  });

  group('FeatureFlags', () {
    test('free tier disables all premium features', () {
      final flags = FeatureFlags.free();
      expect(flags.isPremium, isFalse);
      expect(flags.pdfImportEnabled, isFalse);
      expect(flags.adaptiveSpeedEnabled, isFalse);
    });

    test('premium tier enables all premium features', () {
      final flags = FeatureFlags.premium();
      expect(flags.isPremium, isTrue);
      expect(flags.pdfImportEnabled, isTrue);
      expect(flags.adaptiveSpeedEnabled, isTrue);
      expect(flags.unlimitedAi, isTrue);
      expect(flags.allTimeStats, isTrue);
    });
  });
}
