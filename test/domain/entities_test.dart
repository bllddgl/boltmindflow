import 'package:flutter_test/flutter_test.dart';

import 'package:mindflow/domain/entities/ai_artifact.dart';
import 'package:mindflow/domain/entities/bookmark.dart';
import 'package:mindflow/domain/entities/document.dart';
import 'package:mindflow/domain/entities/reading_session.dart';
import 'package:mindflow/domain/entities/review_card.dart';
import 'package:mindflow/domain/entities/stats_snapshot.dart';
import 'package:mindflow/domain/entities/user_settings.dart';

void main() {
  group('Document', () {
    test('progress is 0 when wordCount is 0', () {
      final doc = Document(
        id: 'd1',
        title: 'Test',
        author: null,
        sourcePath: '/tmp/test.txt',
        sourceFormat: 'txt',
        wordCount: 0,
        coverPath: null,
        parseConfidence: 1.0,
        importedAt: DateTime(2026, 1, 1),
        lastPosition: 0,
        lastReadAt: null,
        isArchived: false,
      );
      expect(doc.progress, 0.0);
    });

    test('progress is clamped to 1.0', () {
      final doc = Document(
        id: 'd1',
        title: 'Test',
        author: null,
        sourcePath: '/tmp/test.txt',
        sourceFormat: 'txt',
        wordCount: 100,
        coverPath: null,
        parseConfidence: 1.0,
        importedAt: DateTime(2026, 1, 1),
        lastPosition: 150,
        lastReadAt: null,
        isArchived: false,
      );
      expect(doc.progress, 1.0);
    });

    test('progress computes correctly', () {
      final doc = Document(
        id: 'd1',
        title: 'Test',
        author: null,
        sourcePath: '/tmp/test.txt',
        sourceFormat: 'txt',
        wordCount: 200,
        coverPath: null,
        parseConfidence: 1.0,
        importedAt: DateTime(2026, 1, 1),
        lastPosition: 50,
        lastReadAt: null,
        isArchived: false,
      );
      expect(doc.progress, 0.25);
    });

    test('copyWith updates only specified fields', () {
      final doc = Document(
        id: 'd1',
        title: 'Original',
        author: 'Author',
        sourcePath: '/tmp/test.txt',
        sourceFormat: 'txt',
        wordCount: 100,
        coverPath: null,
        parseConfidence: 1.0,
        importedAt: DateTime(2026, 1, 1),
        lastPosition: 0,
        lastReadAt: null,
        isArchived: false,
      );
      final updated = doc.copyWith(lastPosition: 50, isArchived: true);
      expect(updated.title, 'Original');
      expect(updated.lastPosition, 50);
      expect(updated.isArchived, isTrue);
      expect(updated.id, 'd1');
    });
  });

  group('ReadingSession', () {
    test('isFinished is true when endedAt is set', () {
      final session = ReadingSession(
        id: 's1',
        documentId: 'd1',
        startedAt: DateTime(2026, 1, 1, 10, 0),
        endedAt: DateTime(2026, 1, 1, 10, 30),
        wordsRead: 500,
        blocksRead: 10,
        avgWpm: 400,
        focusScore: 0.9,
      );
      expect(session.isFinished, isTrue);
      expect(session.duration, const Duration(minutes: 30));
    });

    test('isFinished is false when endedAt is null', () {
      final session = ReadingSession(
        id: 's1',
        documentId: 'd1',
        startedAt: DateTime(2026, 1, 1, 10, 0),
        endedAt: null,
        wordsRead: 0,
        blocksRead: 0,
        avgWpm: 0,
        focusScore: 0.0,
      );
      expect(session.isFinished, isFalse);
      expect(session.duration, isNull);
    });
  });

  group('ReviewCard', () {
    test('isDue is true when dueAt is in the past', () {
      final card = ReviewCard(
        id: 'c1',
        documentId: 'd1',
        cardType: ReviewCardType.flashcard,
        front: 'What is RSVP?',
        back: 'Rapid Serial Visual Presentation',
        ease: 2.5,
        intervalDays: 1,
        repetitions: 0,
        dueAt: DateTime(2020, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(card.isDue, isTrue);
    });

    test('isDue is false when dueAt is in the future', () {
      final card = ReviewCard(
        id: 'c1',
        documentId: 'd1',
        cardType: ReviewCardType.flashcard,
        front: 'What is RSVP?',
        back: 'Rapid Serial Visual Presentation',
        ease: 2.5,
        intervalDays: 1,
        repetitions: 0,
        dueAt: DateTime(2099, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(card.isDue, isFalse);
    });
  });

  group('Bookmark', () {
    test('constructs correctly', () {
      final bookmark = Bookmark(
        id: 'b1',
        documentId: 'd1',
        blockIndex: 5,
        label: 'Important section',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(bookmark.blockIndex, 5);
      expect(bookmark.label, 'Important section');
    });

    test('label can be null', () {
      final bookmark = Bookmark(
        id: 'b1',
        documentId: 'd1',
        blockIndex: 5,
        label: null,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(bookmark.label, isNull);
    });
  });

  group('StatsSnapshot', () {
    test('constructs with daily minutes list', () {
      final snapshot = StatsSnapshot(
        windowStart: DateTime(2026, 1, 1),
        windowEnd: DateTime(2026, 1, 8),
        totalReadingTime: const Duration(hours: 5),
        avgWpm: 400,
        wordsRead: 10000,
        booksCompleted: 2,
        focusScore: 0.85,
        currentStreakDays: 7,
        dailyMinutes: [30, 45, 20, 60, 15, 40, 50],
      );
      expect(snapshot.dailyMinutes.length, 7);
      expect(snapshot.totalReadingTime.inHours, 5);
    });
  });

  group('UserSettings', () {
    test('defaults are correct', () {
      final defaults = UserSettings.defaults();
      expect(defaults.themeMode, 'light');
      expect(defaults.locale, isNull);
      expect(defaults.fontScale, 1.0);
      expect(defaults.rsvp.targetWpm, 400);
      expect(defaults.rsvp.wordsPerDisplay, 1);
      expect(defaults.rsvp.adaptiveSpeed, isFalse);
    });

    test('copyWith updates themeMode', () {
      final defaults = UserSettings.defaults();
      final updated = defaults.copyWith(themeMode: 'dark');
      expect(updated.themeMode, 'dark');
      expect(updated.fontScale, 1.0);
    });

    test('RsvpSettings.copyWith updates targetWpm', () {
      const rsvp = RsvpSettings.defaults();
      final updated = rsvp.copyWith(targetWpm: 600);
      expect(updated.targetWpm, 600);
      expect(updated.wordsPerDisplay, 1);
    });
  });

  group('AiArtifact', () {
    test('SummaryPayload holds summary and keyPoints', () {
      const payload = SummaryPayload(
        summary: 'A brief summary.',
        keyPoints: ['Point 1', 'Point 2'],
      );
      expect(payload.summary, 'A brief summary.');
      expect(payload.keyPoints.length, 2);
    });

    test('QuizPayload holds questions', () {
      const payload = QuizPayload(
        questions: [
          QuizQuestion(
            question: 'What is 2+2?',
            options: ['3', '4', '5'],
            answerIndex: 1,
          ),
        ],
      );
      expect(payload.questions.length, 1);
      expect(payload.questions.first.answerIndex, 1);
    });

    test('QaPayload holds conversation turns', () {
      const payload = QaPayload(
        conversation: [
          QaTurn(role: 'user', content: 'What is this about?'),
          QaTurn(role: 'assistant', content: 'It is about reading.'),
        ],
      );
      expect(payload.conversation.length, 2);
      expect(payload.conversation.first.role, 'user');
    });

    test('FlashcardsPayload holds cards', () {
      const payload = FlashcardsPayload(
        cards: [(front: 'Front', back: 'Back')],
      );
      expect(payload.cards.length, 1);
      expect(payload.cards.first.front, 'Front');
      expect(payload.cards.first.back, 'Back');
    });

    test('VocabularyPayload holds entries', () {
      const payload = VocabularyPayload(
        entries: [
          VocabEntry(
            word: 'ephemeral',
            definition: 'lasting a very short time',
            synonyms: ['transient', 'fleeting'],
            example: 'An ephemeral phenomenon.',
          ),
        ],
      );
      expect(payload.entries.first.word, 'ephemeral');
      expect(payload.entries.first.synonyms.length, 2);
    });

    test('InsightPayload holds insight text', () {
      const payload = InsightPayload(insight: 'You read most on weekends.');
      expect(payload.insight, 'You read most on weekends.');
    });

    test('ArtifactType has all 6 types', () {
      expect(ArtifactType.values.length, 6);
      expect(ArtifactType.values, contains(ArtifactType.summary));
      expect(ArtifactType.values, contains(ArtifactType.quiz));
      expect(ArtifactType.values, contains(ArtifactType.qa));
      expect(ArtifactType.values, contains(ArtifactType.flashcards));
      expect(ArtifactType.values, contains(ArtifactType.vocabulary));
      expect(ArtifactType.values, contains(ArtifactType.insight));
    });
  });
}
