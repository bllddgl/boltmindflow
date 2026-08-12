import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/di/data_providers.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/result.dart';
import '../l10n/app_locale.dart';
import '../theme/app_theme.dart';
import 'feature_flags.dart';

/// App-wide providers that don't belong to a single feature.

/// The user's chosen theme mode. Hydrated from Supabase on startup by
/// [settingsBootstrapProvider].
final themeModeProvider = StateProvider<AppThemeMode>((ref) => AppThemeMode.light);

/// The user's chosen UI language. `null` means follow the device locale.
final localeProvider = StateProvider<Locale?>((ref) => null);

/// Resolves the effective locale: user choice, else English.
final effectiveLocaleProvider = Provider<Locale>((ref) {
  final chosen = ref.watch(localeProvider);
  if (chosen != null) return chosen;
  return const Locale('en');
});

/// Whether onboarding has been completed. Hydrated from Supabase on startup.
final hasOnboardedProvider = StateProvider<bool>((ref) => false);

/// The currently-open document id, shared between library, reader, and AI.
final currentDocumentIdProvider = StateProvider<String?>((ref) => null);

/// Resolves the active [ThemeData] from [themeModeProvider].
final themeDataProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  return switch (mode) {
    AppThemeMode.light => AppTheme.light(),
    AppThemeMode.dark => AppTheme.dark(),
    AppThemeMode.sepia => AppTheme.sepia(),
  };
});

/// Loads settings from Supabase on startup and seeds the state providers.
///
/// Call once in `main.dart` before `runApp`. Returns true on success.
/// Each provider is only updated if the value differs from its default.
Future<bool> bootstrapSettings(Ref ref) async {
  final settingsRepo = ref.read(settingsRepositoryProvider);
  final result = await settingsRepo.getSettings();
  final onboardedResult = await settingsRepo.getHasOnboarded();

  result.when(
    success: (settings) {
      _applyThemeMode(ref, settings.themeMode);
      _applyLocale(ref, settings.locale);
    },
    failure: (_) {},
  );

  onboardedResult.when(
    success: (onboarded) {
      ref.read(hasOnboardedProvider.notifier).state = onboarded;
    },
    failure: (_) {},
  );

  return true;
}

void _applyThemeMode(Ref ref, String mode) {
  final parsed = switch (mode) {
    'dark' => AppThemeMode.dark,
    'sepia' => AppThemeMode.sepia,
    _ => AppThemeMode.light,
  };
  ref.read(themeModeProvider.notifier).state = parsed;
}

void _applyLocale(Ref ref, String? localeCode) {
  if (localeCode != null) {
    ref.read(localeProvider.notifier).state = Locale(localeCode);
  }
}

/// Converts [AppThemeMode] to the string stored in Supabase.
String themeModeToString(AppThemeMode mode) => switch (mode) {
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
      AppThemeMode.sepia => 'sepia',
    };
