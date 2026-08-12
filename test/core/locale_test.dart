import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mindflow/core/di/app_providers.dart';
import 'package:mindflow/core/l10n/app_locale.dart';

void main() {
  group('AppLocale', () {
    test('supported locales include the 8 Phase 1 languages', () {
      expect(AppLocale.supported.length, 8);
      expect(AppLocale.supported.map((l) => l.languageCode),
          containsAll(['en', 'es', 'fr', 'de', 'ar', 'hi', 'pt', 'zh']));
    });

    test('nativeNames has a name for every supported locale', () {
      for (final locale in AppLocale.supported) {
        expect(AppLocale.nativeName(locale), isNotEmpty);
      }
    });

    test('Arabic is RTL, others are LTR', () {
      expect(AppLocale.isRtl(const Locale('ar')), isTrue);
      expect(AppLocale.isRtl(const Locale('en')), isFalse);
      expect(AppLocale.isRtl(const Locale('zh')), isFalse);
    });
  });

  group('localeProvider', () {
    test('defaults to null (follow device)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(localeProvider), isNull);
    });

    test('effectiveLocaleProvider falls back to English when null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(effectiveLocaleProvider), const Locale('en'));
    });

    test('effectiveLocaleProvider returns user choice when set', () {
      final container = ProviderContainer(
        overrides: [localeProvider.overrideWith((_) => const Locale('ar'))],
      );
      addTearDown(container.dispose);
      expect(container.read(effectiveLocaleProvider), const Locale('ar'));
    });
  });
}
