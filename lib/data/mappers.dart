import '../domain/entities/ai_artifact.dart';
import '../domain/entities/bookmark.dart';
import '../domain/entities/content_block.dart';
import '../domain/entities/document.dart';
import '../domain/entities/reading_session.dart';
import '../domain/entities/review_card.dart';
import '../domain/entities/user_settings.dart';

/// Map between Supabase row maps and domain entities.
///
/// Centralized so each repository doesn't repeat serialization logic. If the
/// schema changes, only this file needs updating.
class Mappers {
  Mappers._();

  // ---------------------------------------------------------------------------
  // ContentBlock
  // ---------------------------------------------------------------------------
  static ContentBlock blockFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'heading' => HeadingBlock(text: json['text'] as String, level: (json['level'] as num).toInt()),
      'paragraph' => ParagraphBlock(
          text: json['text'] as String,
          difficulty: Difficulty.values.firstWhere(
            (d) => d.name == (json['difficulty'] as String? ?? 'medium'),
            orElse: () => Difficulty.medium,
          )),
      'list' => ListBlock(
          ordered: json['ordered'] as bool? ?? false,
          items: (json['items'] as List).map((e) => ListItem(
                text: (e as Map)['text'] as String,
                level: (e['level'] as num?)?.toInt() ?? 0,
              )).toList()),
      'table' => TableBlock(
          header: (json['header'] as List?)?.map((e) => e as String).toList(),
          rows: (json['rows'] as List)
              .map((r) => (r as List).map((c) => c as String).toList())
              .toList()),
        ),
      'quote' => QuoteBlock(text: json['text'] as String, attribution: json['attribution'] as String?),
      'code' => CodeBlock(code: json['code'] as String, language: json['language'] as String?),
      'image' => ImageBlock(
          assetPath: json['assetPath'] as String,
          caption: json['caption'] as String?,
          displayDuration: json['displayDurationMs'] != null
              ? Duration(milliseconds: (json['displayDurationMs'] as num).toInt())
              : null),
      'footnote' => FootnoteBlock(text: json['text'] as String, number: json['number'] as int?),
      'caption' => CaptionBlock(text: json['text'] as String),
      'formula' => FormulaBlock(latex: json['latex'] as String),
      _ => ParagraphBlock(text: json['text'] as String? ?? ''),
    };
  }

  static Map<String, dynamic> blockToJson(ContentBlock block) {
    return switch (block) {
      HeadingBlock(:final text, :final level) => {'type': 'heading', 'text': text, 'level': level},
      ParagraphBlock(:final text, :final difficulty) =>
        {'type': 'paragraph', 'text': text, 'difficulty': difficulty.name},
      ListBlock(:final items, :final ordered) => {
        'type': 'list',
        'ordered': ordered,
        'items': items.map((i) => {'text': i.text, 'level': i.level}).toList(),
      },
      TableBlock(:final rows, :final header) => {'type': 'table', 'rows': rows, 'header': header},
      QuoteBlock(:final text, :final attribution) =>
        {'type': 'quote', 'text': text, 'attribution': attribution},
      CodeBlock(:final code, :final language) => {'type': 'code', 'code': code, 'language': language},
      ImageBlock(:final assetPath, :final caption, :final displayDuration) => {
        'type': 'image',
        'assetPath': assetPath,
        'caption': caption,
        'displayDurationMs': displayDuration?.inMilliseconds,
      },
      FootnoteBlock(:final text, :final number) => {'type': 'footnote', 'text': text, 'number': number},
      CaptionBlock(:final text) => {'type': 'caption', 'text': text},
      FormulaBlock(:final latex) => {'type': 'formula', 'latex': latex},
    };
  }

  static List<ContentBlock> blocksFromJsonList(List<dynamic> jsonList) =>
      jsonList.cast<Map<String, dynamic>>().map(blockFromJson).toList();

  static List<Map<String, dynamic>> blocksToJsonList(List<ContentBlock> blocks) =>
      blocks.map(blockToJson).toList();

  // ---------------------------------------------------------------------------
  // Document
  // ---------------------------------------------------------------------------
  static Document documentFromRow(Map<String, dynamic> row) {
    return Document(
      id: row['id'] as String,
      title: row['title'] as String,
      author: row['author'] as String?,
      sourcePath: row['source_path'] as String,
      sourceFormat: row['source_format'] as String,
      wordCount: (row['word_count'] as num).toInt(),
      coverPath: row['cover_path'] as String?,
      parseConfidence: (row['parse_confidence'] as num?)?.toDouble() ?? 1.0,
      importedAt: DateTime.parse(row['imported_at'] as String),
      lastPosition: (row['last_position'] as num?)?.toInt() ?? 0,
      lastReadAt: row['last_read_at'] != null ? DateTime.parse(row['last_read_at'] as String) : null,
      isArchived: row['is_archived'] as bool? ?? false,
    );
  }

  // ---------------------------------------------------------------------------
  // Bookmark
  // ---------------------------------------------------------------------------
  static Bookmark bookmarkFromRow(Map<String, dynamic> row) {
    return Bookmark(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      blockIndex: (row['block_index'] as num).toInt(),
      label: row['label'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  // ---------------------------------------------------------------------------
  // ReadingSession
  // ---------------------------------------------------------------------------
  static ReadingSession sessionFromRow(Map<String, dynamic> row) {
    return ReadingSession(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      startedAt: DateTime.parse(row['started_at'] as String),
      endedAt: row['ended_at'] != null ? DateTime.parse(row['ended_at'] as String) : null,
      wordsRead: (row['words_read'] as num).toInt(),
      blocksRead: (row['blocks_read'] as num).toInt(),
      avgWpm: (row['avg_wpm'] as num).toInt(),
      focusScore: (row['focus_score'] as num).toDouble(),
    );
  }

  // ---------------------------------------------------------------------------
  // ReviewCard
  // ---------------------------------------------------------------------------
  static ReviewCard reviewCardFromRow(Map<String, dynamic> row) {
    return ReviewCard(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      cardType: ReviewCardType.values.firstWhere(
        (t) => t.name == (row['card_type'] as String),
        orElse: () => ReviewCardType.flashcard,
      ),
      front: row['front'] as String,
      back: row['back'] as String,
      ease: (row['ease'] as num).toDouble(),
      intervalDays: (row['interval_days'] as num).toInt(),
      repetitions: (row['repetitions'] as num).toInt(),
      dueAt: DateTime.parse(row['due_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  // ---------------------------------------------------------------------------
  // AiArtifact
  // ---------------------------------------------------------------------------
  static AiArtifact aiArtifactFromRow(Map<String, dynamic> row) {
    return AiArtifact(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      type: ArtifactType.values.firstWhere(
        (t) => t.name == (row['artifact_type'] as String),
        orElse: () => ArtifactType.summary,
      ),
      payload: _aiPayloadFromJson(row['artifact_type'] as String, row['payload'] as Map<String, dynamic>),
      createdAt: DateTime.parse(row['created_at'] as String),
      modelId: row['model_id'] as String?,
      tokenCost: (row['token_cost'] as num?)?.toInt(),
    );
  }

  static AiPayload _aiPayloadFromJson(String type, Map<String, dynamic> json) {
    return switch (type) {
      'summary' => SummaryPayload(
          summary: json['summary'] as String,
          keyPoints: (json['keyPoints'] as List).cast<String>(),
        ),
      'quiz' => QuizPayload(
          questions: (json['questions'] as List)
              .map((q) => QuizQuestion(
                    question: (q as Map)['question'] as String,
                    options: ((q['options'] as List).cast<String>()),
                    answerIndex: (q['answerIndex'] as num).toInt(),
                  ))
              .toList(),
        ),
      'qa' => QaPayload(
          conversation: (json['conversation'] as List)
              .map((t) => QaTurn(
                    role: (t as Map)['role'] as String,
                    content: t['content'] as String,
                  ))
              .toList(),
        ),
      'flashcards' => FlashcardsPayload(
          cards: (json['cards'] as List)
              .map((c) => (front: (c as Map)['front'] as String, back: c['back'] as String))
              .toList(),
        ),
      'vocabulary' => VocabularyPayload(
          entries: (json['entries'] as List)
              .map((e) => VocabEntry(
                    word: (e as Map)['word'] as String,
                    definition: e['definition'] as String,
                    synonyms: ((e['synonyms'] as List).cast<String>()),
                    example: e['example'] as String,
                  ))
              .toList(),
        ),
      'insight' => InsightPayload(insight: json['insight'] as String),
      _ => InsightPayload(insight: json.toString()),
    };
  }

  // ---------------------------------------------------------------------------
  // UserSettings
  // ---------------------------------------------------------------------------
  static UserSettings settingsFromRow(Map<String, dynamic> row) {
    return UserSettings(
      themeMode: row['theme_mode'] as String? ?? 'light',
      locale: row['locale'] as String?,
      fontScale: (row['font_scale'] as num?)?.toDouble() ?? 1.0,
      rsvp: RsvpSettings(
        targetWpm: (row['target_wpm'] as num?)?.toInt() ?? 400,
        wordsPerDisplay: (row['words_per_display'] as num?)?.toInt() ?? 1,
        lineCount: (row['line_count'] as num?)?.toInt() ?? 1,
        imageDuration: Duration(milliseconds: (row['image_duration_ms'] as num?)?.toInt() ?? 2000),
        adaptiveSpeed: row['adaptive_speed'] as bool? ?? false,
      ),
    );
  }
}
