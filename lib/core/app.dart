import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_locale.dart';
import '../l10n/gen/app_localizations.dart';
import 'di/app_providers.dart';
import 'router/app_router.dart';

/// Root widget. Reads the active theme, locale, and router reactively from
/// providers. Keeping this widget thin means all wiring lives in providers,
/// which are overridable in tests.
class MindFlowApp extends ConsumerWidget {
  const MindFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(effectiveLocaleProvider);

    return MaterialApp.router(
      title: 'MindFlow',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: AppTheme.dark(),
      locale: locale,
      supportedLocales: AppLocale.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
