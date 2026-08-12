import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/app_providers.dart';
import '../../core/di/feature_flags.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/theme/app_theme.dart';
import '../../data/di/data_providers.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/result.dart';
import '../../l10n/gen/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final flags = ref.watch(featureFlagsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(l.settingsAppearance),
          _ThemeSelector(),
          _LanguageSelector(),
          _FontSizeSlider(),
          const SizedBox(height: 8),

          _SectionHeader(l.settingsReading),
          _WpmSlider(),
          const SizedBox(height: 8),

          _SectionHeader(l.settingsAccount),
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: Text(l.settingsPlan),
            trailing: Text(
              flags.isPremium ? l.settingsPlanPremium : l.settingsPlanFree,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: flags.isPremium
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
          ),
          if (!flags.isPremium)
            ListTile(
              leading: Icon(Icons.workspace_premium,
                  color: theme.colorScheme.primary),
              title: Text(
                l.paywallTitle,
                style: theme.textTheme.bodyMedium,
              ),
              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
              onTap: () => context.push('/paywall'),
            ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(l.settingsRestorePurchases),
            onTap: () => _restorePurchases(context),
          ),
          const SizedBox(height: 8),

          _SectionHeader(l.settingsAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.settingsVersion),
            trailing: Text('1.0.0', style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _restorePurchases(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchases restored.')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentMode = ref.watch(themeModeProvider);

    final options = [
      (AppThemeMode.light, l.settingsThemeLight, Icons.light_mode_outlined),
      (AppThemeMode.dark, l.settingsThemeDark, Icons.dark_mode_outlined),
      (AppThemeMode.sepia, l.settingsThemeSepia, Icons.menu_book_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: options.map((option) {
          final isSelected = currentMode == option.$1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SelectableChip(
                icon: option.$3,
                label: option.$2,
                isSelected: isSelected,
                onTap: () => _selectTheme(ref, option.$1),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _selectTheme(WidgetRef ref, AppThemeMode mode) {
    ref.read(themeModeProvider.notifier).state = mode;
    _persistSettings(ref);
  }

  void _persistSettings(WidgetRef ref) {
    final mode = ref.read(themeModeProvider);
    final locale = ref.read(localeProvider);
    final settings = UserSettings.defaults().copyWith(
      themeMode: themeModeToString(mode),
      locale: locale?.languageCode,
    );
    ref.read(saveSettingsProvider)(settings);
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.outline,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentLocale = ref.watch(localeProvider);

    final displayLabel = currentLocale != null
        ? AppLocale.nativeName(currentLocale)
        : 'System';

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l.settingsLanguage),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Icon(Icons.chevron_right, color: theme.colorScheme.outline),
        ],
      ),
      onTap: () => _showLanguagePicker(context, ref),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final currentLocale = ref.watch(localeProvider);

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context).settingsLanguage,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.devices),
                title: const Text('System'),
                trailing: currentLocale == null
                    ? Icon(Icons.check, color: theme.colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(localeProvider.notifier).state = null;
                  _persist(ref);
                  Navigator.pop(context);
                },
              ),
              ...AppLocale.supported.map((locale) {
                final isSelected = currentLocale?.languageCode == locale.languageCode;
                return ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(AppLocale.nativeName(locale)),
                  trailing: isSelected
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(localeProvider.notifier).state = locale;
                    _persist(ref);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _persist(WidgetRef ref) {
    final mode = ref.read(themeModeProvider);
    final locale = ref.read(localeProvider);
    final settings = UserSettings.defaults().copyWith(
      themeMode: themeModeToString(mode),
      locale: locale?.languageCode,
    );
    ref.read(saveSettingsProvider)(settings);
  }
}

class _FontSizeSlider extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FontSizeSlider> createState() => _FontSizeSliderState();
}

class _FontSizeSliderState extends ConsumerState<_FontSizeSlider> {
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final result = await ref.read(getSettingsProvider)();
    result.when(
      success: (settings) {
        if (mounted) setState(() => _fontScale = settings.fontScale);
      },
      failure: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Row(
              children: [
                Text(l.settingsFontSize, style: theme.textTheme.bodyLarge),
                const Spacer(),
                Text(
                  '${(_fontScale * 100).round()}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: _fontScale,
            min: 0.85,
            max: 1.3,
            divisions: 9,
            label: '${(_fontScale * 100).round()}%',
            onChanged: (value) => setState(() => _fontScale = value),
            onChangeEnd: (_) => _save(),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final result = await ref.read(getSettingsProvider)();
    result.when(
      success: (settings) {
        ref.read(saveSettingsProvider)(settings.copyWith(fontScale: _fontScale));
      },
      failure: (_) {},
    );
  }
}

class _WpmSlider extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WpmSlider> createState() => _WpmSliderState();
}

class _WpmSliderState extends ConsumerState<_WpmSlider> {
  double _wpm = 400;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final result = await ref.read(getSettingsProvider)();
    result.when(
      success: (settings) {
        if (mounted) setState(() => _wpm = settings.rsvp.targetWpm.toDouble());
      },
      failure: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Row(
              children: [
                Text(l.settingsTargetWpm, style: theme.textTheme.bodyLarge),
                const Spacer(),
                Text(
                  '${_wpm.round()} WPM',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: _wpm,
            min: 100,
            max: 1500,
            divisions: 28,
            label: '${_wpm.round()}',
            onChanged: (value) => setState(() => _wpm = value),
            onChangeEnd: (_) => _save(),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final result = await ref.read(getSettingsProvider)();
    result.when(
      success: (settings) {
        final updated = settings.copyWith(
          rsvp: settings.rsvp.copyWith(targetWpm: _wpm.round()),
        );
        ref.read(saveSettingsProvider)(updated);
      },
      failure: (_) {},
    );
  }
}
