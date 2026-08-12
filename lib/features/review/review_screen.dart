import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import 'review_providers.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(reviewNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.reviewTitle)),
      body: switch (state) {
        ReviewInitial() || ReviewLoading() =>
          const Center(child: CircularProgressIndicator()),
        ReviewError(:final message) => _buildError(context, message, ref, l),
        ReviewLoaded() when state.isFinished =>
          _buildComplete(context, ref, l),
        ReviewLoaded(:final cards, :final currentIndex) =>
          _buildCard(context, ref, l, cards, currentIndex),
      },
    );
  }

  Widget _buildError(
    BuildContext context, String message, WidgetRef ref, AppLocalizations l) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(reviewNotifierProvider.notifier).load(),
              child: Text(l.libraryReparse),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplete(BuildContext context, WidgetRef ref, AppLocalizations l) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(l.reviewEmpty, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(l.reviewEmptyHint, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref.read(reviewNotifierProvider.notifier).reset(),
              child: Text(l.reviewNext),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    List cards,
    int currentIndex,
  ) {
    final theme = Theme.of(context);
    final card = cards[currentIndex];
    final remaining = cards.length - currentIndex;

    return Column(
      children: [
        // Progress header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text(
                l.reviewDueToday(remaining),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const Spacer(),
              Text(
                '${currentIndex + 1} / ${cards.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: currentIndex / cards.length,
          minHeight: 3,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),

        // Card area
        Expanded(child: _ReviewCardView(card: card)),

        // Grade buttons
        _GradeButtons(cardId: card.id),
      ],
    );
  }
}

class _ReviewCardView extends StatefulWidget {
  const _ReviewCardView({required this.card});
  final dynamic card;

  @override
  State<_ReviewCardView> createState() => _ReviewCardViewState();
}

class _ReviewCardViewState extends State<_ReviewCardView>
    with SingleTickerProviderStateMixin {
  bool _showAnswer = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(_ReviewCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _showAnswer = false;
      _flipController.reset();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_showAnswer) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showAnswer = !_showAnswer);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final front = widget.card.front as String;
    final back = widget.card.back as String;
    final cardType = widget.card.cardType;

    return GestureDetector(
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              return Transform.flip(
                flipX: _flipAnimation.value > 0.5,
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Card type badge
                  _CardTypeBadge(type: cardType),
                  const SizedBox(height: 24),

                  // Question or answer
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showAnswer
                        ? Text(
                            back,
                            key: const ValueKey('answer'),
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          )
                        : Text(
                            front,
                            key: const ValueKey('question'),
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    _showAnswer ? '' : 'Tap to show answer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardTypeBadge extends StatelessWidget {
  const _CardTypeBadge({required this.type});
  final dynamic type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (type) {
      ReviewCardType.flashcard => 'Flashcard',
      ReviewCardType.vocab => 'Vocabulary',
      ReviewCardType.quiz => 'Quiz',
      _ => 'Card',
    };
    final icon = switch (type) {
      ReviewCardType.flashcard => Icons.style,
      ReviewCardType.vocab => Icons.translate,
      ReviewCardType.quiz => Icons.quiz,
      _ => Icons.style,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeButtons extends ConsumerStatefulWidget {
  const _GradeButtons({required this.cardId});
  final String cardId;

  @override
  ConsumerState<_GradeButtons> createState() => _GradeButtonsState();
}

class _GradeButtonsState extends ConsumerState<_GradeButtons> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notifier = ref.read(reviewNotifierProvider.notifier);

    if (!_showAnswer) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => setState(() => _showAnswer = true),
            child: Text(l.reviewShowAnswer),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: _GradeButton(
              label: l.reviewAgain,
              color: theme.colorScheme.error,
              onPressed: () => notifier.grade(ReviewGrade.again),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _GradeButton(
              label: l.reviewHard,
              color: theme.colorScheme.error.withValues(alpha: 0.7),
              onPressed: () => notifier.grade(ReviewGrade.hard),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _GradeButton(
              label: l.reviewGood,
              color: theme.colorScheme.primary,
              onPressed: () => notifier.grade(ReviewGrade.good),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _GradeButton(
              label: l.reviewEasy,
              color: theme.colorScheme.tertiary,
              onPressed: () => notifier.grade(ReviewGrade.easy),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
