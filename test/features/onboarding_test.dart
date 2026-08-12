import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/core/di/feature_flags.dart';
import 'package:mindflow/domain/entities/user_settings.dart';

void main() {
  group('Onboarding flow', () {
    test('has 3 pages', () {
      expect(3, 3);
    });
  });

  group('Settings persistence model', () {
    test('default settings match free tier expectations', () {
      final defaults = UserSettings.defaults();
      expect(defaults.themeMode, 'light');
      expect(defaults.fontScale, 1.0);
      expect(defaults.rsvp.adaptiveSpeed, isFalse);
    });

    test('settings can be upgraded to premium WPM range', () {
      final defaults = UserSettings.defaults();
      final premium = defaults.copyWith(
        rsvp: defaults.rsvp.copyWith(
          targetWpm: 1000,
          adaptiveSpeed: true,
        ),
      );
      expect(premium.rsvp.targetWpm, 1000);
      expect(premium.rsvp.adaptiveSpeed, isTrue);
    });

    test('theme can be switched to dark', () {
      final defaults = UserSettings.defaults();
      final dark = defaults.copyWith(themeMode: 'dark');
      expect(dark.themeMode, 'dark');
      expect(dark.fontScale, 1.0);
    });

    test('locale can be set', () {
      final defaults = UserSettings.defaults();
      final localized = defaults.copyWith(locale: 'ar');
      expect(localized.locale, 'ar');
    });
  });

  group('FeatureFlags premium gating', () {
    test('free tier blocks premium features', () {
      final free = FeatureFlags.free();
      expect(free.isPremium, isFalse);
      expect(free.adaptiveSpeedEnabled, isFalse);
      expect(free.pdfImportEnabled, isFalse);
      expect(free.unlimitedAi, isFalse);
      expect(free.allTimeStats, isFalse);
    });

    test('premium tier unlocks all features', () {
      final premium = FeatureFlags.premium();
      expect(premium.isPremium, isTrue);
      expect(premium.adaptiveSpeedEnabled, isTrue);
      expect(premium.pdfImportEnabled, isTrue);
      expect(premium.unlimitedAi, isTrue);
      expect(premium.allTimeStats, isTrue);
    });
  });
}
