/// User-configurable reading and appearance settings.
///
/// [rsvp] is the reading-engine config; the rest are app-level. Persisted in
/// Hive (key-value) by the settings repository.
class UserSettings {
  const UserSettings({
    required this.rsvp,
    required this.themeMode,
    required this.locale,
    required this.fontScale,
  });

  final RsvpSettings rsvp;
  final String themeMode; // 'light' | 'dark' | 'sepia'
  final String? locale; // languageCode or null = follow device
  final double fontScale; // 0.85..1.3

  UserSettings copyWith({RsvpSettings? rsvp, String? themeMode, String? locale, double? fontScale}) {
    return UserSettings(
      rsvp: rsvp ?? this.rsvp,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  static UserSettings defaults() => const UserSettings(
        rsvp: RsvpSettings.defaults(),
        themeMode: 'light',
        locale: null,
        fontScale: 1.0,
      );
}

/// Configuration for the RSVP reading engine.
class RsvpSettings {
  const RsvpSettings({
    required this.targetWpm,
    required this.wordsPerDisplay,
    required this.lineCount,
    required this.imageDuration,
    required this.adaptiveSpeed,
  });

  final int targetWpm; // 100..1500 (power users), default 400
  final int wordsPerDisplay; // 1..20
  final int lineCount; // 1..5
  final Duration imageDuration; // default 2s
  final bool adaptiveSpeed; // premium feature

  RsvpSettings copyWith({
    int? targetWpm,
    int? wordsPerDisplay,
    int? lineCount,
    Duration? imageDuration,
    bool? adaptiveSpeed,
  }) {
    return RsvpSettings(
      targetWpm: targetWpm ?? this.targetWpm,
      wordsPerDisplay: wordsPerDisplay ?? this.wordsPerDisplay,
      lineCount: lineCount ?? this.lineCount,
      imageDuration: imageDuration ?? this.imageDuration,
      adaptiveSpeed: adaptiveSpeed ?? this.adaptiveSpeed,
    );
  }

  static RsvpSettings defaults() => const RsvpSettings(
        targetWpm: 400,
        wordsPerDisplay: 1,
        lineCount: 1,
        imageDuration: Duration(seconds: 2),
        adaptiveSpeed: false,
      );
}
