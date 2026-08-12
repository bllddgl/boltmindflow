import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import 'stats_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(statsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.statsTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(statsNotifierProvider.notifier).load(),
        child: switch (state) {
          StatsLoading() => const Center(child: CircularProgressIndicator()),
          StatsError(:final message) =>
            _buildError(context, message, ref, l),
          StatsLoaded(:final snapshot, :final isPremium) =>
            _buildContent(context, snapshot, isPremium, ref, l),
        },
      ),
    );
  }

  Widget _buildError(
    BuildContext context, String message, WidgetRef ref, AppLocalizations l) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 200),
        Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(message, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(statsNotifierProvider.notifier).load(),
                child: Text(l.libraryReparse),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    StatsSnapshot snapshot,
    bool isPremium,
    WidgetRef ref,
    AppLocalizations l,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Streak card
        _StreakCard(streak: snapshot.currentStreakDays, l: l),
        const SizedBox(height: 16),

        // Key metrics grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _MetricCard(
              icon: Icons.timer_outlined,
              label: l.statsReadingTime,
              value: _formatDuration(snapshot.totalReadingTime),
              color: Theme.of(context).colorScheme.primary,
            ),
            _MetricCard(
              icon: Icons.speed,
              label: l.statsAvgWpm,
              value: '${snapshot.avgWpm}',
              color: Theme.of(context).colorScheme.tertiary,
            ),
            _MetricCard(
              icon: Icons.text_snippets_outlined,
              label: l.statsWordsRead,
              value: _formatNumber(snapshot.wordsRead),
              color: Theme.of(context).colorScheme.secondary,
            ),
            _MetricCard(
              icon: Icons.menu_book,
              label: l.statsBooksCompleted,
              value: '${snapshot.booksCompleted}',
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Focus score
        _FocusCard(focusScore: snapshot.focusScore, l: l),
        const SizedBox(height: 16),

        // Daily reading chart
        _DailyChart(dailyMinutes: snapshot.dailyMinutes, l: l),
        const SizedBox(height: 16),

        // Premium upsell
        if (!isPremium) _PremiumUpsell(context, l),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.l});
  final int streak;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.local_fire_department,
                size: 32,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.statsCurrentStreak(streak),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streak > 0 ? 'Keep it going!' : 'Start reading today',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.focusScore, required this.l});
  final double focusScore;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (focusScore * 100).round();
    final color = focusScore > 0.7
        ? theme.colorScheme.primary
        : focusScore > 0.4
            ? theme.colorScheme.tertiary
            : theme.colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: focusScore,
                      strokeWidth: 6,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: color,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.statsFocusScore, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    _focusLabel(focusScore),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _focusLabel(double score) {
    if (score > 0.8) return 'Excellent focus';
    if (score > 0.6) return 'Good focus';
    if (score > 0.4) return 'Moderate focus';
    return 'Needs improvement';
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.dailyMinutes, required this.l});
  final List<int> dailyMinutes;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxMinutes = dailyMinutes.isEmpty
        ? 1
        : math.max(dailyMinutes.reduce(math.max), 1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.statsDailyReading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Last ${dailyMinutes.length} days',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dailyMinutes.map((minutes) {
                  final heightFraction = minutes / maxMinutes;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (minutes > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${minutes}m',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          Flexible(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: (heightFraction * 80).clamp(4.0, 80.0),
                              decoration: BoxDecoration(
                                color: minutes > 0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumUpsell extends StatelessWidget {
  const _PremiumUpsell(this.context, this.l);
  final BuildContext context;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.workspace_premium, size: 40,
                color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(height: 12),
            Text(
              'Unlock All-Time Stats',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Premium unlocks your full reading history, advanced charts, and deeper insights.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/paywall'),
              child: const Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
