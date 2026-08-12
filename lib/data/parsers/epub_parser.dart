import 'dart:io';

import 'package:epubx/epubx.dart';

import '../../domain/entities/content_block.dart';
import '../../domain/result.dart';
import '../../core/errors/failures.dart';
import 'difficulty_heuristic.dart';
import 'parser_registry.dart';

/// Parser for EPUB files (.epub).
///
/// Uses the `epubx` package to read the EPUB structure, extract metadata
/// (title, author), and iterate spine items in reading order. Each chapter's
/// HTML is converted to content blocks via a lightweight HTML-to-blocks
/// converter.
class EpubParser implements DocumentParser {
  @override
  List<String> get supportedExtensions => ['epub'];

  @override
  Future<Result<ParseOutput>> parse(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final book = await EpubReader.readBook(bytes);

      final blocks = <ContentBlock>[];
      final spine = book.Content?.Html ?? [];
      final orderedSpine = _sortSpine(spine, book.Spine);

      for (final chapter in orderedSpine) {
        final html = chapter.Content ?? '';
        if (html.trim().isEmpty) continue;
        blocks.addAll(_htmlToBlocks(html));
      }

      if (blocks.isEmpty) return const Result.failure(ParseFailure());

      final wordCount = blocks.fold(0, (sum, b) => sum + b.wordCount);
      final title = book.Title ?? _extractTitleFromPath(filePath);
      final author = book.Author;

      String? coverPath;
      if (book.CoverImage != null) {
        coverPath = 'epub_cover:${book.CoverImage!.MediaType ?? ''}';
      }

      return Result.success(ParseOutput(
        blocks: blocks,
        title: title,
        author: author,
        wordCount: wordCount,
        parseConfidence: 0.95,
        coverPath: coverPath,
      ));
    } catch (e) {
      return const Result.failure(ParseFailure());
    }
  }

  /// Sort HTML content files by the spine order defined in the OPF.
  List<EpubTextContentFile> _sortSpine(
    Map<String, EpubTextContentFile> html,
    List<Spine>? spine,
  ) {
    if (spine == null || spine.isEmpty) return html.values.toList();
    final ordered = <EpubTextContentFile>[];
    for (final entry in spine) {
      final idRef = entry.IdRef;
      if (idRef != null && html.containsKey(idRef)) {
        ordered.add(html[idRef]!);
      }
    }
    // Include any items not in the spine
    for (final entry in html.values) {
      if (!ordered.contains(entry)) ordered.add(entry);
    }
    return ordered;
  }

  /// Lightweight HTML → ContentBlock converter.
  ///
  /// Handles the common EPUB HTML tags: h1-h6, p, ul/ol/li, blockquote,
  /// pre/code, img, table. Not a full HTML parser — uses regex to extract
  /// block-level elements. Good enough for most EPUBs; the parseConfidence
  /// reflects this.
  List<ContentBlock> _htmlToBlocks(String html) {
    final blocks = <ContentBlock>[];
    final cleanHtml = _stripComments(html);

    // Headings
    for (var level = 1; level <= 6; level++) {
      final regex = RegExp('<h$level[^>]*>(.*?)</h$level>', multiLine: true, dotAll: true);
      for (final match in regex.allMatches(cleanHtml)) {
        final text = _stripTags(match.group(1)!).trim();
        if (text.isNotEmpty) blocks.add(HeadingBlock(text: text, level: level));
      }
    }

    // Paragraphs
    final pRegex = RegExp(r'<p[^>]*>(.*?)</p>', multiLine: true, dotAll: true);
    for (final match in pRegex.allMatches(cleanHtml)) {
      final text = _stripTags(match.group(1)!).trim();
      if (text.isNotEmpty) {
        blocks.add(ParagraphBlock(text: text, difficulty: estimateDifficulty(text)));
      }
    }

    // Blockquotes
    final quoteRegex = RegExp(r'<blockquote[^>]*>(.*?)</blockquote>', multiLine: true, dotAll: true);
    for (final match in quoteRegex.allMatches(cleanHtml)) {
      final text = _stripTags(match.group(1)!).trim();
      if (text.isNotEmpty) blocks.add(QuoteBlock(text: text));
    }

    // Code blocks
    final codeRegex = RegExp(r'<pre[^>]*>(.*?)</pre>', multiLine: true, dotAll: true);
    for (final match in codeRegex.allMatches(cleanHtml)) {
      final code = _stripTags(match.group(1)!).trim();
      if (code.isNotEmpty) blocks.add(CodeBlock(code: code));
    }

    // Lists
    final ulRegex = RegExp(r'<ul[^>]*>(.*?)</ul>', multiLine: true, dotAll: true);
    for (final match in ulRegex.allMatches(cleanHtml)) {
      final items = _extractListItems(match.group(1)!);
      if (items.isNotEmpty) blocks.add(ListBlock(items: items, ordered: false));
    }

    final olRegex = RegExp(r'<ol[^>]*>(.*?)</ol>', multiLine: true, dotAll: true);
    for (final match in olRegex.allMatches(cleanHtml)) {
      final items = _extractListItems(match.group(1)!);
      if (items.isNotEmpty) blocks.add(ListBlock(items: items, ordered: true));
    }

    // Images
    final imgRegex = RegExp(r'<img[^>]+src="([^"]+)"[^>]*(?:alt="([^"]*)")?[^>]*/?>');
    for (final match in imgRegex.allMatches(cleanHtml)) {
      final src = match.group(1)!;
      final alt = match.group(2);
      blocks.add(ImageBlock(assetPath: src, caption: alt));
    }

    return blocks;
  }

  List<ListItem> _extractListItems(String html) {
    final items = <ListItem>[];
    final liRegex = RegExp(r'<li[^>]*>(.*?)</li>', multiLine: true, dotAll: true);
    for (final match in liRegex.allMatches(html)) {
      final text = _stripTags(match.group(1)!).trim();
      if (text.isNotEmpty) items.add(ListItem(text: text));
    }
    return items;
  }

  String _stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  String _stripComments(String html) {
    return html.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
  }

  String _extractTitleFromPath(String filePath) {
    final slash = filePath.lastIndexOf('/');
    final dot = filePath.lastIndexOf('.');
    final start = slash < 0 ? 0 : slash + 1;
    final end = dot < 0 ? filePath.length : dot;
    return filePath.substring(start, end).replaceAll('_', ' ');
  }
}
