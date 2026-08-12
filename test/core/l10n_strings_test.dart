import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/l10n/gen/strings.dart';

void main() {
  group('l10n string maps', () {
    final allMaps = <String, Map<String, String>>{
      'en': enStrings,
      'es': esStrings,
      'fr': frStrings,
      'de': deStrings,
      'ar': arStrings,
      'hi': hiStrings,
      'pt': ptStrings,
      'zh': zhStrings,
    };

    test('all locales have the same keys as English', () {
      final enKeys = enStrings.keys.toSet();
      for (final entry in allMaps.entries) {
        final localeKeys = entry.value.keys.toSet();
        final missing = enKeys.difference(localeKeys);
        final extra = localeKeys.difference(enKeys);
        expect(missing, isEmpty, reason: '${entry.key} is missing keys: $missing');
        expect(extra, isEmpty, reason: '${entry.key} has extra keys: $extra');
      }
    });

    test('all maps are non-empty', () {
      for (final entry in allMaps.entries) {
        expect(entry.value, isNotEmpty, reason: '${entry.key} strings should not be empty');
      }
    });

    test('parameterized strings contain placeholders', () {
      expect(enStrings['reviewDueToday']!, contains('{count}'));
      expect(enStrings['paywallMonthly']!, contains('{price}'));
      expect(enStrings['paywallYearly']!, contains('{price}'));
    });
  });
}
