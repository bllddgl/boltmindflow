/// The universal content model.
///
/// Every parser emits a `List<ContentBlock>` in reading order. The RSVP engine,
/// renderer, and AI module all consume this stream — none of them knows about
/// PDF, EPUB, or any specific format. Adding a format = adding a parser that
/// emits blocks.
///
/// Sealed so every consumer's `switch` is exhaustive: adding a block type is a
/// compile error everywhere it isn't handled.
sealed class ContentBlock {
  const ContentBlock();

  /// Approximate word count for timing and stats.
  int get wordCount;
}

/// Reading difficulty, estimated by the parser via a cheap heuristic
/// (avg word length, sentence length, rare-word ratio). Feeds adaptive speed.
enum Difficulty { easy, medium, hard }

class HeadingBlock extends ContentBlock {
  const HeadingBlock({required this.text, required this.level});
  final String text;
  final int level; // 1..6

  @override
  int get wordCount => _words(text);
}

class ParagraphBlock extends ContentBlock {
  const ParagraphBlock({required this.text, this.difficulty = Difficulty.medium});
  final String text;
  final Difficulty difficulty;

  @override
  int get wordCount => _words(text);
}

class ListItem {
  const ListItem({required this.text, this.level = 0});
  final String text;
  final int level;
  int get wordCount => _words(text);
}

class ListBlock extends ContentBlock {
  const ListBlock({required this.items, required this.ordered});
  final List<ListItem> items;
  final bool ordered;

  @override
  int get wordCount => items.fold(0, (sum, item) => sum + item.wordCount);
}

class TableBlock extends ContentBlock {
  const TableBlock({required this.rows, this.header});
  final List<List<String>> rows;
  final List<String>? header;

  @override
  int get wordCount {
    final all = rows.expand((r) => r).join(' ');
    final h = header?.join(' ') ?? '';
    return _words('$h $all');
  }
}

class QuoteBlock extends ContentBlock {
  const QuoteBlock({required this.text, this.attribution});
  final String text;
  final String? attribution;

  @override
  int get wordCount => _words(text);
}

class CodeBlock extends ContentBlock {
  const CodeBlock({required this.code, this.language});
  final String code;
  final String? language;

  @override
  int get wordCount => _words(code);
}

class ImageBlock extends ContentBlock {
  const ImageBlock({required this.assetPath, this.caption, this.displayDuration});
  final String assetPath; // local path after extraction
  final String? caption;

  /// If null, the engine uses the global [RsvpSettings.imageDuration].
  final Duration? displayDuration;

  @override
  int get wordCount => 1; // images count as one "tick" for timing
}

class FootnoteBlock extends ContentBlock {
  const FootnoteBlock({required this.text, this.number});
  final String text;
  final int? number;

  @override
  int get wordCount => _words(text);
}

class CaptionBlock extends ContentBlock {
  const CaptionBlock({required this.text});
  final String text;

  @override
  int get wordCount => _words(text);
}

/// Phase 2 placeholder — stored as a LaTeX string until a renderer is added.
class FormulaBlock extends ContentBlock {
  const FormulaBlock({required this.latex});
  final String latex;

  @override
  int get wordCount => 1;
}

int _words(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return RegExp(r'\S+').allMatches(trimmed).length;
}
