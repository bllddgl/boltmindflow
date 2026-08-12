import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/di/data_providers.dart';
import '../../domain/entities/ai_artifact.dart';
import '../../domain/result.dart';

/// AI view state — sealed for exhaustive switching.
sealed class AiState {
  const AiState();
}

class AiIdle extends AiState {
  const AiIdle();
}

class AiLoading extends AiState {
  const AiLoading();
}

class AiSummaryLoaded extends AiState {
  const AiSummaryLoaded(this.artifact);
  final AiArtifact artifact;
}

class AiQuizLoaded extends AiState {
  const AiQuizLoaded(this.artifact, this.currentIndex, this.selectedOption, this.answerChecked);
  final AiArtifact artifact;
  final int currentIndex;
  final int? selectedOption;
  final bool answerChecked;

  QuizPayload get payload => artifact.payload as QuizPayload;
  QuizQuestion get currentQuestion => payload.questions[currentIndex];
  bool get isLast => currentIndex >= payload.questions.length - 1;
}

class AiQaLoaded extends AiState {
  const AiQaLoaded(this.conversation);
  final List<QaTurn> conversation;
}

class AiError extends AiState {
  const AiError(this.message);
  final String message;
}

/// Notifier for the AI feature.
class AiNotifier extends StateNotifier<AiState> {
  AiNotifier(this._ref, this._documentId) : super(const AiIdle());

  final Ref _ref;
  final String _documentId;

  Future<void> loadSummary() async {
    state = const AiLoading();
    final result = await _ref.read(generateSummaryProvider)(_documentId);
    result.when(
      success: (artifact) => state = AiSummaryLoaded(artifact),
      failure: (f) => state = AiError(f.message),
    );
  }

  Future<void> loadQuiz() async {
    state = const AiLoading();
    final result = await _ref.read(generateQuizProvider)(_documentId);
    result.when(
      success: (artifact) => state = AiQuizLoaded(artifact, 0, null, false),
      failure: (f) => state = AiError(f.message),
    );
  }

  void selectQuizOption(int index) {
    final current = state;
    if (current is! AiQuizLoaded) return;
    state = AiQuizLoaded(current.artifact, current.currentIndex, index, false);
  }

  void checkAnswer() {
    final current = state;
    if (current is! AiQuizLoaded || current.selectedOption == null) return;
    state = AiQuizLoaded(
      current.artifact,
      current.currentIndex,
      current.selectedOption,
      true,
    );
  }

  void nextQuestion() {
    final current = state;
    if (current is! AiQuizLoaded || current.isLast) return;
    state = AiQuizLoaded(current.artifact, current.currentIndex + 1, null, false);
  }

  Future<void> askQuestion(String question) async {
    final current = state;
    final prevConversation = current is AiQaLoaded ? current.conversation : <QaTurn>[];

    state = AiQaLoaded([
      ...prevConversation,
      QaTurn(role: 'user', content: question),
    ]);

    final result = await _ref.read(askQuestionProvider)(_documentId, question);
    result.when(
      success: (artifact) {
        final payload = artifact.payload as QaPayload;
        state = AiQaLoaded([...prevConversation, ...payload.conversation]);
      },
      failure: (f) {
        state = AiQaLoaded([
          ...prevConversation,
          QaTurn(role: 'assistant', content: f.message),
        ]);
      },
    );
  }

  void reset() {
    state = const AiIdle();
  }
}

/// Family provider keyed by documentId.
final aiNotifierProvider = StateNotifierProvider.family
    .autoDispose<AiNotifier, AiState, String>(
  (ref, documentId) => AiNotifier(ref, documentId),
);
