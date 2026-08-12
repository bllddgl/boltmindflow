/// A cached AI-generated artifact (summary, quiz, Q&A, etc.).
class AiArtifact {
  const AiArtifact({
    required this.id,
    required this.documentId,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.modelId,
    required this.tokenCost,
  });

  final String id;
  final String documentId;
  final ArtifactType type;
  final AiPayload payload;
  final DateTime createdAt;
  final String? modelId;
  final int? tokenCost;
}

enum ArtifactType { summary, quiz, qa, flashcards, vocabulary, insight }

/// Sealed payload so the renderer switches exhaustively per artifact type.
sealed class AiPayload {
  const AiPayload();
}

class SummaryPayload extends AiPayload {
  const SummaryPayload({required this.summary, required this.keyPoints});
  final String summary;
  final List<String> keyPoints;
}

class QuizPayload extends AiPayload {
  const QuizPayload({required this.questions});
  final List<QuizQuestion> questions;
}

class QuizQuestion {
  const QuizQuestion({required this.question, required this.options, required this.answerIndex});
  final String question;
  final List<String> options;
  final int answerIndex;
}

class QaPayload extends AiPayload {
  const QaPayload({required this.conversation});
  final List<QaTurn> conversation;
}

class QaTurn {
  const QaTurn({required this.role, required this.content});
  final String role; // 'user' | 'assistant'
  final String content;
}

class FlashcardsPayload extends AiPayload {
  const FlashcardsPayload({required this.cards});
  final List<({String front, String back})> cards;
}

class VocabularyPayload extends AiPayload {
  const VocabularyPayload({required this.entries});
  final List<VocabEntry> entries;
}

class VocabEntry {
  const VocabEntry({required this.word, required this.definition, required this.synonyms, required this.example});
  final String word;
  final String definition;
  final List<String> synonyms;
  final String example;
}

class InsightPayload extends AiPayload {
  const InsightPayload({required this.insight});
  final String insight;
}
