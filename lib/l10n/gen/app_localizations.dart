import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'strings.dart' as s;

/// Hand-written minimal AppLocalizations.
///
/// In production, run `flutter gen-l10n` to generate the full implementation
/// with parameterized messages. This stub provides direct string access so
/// the app compiles without the codegen step.
class AppLocalizations {
  final Locale locale;
  final Map<String, String> _strings;

  AppLocalizations(this.locale, this._strings);

  static AppLocalizations of(BuildContext context) {
    final l = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return l ?? AppLocalizations(const Locale('en'), s.enStrings);
  }

  String get(String key) => _strings[key] ?? key;

  // Common accessors used throughout the app.
  String get appName => get('appName');
  String get tagline => get('tagline');
  String get navLibrary => get('navLibrary');
  String get navReview => get('navReview');
  String get navStats => get('navStats');
  String get navSettings => get('navSettings');
  String get onboardingTitle1 => get('onboardingTitle1');
  String get onboardingTitle2 => get('onboardingTitle2');
  String get onboardingTitle3 => get('onboardingTitle3');
  String get onboardingBody1 => get('onboardingBody1');
  String get onboardingBody2 => get('onboardingBody2');
  String get onboardingBody3 => get('onboardingBody3');
  String get onboardingContinue => get('onboardingContinue');
  String get onboardingSkip => get('onboardingSkip');
  String get onboardingStart => get('onboardingStart');
  String get libraryTitle => get('libraryTitle');
  String get libraryContinue => get('libraryContinue');
  String get libraryResume => get('libraryResume');
  String get libraryImport => get('libraryImport');
  String get libraryImportHint => get('libraryImportHint');
  String get libraryEmpty => get('libraryEmpty');
  String get libraryEmptyHint => get('libraryEmptyHint');
  String get librarySearch => get('librarySearch');
  String get librarySortRecent => get('librarySortRecent');
  String get librarySortImported => get('librarySortImported');
  String get librarySortTitle => get('librarySortTitle');
  String get libraryArchive => get('libraryArchive');
  String get libraryDelete => get('libraryDelete');
  String get libraryDeleteConfirm => get('libraryDeleteConfirm');
  String get libraryDeleteConfirmBody => get('libraryDeleteConfirmBody');
  String get libraryParseWarning => get('libraryParseWarning');
  String get libraryReparse => get('libraryReparse');
  String get readerBookmark => get('readerBookmark');
  String get readerSettings => get('readerSettings');
  String get readerWpm => get('readerWpm');
  String get readerWordsPerDisplay => get('readerWordsPerDisplay');
  String get readerLineCount => get('readerLineCount');
  String get readerImageDuration => get('readerImageDuration');
  String get readerAdaptiveSpeed => get('readerAdaptiveSpeed');
  String get readerAdaptiveSpeedHint => get('readerAdaptiveSpeedHint');
  String get readerModeRsvp => get('readerModeRsvp');
  String get readerModeLine => get('readerModeLine');
  String get readerModeParagraph => get('readerModeParagraph');
  String get readerPlay => get('readerPlay');
  String get readerPause => get('readerPause');
  String get readerRewind => get('readerRewind');
  String get readerForward => get('readerForward');
  String get readerSeek => get('readerSeek');
  String get readerFinished => get('readerFinished');
  String get readerProgress => get('readerProgress');
  String get reviewTitle => get('reviewTitle');
  String get reviewEmpty => get('reviewEmpty');
  String get reviewEmptyHint => get('reviewEmptyHint');
  String get reviewShowAnswer => get('reviewShowAnswer');
  String get reviewAgain => get('reviewAgain');
  String get reviewHard => get('reviewHard');
  String get reviewGood => get('reviewGood');
  String get reviewEasy => get('reviewEasy');
  String get reviewNext => get('reviewNext');
  String get statsTitle => get('statsTitle');
  String get statsReadingTime => get('statsReadingTime');
  String get statsAvgWpm => get('statsAvgWpm');
  String get statsWordsRead => get('statsWordsRead');
  String get statsBooksCompleted => get('statsBooksCompleted');
  String get statsFocusScore => get('statsFocusScore');
  String get statsStreak => get('statsStreak');
  String get statsThisWeek => get('statsThisWeek');
  String get statsAllTime => get('statsAllTime');
  String get statsWeeklyInsight => get('statsWeeklyInsight');
  String get statsWeeklyInsightLocked => get('statsWeeklyInsightLocked');
  String get settingsTitle => get('settingsTitle');
  String get settingsAppearance => get('settingsAppearance');
  String get settingsTheme => get('settingsTheme');
  String get settingsThemeLight => get('settingsThemeLight');
  String get settingsThemeDark => get('settingsThemeDark');
  String get settingsThemeSepia => get('settingsThemeSepia');
  String get settingsLanguage => get('settingsLanguage');
  String get settingsFontSize => get('settingsFontSize');
  String get settingsReading => get('settingsReading');
  String get settingsTargetWpm => get('settingsTargetWpm');
  String get settingsAi => get('settingsAi');
  String get settingsAccount => get('settingsAccount');
  String get settingsPlan => get('settingsPlan');
  String get settingsPlanFree => get('settingsPlanFree');
  String get settingsPlanPremium => get('settingsPlanPremium');
  String get settingsManageSubscription => get('settingsManageSubscription');
  String get settingsRestorePurchases => get('settingsRestorePurchases');
  String get settingsAbout => get('settingsAbout');
  String get settingsVersion => get('settingsVersion');
  String get paywallTitle => get('paywallTitle');
  String get paywallFeatureFormats => get('paywallFeatureFormats');
  String get paywallFeatureAdaptive => get('paywallFeatureAdaptive');
  String get paywallFeatureAi => get('paywallFeatureAi');
  String get paywallFeatureStats => get('paywallFeatureStats');
  String get paywallFeatureSync => get('paywallFeatureSync');
  String get errorOffline => get('errorOffline');
  String get errorPremiumRequired => get('errorPremiumRequired');
  String get errorNotFound => get('errorNotFound');
  String get errorParse => get('errorParse');
  String get errorUnsupportedFormat => get('errorUnsupportedFormat');
  String get errorStorage => get('errorStorage');
  String get errorAi => get('errorAi');
  String get errorUnknown => get('errorUnknown');
  String get aiTitle => get('aiTitle');
  String get aiTabSummary => get('aiTabSummary');
  String get aiTabQuiz => get('aiTabQuiz');
  String get aiTabQa => get('aiTabQa');
  String get aiGenerateSummary => get('aiGenerateSummary');
  String get aiGenerateQuiz => get('aiGenerateQuiz');
  String get aiAskQuestion => get('aiAskQuestion');
  String get aiAskHint => get('aiAskHint');
  String get aiKeyPoints => get('aiKeyPoints');
  String get aiNoArtifact => get('aiNoArtifact');
  String get aiNoArtifactHint => get('aiNoArtifactHint');
  String get aiGenerating => get('aiGenerating');
  String get aiSend => get('aiSend');
  String get aiYourQuestion => get('aiYourQuestion');
  String get aiCorrectAnswer => get('aiCorrectAnswer');
  String get aiWrongAnswer => get('aiWrongAnswer');
  String get aiCheckAnswer => get('aiCheckAnswer');

  String reviewDueToday(int count) => get('reviewDueToday').replaceAll('{count}', count.toString());
  String paywallMonthly(String price) => get('paywallMonthly').replaceAll('{price}', price);
  String paywallYearly(String price) => get('paywallYearly').replaceAll('{price}', price);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'), Locale('es'), Locale('fr'), Locale('de'),
    Locale('ar'), Locale('hi'), Locale('pt'), Locale('zh'),
  ];
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final strings = switch (locale.languageCode) {
      'es' => s.esStrings,
      'fr' => s.frStrings,
      'de' => s.deStrings,
      'ar' => s.arStrings,
      'hi' => s.hiStrings,
      'pt' => s.ptStrings,
      'zh' => s.zhStrings,
      _ => s.enStrings,
    };
    return AppLocalizations(locale, strings);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
