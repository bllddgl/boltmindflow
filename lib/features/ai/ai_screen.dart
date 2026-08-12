import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ai_artifact.dart';
import '../../l10n/gen/app_localizations.dart';
import 'ai_providers.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  int _tabIndex = 0;
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(aiNotifierProvider(widget.documentId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.aiTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.aiTabSummary),
              Tab(text: l.aiTabQuiz),
              Tab(text: l.aiTabQa),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SummaryTab(documentId: widget.documentId, state: state),
            _QuizTab(documentId: widget.documentId, state: state),
            _QaTab(
              documentId: widget.documentId,
              state: state,
              controller: _questionController,
              scrollController: _scrollController,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary tab
// ---------------------------------------------------------------------------

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab({required this.documentId, required this.state});
  final String documentId;
  final AiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return switch (state) {
      AiIdle() => _EmptyState(
          icon: Icons.summarize,
          label: l.aiNoArtifact,
          hint: l.aiNoArtifactHint,
          actionLabel: l.aiGenerateSummary,
          onAction: () => ref.read(aiNotifierProvider(documentId).notifier).loadSummary(),
        ),
      AiLoading() => const Center(child: CircularProgressIndicator()),
      AiSummaryLoaded(:final artifact) => _SummaryContent(artifact: artifact),
      _ => _EmptyState(
          icon: Icons.summarize,
          label: l.aiNoArtifact,
          hint: l.aiNoArtifactHint,
          actionLabel: l.aiGenerateSummary,
          onAction: () => ref.read(aiNotifierProvider(documentId).notifier).loadSummary(),
        ),
    };
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.artifact});
  final AiArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = artifact.payload as SummaryPayload;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary text
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payload.summary, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Key points
          if (payload.keyPoints.isNotEmpty) ...[
            Text(l(context).aiKeyPoints, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...payload.keyPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.bolt, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(point, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  AppLocalizations l(BuildContext context) => AppLocalizations.of(context);
}

// ---------------------------------------------------------------------------
// Quiz tab
// ---------------------------------------------------------------------------

class _QuizTab extends ConsumerWidget {
  const _QuizTab({required this.documentId, required this.state});
  final String documentId;
  final AiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    return switch (state) {
      AiIdle() => _EmptyState(
          icon: Icons.quiz,
          label: l.aiNoArtifact,
          hint: l.aiNoArtifactHint,
          actionLabel: l.aiGenerateQuiz,
          onAction: () => ref.read(aiNotifierProvider(documentId).notifier).loadQuiz(),
        ),
      AiLoading() => const Center(child: CircularProgressIndicator()),
      AiQuizLoaded() => _QuizContent(
          documentId: documentId,
          state: state,
        ),
      _ => _EmptyState(
          icon: Icons.quiz,
          label: l.aiNoArtifact,
          hint: l.aiNoArtifactHint,
          actionLabel: l.aiGenerateQuiz,
          onAction: () => ref.read(aiNotifierProvider(documentId).notifier).loadQuiz(),
        ),
    };
  }
}

class _QuizContent extends ConsumerWidget {
  const _QuizContent({required this.documentId, required this.state});
  final String documentId;
  final AiQuizLoaded state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final question = state.currentQuestion;
    final isCorrect = state.answerChecked &&
        state.selectedOption == question.answerIndex;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress
          Row(
            children: [
              Text(
                'Question ${state.currentIndex + 1} of ${state.payload.questions.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const Spacer(),
              Text(
                l.aiCheckAnswer,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (state.currentIndex + 1) / state.payload.questions.length,
            minHeight: 3,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 24),

          // Question
          Text(question.question, style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),

          // Options
          ...question.options.asMap().entries.map((entry) {
            final i = entry.key;
            final option = entry.value;
            final isSelected = state.selectedOption == i;
            final isAnswer = i == question.answerIndex;

            Color? bgColor;
            Color? borderColor;
            if (state.answerChecked) {
              if (isAnswer) {
                bgColor = theme.colorScheme.primaryContainer;
                borderColor = theme.colorScheme.primary;
              } else if (isSelected) {
                bgColor = theme.colorScheme.errorContainer;
                borderColor = theme.colorScheme.error;
              }
            } else if (isSelected) {
              bgColor = theme.colorScheme.surfaceContainerHighest;
              borderColor = theme.colorScheme.primary;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: state.answerChecked
                    ? null
                    : () => ref
                        .read(aiNotifierProvider(documentId).notifier)
                        .selectQuizOption(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgColor ?? theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor ?? theme.dividerColor,
                      width: isSelected || (state.answerChecked && isAnswer) ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: isSelected
                            ? Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                            : Text(
                                String.fromCharCode(65 + i),
                                style: theme.textTheme.labelSmall,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(option, style: theme.textTheme.bodyLarge)),
                      if (state.answerChecked && isAnswer)
                        Icon(Icons.check_circle, color: theme.colorScheme.primary),
                      if (state.answerChecked && isSelected && !isAnswer)
                        Icon(Icons.cancel, color: theme.colorScheme.error),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Feedback + action
          if (state.answerChecked) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrect
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCorrect ? l.aiCorrectAnswer : l.aiWrongAnswer,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isCorrect
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!state.isLast)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => ref
                      .read(aiNotifierProvider(documentId).notifier)
                      .nextQuestion(),
                  child: Text(l.onboardingContinue),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => ref
                      .read(aiNotifierProvider(documentId).notifier)
                      .loadQuiz(),
                  child: Text(l.reviewNext),
                ),
              ),
          ] else if (state.selectedOption != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => ref
                    .read(aiNotifierProvider(documentId).notifier)
                    .checkAnswer(),
                child: Text(l.aiCheckAnswer),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Q&A tab
// ---------------------------------------------------------------------------

class _QaTab extends ConsumerStatefulWidget {
  const _QaTab({
    required this.documentId,
    required this.state,
    required this.controller,
    required this.scrollController,
  });

  final String documentId;
  final AiState state;
  final TextEditingController controller;
  final ScrollController scrollController;

  @override
  ConsumerState<_QaTab> createState() => _QaTabState();
}

class _QaTabState extends ConsumerState<_QaTab> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final conversation = switch (widget.state) {
      AiQaLoaded(:final conversation) => conversation,
      _ => <QaTurn>[],
    };

    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    return Column(
      children: [
        Expanded(
          child: conversation.isEmpty
              ? _EmptyState(
                  icon: Icons.chat,
                  label: l.aiAskQuestion,
                  hint: l.aiAskHint,
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: conversation.length,
                  itemBuilder: (context, i) {
                    final turn = conversation[i];
                    final isUser = turn.role == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          turn.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isUser
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    decoration: InputDecoration(
                      hintText: l.aiAskHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: _send,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _send(widget.controller.text),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _send(String question) {
    if (question.trim().isEmpty) return;
    widget.controller.clear();
    ref.read(aiNotifierProvider(widget.documentId).notifier).askQuestion(question);
  }
}

// ---------------------------------------------------------------------------
// Shared empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.label,
    required this.hint,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(hint, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            )),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
