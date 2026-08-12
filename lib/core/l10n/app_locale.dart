import 'package:flutter/material.dart';

/// The languages MindFlow ships with.
///
/// Adding a language is a new `.arb` file + an entry here. No other code
/// changes — the l10n generator + `localizationsDelegates` pick it up.
class AppLocale {
  const AppLocale._();

  /// All supported locales, in the order shown in the language picker.
  static const List<Locale> supported = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('ar'),
    Locale('hi'),
    Locale('pt'),
    Locale('zh'),
  ];

  /// Human-readable display name for the picker, in the locale's own language
  /// so users can recognize their language regardless of the current UI.
  static const Map<String, String> nativeNames = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'pt': 'Português',
    'zh': '中文',
  };

  /// Whether a locale is right-to-left (affects layout direction).
  static bool isRtl(Locale locale) {
    return locale.languageCode == 'ar';
  }

  static String nativeName(Locale locale) =>
      nativeNames[locale.languageCode] ?? locale.languageCode;
}
