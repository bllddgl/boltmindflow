import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/features/ai/ai_providers.dart';
import 'package:mindflow/domain/entities/ai_artifact.dart';

void main() {
  group('AiState', () {
    test('idle state', () {
      expect(const AiIdle(), isA<AiState>());
    });

    test('loading state', () {
      expect(const AiLoading(), isA<AiState>());
    });

    test('error state carries message', () {
      const state = AiError('fail');
      expect(state.message, 'fail');
    });
  });

  group('AiQuizLoaded', () {
    final artifact = AiArtifact(
      id: 'a1',
      documentId: 'd1',
      type: ArtifactType.quiz,
      payload: const QuizPayload(
        questions: [
          QuizQuestion(question: 'Q1', options: ['A', 'B', 'C'], answerIndex: 0),
          QuizQuestion(question: 'Q2', options: ['A', 'B', 'C'], answerIndex: 2),
          QuizQuestion(question: 'Q3', options: ['A', 'B', 'C'], answerIndex: 1),
        ],
      ),
      createdAt: DateTime(2026, 1, 1),
      modelId: null,
      tokenCost: null,
    );

    test('currentIndex points to correct question', () {
      final state = AiQuizLoaded(artifact, 1, null, false);
      expect(state.currentQuestion.question, 'Q2');
    });

    test('isLast is false when not on last question', () {
      final state = AiQuizLoaded(artifact, 0, null, false);
      expect(state.isLast, isFalse);
    });

    test('isLast is true on last question', () {
      final state = AiQuizLoaded(artifact, 2, null, false);
      expect(state.isLast, isTrue);
    });

    test('payload returns QuizPayload', () {
      final state = AiQuizLoaded(artifact, 0, null, false);
      expect(state.payload, isA<QuizPayload>());
      expect(state.payload.questions.length, 3);
    });

    test('selectedOption tracks choice', () {
      final state = AiQuizLoaded(artifact, 1, 2, false);
      expect(state.selectedOption, 2);
    });

    test('answerChecked flag is independent of selectedOption', () {
      final unchecked = AiQuizLoaded(artifact, 0, 1, false);
      expect(unchecked.answerChecked, isFalse);
      final checked = AiQuizLoaded(artifact, 0, 1, true);
      expect(checked.answerChecked, isTrue);
    });
  });

  group('AiQaLoaded', () {
    test('carries conversation turns', () {
      const state = AiQaLoaded([
        QaTurn(role: 'user', content: 'What is this?'),
        QaTurn(role: 'assistant', content: 'A reading app.'),
      ]);
      expect(state.conversation.length, 2);
      expect(state.conversation.first.role, 'user');
      expect(state.conversation.last.role, 'assistant');
    });

    test('empty conversation is valid', () {
      const state = AiQaLoaded([]);
      expect(state.conversation, isEmpty);
    });
  });
}
